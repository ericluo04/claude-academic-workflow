#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["httpx>=0.27", "lxml>=5.0", "pypdf>=4.0"]
# ///
"""
paper.py — resolve a paper reference to canonical metadata, then fetch the
cleanest available full text (LaTeX preferred, so equations survive intact).

Usage
-----
  paper.py resolve  "<query>"          # link | DOI | arXiv id | title | "author year topic"
  paper.py get      "<query>"          # resolve + fetch best full text -> markdown/LaTeX on stdout
  paper.py search   "<topic>"          # topic search across S2 + OpenAlex + arXiv, deduped
  paper.py author   "<name>"           # works by an author (OpenAlex), newest first
  paper.py cites    "<query>"          # what cites this / what it cites

Options
-------
  --venue "Marketing Science"   filter (author/resolve search)
  --since 2015 --until 2026     year bounds
  -n 10                         number of results
  --save                        write full text into the cache dir and print the path
  --raw                         for `get`: prefer raw LaTeX source over rendered HTML

Design
------
Full-text ladder, best-math-fidelity first:
  1. arXiv e-print tarball  -> raw LaTeX  (equations are the author's own source)
  2. arxiv.org/html/<id>    -> LaTeXML HTML; math carries alttext="<latex>"
  3. ar5iv.labs.arxiv.org   -> same, for papers predating native arXiv HTML
  4. OA PDF via Unpaywall / OpenAlex best_oa_location  (NBER, repositories, JMLR, PMLR...)
  5. Publisher landing page -> usually 403 for INFORMS/SSRN/Elsevier; caller should
     fall back to Claude in Chrome with the user's institutional session.

`search` is the topic-level entry point: one query per source (Semantic Scholar, OpenAlex,
arXiv), merged on DOI -> arXiv id -> normalized title and ranked by reciprocal-rank fusion.
Exactly one OpenAlex `search` call per invocation (10 credits, cached 30 days like everything
else). A source that errors or rate-limits is reported and skipped, never fatal.

Everything here uses keyless public APIs. Set S2_API_KEY to enable Semantic Scholar.
"""

from __future__ import annotations

import argparse
import io
import json
import os
import random
import re
import sys
import tarfile
import time
from pathlib import Path

import httpx
from lxml import html as lxml_html

# API keys live in ~/.claude/secrets/scholar.env (KEY=VALUE lines); real env vars win.
SECRETS = Path.home() / ".claude" / "secrets" / "scholar.env"
if SECRETS.exists():
    for _line in SECRETS.read_text().splitlines():
        _line = _line.strip()
        if _line and not _line.startswith("#") and "=" in _line:
            _k, _, _v = _line.partition("=")
            if _v.strip() and _k.strip() not in os.environ:
                os.environ[_k.strip()] = _v.strip()

# Set SCHOLAR_MAILTO (or edit the default) to your real address: Crossref, Unpaywall,
# and OpenAlex use it as the polite-pool contact and ask for a reachable one.
MAILTO = os.environ.get("SCHOLAR_MAILTO", "you@example.edu")
S2_KEY = os.environ.get("S2_API_KEY")
OA_KEY = os.environ.get("OPENALEX_API_KEY")
CACHE = Path(os.environ.get("PAPER_CACHE", Path.home() / ".claude" / "cache" / "papers"))
META_CACHE = CACHE / "meta"
UA = f"paper.py (mailto:{MAILTO})"
T = 40.0


def oa_params(**kw) -> dict:
    """OpenAlex params. Since 2026 OpenAlex meters by credit: a plain filter costs 1,
    anything using `search` (including `filter=title.search:`) costs 10. Anonymous budget
    is 1000 credits/day; a free key at openalex.org/settings/api raises it 10x."""
    p = {"mailto": MAILTO, **kw}
    if OA_KEY:
        p["api_key"] = OA_KEY
    return p


def _cache_fp(url: str, params: dict) -> Path:
    import hashlib

    key = hashlib.sha1(f"{url}?{sorted(params.items())}".encode()).hexdigest()[:20]
    return META_CACHE / f"{key}.json"


def _cache_load(fp: Path, ttl_days: int = 30):
    if fp.exists() and (time.time() - fp.stat().st_mtime) < ttl_days * 86400:
        try:
            return json.loads(fp.read_text())
        except Exception:
            pass
    return None


def _cache_store(fp: Path, data) -> None:
    META_CACHE.mkdir(parents=True, exist_ok=True)
    fp.write_text(json.dumps(data))


def cached_get(url: str, params: dict, ttl_days: int = 30,
               headers: dict | None = None) -> dict | None:
    """Disk-cache GET responses so repeat lookups don't re-spend API credit."""
    fp = _cache_fp(url, params)
    if (hit := _cache_load(fp, ttl_days)) is not None:
        return hit
    r = http_get(url, headers=headers, params=params)
    if r is None or r.status_code != 200:
        if r is not None and r.status_code == 429:
            _warn("OpenAlex credit budget exhausted for today — set OPENALEX_API_KEY for 10x headroom"
                  if "openalex.org" in url else f"{_host(url)} still rate-limited after backoff")
        return None
    try:
        data = r.json()
    except Exception:
        return None
    _cache_store(fp, data)
    return data

ARXIV_RE = re.compile(r"(?:arxiv\.org/(?:abs|pdf|html|e-print)/|arXiv:)\s*([0-9]{4}\.[0-9]{4,5})(v\d+)?", re.I)
BARE_ARXIV_RE = re.compile(r"^([0-9]{4}\.[0-9]{4,5})(v\d+)?$")
OLD_ARXIV_RE = re.compile(r"(?:arxiv\.org/(?:abs|pdf|html)/)?([a-z-]+(?:\.[A-Z]{2})?/[0-9]{7})", re.I)
DOI_RE = re.compile(r"\b(10\.\d{4,9}/[-._;()/:a-z0-9]+)", re.I)


def _client() -> httpx.Client:
    return httpx.Client(
        follow_redirects=True, timeout=T, headers={"User-Agent": UA}
    )


def _warn(msg: str) -> None:
    print(f"[paper.py] {msg}", file=sys.stderr)


def _host(url: str) -> str:
    m = re.match(r"https?://([^/]+)", url)
    return m.group(1) if m else url


def _retry_after(r: httpx.Response) -> float | None:
    v = r.headers.get("retry-after")
    if not v:
        return None
    try:
        return min(float(v), 30.0)  # cap; some servers send absurd values
    except ValueError:
        return None


