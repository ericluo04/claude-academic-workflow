---
name: bibcheck
description: Audit an existing .bib file entry-by-entry against ground truth (DOI, Semantic Scholar, OpenAlex, arXiv) to catch the silent citation errors that pass spell-check but kill peer review — wrong year, mis-cited authors, wrong journal/volume, swapped title-author pairs, fabricated DOIs, and outright hallucinated entries (a real concern with LLM-assisted drafting). Spawns one narrow-focus subagent per entry so each citation gets full attention rather than the gradient-decay that single-pass audits suffer at scale. Use whenever the user says "/bibcheck", "audit my .bib", "verify references", "check my bibliography for errors", "any fake citations", "pre-submission bib audit", "did Claude hallucinate any of these", or before shipping a manuscript / R&R to Marketing Science, JMR, JCR, Management Science. Read-only and audit-only — never adds, edits, or removes entries; produces a PASS/WARN/FAIL report and a `corrected.bib` the user can diff and move into place themselves. Strictly distinct from `/cite` (which ADDS one entry to a `.bib` from a DOI/arXiv/title) — `/bibcheck` is the verification mirror image.
argument-hint: "[.bib file path] (defaults to references.bib / refs.bib / bibliography.bib in cwd)"
allowed-tools: ["Read", "Grep", "Glob", "Write", "Bash", "Task", "Monitor", "WebFetch", "mcp__semantic-scholar__get_paper_details", "mcp__semantic-scholar__search_papers", "mcp__openalex__openalex_search_entities", "mcp__arxiv__get_abstract", "mcp__arxiv__search_papers", "mcp__zotero__zotero_item_metadata", "mcp__zotero__zotero_search_items"]
effort: medium
---

# bibcheck — Per-Entry Bibliography Audit

Audit-only sister skill to `/cite`. Given a `.bib` file, spawn one subagent per entry to verify the entry against canonical sources (DOI metadata, Semantic Scholar, OpenAlex, arXiv, Zotero). Report PASS / WARN / FAIL per entry with a one-line diagnostic, group by severity, and write a dated report plus a `corrected.bib` the user can review and merge themselves. Never overwrites the source `.bib`.

**Why per-entry parallelism.** One agent asked to audit 80 entries in a single pass drifts: early entries get careful treatment, late entries get pattern-matched. Spawning one subagent per entry gives each citation a full attention budget and removes the late-batch quality cliff. This mirrors the structure of `/seven-pass-review` (parallel lenses) and `/audit-reproducibility` (per-claim checking).

**The LLM-fabrication concern.** Hallucinated citations have a recognizable signature: plausible author names + plausible title + a DOI that 404s + no Semantic Scholar / OpenAlex / arXiv match anywhere. `/bibcheck` is built to surface exactly this pattern.

## When to use

- **Pre-submission**: before MKSCI / JMR / JCR / MS submission or resubmission, especially for drafts where any text was AI-assisted.
- **Inherited `.bib`**: when picking up a coauthor's or RA's bibliography and you don't know its provenance.
- **Post-Zotero-export sanity check**: even Better BibTeX can carry forward bad upstream metadata.
- **After a large `/litreview` batch**: verify that everything the lit-review skill staged into `.bib` actually exists.

## Inputs

- `$0` — path to a `.bib`. If omitted, Glob the cwd for `references.bib`, `refs.bib`, `bibliography.bib`, then any `*.bib`. Overleaf projects typically live under `<OVERLEAF_ROOT>/<PROJECT_SUBDIR>/`. If multiple `.bib` files exist, grep the main `.tex` for `\bibliography{}` / `\addbibresource{}` to pick the right one; ask the user if still ambiguous.

## Workflow

### Phase 0: Parse the .bib

1. Read the full `.bib`.
2. Split into entries on `^@\w+\{` boundaries. Capture entry type (`article`, `book`, `incollection`, `misc`, `inproceedings`, `unpublished`), citation key, and every `field = {value}` pair (handle braced and quoted forms, escaped braces, multi-line values).
3. Build an in-memory list of entries. Note malformed entries (unbalanced braces, missing key, duplicate key) — these go straight to FAIL without dispatching a subagent.
4. Create a working directory `<bib_dir>/bibcheck_<YYYYMMDD_HHMM>/` with subfolders `entries/` (one file per entry for subagent input) and `reports/` (one JSON per entry for subagent output).

### Phase 1: Spawn per-entry subagents

For each well-formed entry, launch a `Task` subagent with a focused prompt: "Verify this single BibTeX entry against canonical sources. Return JSON with verdict and per-field findings." Cap concurrent subagents at 8 (`--max-parallel` if the user passes it). Each subagent runs the per-entry checks below and writes one JSON file to `reports/<citekey>.json`. Lower the cap if rate-limited; raise it for very large bibliographies.

### Phase 2: Per-entry checks (run by each subagent)

In order, stopping early once verdict is determined:

1. **DOI resolution.** If the entry has a `doi` field:
   - Call `mcp__semantic-scholar__get_paper_details(paper_id="DOI:<doi>")`. On hit, compare title / author surnames / year / venue / volume / issue / pages against the entry. Discrepancies → field-level WARN; outright mismatches → FAIL.
   - If S2 misses, fall back to `WebFetch("https://api.crossref.org/works/<doi>")` for Crossref ground truth.
2. **arXiv resolution.** If the entry looks like a preprint (`eprint = {2403.12345}`, `archivePrefix = {arXiv}`, or `note = {arXiv:...}`):
   - Call `mcp__arxiv__get_abstract(paper_id="<id>")` to confirm existence and pull canonical metadata.
   - Cross-check whether the same paper now has a published version with a DOI (use `mcp__semantic-scholar__search_papers(query="<title>")`) — if so, emit a WARN suggesting the published `@article` entry instead of the preprint `@misc`.
3. **Title-only search (no DOI, no arXiv).** Call `mcp__semantic-scholar__search_papers(query="<title>", limit=5)`. Fuzzy-match against the entry's title (case-insensitive, normalize punctuation, accept ≥ 0.85 cosine on token-set). On a confident hit, compare authors / year / venue. On no plausible match, also try `mcp__openalex__openalex_search_entities(entity_type="works", query="<title>")` as a second opinion.
4. **Fabrication test.** If (a) `doi` is present but DOI doesn't resolve in S2 OR Crossref, AND (b) title search returns no fuzzy match in S2 OR OpenAlex OR arXiv → FAIL with diagnostic `fabricated? — DOI does not resolve and no metadata source recognises the title`. This is the LLM-hallucination signal.
5. **Author normalization.** Compare author surnames as the ground-truth source returns them. Flag:
   - Wrong surname (clear mismatch) → FAIL.
   - Initials vs. full first names → no flag (style choice).
   - Missing accents (`Pena` vs. `Peña`), missing tussenvoegsels (`Van Den Bulte` vs. `van den Bulte`) → WARN.
   - Author-list truncation (`& others` or missing trailing authors) → WARN.
6. **Year reconciliation.** If the entry year differs from the canonical publication year:
   - If `eprint`/`archivePrefix=arXiv` present and entry year matches arXiv-submission year → WARN ("entry cites preprint year `<y1>`; published version is `<y2>`"). Do not auto-FAIL — citing the preprint year is a legitimate choice.
   - Otherwise → FAIL ("year mismatch: entry says `<y1>`, canonical says `<y2>`").
7. **Journal canonicalization.** Compare `journal` against canonical name from S2 / OpenAlex. Marketing-relevant cases worth WARNing on:
   - Abbreviation drift: `J. Mark. Res.` vs. `Journal of Marketing Research`, `Mark. Sci.` vs. `Marketing Science`, `Mgmt. Sci.` vs. `Management Science`, `Quant. Mark. Econ.` vs. `Quantitative Marketing and Economics`.
   - Wrong journal entirely (different ISSN family) → FAIL.
   - Apply the same logic for `booktitle` on `@inproceedings` (`ICML`, `NeurIPS`, `KDD` — full names).
8. **Volume / issue / pages.** Compare numeric fields. WARN on a single-field mismatch; FAIL if 2+ disagree (likely a swapped-entry bug — title of paper A glued to the volume/pages of paper B).
9. **Zotero cross-check (optional).** If a citation key looks Better-BibTeX-shaped (e.g., `lastname2024Word`), call `mcp__zotero__zotero_search_items(query="<title>", qmode="titleCreatorYear", limit=3)`. If a Zotero hit exists with a different DOI than the entry, WARN. *The Zotero MCP is read-only* — never attempt to write back; surfacing the mismatch is sufficient.

Each subagent emits:

```json
{
  "citekey": "smith2024paper",
  "verdict": "PASS | WARN | FAIL",
  "diagnostic": "one-line summary",
  "field_findings": [
    {"field": "year", "status": "FAIL", "entry_value": "2023", "canonical_value": "2024", "source": "doi.org/10.1287/mksc.2024.0123"}
  ],
  "canonical_source": "doi | s2 | openalex | arxiv | none",
  "suggested_replacement": "<full corrected BibTeX entry, or null if PASS / unfixable>"
}
```

### Phase 3: Aggregate

Read every JSON in `reports/`. Bucket entries by verdict: FAIL > WARN > PASS. Within each bucket, sort by citekey alphabetically (stable, easy to diff across runs).

### Phase 4: Report

Write `<bib_dir>/bibcheck_<YYYYMMDD_HHMM>/bibcheck_report.md`:

```markdown
# Bibliography Audit: <bib filename>

**Date:** YYYY-MM-DD HH:MM
**Source:** <full path to .bib>
**Entries audited:** N (parsed) / M (malformed, skipped)

## Summary
| Verdict | Count |
|---|---|
| PASS | a |
| WARN | b |
| FAIL | c |
| Possibly fabricated | d  (subset of FAIL)|

## FAIL (blockers — verify before submission)
| Citekey | Diagnostic | Canonical source |
|---|---|---|
| smith2023paper | year mismatch: entry 2023, canonical 2024 | doi.org/10.1287/mksc.2024.0123 |
| jones2024nope  | fabricated? DOI 404s, no S2/OpenAlex/arXiv match | none |

## WARN (style / preprint-vs-published / minor field drift)
| Citekey | Diagnostic |
|---|---|

## PASS
<one-line per entry>

## Per-entry detail
<expandable section with the JSON for each FAIL and WARN>

## Next steps
1. Review each FAIL row. Open `corrected.bib` for suggested replacements.
2. Diff `corrected.bib` against the source `.bib` (`git diff --no-index`).
3. After review, move `corrected.bib` into place yourself — this skill does not overwrite the source.
```

Also write `<bib_dir>/bibcheck_<YYYYMMDD_HHMM>/corrected.bib`: a full copy of the source `.bib` with FAIL/WARN entries replaced by their `suggested_replacement` (preserving every PASS entry untouched, preserving comments and entry order). Entries with no confident correction are kept as-is and tagged with a leading `% bibcheck:FAIL — <diagnostic>` comment line.

## Pass / Warn / Fail criteria

- **PASS** — DOI or canonical source resolves; title, authors, year, venue, volume/issue/pages all match within style tolerance.
- **WARN** — at most one of: author accent/tussenvoegsel drift, journal abbreviation drift, preprint-year vs. published-year, single volume/issue/page disagreement, preprint entry where a published version now exists.
- **FAIL** — any of: DOI doesn't resolve, wrong surname, wrong year (not preprint-explained), wrong journal, two-or-more volume/issue/page disagreements, or the fabrication signature (no source recognises the entry).

## Output report shape

Files written to `<bib_dir>/bibcheck_<YYYYMMDD_HHMM>/`:

```
input.bib              # verbatim copy of source for provenance
entries/<key>.bib      # one parsed entry per file (subagent inputs)
reports/<key>.json     # one verdict per file (subagent outputs)
bibcheck_report.md     # consolidated human-readable report
corrected.bib          # drop-in candidate replacement (user reviews + merges)
```

## Relation to /cite (do not duplicate)

| Skill | Direction | Mutates `.bib`? | Talks to Zotero? |
|---|---|---|---|
| `/cite` | adds ONE entry from a DOI/arXiv/title identifier | yes (appends) | yes (read + write via Web API) |
| `/bibcheck` | audits ALL entries in an existing `.bib` | no (writes a separate `corrected.bib`) | read-only via MCP for cross-check |

If `/bibcheck` finds an entry that should be replaced and the user wants to do that via `/cite`, hand off the DOI / arXiv ID to `/cite` rather than mutating the `.bib` here.

## Long batch runs

Bibliographies over ~60 entries with `--max-parallel 8` can take several minutes. Use `Bash run_in_background: true` for the dispatch loop and stream subagent completion via `Monitor`. Do not block on a single slow MCP call — set a 30-second per-entry timeout and emit a `WARN: lookup_timeout` rather than hanging.

## Failure modes

- **`.bib` not found.** Ask the user for the path; do not invent one.
- **All entries return FAIL with `lookup_timeout`.** MCP rate-limit or network issue. Pause, retry once with `--max-parallel 2`. If still failing, surface the error to the user rather than silently marking everything FAIL.
- **Many false-positive FAILs on `year`.** Likely a preprint-vs-published mismatch pattern; widen Phase 2 step 6's preprint detection rather than loosening tolerance.
- **Match confidence universally below 0.7.** The `.bib` may be a non-English-titled set or a niche venue not indexed by S2/OpenAlex. Flag and ask the user to point at a sample entry known to be correct, then recalibrate.

## Out of scope (do not do these)

- **Don't add entries.** That's `/cite`. If an entry should be replaced, write the suggestion to `corrected.bib`; do not POST to Zotero.
- **Don't auto-overwrite the source `.bib`.** Ever. The user diffs and merges themselves.
- **Don't claim a citation supports a textual claim.** That's a `/review-paper` literature-fidelity check; `/bibcheck` only verifies the entry's metadata matches a real paper.
- **Don't bulk-reformat.** Entries that PASS are copied verbatim into `corrected.bib`, even if the user's style preference differs.
- **Don't audit `.bib` files in `_archive/` or `Old/` subdirectories unless explicitly asked** — these are intentionally frozen.

## Cross-references

- `/cite` — adds individual entries; complementary forward direction.
- `/litreview` — finds papers to cite; pair before `/cite` and `/bibcheck`.
- `/audit-reproducibility` — same per-claim subagent-fanout structure, applied to numeric claims rather than citations.
- `/review-paper` / `/seven-pass-review` — broader manuscript reviews; the citation-pass in those skills delegates here.
