# Literature access: the landscape (surveyed July 2026)

Background for `SKILL.md`. Anything marked (verified) was checked by live fetch from this machine.

## 1. The one thing that determines everything

No MCP server, and no API, can give you paywalled journal full text. Every major publisher in your
fields sits behind a Cloudflare managed challenge (`cf-mitigated: challenge`), verified live:

| Host | Journals | Plain fetch |
|---|---|---|
| `pubsonline.informs.org` | Marketing Sci, Management Sci | 403 (verified) |
| `academic.oup.com` | QJE, ReStud, JCR | 403 |
| `journals.sagepub.com` | JM, JMR, Psych Science | 403 |
| `journals.uchicago.edu` | JPE | 403 |
| `onlinelibrary.wiley.com` | Econometrica | 403 |
| `papers.ssrn.com` | SSRN | 403 (verified) |
| `psycnet.apa.org` | JPSP | 403 |
| **`www.aeaweb.org`** | AEA society site | 200 (verified) |
| **`www.nber.org`** | NBER working papers | 200 (verified) |
| **`ideas.repec.org`** | RePEc | 200 |

So the real architecture is: metadata from aggregators, full text from the open-version layer
(arXiv / NBER / repositories / author pages), publisher sites only via a real browser. Anyone
promising more is either wrong or routing through Sci-Hub.

## 2. What's already connected

| Tool | What it actually is |
|---|---|
| **Scholar Gateway** (`semanticSearch`) | Published by Wiley. Semantic search over a licensed corpus returning *passages* with citations. Cannot fetch by DOI, cannot read a paper end-to-end. Good for corroborating a claim or locating something. |
| **Claude in Chrome** (`mcp__claude-in-chrome__*`) | Your real Chrome, driven by Claude Code, with your logins in it. The only tool here that clears Cloudflare. Your institutional-access escape hatch. |

## 3. MCP servers worth knowing (surveyed, not installed)

The ecosystem is noisier than it looks. Findings worth carrying:

- `github.com/modelcontextprotocol/servers` has zero academic servers; discovery moved to the
  registry, and the registry has dead entries (several listed repos 404) and stale version
  metadata. Install from npm/PyPI, never from registry metadata.
- Only a handful of servers return real full text at all. The ones that do:
  `blazickjp/arxiv-mcp-server` (2,981 stars: `read_paper`, `get_paper_latex`, section-level LaTeX),
  `cyanheads/pubmed-mcp-server` (PMC → Europe PMC → Unpaywall fallback chain),
  `54yyyu/zotero-mcp` (4,399 stars, and note the PyPI package is `zotero-mcp-server`; plain
  `zotero-mcp` is a different, abandoned project), and `ElliotPadfield/unpaywall-mcp`.
- `openags/paper-search-mcp` (2,236 stars) aggregates 21 sources including SSRN, but ships an
  optional Sci-Hub fallback that must stay disabled for grant-funded work.
- Official Anthropic connectors: alphaXiv (arXiv full text), Consensus (220M papers; free tier
  is 30 searches/month and hides DOIs below Enterprise), Elicit (requires Pro).
- The real cost of installing a lot of these is context. The full "recommended stack" is
  ~120 tool definitions loaded into every session, with heavy duplication.

Judgment: a script beats servers here. `paper.py` covers resolve → route → full text →
sections → citations in one Bash call, with zero permanent tool-definition cost, and it encodes
the fallback ladder that no single server implements. The one server with a genuine capability
edge was section-level LaTeX, which is now built in.

## 4. The data layer (what `paper.py` sits on)

| Source | Auth | Notes |
|---|---|---|
| **OpenAlex** | none / free key | Best coverage + OA routing. Now metered (verified); see below. |
| **Crossref** | none | Authoritative DOI ↔ metadata. Has abstracts for most publishers but not JPE or JPSP (verified). Polite pool via `mailto:` UA. |
| **Unpaywall** | email | Clean OA resolver (verified). |
| **arXiv** | none | API, HTML, and raw LaTeX e-print (verified). Be polite: 1 req / 3s. |
| **Semantic Scholar** | key required in practice | 429s immediately when anonymous (verified). Unique value: citation *contexts*, the actual sentence citing a paper. Elides AEA abstracts by publisher request. |
| **OpenCitations** | none | Citation edges pre-joined to DOI *and* OpenAlex IDs. |
| **DBLP** | none | CC0, gold standard for CS author disambiguation (explicit homonym suffixes). No citations, weak title search. |
| **OpenReview** | login required | `api2` now returns a 403 challenge to anonymous callers (verified), so it needs an authenticated `openreview-py` client. Reviews/rebuttals live only here. |
| **ORCID** | none | Deterministic author identity, thin bibliography, spotty senior-economist coverage. |
| **RePEc API** | request by email | Gated; not worth it. IDEAS *pages* are open and give the WP↔article crosswalk. |

