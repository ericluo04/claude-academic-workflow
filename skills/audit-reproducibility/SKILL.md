---
name: audit-reproducibility
description: Cross-check every numeric claim in a manuscript against the actual R / Python outputs that produced it, and report PASS / FAIL per claim against numeric tolerances. Use when the user says "audit reproducibility", "check my numbers", "verify the tables match the code", "reproducibility audit", "do the paper numbers match", or before submitting / resubmitting a paper or releasing a replication package. Designed for quant-marketing manuscripts (Marketing Science, JMR, JCR, Management Science) and economics-style projects in R or Python.
argument-hint: "[manuscript path] [outputs-dir] (outputs-dir defaults to output/ or results/)"
allowed-tools: ["Read", "Grep", "Glob", "Write", "Bash", "Task", "Monitor"]
effort: high
---

# Audit Reproducibility

> **Source.** This skill is jointly adapted from [`pedrohcgs/claude-code-my-workflow`](https://github.com/pedrohcgs/claude-code-my-workflow) and Scott Cunningham's [`MixtapeTools`](https://github.com/scunning1975/MixtapeTools). The 5-phase tolerance-based numeric-claim audit (extract → match → compare → report PASS/FAIL → summarize) draws on both: Pedro's R / Python / Stata multi-language phase structure and Scott's claim-extraction-to-tolerance-comparison flow. This fork tunes the language stack to R / Python only (no Stata) and the manuscript conventions to quantitative-marketing layouts.

Compare numeric claims in a manuscript (point estimates, standard errors, p-values, counts, percentages) against the actual outputs produced by the analysis pipeline. Report PASS / FAIL per claim against documented tolerance thresholds.

**Core principle:** If the paper says `beta = 0.342 (0.091)` and the R / Python code produces `0.338 (0.094)`, we verify — numerically — that the difference is within tolerance. No "looks close enough" eyeballing.

The target stack is R and Python only — there are no Stata `.do` files, `.log` files, or `master.do` runners in scope here. Pipelines are typically R scripts (`scripts/00_run_all.R`, `make`, `targets`) or Python (`run.py`, `snakemake`, `nbconvert`).

## When to use

- **Before submission** to Marketing Science, JMR, JCR, Management Science, or an econ journal. Catches the "I rebuilt the panel but forgot to update Table 3" bug — extremely common between R1 and R2.
- **Before releasing a replication package** required by MKSCI / MS / JMR / AEA-style data-availability policies.
- **After a major revision** where the analysis pipeline changed.
- **Quality gate before circulation** so coauthors don't catch stale numbers.

## Inputs

- `$0` — path to the manuscript (`.tex`, `.qmd`, `.Rmd`, `.md`, `.pdf`). Required. Projects typically live under `<OVERLEAF_ROOT>/<PROJECT_SUBDIR>/`.
- `$1` — path to the outputs directory. Defaults to `output/` or `results/` (try both). Other common locations: `tables/`, `figures/`, `_targets/objects/`, `notebooks/output/`.

## Workflow

### Phase 0: Pre-flight

1. Confirm the manuscript path exists and is readable.
2. Verify the outputs directory exists and is non-empty. If empty or stale (modification times older than the manuscript), prompt the user to re-run the pipeline before auditing:
   - R: `Rscript scripts/00_run_all.R` or `Rscript -e "targets::tar_make()"`
   - Python: `python run.py` or `jupyter nbconvert --execute notebooks/main.ipynb`
3. Look for an environment capture file: `sessionInfo.txt`, `renv.lock`, `DESCRIPTION`, `requirements.txt`, `environment.yml`, `pyproject.toml`. Note its presence in the report.
4. Default numeric tolerances (override by passing `--tolerance-file` or by editing a project-local `.reproducibility.yml`):

| Kind | Default tolerance |
|---|---|
| Integers (N, counts) | Exact |
| Point estimates | `abs(reported - computed) < 0.01` |
| Standard errors | `abs(reported - computed) < 0.05` |
| P-values | Same significance bucket (p<0.001, p<0.01, p<0.05, p<0.10, n.s.) |
| Percentages | Within 0.1 pp |
| Elasticities / large coefficients | Within 1% relative |

### Phase 1: Extract claims from the manuscript

Parse the manuscript for numeric claims. Patterns to match:

- **Point estimate + SE**: `beta = 0.342 (0.091)`, `$\hat{\beta} = 0.342$ (0.091)`, `1.28^{***}` with starred significance.
- **LaTeX table cells**: `& 0.342$^{***}$ & (0.091) &` inside `\begin{tabular}` / `\begin{table}` blocks.
- **Sample-size statements**: `our sample of 12,847 observations`, `$N = 12{,}847$`, `2.3 million records`.
- **Summary stats**: `mean = 0.423`, `SD = 0.087`, `median rating = 3.4`.
- **P-values**: `p < 0.01`, `$p = 0.003$`.
- **Percentages / shares**: `42.3% of cases`, `share = 0.423`.
- **Marketing-specific magnitudes**: lift estimates ("a 6.2% increase in click-through"), elasticities, WTP / dollar values, conjoint part-worth utilities.

Record each claim as a tuple:

```json
{
  "claim_id": "Table2_col3_treatX",
  "location": "Table 2, Column 3, row 'Treatment X'",
  "kind": "point_estimate",
  "reported_value": 0.342,
  "uncertainty": 0.091,
  "significance_stars": 3,
  "raw_context": "the treatment X coefficient of 0.342 (0.091) suggests..."
}
```

Write the extracted claims to `<project>/audit_claims_<YYYYMMDD>.json` so the user can review the extraction before the audit runs.

### Phase 2: Extract results from outputs

Scan `$1` for corresponding values. Priority order:

1. **`.rds` / `.qs` files** — R serialized objects. Use a one-liner: `Rscript -e "obj <- readRDS('path.rds'); print(broom::tidy(obj))"`. For `qs`: `Rscript -e "obj <- qs::qread('path.qs'); ..."`.
2. **`.tex` table files** — parse LaTeX table cells directly; match column headers + row labels.
3. **`.csv` / `.tsv` summary files** — readr / pandas parse, key-value lookup. Common location: `output/tables/main_results.csv`.
4. **`.parquet` / `.feather`** — pyarrow / arrow read. Common in larger-scale pipelines.
5. **`.json`** — direct key lookup. Often produced by Python notebooks.
6. **`.ipynb` outputs** — `jupyter nbconvert --to script` then grep, or parse JSON cells directly.

Record each extracted result:

```json
{
  "source": "output/tables/main_results.rds",
  "lookup_key": "fit_main$coefficients['treatment_x']",
  "value": 0.338,
  "uncertainty": 0.094,
  "p_value": 0.0004
}
```

### Phase 3: Match claims to results

Use fuzzy heuristics when exact labels don't align:

- Name similarity (e.g., `"treatment x score"` ~ `"tx_score"` ~ `"treatment_x"`; `"composite complexity"` ~ `"complexity_idx"`).
- Magnitude similarity: if two candidates are within 10% of the reported value, prefer the one with the closer SE.
- Context hints from the claim's `raw_context` (table number, row label, column header).

Claims with match confidence below 0.7 are flagged `UNMATCHED — manual review needed` rather than silently passing.

### Phase 4: Tolerance check

For each matched claim, apply the tolerance table from Phase 0. Honour any project-local overrides (`.reproducibility.yml`) — the user may loosen for Monte Carlo simulation noise (e.g., neural-net training seeds) or tighten for descriptive statistics that should be exact.

### Phase 5: Report

Write `<project>/audit_<YYYYMMDD>.md`:

```markdown
# Reproducibility Audit: <Manuscript Title>

**Date:** YYYY-MM-DD
**Manuscript:** <path>
**Outputs directory:** <path>
**Tolerance source:** <default or .reproducibility.yml>

## Summary

| Status | Count |
|---|---|
| PASS | N |
| FAIL (diff > tolerance) | M |
| UNMATCHED (manual review) | K |
| **Overall verdict** | **PASS / FAIL** |

## PASS (within tolerance)
| Claim | Reported | Computed | Diff | Tolerance |
|---|---|---|---|---|
| Table2_col3_treatX | 0.342 (0.091) | 0.338 (0.094) | 0.004 / 0.003 | 0.01 / 0.05 |

## FAIL (outside tolerance — BLOCKER)
| Claim | Reported | Computed | Diff | Tolerance | Location in paper |
|---|---|---|---|---|---|

## UNMATCHED (manual review)
| Claim | Raw context | Candidate sources |
|---|---|---|

## Environment
[sessionInfo.txt / renv.lock / requirements.txt excerpt]

## Next steps
1. Fix any FAIL rows — either update the manuscript or rerun the analysis.
2. Resolve UNMATCHED rows — add explicit table-to-file mappings or widen the search scope.
3. After zero FAILs, the paper is replication-ready.
```

## Exit behaviour

- **All PASS:** exit 0; summary printed.
- **Any FAIL:** exit 1; summary printed to stderr. Usable as a pre-submission gate.
- **UNMATCHED > 0 (with 0 FAIL):** exit 0 with a warning — manual review required.

## Long batch reruns

When auditing all numeric claims in a paper and the pipeline takes more than a couple of minutes (e.g. neural-net retraining, large feature extraction), background-launch the rerun with `Bash run_in_background: true`, then use the `Monitor` tool to stream stdout. The audit can react to errors mid-stream rather than waiting for the whole pipeline to finish before noticing a failed step.

## Failure modes

- **No outputs directory found.** Skill cannot locate `output/`, `results/`, or `tables/`. Ask for the correct path; do not invent one.
- **Outputs are older than the manuscript.** Skill warns and refuses to issue a PASS verdict — the comparison would be against stale numbers. Prompt for a rerun.
- **No numeric claims extracted.** Manuscript is too early-stage (no tables yet) or the parser missed everything. Re-run with verbose extraction and ask the user to point at one example claim.
- **Match confidence universally below 0.7.** Table-to-file naming convention is opaque; ask for a minimal mapping (`{"Table 2": "output/tables/main_results.csv", ...}`) and rerun Phase 3.
- **`.rds` extraction errors.** Rscript not on PATH, or the object structure changed. Fall back to `.tex` / `.csv` lookups and flag the affected claims as UNMATCHED.
- **Stochastic results without seeds.** Bootstrap CIs or neural-net retraining without `set.seed()` / `np.random.seed()` will fail tolerance — flag, but recommend adding seeds rather than loosening tolerance.

## Out of scope

- **Re-running the analysis.** The skill compares CURRENT outputs against manuscript claims. If outputs are stale, rerun the pipeline first.
- **Catching wrong specifications.** A regression that compiles and reproduces `0.342` is reproducible. Whether `0.342` is the right estimand is a `review-paper` / domain question.
- **Pinning package versions.** The environment capture file lets a reviewer see the env; pinning is on the user (via `renv.lock`, `pyproject.toml`, `environment.yml`).
- **Stata / SAS / Matlab outputs.** This skill targets R / Python only. If a coauthor brings Stata `.log` files, route them through a Stata-aware audit instead.
- **Submitting to a registry or repository.** This skill audits; it does not upload to Dataverse, OpenICPSR, or a journal replication archive.

## Cross-references

- `/review-paper-code` — broader reproducibility + code-quality audit; pair with this skill for a full pre-submission check.
- `/review-paper` — content review; complementary to this numeric audit.
- `/seven-pass-review` — adversarial multi-lens review; Lens 4 (Results) overlaps lightly with this skill but stays qualitative.