def http_get(url: str, *, headers: dict | None = None, params: dict | None = None,
             retries: int = 4, base: float = 1.5) -> httpx.Response | None:
    """Polite GET with exponential backoff + jitter on 429/503 and transient network
    errors. Honors Retry-After. Every scholarly API here (OpenAlex, Semantic Scholar,
    arXiv, Crossref) rate-limits a shared IP, so all outbound gets route through this.
    Returns the final Response, or None if every attempt raised a network error."""
    hdrs = {"User-Agent": UA, **(headers or {})}
    last: httpx.Response | None = None
    for attempt in range(retries + 1):
        try:
            with httpx.Client(follow_redirects=True, timeout=T, headers=hdrs) as c:
                last = c.get(url, params=params)
        except (httpx.TransportError, httpx.TimeoutException):
            if attempt == retries:
                return None
            time.sleep(base * (2 ** attempt) + random.uniform(0, 0.5))
            continue
        if last.status_code in (429, 503) and attempt < retries:
            wait = _retry_after(last) or base * (2 ** attempt) + random.uniform(0, 0.5)
            _warn(f"{_host(url)} {last.status_code}; retry {attempt + 1}/{retries} in {wait:.1f}s")
            time.sleep(wait)
            continue
        return last
    return last


# --------------------------------------------------------------------------
# resolution
# --------------------------------------------------------------------------
def classify(q: str) -> tuple[str, str]:
    """Return (kind, value) for a raw user query."""
    q = q.strip().strip("<>").rstrip(".,;")
    if m := ARXIV_RE.search(q):
        return "arxiv", m.group(1)
    if m := BARE_ARXIV_RE.match(q):
        return "arxiv", m.group(1)
    if m := DOI_RE.search(q):
        return "doi", m.group(1).rstrip(").")
    if m := OLD_ARXIV_RE.search(q):
        return "arxiv", m.group(1)
    # publisher URLs whose DOI is derivable from the URL itself — avoids Cloudflare entirely
    if m := re.search(r"nber\.org/papers/(w\d+)", q, re.I):
        return "doi", f"10.3386/{m.group(1).lower()}"
    if m := re.search(r"ssrn\.com/(?:.*abstract_id=|abstract=)(\d+)", q, re.I):
        return "doi", f"10.2139/ssrn.{m.group(1)}"
    if q.lower().startswith(("http://", "https://", "www.")):
        return "url", q
    return "text", q


def openalex_by_doi(doi: str) -> dict | None:
    # a plain id lookup is the cheap path: 1 credit, not 10
    return cached_get(f"https://api.openalex.org/works/doi:{doi}", oa_params())


def openalex_source_id(name: str) -> str | None:
    """Venue name -> OpenAlex source id.

    OpenAlex retired `primary_location.source.display_name.search` as a filter (it now 400s
    with "not a valid field"), so venue filtering has to go through the source id. Cached, so
    the extra lookup is paid once per venue name. Exact display-name match wins over relevance
    rank: a search for "Marketing Science" also returns "Journal of the Academy of Marketing
    Science" and the AMS proceedings series.
    """
    data = cached_get("https://api.openalex.org/sources", oa_params(search=name, **{"per-page": 10}))
    results = (data or {}).get("results", [])
    want = _norm_title(name)
    for s in results:
        if _norm_title(s.get("display_name")) == want:
            return (s.get("id") or "").rsplit("/", 1)[-1] or None
    return ((results[0].get("id") or "").rsplit("/", 1)[-1] or None) if results else None


def _venue_filter(venue: str) -> str | None:
    if sid := openalex_source_id(venue):
        return f"primary_location.source.id:{sid}"
    _warn(f"no OpenAlex source matches {venue!r} — ignoring the venue filter")
    return None


def openalex_search(q: str, n: int = 5, venue: str | None = None,
                    since: int | None = None, until: int | None = None) -> list[dict] | None:
    """Costs 10 credits (any `search`). None means the request failed; [] means no hits."""
    filters = []
    if venue and (vf := _venue_filter(venue)):
        filters.append(vf)
    if since:
        filters.append(f"from_publication_date:{since}-01-01")
    if until:
        filters.append(f"to_publication_date:{until}-12-31")
    params = oa_params(search=q, **{"per-page": n})
    if filters:
        params["filter"] = ",".join(filters)
    data = cached_get("https://api.openalex.org/works", params)
    return None if data is None else data.get("results", [])


def crossref_search(q: str, n: int = 5) -> list[dict]:
    r = http_get(
        "https://api.crossref.org/works",
        params={"query.bibliographic": q, "rows": n, "mailto": MAILTO,
                "select": "DOI,title,container-title,author,issued,type"},
    )
    if r is None or r.status_code != 200:
        return []
    return r.json().get("message", {}).get("items", [])


def _norm_title(s: str) -> str:
    # punctuation becomes space (not deleted) so "Debt-Inflation" tokenizes as two words
    return " ".join(re.sub(r"[^a-z0-9]+", " ", (s or "").lower()).split())


def best_crossref_match(query: str, items: list[dict]) -> dict | None:
    """Confident known-item match from a Crossref title search, or None.

    Two traps handled here: fuzzy topic queries must NOT match (we fall through to
    OpenAlex search instead), and near-ties must prefer the journal version of record —
    Crossref routinely ranks the NBER/SSRN version above the published article.
    """
    nq = _norm_title(query)
    if len(nq.split()) < 3:
        return None
    hits = []
    for it in items:
        nt = _norm_title((it.get("title") or [""])[0])
        if not nt:
            continue
        qt, tt = set(nq.split()), set(nt.split())
        jacc = len(qt & tt) / max(1, len(qt | tt))
        if nq in nt or nt in nq or jacc >= 0.7:
            hits.append(it)
    if not hits:
        return None

    # SSRN masquerades as type=journal-article in "SSRN Electronic Journal", and NBER WPs
    # as reports — rank real journals above preprint containers, not just by Crossref type.
    def rank(h: dict) -> int:
        container = _norm_title((h.get("container-title") or [""])[0])
        if any(x in container for x in ("ssrn", "nber working paper", "cepr discussion")):
            return 0
        return 2 if h.get("type") == "journal-article" else 1

    return max(hits, key=rank)


