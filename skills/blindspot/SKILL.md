---
name: blindspot
description: Shklovsky-inspired peripheral-vision audit of a SINGLE figure or table in a quantitative-marketing paper. Forces a four-quadrant grid — Unexplained Feature, Convenient Absence, Unasked Question, Unexploited Strength — to surface what the author has stopped seeing in a coefficient plot, DiD event-study, conjoint utility plot, predicted-engagement curve, GAN attribute-axis image grid, SAE feature heatmap, or livestream time-series. Use when the user says "/blindspot", "audit this figure", "blindspot check on Figure 3", "what am I missing in this plot", "what's a hostile referee going to ask about this figure", "peripheral vision on Table 4", or "make the stone stony again". Operates at the figure / table level only — manuscript-level adversarial review is `/seven-pass-review`; numeric-claim verification is `/audit-reproducibility`; correctness of the code that built the figure is `/review-paper-code`. They compose — run `/blindspot` early on a fresh figure, then `/seven-pass-review` once the surrounding draft is complete.
argument-hint: "[figure path: .pdf|.png|.pgf|.tex|<manuscript>:<figure-label>]"
allowed-tools: ["Read", "Grep", "Glob", "Bash"]
effort: low
---

# Blindspot

A single-figure peripheral-vision audit. After weeks on a paper, the main finding collapses attention onto one feature of a plot and everything else — the spike at t=1, the missing subgroup, the heterogeneity richer than the average, the identification strength the paper undersells — goes invisible. This skill forces you to see them again.

> Shklovsky's frame: art exists to restore perception, to make the stone stony again. `/blindspot` does that for one figure or table at a time.

**Position vs. neighbors.** `/blindspot` is figure-level. `/seven-pass-review` is manuscript-level (seven parallel reviewers across abstract/intro/methods/results/robustness/prose/citations). `/audit-reproducibility` cross-checks numbers against code outputs. `/review-paper-code` audits the script that built the figure. They compose; they do not substitute for each other. If the user asks for a "deep review of the paper" or "review my draft," that is `/seven-pass-review`, not this skill.

## When to use

- A new figure or table has just appeared in an analysis and the prose around it is not yet written.
- Before circulating a draft to coauthors — sanity-check the headline figure.
- Before a seminar, when the first question will obviously be about one specific panel.
- During R&R, on any figure a referee complained about, to find what the response letter has to address before drafting prose with `/draft` or `/referee-response`.

## Inputs

- `$0` — path to ONE figure or table. Accepted forms:
  - Raster: `.png`, `.jpg`, `.jpeg` — read via Read tool's multimodal support so the actual image content is in context.
  - Vector: `.pdf` (single-figure PDF) — read via Read.
  - LaTeX source: `.tex` or `.pgf` snippet, or a TikZ / pgfplots block. Read as text; reason from the code.
  - Manuscript reference: `path/to/main.tex:fig:event-study` — open `main.tex`, locate the `\begin{figure}` / `\begin{table}` whose `\label{...}` matches, read the surrounding caption and code, and (if the figure is `\includegraphics{...}`) recursively read that image file.
- Optional second arg: a 1-sentence description of what the user thinks the figure shows ("event-study around the redesign — I'm reading this as a 14% lift"). Anchors the audit; the skill then probes whether the figure supports that reading.

Projects typically live under `<OVERLEAF_ROOT>/<PROJECT_SUBDIR>/`.

## The four-quadrant frame

|  | What's visible but un-seen | What's absent but un-noticed |
|---|---|---|
| **Vices (problems)** | (1) Unexplained Feature | (2) Convenient Absence |
| **Virtues (opportunities)** | (3) Unasked Question | (4) Unexploited Strength |

### 1. Unexplained Feature — visible vice

Something in the figure that does not fit the story but nobody flagged. The t=1 spike before the treatment date. A coefficient that flips sign in one subsample column. A CI that is suspiciously narrow at one event-time. An attribute axis on a GAN grid where the high-attribute tail looks identical to the middle. An SAE heatmap with one outlier feature firing on a token that shouldn't matter. A bar in a conjoint that is 3x the others with no comment.

Protocol: enumerate every visible feature *before* interpreting any. For each, list mundane generators first (rounding, sample restriction, axis range, color-mapping artifact, a `coord_cartesian()` clip, a single influential observation) and only then substantive ones. Name the single hardest feature to explain under the user's preferred reading.

### 2. Convenient Absence — invisible vice

The dog that did not bark. Pre-trends not plotted. A placebo period missing from the event-study. CI not shown on one panel. A subgroup examined elsewhere in the paper but not on this figure. Sample size changing across columns with no `N=` row. The control mean missing from a treatment-effect plot, so the reader cannot judge magnitude.

