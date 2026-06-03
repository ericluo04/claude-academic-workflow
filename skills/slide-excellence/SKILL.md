---
name: slide-excellence
description: Multi-agent comprehensive Beamer slide review (visual + pedagogy + proofreading, plus TikZ conditionally) for research talks and MBA teaching decks. Use when user says "full review", "excellence pass", "comprehensive check", "review everything", "pre-seminar review", "slide excellence", or before presenting / shipping a deck. Fanout wrapper that spawns slide-auditor, pedagogy-reviewer, proofreader, and (when TikZ present) tikz-reviewer.
argument-hint: "[TEX filename] [--fast]"
allowed-tools: ["Read", "Grep", "Glob", "Write", "Bash", "Task"]
context: fork
---

# Slide Excellence Review

> **Source.** Base orchestrator adapted from [`pedrohcgs/claude-code-my-workflow`](https://github.com/pedrohcgs/claude-code-my-workflow). The conditional-spawn pattern (Visual Auditor + Pedagogy Reviewer + Proofreader, plus TikZ Reviewer when TikZ is present) and the synthesis pass are Pedro H.C. Sant'Anna's. The titles-as-assertions and density-audit pedagogy lenses layered on top are adapted from Scott Cunningham's [`MixtapeTools:beautiful_deck`](https://github.com/scunning1975/MixtapeTools).

Run a comprehensive multi-dimensional review of a Beamer deck. Multiple subagents analyze the file independently, then results are synthesized.

> **Which slide-review tool do I want?**
>
> - **`/slide-excellence`** (this skill) — multi-agent fanout (visual + pedagogy + proofread, plus TikZ if present). Best for **pre-seminar** (MKSCI / JMR / JCR / MS submission talks, faculty seminars) or **pre-class** (MBA Quant Marketing / Marketing Analytics) checks.
> - For a single lens, invoke the relevant subagent directly via the `Agent` tool: `slide-auditor`, `pedagogy-reviewer`, `proofreader`, or `tikz-reviewer`.

**Important:** this orchestrator does **conditional** dispatch — it only spawns the subagents that can produce useful output for the given file. `tikz-reviewer` only runs if TikZ blocks exist.

## Step 1: Identify the File

Parse `$ARGUMENTS` for the filename. Decks usually live under `<OVERLEAF_ROOT>/<PROJECT_SUBDIR>/` — often as `slides_*.tex`, `presentation.tex`, or inside a sub-folder. If only a basename is given, use `Glob` to locate it under the Overleaf root.

Only `.tex` (Beamer) is supported. The intended workflow is Beamer + Overleaf — no Quarto, no Markdown slides.

## Step 2: Pre-flight — Detect Conditions

Before spawning any agent, probe the file with `Grep` to determine which reviews make sense.

- **TikZ blocks present?** Count `\begin{tikzpicture}` occurrences. If `> 0`, schedule `tikz-reviewer`.
- **Preamble inheritance?** Check for `\input{preamble}` or `\input{../preamble.tex}` so the pedagogy reviewer knows where the user's bold-math macros (e.g. `\bphi`, `\bomega`, `\bz`, `\bw`, `\bs`) are defined.
- **Citation style?** Confirm `\citep`, `\citealt`, `\citet` (natbib-apa) usage; flag any inline `[Author, Year]` strings the proofreader should catch.
- **Cross-ref style?** Confirm `\Cref{...}` rather than bare `\ref{...}`.

Report the detection:

```
File:         <resolved path>
Type:         Beamer (.tex)
TikZ blocks:  <N>
Preamble:     <path to preamble.tex if found, else "inline">
Bib style:    natbib-apa
```

## Step 3: Run Review Agents in Parallel

Spawn only the agents whose conditions hold. Use the `Agent` tool, one call per subagent, in a single message so they run in parallel.

**Always-on for any Beamer deck:**

- **Agent A: Visual Audit** (`slide-auditor`)
  Overflow, font consistency, box fatigue, spacing, image paths, overfull hbox risk.
  Save: `quality_reports/[FILE]_visual_audit.md`.
  Additional instruction to pass through:
  > For each frame, score visual density 1–5: count of words + a visual-complexity proxy (1 = sparse, 5 = overloaded). Report frame-by-frame density and the overall mean ± stdev.
  > Flag any slide whose density is > 2σ from the mean for split-or-merge. Tag as MINOR by default; promote to MAJOR if density ≥ 4.5 and surrounding slides ≤ 2.5.

- **Agent B: Pedagogical Review** (`pedagogy-reviewer`)
  13 pedagogical patterns, narrative arc, pacing, notation consistency vs `preamble.tex`.
  Save: `quality_reports/[FILE]_pedagogy_report.md`.
  Additional instruction to pass through:
  > Extract every `\frametitle{...}` and every `\title{...}` in sequence. Output the title-only storyline as a numbered list. For each title, classify as:
  > - **Assertion** — makes a claim ("Treatment increased K/L by 18%")
  > - **Label** — names a section ("Results", "Methodology", "Literature")
  >
  > Flag every label-title as a CRITICAL pedagogy issue UNLESS the slide is a section divider (`Recap`, `Setup`, `Roadmap`, `Q&A`, or the deck opens / closes a major section). The argument should be followable from titles alone.

- **Agent C: Proofreading** (`proofreader`)
  Grammar, typos, overflow, citation-key consistency, `\Cref` usage, terminology.
  Save: `quality_reports/[FILE]_proofread_report.md`.

**Conditional:**

- **Agent D: TikZ Review** (`tikz-reviewer`) — only if `has_tikz > 0`.
  Label position, overlap, geometric accuracy, visual semantics. Iterate until APPROVED.
  Save: `quality_reports/[FILE]_tikz_review.md`.

**De-duplication:** if the user has already invoked one of these subagents on this file in the current session, ask whether to reuse the existing report or re-run. Default: reuse (saves tokens).

## Step 4: Synthesize Combined Summary

Only include sections for agents that actually ran.

```markdown
# Slide Excellence Review: [Filename]

**File:** [path]
**Type:** Beamer (.tex)
**Detected:** TikZ=N | bib=natbib-apa
**Agents spawned:** [A, B, C, D] (skipped: D [no TikZ])

## Overall Quality Score: [EXCELLENT / GOOD / NEEDS WORK / POOR]

| Dimension       | Critical | Medium | Low |
|-----------------|----------|--------|-----|
| Visual/Layout   |          |        |     |
| Pedagogical     |          |        |     |
| Proofreading    |          |        |     |
| TikZ (if ran)   |          |        |     |

### Critical Issues (Immediate Action Required)
### Medium Issues (Next Revision)
### Recommended Next Steps
```

## Step 5: Optional Recompile

If the deck has open issues that are LaTeX-level (e.g., undefined refs flagged by the proofreader), suggest the user run `latexmk -pdf <file>.tex` from the Overleaf project root. Do not auto-compile unless the user asks — Overleaf is the source of truth.

## Step 6: Report Token Budget

```
Spawned N agents; approx token usage ~XXk. For a single-lens review,
invoke the subagent directly via the Agent tool (slide-auditor /
pedagogy-reviewer / proofreader / tikz-reviewer).
```

## Quality Score Rubric

| Score      | Critical | Medium | Meaning              |
|------------|----------|--------|----------------------|
| Excellent  | 0-2      | 0-5    | Ready to present     |
| Good       | 3-5      | 6-15   | Minor refinements    |
| Needs Work | 6-10     | 16-30  | Significant revision |
| Poor       | 11+      | 31+    | Major restructuring  |

## Flag Reference

| Flag     | Effect                                                                                       |
|----------|----------------------------------------------------------------------------------------------|
| `--fast` | Spawn a single synthesis pass reading the file directly, rather than parallel subagents. Cheaper (~8k vs ~50k tokens) but less thorough. |

## Failure modes

- **File not found.** If `$ARGUMENTS` resolves to nothing under the Overleaf root, ask the user to pass an absolute path rather than guessing.
- **Subagent missing.** If one of `slide-auditor`, `pedagogy-reviewer`, `proofreader`, or `tikz-reviewer` isn't installed at `~/.claude/agents/`, report which is missing and run the rest; don't silently skip everything.
- **Preamble not found.** If the deck `\input`s a preamble that resolves to nothing, the pedagogy reviewer will under-report notation conflicts. Warn the user and continue.
- **No TikZ but `tikz-reviewer` requested.** Tell the user the conditional gate skipped it; offer to run anyway with the `Agent` tool directly.

## Out of scope

- Quarto, RevealJS, PowerPoint, Markdown slides — Beamer only.
- Compiling the deck — use `/compile-latex` (or `latexmk` directly).
- Substance / domain review of econometric or methodological claims — that's the job of `/review-paper` or `/review-pap`.
- Editing the file. This skill only produces reports; the user applies the fixes.