def s2_get(path: str, params: dict | None = None, cache: bool = False) -> dict | None:
    # backoff matters most here: unauthenticated S2 shares one pool and 429s constantly
    headers = {"x-api-key": S2_KEY} if S2_KEY else None
    url = f"https://api.semanticscholar.org/graph/v1/{path}"
    if cache:  # opt-in: search results are worth the 30-day disk cache, live lookups aren't
        return cached_get(url, params or {}, headers=headers)
    r = http_get(url, headers=headers, params=params or {})
    if r is None:
        return None
    if r.status_code == 429:
        _warn("Semantic Scholar still 429 after backoff" + ("" if S2_KEY else " (no S2_API_KEY set — expected)"))
        return None
    return r.json() if r.status_code == 200 else None


def arxiv_meta(aid: str) -> dict | None:
    r = http_get("https://export.arxiv.org/api/query", params={"id_list": aid, "max_results": 1})
    if r is None or r.status_code != 200:
        return None
    try:
        doc = lxml_html.fromstring(r.content)
    except Exception:
        return None
    ns = {"a": "http://www.w3.org/2005/Atom"}
    tree = lxml_html.etree.fromstring(r.content)
    e = tree.find("a:entry", ns)
    if e is None:
        return None
    def txt(tag):
        el = e.find(f"a:{tag}", ns)
        return (el.text or "").strip() if el is not None else ""
    return {
        "arxiv_id": aid,
        "title": " ".join(txt("title").split()),
        "abstract": " ".join(txt("summary").split()),
        "published": txt("published")[:10],
        "authors": [a.findtext("a:name", namespaces=ns) for a in e.findall("a:author", ns)],
        "doi": (e.findtext("{http://arxiv.org/schemas/atom}doi") or "").strip() or None,
        "comment": (e.findtext("{http://arxiv.org/schemas/atom}comment") or "").strip(),
    }


def normalize_openalex(w: dict) -> dict:
    loc = w.get("best_oa_location") or w.get("primary_location") or {}
    ids = w.get("ids", {}) or {}
    arx = None
    for cand in (ids.get("arxiv"), (loc or {}).get("landing_page_url") or ""):
        if cand and (m := ARXIV_RE.search(str(cand)) or BARE_ARXIV_RE.match(str(cand))):
            arx = m.group(1)
            break
    cands = [u for l in (w.get("locations") or []) if (u := l.get("pdf_url"))]
    return {
        "title": w.get("title") or w.get("display_name"),
        "oa_candidates": cands or None,
        "doi": (w.get("doi") or "").replace("https://doi.org/", "") or None,
        "year": w.get("publication_year"),
        "venue": ((w.get("primary_location") or {}).get("source") or {}).get("display_name"),
        "authors": [a["author"]["display_name"] for a in (w.get("authorships") or [])][:12],
        "is_oa": (w.get("open_access") or {}).get("is_oa"),
        "oa_url": (w.get("open_access") or {}).get("oa_url"),
        "pdf_url": (loc or {}).get("pdf_url"),
        "landing": (loc or {}).get("landing_page_url"),
        "arxiv_id": arx,
        "cited_by": w.get("cited_by_count"),
        "openalex": w.get("id"),
    }


def aea_materials(doi: str) -> list[str]:
    """Free appendices / replication packages for an AEA paper (AER, AEJ, AER:Insights).

    aeaweb.org (the society site) is open even though the Atypon mirror and the article PDF
    are not — and the online appendix is usually where the proofs and derivations live.
    """
    if not doi.startswith("10.1257/"):
        return []
    r = http_get("https://www.aeaweb.org/articles", params={"id": doi})
    if r is None or r.status_code != 200:
        return []
    ids = sorted(set(re.findall(r"/articles/materials/(\d+)", r.text)))
    return [f"https://www.aeaweb.org/articles/materials/{i}" for i in ids]


def nber_pdf(doi: str) -> str | None:
    """NBER working papers expose a direct PDF path."""
    if m := re.match(r"10\.3386/(w\d+)", doi or "", re.I):
        w = m.group(1).lower()
        return f"https://www.nber.org/system/files/working_papers/{w}/{w}.pdf"
    return None


def unpaywall(doi: str) -> dict | None:
    r = http_get(f"https://api.unpaywall.org/v2/{doi}", params={"email": MAILTO})
    return r.json() if (r is not None and r.status_code == 200) else None


def resolve(q: str, venue=None, since=None, until=None, n=5) -> list[dict]:
    kind, val = classify(q)
    if kind == "arxiv":
        m = arxiv_meta(val) or {}
        rec = {"arxiv_id": val, "title": m.get("title"), "authors": m.get("authors", []),
               "year": (m.get("published") or "")[:4], "doi": m.get("doi"),
               "abstract": m.get("abstract"), "venue": "arXiv", "is_oa": True,
               "landing": f"https://arxiv.org/abs/{val}",
               "note": m.get("comment") or None}
        if rec.get("doi"):
            if w := openalex_by_doi(rec["doi"]):
                rec = {**normalize_openalex(w), **{k: v for k, v in rec.items() if v}}
        return [rec]
    if kind == "doi":
        if w := openalex_by_doi(val):
            rec = normalize_openalex(w)
        else:
            rec = {"doi": val, "title": None}
        # prefer NBER's real PDF path: OpenAlex often reports a bare doi.org link as the
        # "pdf_url", which only resolves to a landing page
        if p := nber_pdf(val):
            rec["pdf_url"] = p
        if mats := aea_materials(val):
            rec["aea_materials"] = mats
        if up := unpaywall(val):
            rec.setdefault("title", up.get("title"))
            best = up.get("best_oa_location") or {}
            rec["pdf_url"] = rec.get("pdf_url") or best.get("url_for_pdf")
            rec["landing"] = rec.get("landing") or best.get("url_for_landing_page")
            for lloc in up.get("oa_locations") or []:
                if u := lloc.get("url_for_pdf"):
                    rec.setdefault("oa_candidates", []).append(u)
                for u in (lloc.get("url_for_pdf"), lloc.get("url_for_landing_page")):
                    if u and (m := ARXIV_RE.search(u)):
                        rec["arxiv_id"] = rec.get("arxiv_id") or m.group(1)
        # S2 sometimes has a green-OA PDF (often NBER) where Unpaywall and OpenAlex say closed
        if not rec.get("pdf_url") and not rec.get("arxiv_id"):
            if s2 := s2_get(f"paper/DOI:{val}", {"fields": "openAccessPdf"}):
                if u := (s2.get("openAccessPdf") or {}).get("url"):
                    rec["pdf_url"], rec["is_oa"] = u, True
        return [rec]
    if kind == "url":
        r = http_get(val)
        if r is not None and r.status_code == 200:
            if m := DOI_RE.search(r.text[:400000]):
                return resolve(m.group(1))
        return [{"landing": val, "title": None}]

    # known-item title? Crossref is free and OpenAlex `search` costs 10 credits, so try
    # Crossref first and only pay for OpenAlex search when the free path isn't confident.
    if not venue and not since and not until:
        if best := best_crossref_match(val, crossref_search(val, 5)):
            if w := openalex_by_doi(best["DOI"]):  # 1 credit, cached
                return [normalize_openalex(w)]
    works = openalex_search(val, n=n, venue=venue, since=since, until=until) or []
    recs = [normalize_openalex(w) for w in works]
    if not recs:
        recs = [{"doi": it.get("DOI"), "title": (it.get("title") or [None])[0],
                 "venue": (it.get("container-title") or [None])[0]} for it in crossref_search(val, n)]
    return recs


