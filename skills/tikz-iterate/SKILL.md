---
name: tikz-iterate
description: Compile a TikZ diagram, rasterize it to PNG with ghostscript, have the tikz-reviewer subagent actually look at the image, apply the surgical fixes it returns, and repeat until APPROVED or 5 rounds elapse. TRIGGER when asked to polish, fix, debug, or iterate on a TikZ figure, a Beamer diagram, a .tikz or .tex snippet, or a DiD / parallel-trends / event-study / DAG / coefficient-plot figure whose labels overlap or that "looks wrong", and on "compile and review this tikz". macOS toolchain: latexmk from MacTeX plus gs.
argument-hint: "[file-or-snippet] [--goal=\"what it should communicate\"] [--max-iter=5] [--output=path]"
---

# tikz-iterate

Compile the diagram, render the PDF to PNG, hand the PNG to the `tikz-reviewer` subagent, apply the
numbered edits it returns, repeat until it answers `APPROVED` or the cap is hit. This file runs the
loop. The subagent does the visual judgment, and it judges from pixels, never from reading source.

For a single critique with no auto-fix, call `tikz-reviewer` directly. Loop concept borrowed from Scott
Cunningham's `/tikz` collision audit in [MixtapeTools](https://github.com/scunning1975/MixtapeTools).

## Inputs

| Argument | Default | Meaning |
|---|---|---|
| positional | required | A `.tex`/`.tikz` path, an inline TikZ block, or an Overleaf project name. |
| `--goal="..."` | none | What the diagram should communicate. Passed to the reviewer verbatim. |
| `--max-iter=N` | 5 | Hard cap on rounds. |
| `--output=path` | `$RUN/final.tex` | Where the approved `.tex` lands. |

If the positional is neither an existing path nor TikZ source, treat it as an Overleaf project name:
list `$HOME/Library/CloudStorage/Dropbox*/Apps/Overleaf/*/`, match, then `Glob` for `*.tex`/`*.tikz` inside and ask which file
if several match. No config file is needed or consulted for this.

## Setup

```bash
export PATH="/Library/TeX/texbin:$HOME/.local/bin:$PATH"
RUN="$HOME/.claude/state/tikz-iterate/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RUN/iter-01"   # and "$RUN/iter-NN" at the top of every later round
```

Preflight `latexmk` and `gs`; if either is missing, surface `SETUP_MISSING:<tool>` and stop before doing
any work. Homebrew is not installed on this machine, so there is no `pdftoppm` and no `pdftotext`; do
not reach for them. If a `.sty` is missing from the local TeX tree, `tectonic` will fetch it
(`tectonic -X compile diagram.tex --outdir <dir>`, where the outdir must already exist).

Each round builds in `$RUN/iter-NN/`, so nothing is clobbered and the history stays inspectable if the
loop stalls. That also keeps `.aux` churn out of the user's project tree and out of Dropbox sync.

## The loop

### 1. Read and wrap

If the input lacks `\documentclass` it is a bare snippet, so wrap it and let `standalone` crop the PDF
to the drawing:

```tex
\documentclass[tikz,border=4pt]{standalone}
\usepackage{tikz}
\usetikzlibrary{arrows.meta,positioning,calc,decorations.pathreplacing,shapes.geometric}
\usepackage{amsmath,amssymb}
\begin{document}
% --- user TikZ here ---
\end{document}
```

A full document (Beamer frame, paper) compiles as-is; review only the page carrying the figure. Record
which case this is, since it sets the render DPI. Write to `$RUN/iter-01/diagram.tex`.

### 2. Compile

```bash
cd "$RUN/iter-NN" && latexmk -pdf -interaction=nonstopmode -halt-on-error diagram.tex
```

If the source must stay in place (a figure that `\input`s a shared preamble), compile there and divert
the build with `-outdir="$RUN/iter-NN"`. On non-zero exit, extract the error, then surface
`COMPILE_FAILED:<line>:<message>` and abort. Never render a stale PDF from the previous round.

```bash
grep -A2 '^! ' diagram.log | head -3
```

The `l.<N>` line follows the bang line. Do not add `-m1`: BSD grep stops reading at the match and drops
the trailing context, so you get the message with no line number.

### 3. Render

```bash
gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=png16m -r200 \
   -dTextAlphaBits=4 -dGraphicsAlphaBits=4 \
   -sOutputFile=page-%d.png diagram.pdf
```

