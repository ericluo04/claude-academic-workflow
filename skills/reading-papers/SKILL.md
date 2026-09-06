---
name: reading-papers
description: Read one known paper the user points at: a link, DOI, title, author name, or vague reference. TRIGGER when the user pastes a paper URL, names a paper to read or summarize, asks "what does X argue", or asks what an author has written. A topic-level search is litreview; auditing a .bib is bibcheck.
---

# Reading papers

Get from a fuzzy reference to clean full text with equations intact, cheaply, without wasting
context on dead ends. The intelligence is yours; the script is a tool. Don't blindly trust its
first answer on hard cases (common author names, paywalled venues). Verify, as flagged below.

## The command

```bash
~/.claude/skills/reading-papers/scripts/paper.py <cmd> "<query>" [flags]
```

| cmd | does |
|---|---|
| `resolve` | fuzzy ref → canonical record (DOI, arXiv id, venue, year, OA status, best free URL, free AEA appendices) |
| `get` | resolve, then fetch the cleanest full text available |
| `search` | topic/keyword search across Semantic Scholar + OpenAlex + arXiv, deduped and merged |
| `author` | works by a person, newest first, with disambiguation |
| `cites` | citation graph: cited-by and references; `--contexts` adds the citing sentences |

Flags: `--venue "…"` · `--since/--until YEAR` · `-n N` · `--json` · `--save` · `--raw` ·
`--list-sections` · `--section "<substr>"` · `--affiliation "…"` · `--orcid "…"` · `--contexts`

Keys (optional, all free) live in `~/.claude/secrets/scholar.env`; the script auto-loads them.

Run it by path exactly as shown: the uv shebang provisions its dependencies (httpx, lxml,
pypdf) in an isolated environment. Invoking it as `python3 paper.py` bypasses the shebang and
fails wherever httpx is not installed (this happened in a subagent environment, 2026-07). If
uv itself is missing, fall back to plain curl against the resolver APIs for the one lookup
you need.

## How resolution works, and why order matters

`resolve` is cheap and prints whether a free copy exists and where. Always resolve before
web-searching or guessing URLs. The routing is cost- and Cloudflare-aware:

- An arXiv id or arxiv link → arXiv metadata (free) + OpenAlex if a DOI exists.
- A DOI → OpenAlex (1 credit) + Unpaywall + NBER direct-PDF + AEA free appendices + a Semantic
  Scholar OA-PDF fallback (catches NBER copies the others miss).
- An NBER or SSRN URL → mapped to a DOI *from the URL itself*, skipping the Cloudflare wall.
- A bare title → Crossref first (free); on a confident title match it pulls the record by
  DOI (1 credit). Only an unconfident title falls through to OpenAlex `search` (10 credits).
  So hand it a DOI or arXiv id when you have one; a title costs up to 10× more.

Version-of-record vs preprint: a title search can surface the NBER or SSRN copy. The matcher
ranks the journal version above preprint containers, but econ papers genuinely exist as several
records with different DOIs and different citation counts, so say which one you mean. Default
rule (made explicit after a 2026-07 reading campaign): read the version of
record whenever one exists and is reachable; fall back to arXiv/NBER only when it is not, and
name the version you read either way, since numbers and author lists can differ across
versions.

`search` is the topic-level entry point (`resolve` is for a known item). One query per source,
merged on DOI → arXiv id → normalized title, re-ranked by reciprocal-rank fusion, one OpenAlex
`search` call per invocation. `--json` carries abstracts and a `sources` block saying which
sources answered; each record names the source of its citation count. A source that 429s or errors
is reported and skipped, never fatal. For a whole literature, use the `litreview` skill, which
wraps this with scoring, Zotero cross-check, and parallel readers.

## Read long papers one section at a time

For any paper with an arXiv copy, map first, then pull only what's needed:

```bash
paper.py get "10.1257/aer.20181169" --list-sections          # cheap map
paper.py get "10.1257/aer.20181169" --section "decomposition" # that section, raw LaTeX
```

The single biggest context saver: a 70K-char paper becomes a 10K-char section with every
equation, `\label`, and `\ref` intact. `--section` carries the preamble's `\newcommand` /
`\newtheorem` definitions along, so macros stay resolvable.

