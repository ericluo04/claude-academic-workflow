---
name: tikz-iterate
description: Iteratively refine a TikZ diagram by compiling it, rendering to PNG, asking the tikz-reviewer sub-agent to evaluate, and applying fixes until APPROVED (or 5 iterations elapse). Designed for Beamer / standalone TikZ snippets in academic papers and lecture decks. Use when the user says "/tikz-iterate", "polish this tikz", "iterate on this diagram until it looks right", "make this figure not look terrible", "compile and review this tikz", or pastes a TikZ block with "fix it visually". Distinct from /slide-excellence (which reviews a whole deck) and the standalone tikz-reviewer agent (which reviews once); /tikz-iterate is the orchestration loop that drives multiple compile/render/refine rounds. Cross-platform — uses latexmk + pdftoppm from MiKTeX (Windows), MacTeX (macOS), or TeX Live (Linux).
argument-hint: "[path-to-tikz-file-or-snippet] [--goal=\"text describing what you want\"] [--max-iter=5] [--output=path]"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash", "Task"]
effort: medium
---

# /tikz-iterate

Compile a TikZ snippet, render the PDF to a PNG, ask the `tikz-reviewer` sub-agent to judge it, apply the returned fixes, and repeat until the reviewer says `APPROVED` or the iteration cap (default 5) is reached. The skill orchestrates the loop; the sub-agent does the visual judgment.

## Credit

Concept inspired by Scott Cunningham's `/tikz` 3-pass collision audit in [scunning1975/MixtapeTools](https://github.com/scunning1975/MixtapeTools). This skill extends the idea into a multi-round refine loop driven by the [`tikz-reviewer`](../../agents/tikz-reviewer.md) sub-agent.

## When to invoke

Trigger on any of:

- `/tikz-iterate`
- "polish this tikz"
- "iterate on this diagram until it looks right"
- "make this figure not look terrible"
- "compile and review this tikz"
- a pasted TikZ block plus "fix it visually" / "clean this up"

Do **not** invoke for:

- Whole-deck audits — use `/slide-excellence`.
- One-shot visual critique with no auto-fix — call the `tikz-reviewer` sub-agent directly.

## Inputs

| Argument | Type | Default | Meaning |
|---|---|---|---|
| positional `path-or-snippet` | string | required | A `.tex`/`.tikz` file path, or an inline TikZ block. If the input is not a complete document, the skill wraps it. |
| `--goal="..."` | string | empty | Free-text description of what the diagram should communicate (passed to the reviewer). |
| `--max-iter=N` | int | 5 | Hard cap on compile/review rounds. |
| `--output=path` | string | `<scratch>/final.tex` | Where to write the approved `.tex`. |

## Cross-platform requirements

The skill needs two binaries on `PATH`:

- `latexmk` — bundled with MiKTeX (Windows), MacTeX (macOS), and TeX Live (Linux).
- `pdftoppm` — ships with the Poppler bundle included in MiKTeX, MacTeX (via the `poppler` Homebrew dep), and TeX Live's standard install. On Linux distros without it: `sudo apt install poppler-utils`.

If either binary is missing, surface `SETUP_MISSING:<tool>` to the caller and stop. See `docs/tex-setup.md` (to be written) for per-OS install notes.

## Workflow

Use a scratch directory under `~/.claude/state/tikz-iterate/<timestamp>/` to keep `.aux`, `.log`, and `.pdf` debris isolated from the user's project tree.

### Step 1 — Read input

Resolve `path-or-snippet`: if it's a path that exists, `Read` it; otherwise treat the argument as inline TikZ source. Detect whether the input already contains `\documentclass`.

### Step 2 — Wrap if needed

If the input lacks `\documentclass`, wrap with this minimal standalone preamble:

```tex
\documentclass[tikz,border=4pt]{standalone}
\usepackage{tikz}
\usetikzlibrary{arrows.meta,positioning,calc,decorations.pathreplacing,shapes.geometric}
\usepackage{amsmath,amssymb}
\begin{document}
% --- user TikZ here ---
\end{document}
```

Write to `<scratch>/diagram.tex`.

### Step 3 — Compile

```bash
cd ~/.claude/state/tikz-iterate/<timestamp>
latexmk -pdf -interaction=nonstopmode -halt-on-error diagram.tex
```

Same command on Windows, macOS, and Linux. If exit code is non-zero, read `diagram.log`, extract the first line matching `^! ` plus the following `l.<N>` line, and surface `COMPILE_FAILED:<line>:<message>`. Abort the loop.

### Step 4 — Render

