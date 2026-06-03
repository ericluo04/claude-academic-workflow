# Future work

Roadmap items that are not yet shipped. Each is on the queue; none are blockers for the core daily-brief / capture / draft loop.

## `/email-triage`

Pull the morning's Gmail threads, classify each as `urgent` / `respond-today` / `respond-this-week` / `archive`, and optionally draft a reply for high-priority items. Inspired by Chris Blattman's `triage-inbox` skill from [claudeblattman](https://github.com/chrisblattman/claudeblattman). Would need the Gmail connector (see [outlook-gmail.md](outlook-gmail.md)) and a per-user calibration pass.

## `/eval-skill` runner

A driver that reruns the eval suite for every skill in the repo, diffs against the last committed baseline, and reports drift. `/skill-creator` produces evals at skill-creation time; this would close the loop by detecting regressions after model upgrades or skill edits. Output: a markdown drift report and a per-skill pass-rate table.

## `/notion-archive`

Long-running project diary pages (the ones `/notion-log` appends to) get unwieldy after a year or two. This skill would rotate entries older than N months into a child "Archive" page, keeping the main page readable. Read-only on history, append-only on the archive — no destructive operations.

## Pandoc / Quarto integration

Several skills (`/draft`, `/posterskill`, `/academic-pptx`) would benefit from format conversions handled by pandoc or Quarto. Today they emit raw LaTeX or HTML; a thin pandoc layer would let the same content flow into `.docx` for co-author review, `.pptx` for talks, and `.qmd` for blog cross-posting. Quarto specifically would also enable embedded R / Python code chunks without leaving the manuscript.

## Auto-DST handling for the cron schedule

The orchestration repo (`lan-daily-brief`) currently uses fixed UTC offsets in its GitHub Actions cron expressions. Twice a year the morning brief lands at the wrong local time for a week until manually fixed. A small workflow that recomputes the cron line based on the current DST state of America/New_York (or whatever timezone the user configures) would eliminate this papercut. Likely a Python script run nightly that opens a PR against `.github/workflows/*.yml` when the offset is about to flip.

## Other items on the watchlist

- A skill that drafts conference abstracts from a finished paper (`/abstract-from-paper`).
- A `/peer-review-as-reviewer` skill — when invited to review for a journal, scaffold a structured report.
- A unified `/grant-budget` skill — handles NSF / ERC / NIH budget tables with the right per-funder constraints.

If you build any of these, please open a PR against this repo's `future-work.md` to update its status, and a separate PR with the skill itself.

## Status legend

For when more items are added and triage becomes useful:

- `planned` — on the queue, no design work yet.
- `designed` — `SKILL.md` drafted but no implementation.
- `prototype` — runs locally but not stable across users.
- `shipped` — promoted to the main skills directory.

All current items above are `planned` except `/email-triage`, which has a rough design sketched in its upstream source. (`/compile-latex` and `/deslop` have shipped — see `skills/compile-latex/` and `skills/deslop/`.)

## Why these are deferred

Each item is sized at a half-day to a day of work and would slot cleanly into the existing repo, but they're gated on the same upstream question: do the model and the MCPs already in this workflow handle the rough version well enough that a skill wrapper adds value? In a few cases — `/email-triage`, `/notion-archive` — the answer is "probably yes but we haven't measured". `/eval-skill` is gated on having stable eval baselines, which the bundled skills don't all have yet.

If you have a strong opinion on prioritization, open an issue rather than starting from cold — there may already be a half-finished branch.