# --------------------------------------------------------------------------
# topic search
# --------------------------------------------------------------------------
RRF_K = 60  # reciprocal-rank fusion constant (Cormack, Clarke & Buettcher 2009)


def _oa_abstract(w: dict) -> str | None:
    """OpenAlex ships abstracts as an inverted index (word -> positions); invert it back."""
    inv = w.get("abstract_inverted_index") or {}
    pos: dict[int, str] = {}
    for word, idxs in inv.items():
        for i in idxs:
            pos[i] = word
    return " ".join(pos[i] for i in sorted(pos)) or None


def normalize_s2(p: dict) -> dict:
    ext = p.get("externalIds") or {}
    pid = p.get("paperId")
    return {
        "title": p.get("title"),
        "authors": [a.get("name") for a in (p.get("authors") or []) if a.get("name")][:12],
        "year": p.get("year"),
        "venue": p.get("venue") or None,
        "doi": ext.get("DOI") or None,
        "arxiv_id": ext.get("ArXiv") or None,
        "abstract": p.get("abstract"),
        "is_oa": p.get("isOpenAccess"),
        # openAccessPdf.url is "" (present but empty) when S2 knows the paper is closed
        "pdf_url": (p.get("openAccessPdf") or {}).get("url") or None,
        "landing": f"https://www.semanticscholar.org/paper/{pid}" if pid else None,
        "citations": {"semanticscholar": p.get("citationCount")},
    }


def s2_search(q: str, n: int = 20, venue: str | None = None,
              since: int | None = None, until: int | None = None) -> list[dict] | None:
    """Semantic Scholar relevance search. None means the source failed (429 / network)."""
    params = {"query": q, "limit": min(n, 100),
              "fields": ("title,abstract,year,venue,externalIds,citationCount,"
                         "isOpenAccess,openAccessPdf,authors,publicationTypes")}
    if since or until:
        params["year"] = f"{since or ''}-{until or ''}"
    if venue:
        params["venue"] = venue
    data = s2_get("paper/search", params, cache=True)
    return None if data is None else (data.get("data") or [])


def arxiv_search(q: str, n: int = 20, since: int | None = None,
                 until: int | None = None) -> list[dict] | None:
    """arXiv Atom search. Cached by hand because the payload is XML, not JSON."""
    sq = f"all:{q}"
    if since or until:
        sq += f" AND submittedDate:[{since or 1991}01010000 TO {until or 2100}12312359]"
    url = "https://export.arxiv.org/api/query"
    params = {"search_query": sq, "start": 0, "max_results": min(n, 100), "sortBy": "relevance"}
    fp = _cache_fp(url, params)
    if (hit := _cache_load(fp)) is not None:
        return hit
    r = http_get(url, params=params)
    if r is None or r.status_code != 200:
        return None
    try:
        tree = lxml_html.etree.fromstring(r.content)
    except Exception:
        return None
    ns = {"a": "http://www.w3.org/2005/Atom"}
    out: list[dict] = []
    for e in tree.findall("a:entry", ns):
        def txt(tag: str, el=e) -> str:
            node = el.find(f"a:{tag}", ns)
            return " ".join((node.text or "").split()) if node is not None else ""
        eid = txt("id")
        if "api/errors" in eid:  # a malformed query comes back as one error entry, not a 400
            _warn(f"arXiv rejected the query: {txt('summary')[:120]}")
            return []
        m = ARXIV_RE.search(eid) or OLD_ARXIV_RE.search(eid)
        if not m:
            continue
        aid, pub = m.group(1), txt("published")[:4]
        out.append({
            "title": txt("title"),
            "authors": [a.findtext("a:name", namespaces=ns) for a in e.findall("a:author", ns)][:12],
            "year": int(pub) if pub.isdigit() else None,
            "venue": (e.findtext("{http://arxiv.org/schemas/atom}journal_ref") or "").strip() or "arXiv",
            "doi": (e.findtext("{http://arxiv.org/schemas/atom}doi") or "").strip() or None,
            "arxiv_id": aid,
            "abstract": txt("summary"),
            "is_oa": True,
            "landing": f"https://arxiv.org/abs/{aid}",
        })
    _cache_store(fp, out)
    return out


def _dedupe_keys(r: dict) -> list[str]:
    """Same identity ladder resolve() uses: DOI, then arXiv id, then normalized title."""
    keys = []
    if r.get("doi"):
        keys.append("doi:" + str(r["doi"]).lower().replace("https://doi.org/", ""))
    if r.get("arxiv_id"):
        keys.append("arxiv:" + re.sub(r"v\d+$", "", str(r["arxiv_id"]).lower()))
    if t := _norm_title(r.get("title")):
        keys.append("title:" + t)
    return keys


def _absorb(dst: dict, src: dict) -> None:
    """Fold one source's record into the merged one, keeping the richest value per field.
    First writer wins on scalars, so sources are fed in descending metadata quality."""
    for k, v in src.items():
        if k in ("citations", "sources", "ranks") or v in (None, "", [], {}):
            continue
        cur = dst.get(k)
        if cur in (None, "", [], {}):
            dst[k] = v
        elif k == "oa_candidates":
            dst[k] = list(dict.fromkeys(list(cur) + list(v)))
        elif k in ("authors", "abstract") and len(v) > len(cur):
            dst[k] = v
        elif k == "is_oa" and v:
            dst[k] = True  # OA is a positive claim: one source finding a free copy settles it
    for name, cnt in (src.get("citations") or {}).items():
        if cnt is not None:
            dst["citations"][name] = cnt