```bash
pdftoppm -r 200 diagram.pdf diagram
```

Produces `diagram-1.png` at 200 DPI. If `pdftoppm` fails or the PNG is missing, surface `RENDER_FAILED:<message>` and abort.

### Step 5 — Sub-agent review

Invoke the `tikz-reviewer` sub-agent via the `Task` tool with `subagent_type: "tikz-reviewer"` and the prompt template below. The sub-agent's `Read` tool will pick up the PNG as multimodal input.

### Step 6 — On APPROVED

Copy the current `.tex` to `--output`. Surface the PNG path. Write a one-paragraph rationale describing what changed across iterations (collect the issue list from each round's reviewer response).

### Step 7 — On fixes returned

Parse the numbered fix list. Apply each fix to `<scratch>/diagram.tex` using the `Edit` tool with **surgical** `old_string`/`new_string` replacements — do not rewrite the whole snippet. Bump iteration counter. Go to Step 3.

### Step 8 — Iteration cap

If iteration counter reaches `--max-iter` without approval, surface:

- the last rendered PNG path,
- the outstanding objections from the final review,
- the in-progress `<scratch>/diagram.tex` path.

Let the caller decide whether to merge, continue manually, or restart with a different goal.

## Sub-agent prompt template

The exact text sent to `tikz-reviewer` on each round:

```
You are reviewing a TikZ diagram for visual quality.

ITERATION: {iter} of {max_iter}

USER GOAL:
{goal_or_"(none provided — judge purely on visual quality)"}

CURRENT TIKZ SOURCE (file: {tex_path}):
```tex
{tex_contents}
```

RENDERED PNG: {png_path}
Please Read the PNG to inspect the actual rendered output.

Evaluate using your standard checks (label overlap, geometric accuracy,
visual semantics, spacing, polish). Then return EXACTLY ONE of:

(a) The single word APPROVED on its own line — if zero CRITICAL and zero
    MAJOR issues remain.

(b) A numbered list of concrete fixes, each phrased as a surgical edit
    the orchestrator can apply via search-and-replace. Example:

    1. Node "A" overlaps the arrow from (1,0) to (2,1).
       Change `\node at (1.5,0.5) {A};` to `\node at (1.5,0.9) {A};`.
    2. Missing arrowhead on the edge B->C.
       Change `\draw (B) -- (C);` to `\draw[->] (B) -- (C);`.

    Each item must name the problem AND give the exact textual replacement.
    Do NOT rewrite the whole snippet. Do NOT include explanatory prose
    outside the numbered list.
```

## Failure modes

| Symptom | Cause | Skill response |
|---|---|---|
| `latexmk` exits non-zero | LaTeX syntax error in snippet or preamble | Surface `COMPILE_FAILED:<line>:<msg>` from `.log`, abort. |
| `pdftoppm` exits non-zero or PNG absent | Poppler missing, PDF corrupt | Surface `RENDER_FAILED:<msg>`, abort. |
| Sub-agent returns neither `APPROVED` nor a parseable list | Reviewer drift | Re-prompt once with "Please respond in the required format." If second attempt also fails, abort and surface the raw response. |
| Sub-agent times out | Task tool timeout | Treat as iteration failure; surface scratch path and let caller retry. |
| Reaches `--max-iter` | Genuinely hard diagram, or oscillation between two fixes | Surface last PNG, outstanding fix list, and in-progress `.tex`. |

## Examples

### Example 1 — polish a 4-node graph

Input: a `.tikz` file with four nodes and three edges; labels overlap two arrows.

```
/tikz-iterate ~/scratch/causal-dag.tikz --goal="DAG showing X -> Y with mediator M and confounder U"
```

Iteration 1: reviewer flags label `M` overlapping the `X->Y` edge and a missing arrowhead on `U->Y`. Skill applies both surgical edits.
Iteration 2: reviewer returns `APPROVED`. Final `.tex` written to `--output`; PNG path surfaced.

### Example 2 — converge a colored coefficient plot

Input: an inline TikZ block (no `\documentclass`) drawing six coefficient estimates with CIs.

```
/tikz-iterate "<pasted tikz>" --goal="coefficient plot, CIs not touching the y-axis labels, treatment color = ForestGreen"
```

Skill wraps the snippet, compiles. Iteration 1: reviewer flags two CI whiskers crossing the y-axis tick labels and a `red` literal violating the requested `ForestGreen`. Iteration 2: minor — one label vertical-anchor inconsistency. Iteration 3: `APPROVED`. Rationale paragraph notes the three concrete shifts applied.