### OpenAlex is now metered (verified from live headers)

| call | credits |
|---|---|
| DOI/ID lookup, plain `filter=` | 1 |
| anything using `search`, including `filter=title.search:` | 10 |

Anonymous = 1,000 credits/day. A free key (`openalex.org/settings/api`) gives 10×; export
`OPENALEX_API_KEY`. `mailto` no longer affects limits. `paper.py` disk-caches responses for 30
days so repeat reads are free.

## 5. Equations

Fidelity ladder, best first:

1. arXiv raw LaTeX (`/e-print/<id>`, verified): the authors' own source. Nothing beats it.
   Gotcha: papers define macros (`\newcommand{\E}{\mathbb{E}}`), so a section slice without the
   preamble is unreadable. `paper.py --section` carries the macros along.
2. arXiv HTML (LaTeXML, verified): `<math alttext="...">` holds the original TeX, with macros
   already expanded and clean prose around it. Often the *best* representation for an LLM. Covers
   TeX submissions from Dec 2023 (~97% partial, ~75% clean); older → ar5iv.
3. Born-digital PDF: real text layer; read it with
   `~/.claude/assets/bin/pdfread.py text <pdf>` (`png` for figure pages).
4. OCR, only for scans, through the `~/ocr-examples` pipeline (if you have one set up).
   Verified engine order, best math
   first: `olmocr2` (olmOCR-2, Apache-2.0, the default, fits an RTX 8000), `deepseek_ocr`,
   `glm_ocr`, then `docling` (structure-strong, math-weaker) and `pypdf` (text-native only, no
   OCR). Never `pymupdf4llm` or GROBID for math; both destroy it. Cluster work belongs in a
   Slurm job, never the login node.

## 6. Per-field cheat sheet

- CS: nearly everything is on arXiv, so `--raw` is the default and equations are exact.
  Bulk-friendly mirrors: PMLR (one `bibliography.bib` per volume), ACL Anthology
  (`anthology+abstracts.bib.gz`, and the whole corpus is a git repo), JMLR, NeurIPS proceedings.
  Reviews/scores require an authenticated OpenReview client.
- Econ: arXiv `econ.EM`, then NBER (direct PDF path, verified). AEA article PDFs are members-only
  but appendices and replication packages are free (verified), and the appendix usually holds the
  proofs. The open AEA ReDIF archive (`aeaweb.org/RePEc/aea/*/`) carries full abstracts, DOIs,
  JEL codes and materials links in plain text (verified).
- Marketing: INFORMS is walled but green OA, so authors may post the accepted manuscript
  immediately and the readable copy is normally an institutional repository. OpenAlex finds these.
- Psych: SAGE blocks PMC XML full text (front matter only). Try PsyArXiv/OSF.

## 7. Setup & API keys

All keys go in `~/.claude/secrets/scholar.env` (chmod 600; real env vars override it).
`paper.py` and the Zotero launcher both read it. All three keys are free.

OpenAlex (do this, for 10× the daily credit budget):
1. Go to `https://openalex.org/settings/api`, enter an email, get a key instantly.
2. Paste after `OPENALEX_API_KEY=` in `scholar.env`. Done, the script picks it up.

Semantic Scholar (lifts the 429 wall; unlocks `cites --contexts`):
1. Request at `https://www.semanticscholar.org/product/api#api-key-form`. Arrives by email;
   approval can take weeks, so request it now and it'll start working when it lands.
2. Paste after `S2_API_KEY=`.

Zotero (this setup assumes it is installed and connected). Things to know:
- The MCP was added at user scope via `zotero-mcp-launch.sh` (keeps keys out of settings.json).
- Local reads require the Zotero 7+ desktop app to be open, with Settings → Advanced →
  "Allow other applications on this computer to communicate with Zotero" checked. Reads are
  read-only and need no key.
- Writes (adding papers to the library) need a web key: `https://www.zotero.org/settings/keys`
  → Create new private key → allow library access (+ write if wanted). Put the key in
  `ZOTERO_API_KEY=` and your numeric userID (same page) in `ZOTERO_LIBRARY_ID=`.

Claude in Chrome + an institutional EZproxy for INFORMS/SSRN: human-in-the-loop only. Login
is typically SSO + MFA (not automatable); at-scale proxy use risks access for the *whole
university*. One paper at a time, ask first, never loop.

## 8. Still-open policy calls (not technical)

- NBER bulk downloading: the per-paper PDF path is open (verified), but NBER's stated terms limit
  free access to affiliates. Fine for reading papers you need; not a license to mass-harvest.
- OCR at scale on an HPC cluster: `~/ocr-examples` is wired in as the scanned-PDF rung (this
  setup assumes such a pipeline; adjust to yours). Big
  batches belong in a Slurm job on an RTX 8000, tunnel mode for anything sensitive. Load any
  HPC plugin skills you use first.