def topic_search(q: str, n: int = 10, venue: str | None = None,
                 since: int | None = None, until: int | None = None) -> dict:
    """One search per source, merged and re-ranked. Sources fail independently."""
    per = min(max(2 * n, 10), 50)  # headroom so dedupe doesn't eat the result count
    status: dict[str, dict] = {}
    merged: list[dict] = []
    index: dict[str, dict] = {}

    def add(name: str, recs: list[dict]) -> None:
        for rank, rec in enumerate(recs, 1):
            if not rec.get("title"):
                continue
            keys = _dedupe_keys(rec)
            tgt = next((index[k] for k in keys if k in index), None)
            if tgt is None:
                tgt = {"sources": [], "ranks": {}, "citations": {}}
                merged.append(tgt)
            _absorb(tgt, rec)
            if name not in tgt["ranks"]:
                tgt["sources"].append(name)
                tgt["ranks"][name] = rank
            for k in set(keys) | set(_dedupe_keys(tgt)):
                index.setdefault(k, tgt)  # setdefault: never steal a key from another group

    def run(name: str, fn, note: str | None = None) -> None:
        try:
            recs = fn()
        except Exception as e:  # a parser bug in one source must not sink the search
            recs, note = None, f"{type(e).__name__}: {e}"
        if recs is None:
            status[name] = {"ok": False, "hits": 0, "note": note or "no response (rate limit or network)"}
            _warn(f"{name} search failed — continuing with the other sources")
            return
        status[name] = {"ok": True, "hits": len(recs), "note": note}
        add(name, recs)

    # order matters: OpenAlex first because its record is the richest (venue, OA routing,
    # citation count consistent with resolve/author/cites), then S2, then arXiv.
    run("openalex", lambda: (lambda ws: None if ws is None else [
        {**normalize_openalex(w), "abstract": _oa_abstract(w),
         "citations": {"openalex": w.get("cited_by_count")}}
        for w in ws])(openalex_search(q, n=per, venue=venue, since=since, until=until)))
    run("semanticscholar", lambda: (lambda ps: None if ps is None else [normalize_s2(p) for p in ps])(
        s2_search(q, n=per, venue=venue, since=since, until=until)))
    if venue:
        status["arxiv"] = {"ok": True, "hits": 0, "note": "skipped: --venue, and arXiv has no venue field"}
    else:
        run("arxiv", lambda: arxiv_search(q, n=per, since=since, until=until))

    # second pass for near-identical titles the exact-key ladder missed (subtitle, punctuation)
    out: list[dict] = []
    for rec in merged:
        toks = set(_norm_title(rec.get("title")).split())
        twin = None
        for prev in out:
            ptoks = set(_norm_title(prev.get("title")).split())
            if toks and ptoks and len(toks & ptoks) / len(toks | ptoks) >= 0.9:
                twin = prev
                break
        if twin is None:
            out.append(rec)
            continue
        _absorb(twin, rec)
        for name, rk in rec["ranks"].items():
            if name not in twin["ranks"]:
                twin["sources"].append(name)
                twin["ranks"][name] = rk

    for rec in out:
        rec["rrf"] = round(sum(1 / (RRF_K + rk) for rk in rec["ranks"].values()), 6)
        # one count, one named source — the honesty rule is that counts across sources
        # disagree, so pick a source per record and say which rather than blending them
        for name in ("openalex", "semanticscholar"):
            if (c := rec["citations"].get(name)) is not None:
                rec["cited_by"], rec["cited_by_source"] = c, name
                break
        if rec.get("arxiv_id"):  # an arXiv id is a free copy, whatever S2 says about the VOR
            rec["is_oa"] = True
            rec["oa_url"] = rec.get("oa_url") or f"https://arxiv.org/abs/{rec['arxiv_id']}"
        rec["best_url"] = rec.get("pdf_url") or rec.get("oa_url") or rec.get("landing")
    out.sort(key=lambda r: (r["rrf"], r.get("cited_by") or 0), reverse=True)
    return {"query": q, "sources": status, "unique": len(out), "results": out[:n]}


# --------------------------------------------------------------------------
# full text
# --------------------------------------------------------------------------
def latex_from_arxiv_source(aid: str) -> str | None:
    """Download the e-print tarball and stitch the LaTeX together."""
    r = http_get(f"https://arxiv.org/e-print/{aid}")
    if r is None or r.status_code != 200 or not r.content:
        return None
    blob = r.content
    texts: dict[str, str] = {}
    try:
        with tarfile.open(fileobj=io.BytesIO(blob), mode="r:*") as tf:
            for m in tf.getmembers():
                if m.isfile() and m.name.lower().endswith((".tex", ".bbl")):
                    f = tf.extractfile(m)
                    if f:
                        texts[m.name] = f.read().decode("utf-8", "replace")
    except tarfile.TarError:
        # single gzipped .tex
        import gzip
        try:
            texts["main.tex"] = gzip.decompress(blob).decode("utf-8", "replace")
        except Exception:
            return None
    if not texts:
        return None

    main = next((k for k, v in texts.items() if "\\documentclass" in v), None)
    if main is None:
        main = max(texts, key=lambda k: len(texts[k]))

    seen: set[str] = set()

    def expand(name: str, depth: int = 0) -> str:
        if depth > 6 or name in seen:
            return ""
        seen.add(name)
        body = texts.get(name, "")

        def sub(m: re.Match) -> str:
            target = m.group(1).strip()
            for cand in (target, target + ".tex", target.lstrip("./"), target.lstrip("./") + ".tex"):
                for key in texts:
                    if key == cand or key.endswith("/" + cand):
                        return "\n" + expand(key, depth + 1) + "\n"
            return m.group(0)

        return re.sub(r"\\(?:input|include)\{([^}]+)\}", sub, body)

    doc = expand(main)
    doc = re.sub(r"(?<!\\)%.*$", "", doc, flags=re.M)          # strip comments
    doc = re.sub(r"\n{3,}", "\n\n", doc)
    return doc.strip()


def latex_sections(tex: str) -> list[tuple[str, str]]:
    """Split a LaTeX document into (section title, body) pairs."""
    body = tex
    if m := re.search(r"\\begin\{document\}", tex):
        body = tex[m.end():]
    parts = re.split(r"\\(?:sub)?section\*?\{", body)
    out: list[tuple[str, str]] = []
    if parts and parts[0].strip():
        out.append(("(front matter / abstract)", parts[0].strip()))
    for chunk in parts[1:]:
        # split the braced title off the front, respecting one level of nesting
        depth, cut = 1, None
        for i, ch in enumerate(chunk):
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    cut = i
                    break
        if cut is None:
            continue
        out.append((" ".join(chunk[:cut].split()), chunk[cut + 1:].strip()))
    return out