## Math fidelity ladder

`get` tries these in order and prints the `source:` rung it used:

1. arXiv raw LaTeX (`--raw`, or auto when HTML is absent): the authors' own source. Best for
   reproducing/checking an equation. Quote the LaTeX verbatim; don't retype it.
2. arXiv HTML (LaTeXML): `<math alttext="…">` holds the TeX, macros already expanded, clean
   prose around it. Best default for *discussing* a paper.
3. ar5iv: same engine, for papers before arXiv's native HTML (pre-Dec 2023).
4. Born-digital PDF (NBER, JMLR, PMLR, repositories): saved to `~/.claude/cache/papers/`;
   read with `~/.claude/assets/bin/pdfread.py text <pdf>` (`png` for figure pages).
   Text layer survives; math is fine.
5. OCR: only when `get` reports `(SCANNED)`. See the OCR rung below.

Rule of thumb: discuss → HTML; reproduce/check an equation → `--raw`.

### The OCR rung: `~/ocr-examples` (scanned PDFs only)

`get` runs a text-layer check and tags a PDF `(SCANNED)` when the first pages have almost no
extractable text. Only then is OCR worth it. If you have such a setup, route it through the
`~/ocr-examples` repo
(an OCR pipeline on an HPC cluster); do not hand-roll OCR.

- Read first: `~/ocr-examples/README.md`, `docs/ocr-engines.md`, and the relevant
  `scripts/*.py --help`. Load any HPC plugin skills you use before launching a cluster job.
- Two modes. `disk` is for public/non-sensitive PDFs (bytes may live on HPC disk).
  `tunnel` is for sensitive documents: the Mac reads the PDF and streams pages to a compute-node
  service over SSH, so bytes never land on HPC storage and the output is written locally. Use
  tunnel when in doubt about sensitivity.
- Engines (best math first): `olmocr2` (olmOCR-2, Apache-2.0, the default), `deepseek_ocr`,
  `glm_ocr`, `docling` (structure-strong, math-weaker), `pypdf` (text-native only, no OCR).
- Smallest safe start: one document, one worker, one engine, RTX 8000 not A100.
  `just smoke olmocr2 tunnel` proves the path; `just documents-process` / `just engine-olmocr2`
  run real work. Layout is `<documents-root>/<guid>/document.pdf`; feed a GUID list via
  `--from-file` or direct paths via `--pdf-list`. Run `just sync-hpc` after editing that repo.
- Apple-Silicon note: `olmocr2`/`deepseek_ocr`/`glm_ocr` also have a local MLX backend, so a
  single non-sensitive page can be OCR'd on the Mac without the cluster. A large batch belongs on
  a GPU node via Slurm, never the login node.

## Zotero: the user's citation library

A Zotero MCP server is connected; its tools are underscore-named under `mcp__zotero__`, e.g.
`zotero_search_items`. This is the user's own reference manager.

- Reads work only while the Zotero desktop app is open with the local API enabled
  (Settings → Advanced → "Allow other applications on this computer to communicate with Zotero").
  If a `zotero_*` call fails, that's almost always the cause, so ask the user to open Zotero.
- Use it to: search what they already have, read PDF full text and their own annotations/notes,
  pull BibTeX for citing, and find items by tag. Prefer *their* copy of a paper over re-fetching;
  it's faster and it's the version they annotated.
- Writes (adding a found paper to the library) need a web API key in `scholar.env` and are
  hybrid-mode. Don't add items unless asked.
- Natural pairing: `paper.py` finds and reads anything on the open web; Zotero is the private
  library. When the user says "the paper I saved / my notes on X," reach for Zotero first.

## When there is no free copy

Verified July 2026, hard-blocked to plain HTTP: INFORMS (Marketing/Management Science), SSRN,
AEA direct PDF, Elsevier/Wiley/OUP/Chicago, OpenReview anonymous `api2`. Escalate in order:

1. `resolve` already checked for a green-OA copy (repository, arXiv, RePEc, NBER) and iterates
   *all* OA locations, including the ones it doesn't rank first. Trust it; it finds most paywalled
   AER / Marketing Science papers as a free copy elsewhere.
