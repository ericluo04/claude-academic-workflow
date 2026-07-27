---
name: compile-latex
description: Compile a .tex with latexmk, auto-detecting the engine (pdflatex/xelatex/lualatex) and bib backend (biber/bibtex), then emit a ranked error report with accurate file:line attribution across \input'd files, plus a diff against the last compile. Guards against Dropbox conflicted-copy files in Overleaf projects. TRIGGER on "compile this", "build my paper", "build the beamer deck", "why won't this compile", "what are the latex errors", "did my edit add warnings", or any request to build or debug a LaTeX document; Quarto .qmd decks belong to research-talk and teaching-lecture. An opt-in --figures pass hands TikZ/pgfplots blocks to the tikz-iterate skill.
---

# compile-latex

Compile a `.tex`, parse the log into a ranked report with correct `file:line`
attribution, and diff it against the previous build. The default is
compile-and-report only; nothing in the source is edited unless `--figures` is
passed.

Parsing detail (package tables, log regexes, file-stack rules, box thresholds,
state schema) is in [`references/log-patterns.md`](references/log-patterns.md).
Read it before steps 3 through 5. Diff-vs-last-compile is adapted from
`compiledeck` in [scunning1975/MixtapeTools](https://github.com/scunning1975/MixtapeTools).

## Options

| Option | Default | Meaning |
|---|---|---|
| positional path | required | Master `.tex`. Absolute path, or a basename to resolve. |
| `--engine=` | `auto` | Force `pdflatex` / `xelatex` / `lualatex`. |
| `--outdir=` | `build` | Aux directory (`latexmk -outdir`). |
| `--box-threshold=` | `5pt` | Overfull reporting gate. |
| `--figures` | off | Opt-in: polish TikZ/pgfplots figures via `tikz-iterate`, then splice back. |
| `--no-bib` | off | Skip the bib run (`-bibtex-`). |
| `--force` | off | Compile even if a conflicted copy is present. |
| `--clean` / `--clean-all` | off | `latexmk -c` / `-C`, then stop. |

## Resolving the file

No config file. In order: use an absolute or cwd-relative path if given;
otherwise `Glob` `~/Library/CloudStorage/Dropbox*/Apps/Overleaf/*/**/<name>.tex` and, if a
project name was mentioned, filter to that project directory; otherwise `Glob`
`*.tex` in the cwd and pick the one with `\documentclass`. Ask only if that
leaves zero or several plausible masters.

## Step 0, pre-flight

1. `Read` the master.
2. Conflicted-copy guard. This setup assumes these projects sync through
   Dropbox (adjust to your machine), so compiling
   next to a stale sibling means reporting errors the user already fixed
   elsewhere. `Glob` the project directory recursively for `*conflicted copy*`
   (`.tex`, `.bib`, `.sty`, `.cls`). If any exist, stop and list them with
   mtimes so the user can resolve the conflict. `--force` overrides.
3. `--clean` / `--clean-all`: run `latexmk -c -outdir=<outdir> <file>` or
   `latexmk -C -outdir=<outdir> <file>` and stop.
4. `latexmk` is at `/Library/TeX/texbin/latexmk` on a MacTeX install. If it is
   missing from `PATH`,
   prepend `/Library/TeX/texbin` before failing with `SETUP_MISSING:latexmk`.
   With `--figures`, also check `gs` (e.g. `/usr/local/bin/gs`); if absent, report
   `SETUP_MISSING:gs` and skip the figure pass, keeping the compile report.

## Step 1, detect engine and bib backend

Read the preamble plus any `\input`'d preamble file (§6 of the reference).
A `% !TEX program =` magic comment wins. Otherwise `fontspec` / `unicode-math` /
`\setmainfont` / `xeCJK` / `ctex` implies xelatex; `\directlua` / `luacode`
implies lualatex; else pdflatex. `--engine=` overrides both.

Bib backend, unless `--no-bib`: `biblatex` or `\addbibresource` means biber;
`natbib` plus `\bibliographystyle` means bibtex. Warn on a mismatch (biblatex
loaded with a leftover `\bibliographystyle`, or `\addbibresource` with no
biblatex).

Print the detection before compiling:

```
File:   <path>
Engine: xelatex  (\setmainfont in preamble)
Bib:    biber    (\addbibresource)
Outdir: build/
```

## Step 2, compile

```bash
latexmk -f "$ENGINE_FLAG" -interaction=nonstopmode -synctex=1 -outdir=<outdir> <file>
```

`ENGINE_FLAG` comes from the step-1 detection: `-pdf` (pdflatex), `-pdfxe`
(xelatex), `-pdflua` (lualatex).
`-f` matters: without it latexmk stops at the first failing pass, so the log
holds one error instead of all of them. Never pass `-halt-on-error`. Add
`-bibtex-` for `--no-bib`. A nonzero exit code is expected on a failed document
and is not a tooling failure; parse the log regardless.

## Step 3, parse the log

Read `<outdir>/<jobname>.log` and run the file-stack tracker from §3 so every
`file:line` lands on the right `\input`'d sub-file rather than the master. The
tracker must push a placeholder for non-path `(` as well, otherwise the parens
inside ordinary messages (`Overfull \hbox (15.83003pt too wide)`) pop real files
off the stack and every subsequent attribution is wrong.

Extract blocking errors (`! ...` plus the following `l.<N>`), undefined
refs/cites (§4), and boxes (§5).

## Step 4, rank and report

Lead with one verdict line, `BUILD OK` / `BUILD OK (with warnings)` /
`BUILD FAILED (N blocking)`, and the PDF path. Then, in this fixed order:

1. Blocking errors. `<file>:<line>` plus the `! ...` message. For
   `Undefined control sequence`, look the token up in §1 and suggest the
   `\usepackage`. For `Environment X undefined`, use the environment table in
   §1. For a missing `.sty`, print the `tlmgr` line from §2 for the user to run
   (MacTeX's tree is root-owned, so it needs `sudo`; never run it unprompted).
   Collapse cascades per §1: one undefined environment produces two or three
   downstream errors that vanish once the root cause is fixed.
2. Undefined refs and cites, split into two lists, keys with input lines. Only
   report what survives the final pass (§4).
3. Boxes, gated: overfull above `--box-threshold`, underfull at badness >= 5000.
   Worst 10 sorted by severity, then `+K more`.

Below-threshold and font/rerun-check noise is dropped silently.

## Step 5, diff vs last compile

State lives at `~/.claude/state/compile-latex/<hash>/last.json`, where `<hash>`
is `sha1(abspath)[:12]`. Load it, diff the new ref/cite/box sets, and report
deltas (`+2 overfull, -1 undefined ref since last compile`). Box identity is
`file:lines:kind`, not the pt value, so a reflow of the same box is not counted
as new. Write the new state atomically (tmp file plus rename); the Write tool
creates missing parent directories, but a Bash-side write needs a `mkdir -p`
first, since `~/.claude/state/` may not exist yet. With no baseline,
note `first compile (no baseline)` and just write. Schema in §8.

## Step 6, figures (opt-in, `--figures` only)

Runs only under `--figures`, and only when the build was clean and figures
exist.

1. `Grep` the master and its `\input`'d files for `\begin{tikzpicture}` and
   pgfplots `\begin{axis}` / `\begin{groupplot}` blocks (§7). Treat the
   outermost `tikzpicture` as the unit.
2. For each block, record the file, the exact body text, and `sha1(body)`.
   Harvest the parent preamble's `\usepackage` / `\usetikzlibrary` /
   `\usepgfplotslibrary` / `\pgfplotsset` / `\definecolor` / `\colorlet` /
   `\newcommand` / `\def` / `\tikzset` lines into a standalone wrapper so colors
   and macros resolve.
3. Hand each wrapped figure to the `tikz-iterate` skill (one subagent per
   figure, run concurrently), with a goal derived from the caption if there is
   one. Do not reimplement its refine loop here.
4. Splice back only on a verified anchor. Re-`Read` the source file, confirm the
   captured body still appears exactly once and its `sha1` is unchanged, then
   `Edit` with that body as `old_string`. If it is missing, appears more than
   once, or the hash moved, skip it and report `not spliced (source changed)`.
   Strip the wrapper first; keep the surrounding `figure` env, `\caption`,
   `\label`, `\centering`, and any `\resizebox` / `\adjustbox`.
5. Recompile once and report which blocks changed.

Rasterization belongs to `tikz-iterate`, which uses ghostscript (this setup
assumes no poppler is installed; adjust to your machine); leave it there. To
inspect the compiled document's
text, run `~/.claude/assets/bin/pdfread.py text <outdir>/<jobname>.pdf`. On a
machine without poppler, the Read
tool cannot open a PDF (no `pdftoppm`), and `pdftotext` does
not exist either, so never shell out to those.

## Step 7, cleanup

Aux files stay in `<outdir>/`. Mention `--clean` / `--clean-all` as the way to
wipe them; leave the PDF. For a live rebuild loop tell the user to run
`latexmk -pvc -outdir=<outdir> <file>` themselves.

## Failure modes

| Symptom | Cause | Response |
|---|---|---|
| Conflicted-copy sibling | Dropbox sync conflict | Stop in step 0, list files, offer `--force`. |
| `! ... .sty not found` | Package absent | Check `kpsewhich <file>`, then print the `tlmgr` line (§2). |
| Undefined control sequence | Missing package or user macro | §1 lookup; if it is a project macro, flag a missing `\newcommand` or an un-`\input`'d macro file. |
| Refs undefined, log says `Rerun to get cross-references right` | latexmk did not converge | Re-run once; do not report the refs (§4). |
| Stack depth goes negative | Unbalanced parens in log text | Reset to master, mark the attribution `~approx`. |
| Empty or absent `.log` | latexmk never started | Report the raw latexmk stderr; do not invent errors. |
| Figure will not converge | Hard diagram | Leave that block unspliced, report it, continue. |

## Examples

```
compile-latex main.tex
→ BUILD FAILED (1 blocking)
  sections/results.tex:212  Undefined control sequence \toprule
    fix: \usepackage{booktabs}
→ 1 undefined cite: Smith2020
→ since last compile: +0 boxes
```

```
compile-latex "Algorithmic Pricing Manuscript" --box-threshold=2pt
→ BUILD OK (with warnings) | build/main.pdf
→ 3 overfull >2pt (worst: sections/model.tex:88, 18.4pt) | +1 since last compile
```