MACRO_RE = re.compile(
    r"^\s*\\(?:newcommand|renewcommand|providecommand|def|DeclareMathOperator\*?|"
    r"newtheorem\*?|newenvironment|let)\b.*$",
    re.M,
)


def preamble_macros(tex: str) -> str:
    """Author-defined macros from the preamble.

    Slicing a section out of raw LaTeX otherwise strips the definitions of things like
    \\newcommand{\\E}{\\mathbb{E}}, leaving equations referencing undefined commands.
    """
    head = tex[: m.start()] if (m := re.search(r"\\begin\{document\}", tex)) else tex
    lines = MACRO_RE.findall(head)
    return "\n".join(lines)


def pick_section(tex: str, want: str) -> str | None:
    secs = latex_sections(tex)
    w = want.lower()
    for title, body in secs:
        if w in title.lower():
            macros = preamble_macros(tex)
            head = (f"% ---- author macros carried over from the preamble ----\n"
                    f"{macros}\n% ---- end macros ----\n\n") if macros else ""
            return f"{head}\\section{{{title}}}\n\n{body}"
    return None


def _mathify(tree) -> None:
    """Replace LaTeXML <math> nodes with their alttext, so equations read as LaTeX."""
    for m in tree.xpath("//math"):
        alt = m.get("alttext")
        display = (m.get("display") or "").lower() == "block"
        repl = f"\n$$\n{alt}\n$$\n" if display else f"${alt}$"
        text = repl if alt else (m.text_content() or "")
        prev, parent = m.getprevious(), m.getparent()
        if parent is None:
            continue
        tail = m.tail or ""
        if prev is not None:
            prev.tail = (prev.tail or "") + text + tail
        else:
            parent.text = (parent.text or "") + text + tail
        parent.remove(m)


def html_to_markdown(raw: bytes) -> str:
    tree = lxml_html.fromstring(raw)
    for bad in tree.xpath("//script|//style|//nav|//footer|//noscript"):
        bad.getparent().remove(bad)
    _mathify(tree)
    out: list[str] = []
    body = tree.xpath("//article") or tree.xpath("//body") or [tree]
    for el in body[0].iter():
        tag = el.tag if isinstance(el.tag, str) else ""
        if tag in ("h1", "h2", "h3", "h4", "h5", "h6"):
            txt = " ".join(el.text_content().split())
            if txt:
                out.append("\n" + "#" * int(tag[1]) + " " + txt + "\n")
        elif tag in ("p", "li", "figcaption", "td"):
            txt = " ".join(el.text_content().split())
            if txt:
                out.append(("- " if tag == "li" else "") + txt)
    md, seen = [], set()
    for line in out:
        key = line.strip()
        if key and key in seen:
            continue
        seen.add(key)
        md.append(line)
    return "\n\n".join(md)


_REF_HEAD_RE = re.compile(
    r"(?im)^\s*(?:#{1,6}\s*)?(references|bibliography|works cited|literature cited)\s*$")


def classify_page(md: str) -> str:
    """Is an HTML page full text, an abstract stub, or unclear?

    A flat length threshold is unreliable: repository landing pages carry navigation,
    citation blocks, and related-article chrome that inflate length past 2500 chars with
    no body, while a short genuine note (an AER P&P piece, a Comment) is real full text
    under 800 words. Classify on structure instead."""
    words = len(md.split())
    headings = len(re.findall(r"(?m)^\s*#{1,6}\s", md))
    has_refs = bool(_REF_HEAD_RE.search(md))
    if has_refs or (headings >= 3 and words > 1500):
        return "full"
    if words < 800 and not has_refs:
        return "abstract"
    return "uncertain"


def pdf_links_in(raw: bytes, base_url: str) -> list[str]:
    """PDF URLs advertised on a landing page. `citation_pdf_url` (the Highwire/Google
    Scholar meta tag most repositories and publishers set) is the most reliable, so it
    goes first; then any <a> href that looks like a PDF."""
    try:
        tree = lxml_html.fromstring(raw)
    except Exception:
        return []
    try:
        tree.make_links_absolute(base_url, resolve_base_href=True)
    except Exception:
        pass
    out: list[str] = []
    out += tree.xpath("//meta[@name='citation_pdf_url']/@content")
    for a in tree.xpath("//a[@href]"):
        href = a.get("href") or ""
        low = href.lower()
        if low.endswith(".pdf") or "/pdf/" in low or low.endswith("/pdf") or "type=pdf" in low:
            out.append(href)
    seen, res = set(), []
    for u in out:
        if u and u.startswith("http") and u not in seen:
            seen.add(u)
            res.append(u)
    return res


def _save_pdf(content: bytes, rec: dict, url: str) -> tuple[str, str]:
    """Cache a PDF and flag it if it has no text layer (a scan needing OCR)."""
    CACHE.mkdir(parents=True, exist_ok=True)
    stem = re.sub(r"[^\w.-]", "_", (rec.get("doi") or rec.get("title") or "paper"))[:80]
    p = CACHE / f"{stem}.pdf"
    p.write_bytes(content)
    try:
        from pypdf import PdfReader
        sample = "".join((pg.extract_text() or "") for pg in PdfReader(str(p)).pages[:3])
        if len(sample.strip()) < 200:
            return (f"PDF {url} (SCANNED)",
                    f"[PDF saved: {p}]\nWARNING: no text layer — this is a scanned PDF."
                    "\nOCR it via ~/ocr-examples (HPC GPU engines, if you have that"
                    " pipeline) before reading;"
                    " see the OCR rung in the reading-papers skill.")
    except Exception:
        pass
    return f"PDF {url}", f"[PDF saved: {p}]\nRead it with the Read tool — it renders PDFs natively."