2. Working-paper version: NBER (`nber.org/papers/wXXXXX`), CEPR, author's site. For econ this
   is usually near-identical to the published version.
3. Free AEA appendix/data: for AER/AEJ the article PDF is walled but the online appendix
   (where the proofs live) and replication package are free; `resolve` surfaces them.
4. Claude in Chrome, the user's real browser, the only thing that clears Cloudflare. An institutional
   proxy has the shape
   `https://<your-library>.idm.oclc.org/login?URL=<target>`, but login is typically SSO + MFA, so the
   user must be in the loop. Ask first; one paper at a time. Systematic proxy downloading can
   get the whole university cut off, so never loop it.
5. Scholar Gateway (`semanticSearch`): Wiley-leaning licensed corpus, returns *passages*, not
   full text; can't fetch by DOI. Good for corroborating a claim, not reading a paper.
6. Say plainly that only the abstract is reachable. Never paraphrase an abstract as if you read the
   paper.

## Cost model (OpenAlex, metered since 2026)

| call | credits |
|---|---|
| DOI / ID lookup, plain `filter=` | 1 |
| anything with `search`, incl. `filter=title.search:` | 10 |

Anonymous = 1,000 credits/day. A free key (`openalex.org/settings/api`) → 10×; put it in
`scholar.env` as `OPENALEX_API_KEY`. The script disk-caches every response 30 days, so re-reads
are free. Prefer DOIs/arXiv ids over titles.

## Author queries: where you must stay in the loop

`author` resolves a name via OpenAlex (most-works profile) and prints runner-up matches. Common
names are genuinely hard; do not trust the top pick blindly:

- OpenAlex fragments one person across profiles: the same author appears as a 300-work record
  and a 2-work stub, and even an ORCID can resolve to a stub. Always sanity-check that the
  returned *works match the person's field* (a marketing scholar shouldn't be returning optics
  papers). If they don't, you have the wrong fragment.
- `--affiliation "Columbia"` filters to the current institution, the reliable fix for a common
  name. If nothing matches, the script lists candidates with their ORCIDs instead of guessing.
- `--orcid` is the most deterministic single input, but see the fragment caveat above.
- In CS, DBLP is the gold standard for name disambiguation (explicit homonym suffixes) and its
  author XML also yields the person's Google Scholar / ORCID / ACM ids.
- Diacritics matter: the canonical `display_name` may be `Acemoğlu`, not `Acemoglu`.

`cites --contexts` shows the actual sentences citing a paper (Semantic Scholar; needs `S2_API_KEY`).
Use it to see what a paper is actually being used for.

## Gray areas / known false positives

- Abstract-vs-fulltext: `get` classifies an HTML page structurally (has a References section?
  heading count? body word count?), not by raw length, so a short genuine paper with references
  (an AER P&P note, a Comment) reads as full text and is not flagged. When a page looks
  abstract-only, `get` first tries any PDF the page advertises (the `citation_pdf_url` meta tag, or
  a linked author manuscript) before falling back, which recovers the full text on many repository
  landing pages. If it still returns only the abstract, it says so (label ends `abstract-only`).
- Scanned-PDF flag: heuristic (little text in the first 3 pages). A born-digital paper with a
  figure-only opening could false-flag; conversely a mostly-image PDF with a text cover could slip
  through. Glance at the PDF before committing to an OCR job.
- "Open access" that isn't fetchable: for hybrid-OA Oxford/SAGE, OpenAlex reports a PDF URL on
  `academic.oup.com` / `journals.sagepub.com` (legally open, technically Cloudflare-dead). The
  green-OA (repository/PMC/OSF/arXiv) locations are the ones that resolve; `resolve` prefers them.
  Wiley behaves the same: `onlinelibrary.wiley.com` pdfdirect URLs 403 even for OA articles
  (confirmed twice, 2026-07), and the landing pages 403 too; the working route is an
  institutional-repository or author-page copy (MIT DSpace and an author's Harvard page both
  delivered papers Wiley refused).
- Missing abstracts: Crossref lacks abstracts for JPE (Chicago) and JPSP (APA), though OpenAlex has
  them. Semantic Scholar *elides AEA abstracts* by publisher request.

## Venue cheat sheet

