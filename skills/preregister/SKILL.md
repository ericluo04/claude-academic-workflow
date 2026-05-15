---
name: preregister
description: Draft a structured preregistration document (AsPredicted, OSF, or AEA RCT Registry style) from a study spec or free-form description, annotated with MUST / SHOULD / MAY clarity flags. Use when the user says "preregister", "draft a preregistration", "OSF preregistration", "AsPredicted form", "AEA RCT registry", "PAP", "preanalysis plan", or before launching an online experiment, conjoint, vignette study, eye-tracking session, or any data collection / confirmatory analysis they have not yet seen. Output is a LaTeX (`.tex`) or Markdown file the user uploads to OSF / AsPredicted / AEA themselves — this skill writes structure and prose, it does not submit. Designed for quant-marketing experiments (online vignettes, MTurk / Prolific, conjoint, lab eye-tracking, livestreaming field tests) targeting MKSCI / JMR / JCR / MS.
argument-hint: "[--style aspredicted|osf|aea-rct] [--input <spec-path>] [--format tex|md] [--no-verify]"
allowed-tools: ["Read", "Write", "Task", "WebFetch"]
---

# /preregister — Preregistration Document Generator

> **Source.** This skill is adapted from [`pedrohcgs/claude-code-my-workflow`](https://github.com/pedrohcgs/claude-code-my-workflow). The three-registry structure (OSF / AsPredicted / AEA RCT), the MUST / SHOULD / MAY clarity-flag taxonomy, and the retrospective-preregistration refusal gate are Pedro H.C. Sant'Anna's; this fork tunes the experiment templates for quantitative-marketing designs (online vignettes, MTurk / Prolific, conjoint, lab eye-tracking, livestreaming field tests).

Produce a registry-ready preregistration document. The user uploads the result to a real registry (OSF / AsPredicted / AEA RCT Registry) — this skill writes the prose and structure, it does not submit anywhere.

## Why preregister

Preregistration is a written commitment to your hypotheses, design, and analysis plan **before** you see the data (or, for observational analyses, before you analyse the realised focal outcome). It separates confirmatory tests from exploratory tests and protects against p-hacking, HARKing, and forking paths. Marketing's top journals (MKSCI, JMR, JCR, MS) increasingly expect preregistration for experimental work; AEA-style field experiments require it.

Marketing fits each registry roughly as follows:

- **Online experiments, vignettes, conjoint, eye-tracking** -> **AsPredicted** is the default short form. **OSF** when more structure is needed (multiple DVs, complex sampling).
- **Field experiments / RCTs** -> **AEA RCT Registry** is the standard (and is required for AEA-journal submission since 2018; MKSCI and MS-Marketing accept either OSF or AEA).
- **Observational confirmatory analyses** on data not yet seen for the focal outcome -> **OSF** preanalysis-plan template.

Clinical trials (ClinicalTrials.gov, ISRCTN) and meta-analyses (PROSPERO) are out of scope — use those registries' own templates.

## When to use

- Before launching a lab, field, or online experiment.
- Before collecting observational data on a target population for a specific RQ.
- Before analysing data the user has access to but has not yet examined for the focal hypothesis.
- During an R&R when a referee asks for a written preanalysis plan (Marketing Science increasingly requests one for experimental papers at R1).

## When NOT to use

- After the user has already seen the realised outcomes and wants to "preregister retrospectively" — that is not preregistration. The skill will refuse if the input description contains results.
- For purely exploratory analyses — those do not need preregistration; they need transparent labelling.
- For clinical trials or meta-analyses (wrong registry).

## Workflow

### PHASE 1 — Read inputs

Two input modes:

1. **`--input <path>`** — a study spec (e.g., a Markdown draft from `/evaluate-idea-marketing`, a Notion export, or a section pulled from a project planning doc). Read the spec and extract: research question, hypotheses (must be directional), data source, design, sample, primary analysis. If the spec lists `paper_type: survey-experiment` / `field-experiment` / `conjoint` / `eye-tracking` / `observational`, use that to bias the style choice.
2. **No `--input`** — prompt for a 1-3 paragraph description of the study, then proceed. If the description omits a directional hypothesis, ask once. Do not fabricate.

Refusal conditions (checked before any drafting):

- Description contains realised results ("we found", "the estimate is", "p =", "respondents in condition A scored higher") -> refuse with: "Preregistration is forward-looking; this description includes results. Did you mean `/draft` for a methods or results section?"
- Description has no testable hypothesis at all (pure exploratory framing) -> ask whether to use the OSF *exploratory analysis* template (still useful, but not a registered confirmatory test).

### PHASE 2 — Pick the style

Default style table (used when `--style` is not given):

| Signal in spec / description | Default style |
|---|---|
| Online vignette / MTurk / Prolific / quick lab experiment, 1-3 DVs | `aspredicted` |
| Conjoint, eye-tracking, multi-DV survey experiment, complex sampling | `osf` |
| Field experiment / RCT (livestream pilot, retailer pilot, app A/B) | `aea-rct` |
| Observational confirmatory study | `osf` (preanalysis plan variant) |
| Anything else / ambiguous | `aspredicted` |

Override with `--style aspredicted|osf|aea-rct`.

### PHASE 3 — Generate the document

Produce the document in the chosen style. **Do not merge style sections** — the three registries differ in what they require.

Common to all styles, the document MUST include:

- Title and authors.
- Date and version (semantic: `v0.1` for draft, `v1.0` when uploaded).
- Pointer back to the source spec (if `--input` was given) so traceability survives.
- Target journal (e.g., MKSCI, JMR, JCR, MS) so reviewers know the confirmatory bar.

Style-specific sections:

- **`aspredicted`** — 9 numbered fields per the AsPredicted form: (1) data collection status, (2) hypothesis, (3) key dependent variable, (4) conditions, (5) analyses, (6) outliers / exclusions, (7) sample size + stopping rule, (8) anything else, (9) name (study not paper).
- **`osf`** — Hypotheses (directional, numbered) - Design - Sampling Plan - Variables (independent, dependent, controls, manipulation checks) - Analysis Plan (estimator, software, package versions) - Inference Criteria - Data Exclusions - Missing Data Handling - Exploratory Analyses (clearly labelled as such) - Other.
- **`aea-rct`** — Intervention - Outcomes (primary, secondary) - Primary hypotheses - Sample (target N, eligibility, randomization unit, randomization method) - IRB approval - Trial dates - Power calculation - Pre-analysis plan attachment - Status (not yet on the air / ongoing / completed).

Annotate each section with one of:

- **MUST** — the registry requires this; the document cannot be submitted without it.
- **SHOULD** — strongly recommended; reviewers and editors expect it.
- **MAY** — optional; include if relevant.

For each MUST that the input did not supply, write `[CLARIFY: <specific question>]` rather than fabricating content.

### PHASE 4 — Cross-checks (before writing to disk)

Refuse to mark the document "ready" if any of these fails:

- **Hypothesis directionality.** Each hypothesis must contain a direction ("higher than", "increases", "negatively predicts"; "no effect" is acceptable under an equivalence-test frame). Reject "is associated with" without a sign.
- **Estimator named.** The analysis plan names a specific estimator with software — e.g., `lm()` / `lme4::lmer()` / `fixest::feols()` / `brms::brm()` in R, or `statsmodels.OLS` / `linearmodels.PanelOLS` / `pymer4` / `pymc` in Python — plus the primary outcome variable. "Regression" alone is insufficient. **Stata is not supported by this skill** — analyses are expected to run in R or Python.
- **Sample plan numeric.** Target N, stopping rule, or power-calc target appears. "As many as we can recruit" is not a sample plan. For Prolific / MTurk, state the platform and screening criteria. For field experiments, state cluster N and within-cluster N.
- **Exclusions ex ante.** Outlier and exclusion rules are stated *before* the data is seen (e.g., "we will exclude observations with completion time under 60 seconds or who fail the attention check"). Vague "we'll deal with outliers" fails.
- **Internal consistency.** If the design is randomised, the unit of randomisation matches the unit of analysis OR the analysis plan addresses clustering. If observational, the identification strategy is stated.
- **Manipulation checks.** For experiments, at least one manipulation check is named (top marketing journals push back hard on this).

For each failure, the document gets a `[CLARIFY: ...]` placeholder; the document is written to disk but flagged in the output summary as "INCOMPLETE — N MUST items unresolved".

### PHASE 5 — Post-flight verification

If the document cites prior literature in the rationale section, invoke a citation check via `Task` (a forked `claim-verifier` agent that never sees the draft). Pass the draft path and a list of explicit citations. The verifier returns PASS / PARTIAL / FAIL per citation. Surface any FAIL / PARTIAL in the output summary.

Skip post-flight if:

- No prior-literature citations in the document.
- The user passes `--no-verify`.

### PHASE 6 — Output

Write to `<project>/preregistration_<study-slug>_<YYYYMMDD>.<ext>`:

- Default extension: `.tex` (papers and PAPs live in LaTeX under `<OVERLEAF_ROOT>/<PROJECT_SUBDIR>/`). Use a minimal preamble compatible with an existing `.tex` workflow (`article` class, `natbib`, `\Cref` cross-references, `\emph` over `\textit`).
- Override with `--format md` for OSF web-form pasting.

Print to chat:

```
Preregistration draft saved: <project>/preregistration_<study-slug>_<YYYYMMDD>.tex
  Style: <aspredicted|osf|aea-rct>
  Target journal: <MKSCI|JMR|JCR|MS|...>
  Sections: <count> total — <complete> complete, <clarify> with [CLARIFY:] placeholders
  Citations verified: <PASS>/<PARTIAL>/<FAIL>  (or "no citations to verify")
  Next: review the [CLARIFY:] placeholders, fill in, then upload to <registry-url>
```

Registry URLs:

- AsPredicted -> `aspredicted.org`
- OSF -> `osf.io/registries`
- AEA RCT -> `socialscienceregistry.org`

## Examples

### Example 1 — AsPredicted form for a vignette study
**User says:** "preregister a vignette study testing whether attribute X increases booking intent" (no `--input`)
**Actions:**
1. Prompt for the 1-3 paragraph description.
2. Default style -> `aspredicted` (short online experiment).
3. Populate the 9 AsPredicted fields. Estimator: `lm(booking_intent ~ attribute_x * gender + age + ...)`. Stopping rule: N = 800 on Prolific, recruit until quota.
4. No prior-lit cites in the form -> skip post-flight.
**Result:** Saved to `<project>/preregistration_attribute-x-vignette_<YYYYMMDD>.tex`. The user pastes into AsPredicted.

### Example 2 — OSF preanalysis plan for an observational panel
**User says:** "preregister my panel analysis before I see the sales data" (with `--input ideas/panel-spec.md`)
**Actions:**
1. Read spec; observational confirmatory -> default `osf`.
2. Two directional hypotheses on feature X -> log(sales). Estimator: `fixest::feols()` with author and genre-week FEs, clustered SEs at author.
3. Cross-checks pass; one `[CLARIFY: minimum within-author observations]` placeholder.
4. Lit cites verified.
**Result:** Saved to `<project>/preregistration_panel-analysis_<YYYYMMDD>.tex`. The user reviews the one [CLARIFY:] and uploads to OSF.

### Example 3 — AEA RCT registration for a field experiment
**User says:** "draft an AEA RCT preregistration for the field pilot" (with `--style aea-rct --input ideas/field-pilot.md`)
**Actions:**
1. Read spec; randomization unit = unit-day, primary outcome = engagement-minutes.
2. Generate AEA RCT fields. IRB number missing -> `[CLARIFY: IRB approval number]`.
3. Cross-checks: cluster-robust OLS estimator named, primary outcome stated, ITT exclusion rule stated. Pass.
**Result:** Document written. Output summary flags 1 [CLARIFY:] item to fill before AEA submission.

## Failure modes

- **Description contains results.** Refuse, point at `/draft` for methods / results writing.
- **No testable directional hypothesis.** Ask once; if the user declines, switch to the OSF *exploratory analysis* variant and flag prominently in the document header.
- **OSF / AsPredicted web template fetch unavailable.** The skill ships with the three style scaffolds embedded — if WebFetch to the registry homepage fails, proceed offline using the embedded scaffold and flag in the summary so the user can verify against the live form before upload.
- **No `--input` and the user does not respond with a description in chat.** Do not write a placeholder document; abort and ask once.
- **Citation post-flight returns FAIL / PARTIAL.** Surface the offending citations; do not silently drop them. Likely a recent / paywalled paper the verifier missed, or a hallucinated cite — the user must inspect.
- **Output directory does not exist.** Create `<project>/` if missing; if the project root is not yet under the Overleaf root, fall back to `~/.claude/cache/preregistrations/`.

## Out of scope

- **Submitting to a registry.** This skill writes the document; the user uploads it.
- **Clinical trial registries** (ClinicalTrials.gov, ISRCTN) — use those registries' own forms.
- **Meta-analysis preregistration** — use PROSPERO directly.
- **Power-calculation arithmetic.** The skill records the target N and the assumed effect size supplied; it does not run `pwr::pwr.t.test()` itself (use `/draft` plus an R chunk, or a separate `Bash` call to `Rscript`).
- **Editing already-submitted preregistrations.** Registries require formal amendments — out of scope here.
- **Notion logging.** To track the registration in the Notion Tasks DB, run `mcp__notion__notion-create-pages` separately after the document is written.

## Cross-references

- `/evaluate-idea-marketing` — upstream; produces the spec this skill often consumes via `--input`.
- `/review-pap` — downstream; runs a 6-agent adversarial review of the resulting PAP before upload.
- `/draft` — for the methods section that mirrors the preregistration once data come in.
- `/cite` — to add cited works to Zotero / `.bib` before / after this skill runs.
