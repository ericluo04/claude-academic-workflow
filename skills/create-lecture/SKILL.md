---
name: create-lecture
description: Scaffold a new Beamer lecture or research-talk `.tex` from source papers, notes, or a prior deck — with notation consistency against the project preamble and the user's bold-math conventions wired in. Use when user says "create a lecture on X", "new lecture from these papers", "scaffold a Beamer deck", "build me a research talk on Y", "start a seminar deck", "MBA lecture on Z". Supports two modes: research-talk (MKSCI / JMR / JCR / MS seminars) and pedagogical-lecture (MBA Quant Marketing / Marketing Analytics).
argument-hint: "[Topic name] [--mode=research|teaching] [--triage]"
allowed-tools: ["Read", "Grep", "Glob", "Write", "Edit", "Bash", "Task"]
context: fork
---

# Lecture / Talk Creation Workflow

> **Source.** Base skill adapted from [`pedrohcgs/claude-code-my-workflow`](https://github.com/pedrohcgs/claude-code-my-workflow). The Beamer-pedagogy workflow phases (intake → paper analysis → structure proposal → draft slides → polish), the notation-consistency check against the project preamble, and the dual research-talk / pedagogical-lecture mode split are Pedro H.C. Sant'Anna's. The opt-in `--triage` Step-0 gate (audience + closing-claim pre-write check) is adapted from Scott Cunningham's [`MixtapeTools:beautiful_deck`](https://github.com/scunning1975/MixtapeTools).

## Personalization

This skill resolves placeholders against `~/.claude/state/personal_config.json`. See `_config/README.md` and `_config/personal_config.example.json` for setup. If the config is missing or a needed field is unset, the skill must surface an error to the user and refuse to proceed rather than guess.

Required config fields:
- `personal_config.paths.overleaf_root` — root containing project subdirs.
- `personal_config.projects[]` — each entry should declare `overleaf_subdir` and optional `preamble_tex` / `bib_file`.

## Purpose

Create a beautiful, pedagogically clean Beamer deck — either a research talk for a seminar or a teaching lecture for MBAs.

**This is a collaborative, iterative process. The user drives the vision; Claude is a thinking partner.**

---

## MODE SELECTION

Parse `--mode` from `$ARGUMENTS`. If absent, infer from context:

- **research mode** — invited seminar, conference talk, job-talk style, JMR/MKSCI submission talk. Audience: peer faculty + PhD students. Tone: assumes domain priors, dense with results, citation-heavy, single running empirical thread.
- **teaching mode** — MBA Quant Marketing or Marketing Analytics lecture. Audience: MBAs with limited stats background. Tone: motivation-first, every formal definition gets a worked example within 2 slides, embedded Socratic questions, 2-3 fragment reveals per deck.

Both modes share the constraints below. Differences are flagged inline as **[research]** / **[teaching]**.

---

## Modes

- **Default (no flag).** Mode inferred from path/keywords as described above; scaffold proceeds straight into Phase 0. Behavior unchanged from prior versions of this skill.
- **`--triage` (opt-in).** Before any `.tex` is written, run the Pre-Write Triage gate below. Three questions, asked once, then the skill returns to its normal flow. Discipline, not bureaucracy — the gate exists because a deck whose closing claim isn't yet a single sentence will burn an hour of slide-shuffling later.

### Pre-Write Triage (only when `--triage` is passed)

Ask the user, in order:

1. **Audience** — pick one: peer researchers (econometric / methodological) / MBA students (applied / decision-relevant) / mixed academic-practitioner / brownbag / dissertation committee.
2. **Single-sentence closing claim** — "After this talk/lecture, the audience should leave knowing _____." One sentence. Not a bullet list.
3. **Mode confirmation** — research-talk vs. pedagogical-lecture. Overrides the inferred mode if the user picks the other one.

If the user cannot articulate the closing claim in one sentence, refuse to scaffold and surface verbatim: **"State the closing claim in one sentence first; the deck structure depends on it."** Do not proceed to Phase 0 until the sentence exists.

Record the three answers and carry them into the Pre-Flight Report (audience → "Audience & narrative position"; closing claim → "Pedagogical goal"; mode → "Mode").

---

## CONSTRAINTS (Non-Negotiable)

1. **Read the project preamble FIRST** — the user's bold-math macros (e.g. `\bphi`, `\bomega`, `\bz`, `\bw`, `\bs`), citation style (natbib-apa: `\citep`, `\citealt`, `\citet`), and cross-ref macro (`\Cref`) all live in `preamble.tex`.
2. Every new symbol MUST be checked against the preamble's notation conventions — flag conflicts before drafting.
3. Motivation before formalism — no exceptions, both modes.
4. **[teaching]** Worked example within 2 slides of every definition.
5. **[research]** A running empirical application (one of the user's own projects, or the topic's canonical example) threaded throughout.
6. Max 2 colored boxes per slide.
7. No `\pause` or overlay commands unless the user explicitly asks — they hurt PDF export and Beamer→Overleaf diff readability.
8. Transition slides at major conceptual pivots.
9. All citations verified against the project's `.bib` file; use `\citep`/`\citet` per natbib-apa.
10. **Work in batches of 5-10 slides** — share for feedback, don't bulk-dump.

---

## WORKFLOW

### Phase 0: Intake & Context (Pre-Flight Report required)

Read the inputs, then produce a Pre-Flight Report before Phase 1.

Inputs to read:

- Project `preamble.tex` (look under `<OVERLEAF_ROOT>/<PROJECT_SUBDIR>/` or a sibling folder).
- Project `.bib` file(s) so citation keys can be verified.
- Any source papers / existing slides the user provided.
- A prior deck's `.tex` if this is a follow-on lecture.

Required Pre-Flight Report block:

```markdown
## Pre-Flight Report

**Mode:** [research / teaching]

**Sources read:**
- [source 1]: [one-line takeaway — what notation, what result, what figure]
- [source 2]: ...

**Preamble check:**
- Preamble path: [path]
- Existing bold-math macros available: [list from preamble]
- New symbols this deck will introduce: [list]
- Conflicts with preamble: [none / specific clashes]

**Citation check:**
- `.bib` path: [path]
- Citation keys to be used: [list]
- Missing from .bib: [none / list — user must add via `/cite` skill]

**Audience & narrative position:**
- [research] Venue + audience priors. What's the one-slide takeaway?
- [teaching] Where does this lecture sit in the course arc? What did the previous lecture end on?

**Pedagogical goal:** [one sentence]

**Running application:** [which real-world example threads through this deck]
```

State the goal, get the user's confirmation, then proceed.

**Fresh-project fallback.** If no preamble exists yet (brand-new Overleaf project), propose a minimal starter preamble with the user's standard macros and natbib-apa citation setup. Present for approval, write it, then continue to Phase 1.

### Phase 1: Source Analysis (When Papers Provided)

- Split each paper into chunks; extract key ideas, results, notation.
- Map paper notation → the user's project notation.
- Identify slide-worthy content (theorems, key plots, summary tables).
- Present summary for approval.

### Phase 2: Structure Proposal

- Propose outline.
  - **[research]** 5-Act: Motivation → Setting → Identification/Method → Results → Implications.
  - **[teaching]** 3-Part: Why-this-matters → Core idea (build incrementally) → Apply-it (worked example + small exercise).
- List TikZ diagrams and figures needed.
- List new notation to introduce, mapped to preamble macros.
- **GATE: User approves before Phase 3.**

### Phase 3: Draft Slides (Iterative)

- Work in batches of 5-10 slides.
- Check every new symbol against the preamble; use existing bold-math macros rather than re-defining bolds.
- Use `\citep{}` for parenthetical, `\citet{}` for in-line, `\citealt{}` for "see also" lists.
- Use `\Cref{...}` for all internal cross-refs.
- Apply mode-specific patterns:
  - **[teaching]** Embed 2-3 Socratic prompts; use 3-5 fragment reveals at problem→solution moments; pair every definition with a worked example.
  - **[research]** Lead each section with a one-sentence claim; keep one running empirical thread; budget ~1 slide per minute of talk.

### Phase 4: Figures & Code

- R or Python scripts following the user's project conventions (no Stata).
- TikZ diagrams inline in the Beamer source so the deck stays self-contained.
- Save plot data (RDS / parquet) alongside scripts for reproducibility.

### Phase 5: Polish & Compile

- Compile via `latexmk -pdf <deck>.tex` from the Overleaf project root.
- Run `/slide-excellence` for the full multi-agent pass.
- If any TikZ blocks exist, expect `tikz-reviewer` to flag label-overlap issues — iterate until APPROVED.

---

## Post-Creation Checklist

```
[ ] Deck compiles without errors via latexmk
[ ] No overfull hbox > 10pt
[ ] All citations resolve against the project .bib
[ ] [teaching] Every definition has motivation + worked example
[ ] [research] Running empirical thread is visible across sections
[ ] Max 2 colored boxes per slide
[ ] [teaching] 2-3 Socratic questions embedded
[ ] Transition slides between sections
[ ] At least 1 running application threaded throughout
[ ] New notation does not collide with preamble macros
[ ] /slide-excellence run; critical issues addressed
```

## Failure modes

- **Preamble not found.** Don't invent bold-math macros from scratch — ask the user to point to the project's preamble, or scaffold a fresh one as in Phase 0 fallback.
- **Citation key invented.** Never fabricate a `.bib` key. If a citation is missing, list it under "Missing from .bib" in the Pre-Flight Report and have the user run `/cite` first.
- **Stata / SAS code suggested.** Never. This skill targets R + Python only.
- **Mode mismatch.** A research talk with MBA-style "let's think about why this matters" framing will feel patronizing to a JMR audience; an MBA lecture with proof-density will lose the room. If the mode inference is uncertain, ASK before drafting.

## Out of scope

- Compiling for the user — the user compiles in Overleaf; this skill only suggests the `latexmk` command for local previews.
- Editing PowerPoint or Google Slides — Beamer only.
- Generating Quarto-flavored slides.
- Reviewing an existing deck (use `/slide-excellence` for that).