- CS: almost all on arXiv → `--raw` gives exact math. Bulk-friendly mirrors are PMLR (per-volume
  `bibliography.bib`), ACL Anthology (whole corpus is a git repo), JMLR, NeurIPS proceedings.
  Reviews/scores need an authenticated OpenReview client.
- Econ: arXiv `econ.EM`, then NBER (direct PDF). AER/AEJ article PDF is members-only but
  appendices are free. IDEAS pages give the working-paper ↔ published crosswalk.
- Marketing: INFORMS is walled but green OA, so the readable copy is normally an
  institutional repository, which `resolve` finds. 2023+ INFORMS DOIs changed shape; listings
  contain non-article DOIs (`…ack…`, `…eb…`) worth ignoring.
- Psychology: Psych Science is SAGE (PMC holds front matter only). Try PsyArXiv/OSF.
- Annual Reviews: CC-BY articles fetched directly in early July 2026, but as of 2026-07-28
  the landing pages sit behind a Cloudflare challenge that blocks curl. Go arXiv-first for AR
  titles (accepted versions usually exist and worked where the AR page failed); treat any
  direct-fetch success as date-dependent.

## Honesty rules

- State which version you read (published, arXiv preprint, or NBER working paper). The numbers
  can differ.
- Citation counts are source-specific and disagree (same Econometrica paper: 235 OpenAlex / 177 S2
  / 210 Crossref / 157 OpenCitations). Name the source; never mix counts in one table.
- Never invent a DOI, page number, or quotation. If `resolve` returns nothing, say so.

### Quoting the paper

Report what a paper says in indirect speech. Wording kept from the authors goes inside quotation
marks and italics, formatted *"like this"*, with the page or section it came from, and that holds
in chat, in a subagent's structured summary, in a `note` field, and in anything that reaches a
draft. A summary that reuses the paper's own sentences without those marks is plagiarism once it
lands in a document.

<example>
<user>what does https://doi.org/10.1287/mksc.2025.0142 argue</user>
<response>
[paper.py resolve: 10.1287/mksc.2025.0142]
[paper.py get --list-sections: 10.1287/mksc.2025.0142]
[paper.py get --section: "Identification"]
Okonjo and Vance argue that most of the measured return to retail media advertising comes from
selection into who sees the ad. Geo holdouts on a grocery platform give them a lift of about 4
percent against the 31 percent the platform's own attribution reports, and they show the gap widens
where the budget lands on shoppers already searching for the brand. Their claim about attribution
rests on the holdout and is the strong one. The decomposition behind the mechanism rests on a
keyword classifier validated against 500 hand-coded queries, and they push it further than that
validation carries, calling the gap *"a measurement artifact the platform has no incentive to
correct"* (Section 6, p. 22). Read: published version, arXiv HTML rung.
</response>
<rationale>CORRECT: The argument is stated in the assistant's own words, with the claim the design supports separated from the one it does not. Exactly one phrase is kept from the authors, marked and italicized with its section and page, and everything else is reworded while the numbers a reader needs survive.</rationale>
</example>

## Working with many papers

Per the user's standing preference, for several papers at once spawn parallel subagents, one
paper each, returning structured summaries. Every API call in `paper.py` now retries with
exponential backoff on 429/503 (arXiv, Semantic Scholar, OpenAlex, Crossref), and the OpenAlex key
gives a 10,000-credit daily budget, so a fan-out of a dozen readers is safe. Two things still
apply: results are disk-cached (so re-reads across agents are free), and for a very large batch
(many dozens) keep arXiv-heavy concurrency modest, since arXiv politeness is ~1 request / 3s.

## Setup state

- This setup assumes Zotero MCP (`zotero-mcp-launch.sh` reads `scholar.env`), Claude in Chrome,
  and Scholar Gateway are installed and connected; adjust to your machine. `paper.py` needs no keys.
- `~/.claude/secrets/scholar.env`: put `OPENALEX_API_KEY` and `S2_API_KEY` here, plus the
  optional Zotero web-API creds; REFERENCE.md §7 says how to get all of them.
- Background on the whole landscape (what's blocked, what's open, why a script beat a fleet of MCP
  servers): `REFERENCE.md` in this directory.