The `%d` writes one PNG per page. The alpha-bits flags are anti-aliasing; without them thin rules and
small type alias badly and the reviewer reports artifacts as real defects.

Pick DPI from the canvas. `-r200` suits a full page (a Beamer frame lands near 1000px wide) and `-r300`
a dense one, but a cropped `standalone` PDF is often two inches across, where `-r200` yields about
390px and millimetre clearances become unjudgeable. Start those at `-r600`, then confirm:

```bash
long=$(sips -g pixelWidth -g pixelHeight page-1.png | awk '/pixel(Width|Height)/{print $2}' | sort -rn | head -1)
```

Under 700, re-render at double the DPI; over 2400, halve it. Correct once, do not loop. If `gs` exits
non-zero or the PNG is missing or empty, surface `RENDER_FAILED:<message>` and abort.

### 4. Review

Launch the `tikz-reviewer` subagent (`subagent_type: "tikz-reviewer"`) with the template below, passing
absolute paths. It reads the PNG itself as an image.

### 5. Apply or finish

On a bare `APPROVED`: copy the current `.tex` to `--output`, surface the PNG path, and write one
paragraph on what changed across the rounds, collected from each round's reply as you go.

Otherwise apply each numbered item with `Edit`, using the exact `old_string`/`new_string` given.
Surgical replacements only; never regenerate the snippet. Copy the edited file into `$RUN/iter-NN+1/`
and return to step 2.

Before applying, diff the list against the previous round's. A verbatim repeat means the loop is
oscillating between two fixes, so stop early and report it instead of burning the remaining rounds.

### 6. Cap

At `--max-iter` without approval, surface the last PNG, the outstanding objections, and the in-progress
`.tex`. The caller decides whether to merge, continue by hand, or restart with a different goal.

## Reviewer prompt template

Send exactly this each round:

````
You are reviewing a TikZ diagram for visual quality.

ITERATION: {iter} of {max_iter}

USER GOAL:
{goal, or "(none provided - judge on visual quality alone)"}

CURRENT SOURCE ({tex_path}):
```tex
{tex_contents}
```

RENDERED IMAGE: {abs_png_path}
Read that PNG. Judge from the pixels. Do not infer geometry from the source.

Apply your standard checks, then return EXACTLY ONE of:

(a) The single word APPROVED on its own line, if zero CRITICAL and zero MAJOR
    issues remain.

(b) A numbered list of fixes, each with severity, the arithmetic justifying it,
    and an exact search-and-replace the orchestrator can apply:

    1. [CRITICAL] Label "M" sits on the X->Y edge.
       Arithmetic: "M" at \footnotesize is 1 char, width ~0.18cm, half-width
       0.09cm. The edge passes 0.05cm from the node center, so clearance is
       0.05cm against the 0.30cm minimum.
       Change `\node at (1.5,0.5) {$M$};` to `\node at (1.5,0.9) {$M$};`.

    Each old_string must appear exactly once in the source. No prose outside
    the numbered list. Do not rewrite the whole snippet.
````

## Failure taxonomy

| Symptom | Response |
|---|---|
| `latexmk` non-zero | `COMPILE_FAILED:<line>:<msg>` from the log, abort. Retry once via `tectonic` if the log names a missing `.sty`. |
| `gs` non-zero, PNG missing or empty | `RENDER_FAILED:<msg>`, abort. On a PDF latexmk just produced this usually means a truncated PDF, so recompile before blaming the rasterizer. |
| `latexmk` or `gs` off `PATH` | `SETUP_MISSING:<tool>` at preflight, stop. |
| Reply is neither `APPROVED` nor a parseable list | Re-prompt once with "Please respond in the required format." On a second drift, abort and surface the raw reply. |
| Subagent times out | Failed round. Surface the scratch path for a retry. |
| Same fix twice running | Oscillation. Stop, surface both renders. |
| Hit `--max-iter` | Surface last PNG, outstanding items, in-progress `.tex`. |

## Example

A four-node DAG at `~/scratch/causal-dag.tikz`, `--goal="X -> Y with mediator M and confounder U"`.
Round 1: the reviewer measures `M` at 0.09cm from the `X->Y` edge against a 0.30cm minimum, and finds
`U->Y` drawn with `--` while the other three edges use `->`. Both edits apply cleanly. Round 2:
`APPROVED`. A parallel-trends figure behaves the same way, with the reviewer comparing the pre-period
slope against the dashed counterfactual's and flagging the mismatch numerically.