Protocol: ask what a hostile MKSCI / JMR referee demands to see *on this exact figure* — falsification panel, pre-treatment leads, placebo outcome, alternative bandwidth, control mean, balance test, robust SEs. Name what is missing.

### 3. Unasked Question — invisible virtue

A pattern in the figure that hints at a more interesting finding than the one being claimed. Heterogeneity richer than the average effect (one subgroup carrying everything). A non-monotonicity that the linear-summary obscures. A second mode in a distribution that suggests a mixture. A mechanism visible in the spatial layout of an SAE heatmap that the text does not name. A predicted-engagement curve with a kink at a meaningful threshold.

Protocol: is there a paper inside this paper? Would showing the heterogeneity panel separately upgrade the contribution? Does the figure suggest a moderator the design did not pre-specify?

### 4. Unexploited Strength — visible virtue

The figure is doing more work than the paper claims. Natural variation the design exploits but the prose undersells. A clean discontinuity that would survive a placebo. A pre-trend so flat it would crush a parallel-trends objection in one panel — but is currently buried. An identification argument stronger than the text allows itself to say. A GAN-grid axis that is unusually clean and could anchor a stronger causal claim about the manipulated attribute.

Protocol: is the figure the strongest version of itself? Could one annotation (a horizontal reference line, a callout for the control mean, a shaded pre-period) turn this from supporting evidence into the headline figure?

## Workflow

1. Resolve `$0`. If it's `path:label`, locate the `\label{label}` in the `.tex` and pull the surrounding `\begin{figure}` / `\begin{table}` block + caption. If it `\includegraphics`'s a file, read that file too.
2. Read the figure (image or code). If raster/PDF, use Read for the actual visual content. If TikZ/pgfplots/tabular, read as text and reason structurally from the code.
3. For each quadrant, generate 2-4 short bullets. No padding. If a quadrant has nothing real to say, write one bullet noting that and move on — do not invent vices to fill space.
4. Verdict ruling: **CLEAR** / **CONDITIONAL** / **HOLD**.

## Output report shape

Print a single Markdown block, no preamble:

```
# Blindspot — <figure id or path>

**Reading under audit:** <1-sentence paraphrase of the user's claimed interpretation, or "(none provided)">

## (1) Unexplained Feature
- <bullet> — FLAG | DONE
- <bullet> — FLAG | DONE

## (2) Convenient Absence
- <bullet> — FLAG | DONE

## (3) Unasked Question
- <bullet>

## (4) Unexploited Strength
- <bullet>

## Verdict: CLEAR | CONDITIONAL | HOLD
<one sentence on what to do before writing prose around this figure>
```

Rules:
- 2-4 bullets per quadrant, each one short and concrete. Reference axis values, panel labels, column numbers, event-time indices — not vague gestures.
- Vices get **FLAG** (open) or **DONE** (resolved by reading the caption / surrounding code). Virtues do not need a status — they are opportunities.
- **CLEAR**: no vices, virtues noted. Proceed to prose.
- **CONDITIONAL**: vices flagged but manageable — proceed with explicit acknowledgement in the text or a footnote.
- **HOLD**: at least one vice that, if a referee surfaces it first, would re-frame the figure. Do not write prose until resolved.

## Voice constraints

Hedged, modest, no padding. No "Overall, this is a strong figure." No emojis. Use `\Cref{}`-style references when pointing at panels (panel (b), column 3, event-time t=2). When naming a substantive cause, prefer the mundane generator first: rounding, sample mask, clip, single influential obs.

## Relation to other skills

- `/seven-pass-review` — manuscript-level adversarial review across seven lenses. Run after the draft around this figure is written. **Do not route here when the user asks for a paper-level review.**
- `/audit-reproducibility` — verifies the *numbers* in the figure match the script that produced them. `/blindspot` does not check numbers; it checks perception.
- `/review-paper-code` — audits the analysis script that built the figure. Complement, not substitute.
- `/draft`, `/referee-response` — natural next steps once a blindspot verdict is CLEAR or CONDITIONAL.

## Origin

Ported from Scott Cunningham's MixtapeTools (`scunning1975/MixtapeTools`, `skills/blindspot/`), which was itself prompted by Jason Fletcher's "Owning All the Numbers" framing and Viktor Shklovsky's *Art as Device* (1917). Adapted here for quantitative-marketing figures — coefficient plots, DiD event-studies, conjoint utilities, predicted-engagement curves, GAN attribute axes, SAE feature heatmaps, time-series plots.