def fetch_fulltext(rec: dict, prefer_raw: bool = False) -> tuple[str, str]:
    """Return (source_label, text)."""
    aid = rec.get("arxiv_id")
    if aid:
        if prefer_raw:
            if tex := latex_from_arxiv_source(aid):
                return f"arxiv:e-print/{aid} (raw LaTeX)", tex
        for url, label in (
            (f"https://arxiv.org/html/{aid}", f"arxiv.org/html/{aid} (LaTeXML)"),
            (f"https://ar5iv.labs.arxiv.org/html/{aid}", f"ar5iv/{aid}"),
        ):
            r = http_get(url)
            if r is not None and r.status_code == 200 and b"<math" in r.content:
                return label, html_to_markdown(r.content)
        if tex := latex_from_arxiv_source(aid):
            return f"arxiv:e-print/{aid} (raw LaTeX)", tex

    seen_urls: set[str] = set()
    fallback: tuple[str, str] | None = None
    candidates = [rec.get("pdf_url"), *(rec.get("oa_candidates") or []),
                  rec.get("oa_url"), rec.get("landing")]
    for url in candidates:
        if not url or url in seen_urls:
            continue
        seen_urls.add(url)
        r = http_get(url)
        if r is None:
            _warn(f"{url}: network error after retries")
            continue
        ctype = r.headers.get("content-type", "")
        if r.status_code != 200:
            _warn(f"{url} -> HTTP {r.status_code}"
                  + (" (paywall/bot-wall; open it in Claude in Chrome with institutional access)"
                     if r.status_code in (401, 403) else ""))
            continue
        if "pdf" in ctype:
            return _save_pdf(r.content, rec, url)
        if "html" in ctype:
            md = html_to_markdown(r.content)
            if classify_page(md) == "full":
                return f"HTML {url}", md
            # abstract-only or unclear: many repository/publisher landing pages link the
            # actual PDF (the author manuscript) even when the body isn't inline. Follow it.
            for plink in pdf_links_in(r.content, str(r.url)):
                if plink in seen_urls:
                    continue
                seen_urls.add(plink)
                pr = http_get(plink)
                if pr is None or pr.status_code != 200:
                    continue
                pctype = pr.headers.get("content-type", "")
                if "pdf" in pctype:
                    return _save_pdf(pr.content, rec, f"{plink} (linked from {_host(url)})")
                if "html" in pctype:
                    md2 = html_to_markdown(pr.content)
                    if classify_page(md2) == "full":
                        return f"HTML {plink} (via {_host(url)})", md2
            note = "abstract-only" if classify_page(md) == "abstract" else "possibly partial"
            fallback = fallback or (f"HTML {url} ({note})", md)
    if fallback:
        _warn("only an abstract-length page was reachable — escalate per the skill ladder")
        return fallback
    return "none", ""


# --------------------------------------------------------------------------
# author / citation
# --------------------------------------------------------------------------
def author_works(name: str, n: int = 25, venue=None, since=None, until=None,
                 affiliation: str | None = None, orcid: str | None = None) -> dict:
    # An ORCID resolves deterministically — always prefer it when available.
    if orcid:
        oid = orcid.rsplit("/", 1)[-1]
        a = cached_get(f"https://api.openalex.org/authors/https://orcid.org/{oid}", oa_params())
        cands = [a] if a else []
    else:
        data = cached_get("https://api.openalex.org/authors",
                          oa_params(search=name, **{"per-page": 50}))
        cands = (data or {}).get("results", [])
        if affiliation:
            # match CURRENT institution only — the full historical `affiliations` list
            # produces false positives (someone who once passed through the institution)
            want = affiliation.lower()
            matched = [a for a in cands if any(
                want in (i.get("display_name") or "").lower()
                for i in (a.get("last_known_institutions") or []))]
            if not matched:
                return {"author": None, "affiliation_unmatched": affiliation,
                        "candidates": [{"name": a.get("display_name"),
                                        "inst": [(i.get("display_name")) for i in
                                                 (a.get("last_known_institutions") or [])],
                                        "orcid": a.get("orcid"),
                                        "works_count": a.get("works_count")} for a in cands[:15]],
                        "works": []}
            cands = matched
    if not cands:
        return {"author": None, "candidates": [], "works": []}
    # OpenAlex fragments one person across duplicate profiles; among true homonyms, though,
    # most-works is only a guess — callers should check the printed candidate list.
    best = max(cands, key=lambda a: a.get("works_count", 0))
    filters = [f"author.id:{best['id'].rsplit('/', 1)[-1]}"]
    if venue and (vf := _venue_filter(venue)):
        filters.append(vf)
    if since:
        filters.append(f"from_publication_date:{since}-01-01")
    if until:
        filters.append(f"to_publication_date:{until}-12-31")
    data = cached_get("https://api.openalex.org/works",
                      oa_params(filter=",".join(filters), sort="publication_date:desc",
                                **{"per-page": n}))
    works = (data or {}).get("results", [])
    return {
        "author": {"name": best.get("display_name"), "id": best.get("id"),
                   "works_count": best.get("works_count"),
                   "affiliation": ((best.get("last_known_institutions") or [{}])[0] or {}).get("display_name")},
        "candidates": [{"name": a.get("display_name"), "id": a.get("id"),
                        "works_count": a.get("works_count")} for a in cands],
        "works": [normalize_openalex(w) for w in works],
    }


def citations(q: str, n: int = 25) -> dict:
    rec = resolve(q)[0]
    oid = (rec.get("openalex") or "").rsplit("/", 1)[-1]
    out = {"paper": rec, "cited_by": [], "references": []}
    if not oid:
        return out
    # note: `cites:X` means "works that cite X" — the direction reads backwards
    d = cached_get("https://api.openalex.org/works",
                   oa_params(filter=f"cites:{oid}", sort="cited_by_count:desc", **{"per-page": n}))
    out["cited_by"] = [normalize_openalex(w) for w in (d or {}).get("results", [])]

    d = cached_get(f"https://api.openalex.org/works/{oid}", oa_params(select="referenced_works"))
    refs = (d or {}).get("referenced_works", [])[:n]
    if refs:
        ids = "|".join(x.rsplit("/", 1)[-1] for x in refs)
        d = cached_get("https://api.openalex.org/works",
                       oa_params(filter=f"openalex_id:{ids}", **{"per-page": n}))
        out["references"] = [normalize_openalex(w) for w in (d or {}).get("results", [])]
    return out


