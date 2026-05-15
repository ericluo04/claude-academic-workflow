---
name: seven-pass-review
description: Run a seven-pass adversarial review of an academic manuscript by spawning 7 parallel review subagents (abstract, intro, methods, results, robustness, prose, citations) and synthesizing their findings into a prioritized revision checklist with 80 / 90 / 95 quality thresholds. Use when the user says "seven pass review", "seven-pass review my draft", "full adversarial review", "deep review my paper", or before submitting / resubmitting to Marketing Science, JMR, JCR, Management Science, or a comparable econ / finance journal. Higher-cost, higher-coverage than /review-paper or /review-paper-light.
argument-hint: "[manuscript path] [--journal MKSCI|JMR|JCR|MS|QJE|AER|JF|RFS|Econometrica]"
allowed-tools: ["Read", "Grep", "Glob", "Write", "Bash", "Task"]
effort: high
---

# Seven-Pass Adversarial Review

> **Source.** This skill is adapted from [`pedrohcgs/claude-code-my-workflow`](https://github.com/pedrohcgs/claude-code-my-workflow). The seven-lens taxonomy (Abstract / Intro / Methods / Results / Robustness / Prose / Citations), the parallel-subagent-then-synthesizer topology, and the 80 / 90 / 95 quality-threshold scoring are Pedro H.C. Sant'Anna's; this fork tunes the journal targets to marketing (MKSCI / JMR / JCR / MS) alongside the econ / finance ones.

Spawns seven independent reviewers, each focused on a single lens, then synthesizes their findings into one prioritized revision plan.

**Why seven passes?** A single-agent review blends lenses and softens each one. Seven forked subagents each approach the paper with full context for their own lens, then a synthesizer resolves conflicts, deduplicates issues, and scores the manuscript against quality thresholds (80 / 90 / 95).

> **When to pick this over `/review-paper` or `/review-paper-light`:** This skill costs roughly 7x more tokens than `/review-paper-light` and ~3x more than `/review-paper`. Use it when the paper is submission-ready, R&R-stage, or about to go to a top marketing or econ journal. For early drafts and iterative work, the lighter reviews are the right tool.

## Inputs

- `$0` — manuscript path (`.tex`, `.qmd`, `.Rmd`, `.md`, or `.pdf`). Required. Manuscripts typically live under `<OVERLEAF_ROOT>/<PROJECT_SUBDIR>/`.
- `--journal` — optional target journal. Adjusts severity calibration and the bar for the Executive verdict. Supported: Marketing Science (MKSCI, default), JMR, JCR, Management Science (MS), QJE, AER, ReStud, Econometrica, JF, JFE, RFS. Defaults to MKSCI if not specified.

## The Seven Lenses

Each lens runs as a forked subagent (context: fork) so the main conversation stays clean.

| # | Lens | Focus | Agent type |
|---|---|---|---|
| 1 | Abstract audit | Does the abstract state question, method, result, and contribution in marketing-appropriate, hedged language? Does it match the body? | general-purpose |
| 2 | Intro structure | Does the intro follow the marketing-paper structure (hook, motivating phenomenon, research questions, approach, contribution, roadmap)? Three-stream lit review placed correctly? | general-purpose |
| 3 | Methods / identification | Are identification assumptions stated and credible? Are obvious threats (selection, endogeneity, measurement, SUTVA) addressed? For ML / GenAI methods, is the train/test/holdout discipline clear? | domain-reviewer |
| 4 | Results + tables | Do tables and figures read standalone? Are magnitudes interpreted in managerially meaningful units (not just stars)? Are units consistent? Are SEs / clustering specified? | general-purpose |
| 5 | Robustness | Does the paper anticipate a sharp referee's objections? Are robustness checks motivated or theatrical? Power / placebo / heterogeneity? For obs studies, alternative identification? | general-purpose |
| 6 | Prose quality | Sentence-level clarity, modest hedging proportionate to evidence, active voice, paragraph topic sentences. Marketing voice — not econ-aggressive, not psychology-bombastic. | proofreader |
| 7 | Citation audit | For top-15 cited works, does the in-text claim match the cited paper's actual finding direction? Are contemporary / competing works cited? Marketing canon (e.g., relevant MKSCI / JMR pieces) represented? | general-purpose |

## Workflow

### Phase 0: Pre-flight

1. Resolve manuscript path. If a `.pdf`, extract text first via `pdftotext -layout` (or fall back to reading the `.tex` source under the same project root).
2. Read the manuscript once in the main agent so the synthesizer has a shared mental model.
3. Resolve `--journal`. Default to MKSCI. Set lens-5 and lens-3 severity thresholds based on the target (top-five econ journals get tighter identification expectations; MKSCI / JMR / JCR / MS get tighter managerial-relevance and substantive-contribution expectations).
4. Create output directory: `<project>/seven_pass_<YYYYMMDD>/` for lens reports.

### Phase 1: Spawn 7 reviewers in parallel

In a single message, spawn 7 `Task` tool calls (one per lens). Each subagent gets:

- The manuscript path (to re-read with its own fresh context).
- The lens-specific prompt (rubric summarised below).
- The target journal so it can calibrate severity.
- Instructions to write to `<project>/seven_pass_<YYYYMMDD>/lens_<N>_<lens-name>.md`.
- Severity tagging: CRITICAL / MAJOR / MINOR.

Lens prompt summaries (each forked subagent receives its lens's rubric plus the manuscript path and target journal):

- **Lens 1 (Abstract):** Does the first sentence state the question? Does it name the method? Quantify the headline result? State a one-sentence contribution? Do these four things match the body and the table of magnitudes? Marketing abstracts should foreground the managerial / substantive insight, not just the technical contribution.
- **Lens 2 (Intro):** Does the intro open with a motivating phenomenon (the marketing-paper standard pattern), then research questions, then approach, then numbered contributions, then roadmap? Is the three-stream lit review placed after the hook (not before)? Are findings previewed with magnitudes?
- **Lens 3 (Methods / identification):** Is every identification assumption stated and defended? Are known violations (selection, omitted variables, reverse causality, measurement error, SUTVA) addressed? For deep-learning / GenAI components (GAN-based features, sparse autoencoders, vision embeddings), are training-set leakage, holdout discipline, and external validity discussed? Is the unit of analysis vs. unit of randomisation / treatment consistent?
- **Lens 4 (Results):** Does each table read standalone (caption, units, SEs / CIs clarified, clustering documented)? Are magnitudes interpreted in interpretable units (dollars, percentage points, elasticities, lift)? Are units consistent across tables? Are figures legible at 9pt and color-blind safe?
- **Lens 5 (Robustness):** Does the paper ANTICIPATE the sharp referee's objections (the AE for the target journal)? Are robustness checks motivated, or just listed? For experiments: power, manipulation checks, attention checks. For obs work: placebo, alternative samples, alternative DVs. For text / image ML: alternative embeddings or feature extractors.
- **Lens 6 (Prose):** Sentences under 30 words on average? Active voice dominant? Hedging proportionate (neither overclaiming nor endless "may suggest")? Paragraph topic sentences? Marketing voice — modest, evidence-anchored, no econ swagger, no psych breathlessness.
- **Lens 7 (Citations):** For top-15 cited works, does the in-text claim match the cited paper's actual finding direction? Are 2024–2026 contemporaries cited (in vision-ML / GenAI-marketing, two-year-old citations are a red flag)? Are the marketing canon AND the relevant CS / methods canon both represented?

### Phase 2: Synthesize

Wait for all 7 lens reports. Read them and produce `<project>/seven_pass_<YYYYMMDD>.md`:

```markdown
# Seven-Pass Review: <Manuscript>

**Date:** YYYY-MM-DD
**Path:** <manuscript>
**Target journal:** <MKSCI / JMR / JCR / MS / QJE / ...>

## Executive verdict

**Quality score:** <NN>/100
**Threshold reached:** <80 desk-survives / 90 R&R-likely / 95 conditional-accept range>
**Overall state:** <SUBMIT / REVISE-MINOR / REVISE-MAJOR / REJECT-AND-RESTART>

Quality threshold key:
- **>=95** Conditional-accept range at the target journal (rare).
- **>=90** Likely R&R with revisable issues.
- **>=80** Desk-survives but needs substantive work before submission.
- **<80** Not yet submission-ready.

## Cross-lens CRITICAL issues
| # | Lens(es) | Issue | Recommendation |
|---|---|---|---|

## MAJOR issues (second-round)
| # | Lens(es) | Issue |
|---|---|---|

## MINOR polish
[bulleted]

## Per-lens scorecard
| Lens | Critical | Major | Minor | Score/10 |
|---|---|---|---|---|
| 1. Abstract | | | | |
| 2. Intro | | | | |
| 3. Methods | | | | |
| 4. Results | | | | |
| 5. Robustness | | | | |
| 6. Prose | | | | |
| 7. Citations | | | | |
| **Overall** | | | | |

## Revision plan (in recommended order)
1. <Highest-leverage fix — usually a lens with 2+ CRITICALs>
2. ...
7. <Lowest-leverage polish>

## Contradictions between lenses
[If two lenses disagree, surface here. E.g., Lens 2 says "expand contribution framing" but Lens 6 says "trim intro by 15%". Recommend a reconciliation.]
```

The synthesizer must convert the seven lens-level severity counts into the overall quality score:

- Start at 100.
- Subtract 8 per CRITICAL, 3 per MAJOR, 1 per MINOR.
- Floor at 40 (below that, the paper is REJECT-AND-RESTART regardless of arithmetic).

### Phase 3: Token-budget report

After synthesis, print:

```
Seven-pass review complete.
Subagents: 7 (parallel) + 1 synthesizer.
Approx token usage: ~80-120k (vs ~10-15k for /review-paper-light, ~25-35k for /review-paper).
Runtime: ~3-5 min wall-clock.
For cheaper alternatives:
  - 2-agent fast pass: /review-paper-light
  - 6-agent journal-targeted referee report: /review-paper
```

## When to use this skill

- **Before first submission** to MKSCI / JMR / JCR / MS / QJE / AER / RFS / JF.
- **After a major revision** when drift is likely (e.g., R1 -> R2 turnaround).
- **R&R when referees disagree** — surfaces contradictions the revision must navigate.
- **Job-market-paper polish** where every lens matters.

## When NOT to use

- Very early drafts (use `/review-paper-light` for a fast contribution / identification gut-check).
- Short notes, comments, replies (overkill).
- Already-reviewed papers where nothing substantive changed since the last seven-pass run.

## Failure modes

- **Manuscript unreadable or empty.** `.pdf` text extraction failed; `.tex` has unresolved `\input{}`s. Fall back to the most recent `.tex` source under the project root; if still empty, abort and surface a clear error.
- **Subagent timeout or empty lens report.** Re-spawn just the affected lens once; if it fails again, mark that lens as "DEGRADED" in the synthesis and continue. Do not block the report on one lens.
- **Lens 7 cannot resolve citations.** If the `.bib` is missing or `/validate-bib` / Zotero MCP is unavailable, scope Lens 7 to in-text-claim spot checks only and flag in the synthesis.
- **Project root not under Overleaf path.** Skill writes lens reports next to the manuscript path the user provided; if that directory is read-only, fall back to `~/.claude/cache/seven_pass_<stem>_<date>/` and surface the path.
- **No journal specified and project ambiguous.** Default to MKSCI; surface this in the report header so the user can re-run with `--journal JMR` if they want a different calibration.

## Out of scope

- **Auto-applying fixes.** This skill produces a checklist; it does not edit the manuscript. For surgical edits, use `/draft` or a manual rewrite pass.
- **Numeric reproducibility.** That is `/audit-reproducibility`. Lens 4 only flags qualitative inconsistencies (e.g., "Table 3 caption says percentage points but the text reads as proportions").
- **Replication-package audit.** Use `/review-paper-code` for that.
- **Human judgment.** A trusted senior reviewer who knows the subfield still beats seven LLMs. Treat this as triage.

## Cross-references

- `/review-paper` — six-agent journal-targeted referee report (cheaper, faster).
- `/review-paper-light` — two-agent fast contribution / identification check (cheapest).
- `/review-paper-code` — code + paper reproducibility audit.
- `/audit-reproducibility` — numeric-claim-by-claim verification.
- `/review-pap` — preregistration-stage analogue.
