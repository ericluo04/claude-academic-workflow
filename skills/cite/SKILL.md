---
name: cite
description: Resolve a paper (DOI, arXiv ID, title, or URL) to a Zotero entry, append its BibTeX to the active project's .bib file, and return the citation key ready for \citep{}. Use this whenever the user asks to add a citation, "cite this paper", or pastes a paper identifier.
---

# /cite — resolve identifier, file in Zotero, append BibTeX

## Personalization

This skill resolves placeholders against `~/.claude/state/personal_config.json`. See `_config/README.md` and `_config/personal_config.example.json` for setup. If the config is missing or a needed field is unset, the skill must surface an error to the user and refuse to proceed rather than guess.

Required config fields:
- `personal_config.paths.overleaf_root` — root containing project subdirs.
- `personal_config.projects[]` — each entry should declare `name`, `overleaf_subdir`, `bib_file`, and optional `zotero_collection_key` (used by step 4 below). Aliases may also help match free-form mentions.
- Zotero credentials (`ZOTERO_API_KEY`, `ZOTERO_USER_ID`) are read from environment variables, not from `personal_config.json`. See `docs/mcps.md` for the Zotero MCP setup; the read-only MCP picks them up automatically.

## When to invoke

The user invokes `/cite` followed by one or more identifiers:

- DOI: `10.1287/mksc.2023.1234` or `https://doi.org/10.1287/mksc.2023.1234`
- arXiv ID or URL: `2403.12345`, `arXiv:2403.12345`, `https://arxiv.org/abs/2403.12345`
- Paper title in quotes: `"Some Paper Title"`
- A Zotero item key already in the library
- Free-form: a URL pointing to a paper page on Springer / journal site — extract DOI from it

Multiple identifiers in one invocation are allowed; process each independently and report a summary at the end. If `/cite` is invoked with no argument, ask once what to cite, then continue.

## Tools to use

**MCP tools (verified live tool names)**:
- `mcp__semantic-scholar__get_paper_details` — primary resolver. Accepts `DOI:10.xxx`, `ARXIV:2403.12345`, or a Semantic Scholar paper ID. Returns full metadata.
- `mcp__semantic-scholar__search_papers` — fallback when only a title is given. Returns up to 100 candidates.
- `mcp__semantic-scholar__export_bibtex` — emits BibTeX for one or more paper IDs.
- `mcp__zotero__zotero_search_items` — check if a paper already lives in the library. Modes: `titleCreatorYear` (default) or `everything`.
- `mcp__zotero__zotero_item_metadata` — fetch full metadata for a Zotero item key.
- `mcp__arxiv__get_abstract`, `mcp__arxiv__search_papers` — for arXiv-only resolution.
- `mcp__openalex__openalex_search_entities` with `id="<DOI>"` — secondary resolver, useful for venue/concept tags.

**The Zotero MCP is read-only.** For adds, updates, collection filing, and PDF attachments, hit the Zotero Web API directly. Read `$env:ZOTERO_API_KEY` and `$env:ZOTERO_USER_ID` at runtime — never hardcode credentials.

## Step-by-step

### 1. Resolve identifier → canonical metadata

- **DOI** → `get_paper_details(paper_id="DOI:<doi>")`
- **arXiv ID** → `get_paper_details(paper_id="ARXIV:<id>")` or `mcp__arxiv__get_abstract(paper_id="<id>")`
- **Title only** → `search_papers(query="<title>", limit=5)`. If multiple plausible matches, show top 3 with year + first author + venue and ask which one. Don't auto-pick when ambiguous.
- **DOI URL or publisher landing page** → extract DOI substring (regex `10\.\d{4,9}/[-._;()/:A-Z0-9]+`) and resolve via DOI path. Use playwright only for paywalled/JS pages where regex extraction fails.

The fields you need: `paperId` (Semantic Scholar ID), `title`, `authors`, `year`, `venue`, `DOI`, `arxivId` (if any), `openAccessPdf.url` (if any).