# --------------------------------------------------------------------------
def brief(r: dict) -> str:
    a = r.get("authors") or []
    who = ", ".join(a[:3]) + (" et al." if len(a) > 3 else "")
    bits = [f"**{r.get('title') or '(untitled)'}**", f"  {who} — {r.get('venue') or '?'} {r.get('year') or ''}"]
    if r.get("doi"):
        bits.append(f"  doi:{r['doi']}")
    if r.get("arxiv_id"):
        bits.append(f"  arXiv:{r['arxiv_id']}")
    if r.get("cited_by") is not None:
        # counts disagree across sources, so name the source whenever the record knows it
        bits.append(f"  cited_by={r['cited_by']}"
                    + (f" ({r['cited_by_source']})" if r.get("cited_by_source") else ""))
    if r.get("sources"):
        bits.append(f"  found in: {', '.join(r['sources'])}")
    oa = "OA" if r.get("is_oa") else "closed"
    bits.append(f"  [{oa}] {r.get('pdf_url') or r.get('oa_url') or r.get('landing') or ''}")
    if r.get("note"):
        bits.append(f"  note: {r['note']}")
    for m in r.get("aea_materials") or []:
        bits.append(f"  free AEA appendix/data: {m}")
    return "\n".join(bits)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("cmd", choices=["resolve", "get", "search", "author", "cites"])
    ap.add_argument("query")
    ap.add_argument("--venue")
    ap.add_argument("--since", type=int)
    ap.add_argument("--until", type=int)
    ap.add_argument("--affiliation", help="author: pin the name to an institution")
    ap.add_argument("--orcid", help="author: resolve deterministically by ORCID")
    ap.add_argument("--contexts", action="store_true",
                    help="cites: show the citing sentences (Semantic Scholar; needs S2_API_KEY)")
    ap.add_argument("-n", type=int, default=10)
    ap.add_argument("--save", action="store_true")
    ap.add_argument("--raw", action="store_true", help="prefer raw LaTeX source")
    ap.add_argument("--section", help="return only the LaTeX section whose title contains this")
    ap.add_argument("--list-sections", action="store_true", help="list LaTeX section titles and sizes")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args()

    if a.cmd == "resolve":
        recs = resolve(a.query, a.venue, a.since, a.until, a.n)
        print(json.dumps(recs, indent=2) if a.json else "\n\n".join(brief(r) for r in recs) or "no match")
        return

    if a.cmd == "search":
        res = topic_search(a.query, n=a.n, venue=a.venue, since=a.since, until=a.until)
        if a.json:
            print(json.dumps(res, indent=2)); return
        line = []
        for name, st in res["sources"].items():
            tag = f"{name} {st['hits']}" if st["ok"] else f"{name} FAILED"
            line.append(tag + (f" ({st['note']})" if st.get("note") else ""))
        print(f"# search {a.query!r} — showing {len(res['results'])} of {res['unique']} unique papers")
        print("#   " + " | ".join(line) + "\n")
        if not res["results"]:
            print("no results")
            return
        for r in res["results"]:
            print(brief(r) + "\n")
        return

    if a.cmd == "author":
        res = author_works(a.query, a.n, a.venue, a.since, a.until,
                           affiliation=a.affiliation, orcid=a.orcid)
        if a.json:
            print(json.dumps(res, indent=2)); return
        if not res["author"]:
            if res.get("affiliation_unmatched"):
                print(f"No '{a.query}' found at {res['affiliation_unmatched']!r}. "
                      "Closest name matches (pick one and re-run with its ORCID):")
                for c in res["candidates"]:
                    print(f"  {c['works_count']:>5} works  {c['name']}  "
                          f"{c['inst']}  {c.get('orcid') or ''}")
            else:
                print("no author match")
            return
        au = res["author"]
        print(f"# {au['name']} ({au.get('affiliation') or 'affiliation unknown'}) — {au['works_count']} works")
        if len(res["candidates"]) > 1:
            print("  other name matches: " + "; ".join(
                f"{c['name']} ({c['works_count']})" for c in res["candidates"][1:]))
        print()
        for w in res["works"]:
            print(brief(w) + "\n")
        return

    if a.cmd == "cites":
        res = citations(a.query, a.n)
        if a.json:
            print(json.dumps(res, indent=2)); return
        print("## paper\n" + brief(res["paper"]))
        if a.contexts:
            # S2's unique feature: the actual sentences in which the paper is cited
            pid = None
            if res["paper"].get("doi"):
                pid = f"DOI:{res['paper']['doi']}"
            elif res["paper"].get("arxiv_id"):
                pid = f"ARXIV:{res['paper']['arxiv_id']}"
            data = s2_get(f"paper/{pid}/citations",
                          {"fields": "contexts,isInfluential,title,year", "limit": a.n}) if pid else None
            if data and data.get("data"):
                print("\n## citing sentences (Semantic Scholar)")
                for c in data["data"]:
                    cp = c.get("citingPaper") or {}
                    star = "*" if c.get("isInfluential") else " "
                    print(f"{star} {cp.get('title')} ({cp.get('year')})")
                    for ctx in (c.get("contexts") or [])[:2]:
                        print(f"    “{' '.join(ctx.split())[:300]}”")
            else:
                _warn("no citation contexts available (needs S2_API_KEY, or S2 lacks this paper)")
        print("\n## cited by (most cited first)")
        for w in res["cited_by"]:
            print(brief(w) + "\n")
        print("\n## references")
        for w in res["references"]:
            print(brief(w) + "\n")
        return

    # get
    recs = resolve(a.query, a.venue, a.since, a.until, n=3)
    if not recs:
        print("no match", file=sys.stderr); sys.exit(1)
    rec = recs[0]
    want_tex = a.raw or a.section or a.list_sections
    src, text = fetch_fulltext(rec, prefer_raw=want_tex)
    header = brief(rec) + f"\n  source: {src}\n"

    if (a.section or a.list_sections) and text:
        if "LaTeX" not in src:
            _warn("no LaTeX source available; section slicing needs an arXiv e-print")
        else:
            if a.list_sections:
                print(header)
                for t, b in latex_sections(text):
                    print(f"  {len(b):>7,}ch  {t}")
                return
            if sec := pick_section(text, a.section):
                text = sec
            else:
                titles = ", ".join(t for t, _ in latex_sections(text))
                print(f"{header}\nno section matching {a.section!r}. available: {titles}", file=sys.stderr)
                sys.exit(3)
    if not text:
        print(header + "\nNO FREE FULL TEXT REACHABLE.\n"
              "Next step: open the landing page in Claude in Chrome using the user's\n"
              "institutional session, or look for an NBER/SSRN/author-site version.",
              file=sys.stderr)
        print(header)
        sys.exit(2)
    if a.save:
        CACHE.mkdir(parents=True, exist_ok=True)
        stem = re.sub(r"[^\w.-]", "_", (rec.get("arxiv_id") or rec.get("doi") or rec.get("title") or "paper"))[:80]
        ext = "tex" if "LaTeX" in src else "md"
        p = CACHE / f"{stem}.{ext}"
        p.write_text(header + "\n" + text)
        print(p)
    else:
        print(header)
        print(text)


if __name__ == "__main__":
    main()
