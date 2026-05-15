---
name: litreview
description: Runs a structured multi-source literature search across arXiv, Semantic Scholar, and OpenAlex MCPs (with Crossref as fallback), dedupes by DOI / arXiv-ID / fuzzy title, scores each unique paper 1–5 for relevance to the user's query, and returns a ranked summarized list with takeaways framed for a quantitative marketing audience. Use this skill whenever the user asks to "find papers on X", "do a lit review on Y", "what's the literature on Z", "any recent work on W", "find references for my paper's intro", or pastes a topic with phrases like "since 2022" / "open access only" / "n=30". Optionally hands off the top hits (score >=4) to `/cite` for batch Zotero adds. Distinct from `/draft` (which writes prose) and `/cite` (which adds a single paper).
argument-hint: <query> [--four-axis]
---

# /litreview — Multi-source literature search and synthesis

The goal is to give the user a high-signal, ranked, deduped paper list with enough takeaway per item that they can decide which to read, which to cite, and which to skip — all in one pass. The output is the **input** to `/draft` (when writing a lit review) and to `/cite` (when batch-adding the best hits to Zotero).

## Modes

- **Default** (no flag): single 1–5 relevance score per paper — exactly as documented in step 3 below. This is the canonical mode.
- **`--four-axis`** (opt-in): replace the single score with four 1–5 sub-scores — **Novelty** (vs. the existing lit on this topic), **Credibility** (venue tier + author rep + sample / data quality), **Relevance** (fit to the specific project context), **Actionability** (cite-as-prior / replicate-method / pivot-target / superseded). **Composite** = arithmetic mean of the four, rounded to one decimal. The breakdown is rendered only when **composite >= 4** (else show only the composite, to keep output tight). All downstream thresholds — ranking, in-Zotero check, the `/cite` handoff — use the composite as a drop-in replacement for the single score, so the **composite >= 4** cutoff matches the default **score >= 4** cutoff exactly. Default behavior is unchanged unless `--four-axis` appears in the invocation.

## When to invoke

The user invokes `/litreview <query>` with a topic, paper, or research question. Common shapes:

- `/litreview discrimination in online labor markets using AI-generated profile images`
- `/litreview sparse autoencoder steering for text generation`
- `/litreview meta-science applied to social media engagement prediction`
- `/litreview cite-by-DOI 10.1287/mksc.2023.1234`  (anchor mode — seed paper)
- `/litreview "moral outrage" Brady PNAS replications`
- `/litreview generative AI in product design since 2022 open access n=30`

Loosely-stated flags inside the query — interpret them, don't require a CLI:

| Phrase | Action |
|---|---|
| "since YYYY", "last N years", "post-2022" | year filter |
| "open access only", "OA only" | filter to OA papers (has `openAccessPdf`) |
| "n=N", "top N", "give me N" | result cap (default 25) |
| "add to zotero", "file these", "send to /cite" | hand off step 5 |
| "in collection X" | propagate to `/cite` |
| "marketing only", "MKSCI/JMR/JCR/MS only" | venue filter |
| "exclude preprints" | filter out arXiv-only / unpublished |

## Required MCP tools (verified live names)

Run these in parallel for source coverage. If a server is down, continue with whichever responded.

- `mcp__arxiv__search_papers` — primary for recent ML/CS/preprints.
- `mcp__arxiv__semantic_search` — embedding-similarity within a local arXiv corpus (if pre-indexed). Useful for "papers similar to <seed arXiv ID>".
- `mcp__arxiv__get_abstract` — fetch abstract by ID after a hit.
- `mcp__semantic-scholar__search_papers` — primary for published / peer-reviewed work and citation counts.
- `mcp__semantic-scholar__get_paper_details` — full metadata + DOI + venue + OA link.
- `mcp__semantic-scholar__get_paper_references` / `mcp__semantic-scholar__get_paper_citations` — for seed-paper expansion ("papers like X", "papers citing Y").
- `mcp__semantic-scholar__get_recommendations` — Semantic Scholar's recommendation engine.
- `mcp__openalex__openalex_search_entities` — broadest interdisciplinary venue coverage, best for social-science / marketing / policy work that Semantic Scholar misses.
- `mcp__openalex__openalex_analyze_trends` — only when the user asks "how has the literature evolved" or similar trend question.

**Fallback (manual)** when all three MCPs miss something specifically expected: Crossref REST API via `Invoke-WebRequest` (`https://api.crossref.org/works?query=<terms>&rows=20`) — no auth, no MCP needed.

**Out-of-loop tools**: Zotero MCP (`mcp__zotero__zotero_search_items`) only for deduping against the existing library; the Zotero MCP is read-only — adds go through `/cite`, which uses the Zotero Web API directly.

## Workflow

### 1. Plan the queries

Translate the natural-language query into 1–3 targeted search strings per source. Don't echo the exact phrase — strip filler ("can you find", "I'm interested in"), pull out the substantive nouns, expand acronyms (e.g. SAE → "sparse autoencoder"; but don't expand acronyms that are project shorthand for a topic — search the topic, not the acronym).

Tailor per source:

- **arXiv**: short keyword phrase, optional category filter (e.g., `cs.LG`, `econ.EM`, `stat.ME`).
- **Semantic Scholar**: full query string; use `year>=2020` filter parameter if the user asked for recent work.
- **OpenAlex**: broader keyword set; include MeSH-like concept terms for biomedical/policy adjacency.

Run all three searches **in parallel** with `limit=20` to `30` each so dedupe has headroom.

### 2. Dedupe

Build a unified candidate list. Dedupe in this order:

1. **DOI** exact match (strip `https://doi.org/`, lowercase).
2. **arXiv ID** exact match (handle both `2403.12345` and `arXiv:2403.12345v2`).
3. **Title fuzzy match** — lowercase, strip punctuation, tokenize; >=90% token-set overlap = same paper.
4. **Author-first + year** as a last-resort tiebreak.

When the same paper appears in multiple sources, merge metadata:
- Prefer **Semantic Scholar** for citation count, abstract, references.
- Prefer **OpenAlex** for venue name, concept tags, OA status.
- Prefer **arXiv** for the preprint version + latest version date.

### 3. Score relevance (1–5)

For each unique paper, score against the query using abstract + venue + year:

- **5** — directly on the question; central reference; would be cited in the intro of a paper on this topic.
- **4** — closely related; definitely cite; secondary support.
- **3** — adjacent; worth knowing about; might cite in a robustness or lit-review paragraph.
- **2** — tangential; mention only if asked.
- **1** — false positive; filter out before output.

Be honest. If only 8 papers score >=3, return 8 — not 25 padded with score-2 noise. Padding wastes the user's time and credibility.

### 4. Pre-existing-in-Zotero check (cheap dedupe against the library)

Before output, for the score >=4 papers, call `mcp__zotero__zotero_search_items(query="<short title>", qmode="titleCreatorYear", limit=3)` to check if it's already there. Flag as `[in Zotero]` in output — saves the `/cite` step on those.

### 5. Output — ranked summarized list

Order by score (descending), then year (newest within score). Format per paper:

```
**[1] (score=5, 2024) Athey, Imbens et al. — *Title in italics*. *Marketing Science*. doi:10.xxx
   Why relevant: <one sentence anchoring to the query>
   Key finding/contribution: <one short sentence>
   Method/identification: <one phrase — RDD, RCT, DiD, structural, observational, etc.>
   arXiv:24xx.xxxxx | OA: yes | citations: 142 | [in Zotero: existing-key | not yet]
```

After the list, give a **3–5 sentence synthesis** through a quantitative-marketing / causal-inference lens:
- Which sub-themes dominate.
- Where the field disagrees (a real edge to position against).
- What's missing — gaps that could plausibly be filled or that the user's papers already address.

If the user asked for "add to zotero" or "send to /cite", proceed to step 6.
Otherwise stop here and ask: *"Add the score >=4 hits to Zotero via /cite?"*

### 6. Optional: hand off top hits to /cite

For each paper with score >=4 (or whatever cap was given), pass DOI or arXiv ID to `/cite` in one batch. `/cite` handles:
- DOI/arXiv resolution via `mcp__semantic-scholar__get_paper_details`.
- Duplicate check via `mcp__zotero__zotero_search_items` (read-only MCP).
- Zotero **write** via Web API — the MCP can't write.
- Better-BibTeX export via Zotero Web API (`?format=bibtex`).
- Append to active project's `.bib`.
- File in the matching `zotero_collection_key` from `personal_config.projects[]`.

Don't re-implement that logic here — invoke `/cite` and surface its summary back.

## Search-quality heuristics

- **Methodological queries** ("interpretable ML for marketing", "double-machine learning for heterogeneous treatment effects") — Semantic Scholar's citation network is strongest; use `get_paper_references` / `get_paper_citations` once you've identified a seed paper.
- **Preprints / recent ML** ("sparse autoencoder", "GemmaScope", "SAE steering") — arXiv first; Semantic Scholar lags by 2–6 weeks on indexing.
- **Marketing / consumer behavior / JMR-JCR territory** — OpenAlex is broadest; supplement with Semantic Scholar.
- **Author-specific** ("Athey work on conformal prediction", "Imbens recent papers") — OpenAlex `author.id` filter; or Semantic Scholar `search_authors` → `get_author_top_papers`.
- **Seed-paper expansion** (DOI seed → "find papers like this") — `get_paper_recommendations` first, then `get_paper_citations` for forward, `get_paper_references` for backward.

## Failure modes

- **One source down or rate-limited**: report which one, continue with the others — don't fail the whole search.
- **All three sources return nothing**: try a relaxed query (drop year filter, broaden terms) once. If still empty, fall back to Crossref. If still empty, surface what was tried.
- **Query too vague** ("find me papers", "lit review please"): ask for at least one keyword or topic before searching. Don't guess.
- **Paywalled paper, no abstract available**: include it in the list with `<abstract not accessible>` and lower-bound the score at 3 (don't auto-promote it). Note OA status `no`.
- **Suspected duplicate that isn't** (same title, different papers — common with workshop vs journal versions): keep both; tag the older version as `[v1 — superseded by entry N]`.
- **User pastes a fully-formatted citation as the query**: treat that as a seed-paper anchor mode — resolve it first via DOI/title, then return related work plus the seed itself at score 5.
- **OpenAlex returns 500 candidates for a broad query**: tighten the keyword set rather than truncate — truncation hides relevance.

## Out of scope

- **Writing prose / lit-review section**: that's `/draft`. This skill returns the input; `/draft` writes the section.
- **Adding one paper to Zotero**: that's `/cite`. This skill is for batches discovered through search.
- **Reading PDFs in depth / extracting figures**: this skill works from abstracts + metadata. For deep reads, route specific papers to a manual read or to `review-paper-code` if it's a methods reference.
- **Comprehensive systematic review** (PRISMA-style): out of scope — this is a fast-turn discovery + ranking tool, not a 6-month SR.
- **Fabricating citations**: never. If a paper isn't found in any of the three MCPs + Crossref, say so — don't invent author-year-title triples that "sound right".