### 2. Check Zotero for an existing entry

Call `zotero_search_items(query="<short title>", qmode="titleCreatorYear", limit=5)`. If a hit's metadata DOI matches the resolved DOI, **reuse** that entry — do not create a duplicate. Note its Zotero item key and existing citation key (visible in metadata's `extra` field if Better BibTeX is set, or default).

If no DOI is recorded on the Zotero item but the title matches exactly, also treat as duplicate but flag ("found in Zotero without DOI — should I add the DOI?").

**Existing-item re-filing**: when reusing, also check current collections via `https://api.zotero.org/users/$env:ZOTERO_USER_ID/items/<key>` (`data.collections`). If the active project's collection key (per step 4) is not already in the list, PATCH it in *additively* (preserve existing collection memberships — don't remove). This requires capturing the item's `version` and sending `If-Unmodified-Since-Version: <version>`.

```powershell
$key = $env:ZOTERO_API_KEY
$uid = $env:ZOTERO_USER_ID
$body = @{ collections = @($existing + $newCollectionKey) } | ConvertTo-Json
Invoke-WebRequest -Method PATCH -Uri "https://api.zotero.org/users/$uid/items/<itemKey>" `
  -Headers @{ 'Zotero-API-Version'='3'; Authorization="Bearer $key"; `
              'If-Unmodified-Since-Version'=$itemVersion; 'Content-Type'='application/json' } `
  -Body $body -UseBasicParsing
```

A 204 response means success. If you get 412 Precondition Failed, the item changed underneath — re-fetch and retry once.

### 3. Add to Zotero (if new)

Use Zotero Web API directly (the MCP can't write):

```powershell
$key = $env:ZOTERO_API_KEY
$uid = $env:ZOTERO_USER_ID
$item = @{
  itemType = 'journalArticle'   # or 'preprint', 'conferencePaper', 'book' etc.
  title = '...'
  creators = @(
    @{ creatorType='author'; firstName='...'; lastName='...' }
  )
  date = '2024-05'
  publicationTitle = 'Journal Name'
  volume = '...'
  issue = '...'
  pages = '...'
  DOI = '10.xxx/...'
  url = '...'
  abstractNote = '...'
  collections = @('<collection-key>')   # see step 4
  extra = 'arXiv:2403.12345 [cs.LG]'    # for arXiv preprints
}
$body = ConvertTo-Json -InputObject @($item) -Depth 6
Invoke-WebRequest -Method POST `
  -Uri "https://api.zotero.org/users/$uid/items" `
  -Headers @{ 'Zotero-API-Version'='3'; Authorization="Bearer $key"; 'Content-Type'='application/json' } `
  -Body $body -UseBasicParsing
```

For arXiv preprints: `itemType='preprint'`, also set `archive='arXiv'`, `archiveID='<id>'`, `extra='arXiv:<id> [<category>]'`.

If `openAccessPdf.url` is present and the user wants the PDF too, queue a follow-up: download and attach using a child `attachment` item (skip on first version unless requested).

### 4. Determine the right Zotero collection

Map cwd or the user's mention to the project's `zotero_collection_key` from `personal_config.projects[]`. Each project entry may declare:

```json
{
  "name": "ProjectA",
  "overleaf_subdir": "ProjectA Manuscript",
  "bib_file": "references.bib",
  "zotero_collection_key": "<COLLECTION_KEY>"
}
```

If a more-specific subcollection clearly fits (e.g. for a Generative-AI paper added under a project that has a "Generative AI" subcollection), file there. If unsure, file at the top-level project key. Never auto-create new collections.

If the project entry has no `zotero_collection_key`, ask which collection to file in rather than guessing.

### 5. Get BibTeX

**Primary (always prefer this if the item exists in Zotero):** Zotero Web API export. If the user has Better BibTeX configured, the export already matches their existing style — citation key like `abadie2023When`, field order title/shorttitle/url/doi/abstract/urldate/publisher/author/month/year/note/keywords, brace-protected name casing, `@misc` for arXiv preprints with `note={arXiv:... [cs]}`.

```powershell
$key = $env:ZOTERO_API_KEY
$uid = $env:ZOTERO_USER_ID
$r = Invoke-WebRequest -Uri "https://api.zotero.org/users/$uid/items/<itemKey>?format=bibtex" `
  -Headers @{ 'Zotero-API-Version'='3'; Authorization="Bearer $key" } -UseBasicParsing -TimeoutSec 15
[System.Text.Encoding]::UTF8.GetString($r.Content)   # decode — Zotero serves application/x-bibtex
```

**Fallback only when not in Zotero (paper failed to add or user declined to add):** `mcp__semantic-scholar__export_bibtex(paper_ids=["<paperId>"], cite_key_format="author_year_title", include_doi=true, include_url=true)`. The output is plainer (`@article` even for arXiv, lowercase keys, no shorttitle/note) — flag this in the chat output so the user knows it's not the full Better-BibTeX style.

### 6. Resolve target .bib file

Lookup priority:
1. cwd is inside `<personal_config.paths.overleaf_root>/<project_subdir>/` → use that project's `bib_file` from config (else glob `*.bib` in the project root).
2. cwd has any `.tex` files → glob `*.bib` in same directory.
3. Multiple `.bib` files → grep main `.tex` for `\bibliography{...}` or `\addbibresource{...}` to find the right one.
4. Still ambiguous → ask which `.bib`.
5. No `.bib` exists → ask whether to create one or just print the BibTeX for paste.

### 7. Append BibTeX to .bib

Before appending:
- **Duplicate-key check**: read target `.bib`, grep for the generated citation key. If present with a different DOI, suffix `a`, `b`, `c` until unique.
- **Duplicate-DOI check**: grep for the DOI. If present, do NOT append — reuse the existing key and report it.
- **Field order match**: if the user's existing entries follow a consistent order (e.g. `author, title, journal/booktitle, volume, number, pages, year, publisher, doi`), reorder S2's output to match.

Append a single blank line then the entry. Do not reorder existing entries. Do not strip existing whitespace.

### 8. Output to chat

Per identifier, print:

```
<Title>
  Authors: <First Last, First Last>, <year>
  Venue: <journal name>
  DOI: <doi or "—">
  Zotero: <added | existing>, key: <zotero-itemKey>, collection: <collection-name>
  BibTeX: appended to <path>
  Use as: \citep{<citationkey>}
```

If something failed, say so and stop — don't silently proceed to the next identifier without flagging.

## Paper-style notes for emitted BibTeX

The user uses natbib-apa. Don't strip the `doi` field — `apacite`/`natbib-apa` use it. Don't add `note=` unless the paper has special status (preprint, in press). For arXiv preprints use `@misc{...}` with `eprint`, `archivePrefix={arXiv}`, `primaryClass`, `year`, `note={Preprint}`.

## Failure modes — call out, don't paper over

- **Paper not found in any source**: tell the user, ask for a DOI or PDF.
- **Multiple Zotero matches** for the same DOI: rare. Use the most recently added; flag.
- **Zotero rate limit (429)**: wait 30 sec, retry once; if still failing, stop.
- **.bib file is read-only or in cloud-sync conflict state**: do not force the write; surface the error.
- **POST to Zotero returns 4xx**: print the response body — usually `failed: { "0": { "code": 400, "message": "..." } }` reveals which field is wrong.
- **Zotero env vars missing**: hard-fail with a pointer to `docs/mcps.md` setup instructions. Don't try to write without auth.

## Out of scope (don't do these unless asked)

- Don't insert the `\citep{}` into the `.tex` body — the user does precise edits themselves.
- Don't reformat existing `.bib` entries.
- Don't bulk-import from a folder of PDFs — that's `/litreview` or a separate flow.
