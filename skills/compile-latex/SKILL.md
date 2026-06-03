---
name: compile-latex
description: Compiles any .tex with auto engine/bib detection, a ranked error report (BLOCKING errors with file:line + suggested \usepackage / package-install fixes, then undefined refs/cites, then threshold-gated overfull/underfull boxes), diff-vs-last-compile, and a conflicted-copy guard. After a clean build it auto-iterates every detected TikZ/pgfplots figure via /tikz-iterate and splices the refined bodies back into the source. Trigger phrases - "/compile-latex", "compile this", "build my paper", "build my deck", "why won't this compile", "what are the latex errors", "did my edit add warnings". Cross-platform MiKTeX (Windows) / MacTeX (macOS) / TeX Live (Linux). Distinct from /tikz-iterate (single figure) and /slide-excellence (deck content review).
argument-hint: "[path-to-tex] [--engine=auto|pdflatex|xelatex|lualatex] [--outdir=build] [--box-threshold=5pt] [--clean|--clean-all] [--no-iterate] [--no-bib]"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash", "Task"]
effort: medium
---

# /compile-latex

Compile a `.tex`, parse the log into a ranked, actionable error report, diff it
against the last compile, then auto-iterate every TikZ/pgfplots figure through
`/tikz-iterate` and splice the refined bodies back. One command from "compile
this" to "figures polished and source updated."

The heavy parsing detail (command→package table, log regexes, file-stack rules,
box thresholds, state schema) lives in [`references/log-patterns.md`](references/log-patterns.md).
Read it before implementing Steps 3–6.

## Credit

The diff-vs-last-compile warning-set idea (persist the warning/box set, report
deltas between successive builds) is inspired by Scott Cunningham's
`compiledeck` in [`scunning1975/MixtapeTools`](https://github.com/scunning1975/MixtapeTools).
The figure-iterate hand-off chains into this repo's [`/tikz-iterate`](../tikz-iterate/SKILL.md).

## When to invoke

Trigger on: `/compile-latex`, "compile this", "build my paper/deck", "why won't
this compile", "what are the latex errors", "did my edit add warnings".

Do **not** invoke for:
- Single-figure visual polish with no full-document compile — use `/tikz-iterate`.
- Deck content / pedagogy review — use `/slide-excellence`.
- Editing prose or sections — use `/draft`.

## Inputs

This skill resolves paths against `~/.claude/state/personal_config.json` (see
`_config/personal_config.example.json`). If a `.tex` path is given, use it. If
only a basename is given, `Glob` for it under `personal_config.paths.overleaf_root`.
If the config is missing and no absolute path is given, ask the user for the path.

| Argument | Default | Meaning |
|---|---|---|
| positional `path-to-tex` | required | Master `.tex` to compile. |
| `--engine=` | `auto` | Force `pdflatex` / `xelatex` / `lualatex`; `auto` detects. |
| `--outdir=` | `build` | Aux-file directory (latexmk `-outdir`). |
| `--box-threshold=` | `5pt` | Overfull-hbox reporting gate. |
| `--clean` | off | `latexmk -c` (intermediate files), then stop. |
| `--clean-all` | off | `latexmk -C` (incl. PDF), then stop. |
| `--no-iterate` | off | Skip Step 6 figure loop — fast compile only. |
| `--no-bib` | off | Skip bib backend (no biber/bibtex run). |

## Step 0 — Pre-flight

1. Resolve the master `.tex` path (above). `Read` it.
2. **Conflicted-copy guard.** `Glob` the master's directory for Dropbox
   conflicted siblings: `* (*conflicted copy*).tex` and `*conflicted*.tex`.
   If any exist, **ABORT** with a warning listing them — do not compile or
   iterate on a possibly-stale file. The user resolves the conflict first.
3. If `--clean`/`--clean-all`: run `latexmk -c`/`-C -outdir=<outdir> <file>` and
   stop (skip everything below).
4. Verify `latexmk` and (for Step 6) `pdftoppm` are on `PATH`. If `latexmk` is
   missing, surface `SETUP_MISSING:latexmk` and stop (see `docs/tex-setup.md`).

## Step 1 — Detect engine & bib backend

Read the preamble (and any `\input`'d preamble file). Per `references/log-patterns.md` §6:

- **Engine.** Honor a `% !TEX program =` magic comment first. Else: `fontspec`
  / `unicode-math` / `setmainfont` / CJK → `xelatex`; `\directlua` / lua code →
  `lualatex`; otherwise `pdflatex`. `--engine=` overrides everything.
- **Bib backend** (unless `--no-bib`): `biblatex`/`\addbibresource` → **biber**;
  `natbib` + `\bibliographystyle` → **bibtex**. Warn on mismatch (e.g. biblatex
  + leftover `\bibliographystyle`).

Report the detection before compiling:
```
File:    <path>
Engine:  xelatex   (reason: \setmainfont in preamble)
Bib:     biber     (\addbibresource detected)
Outdir:  build/
```

## Step 2 — Compile

```bash
latexmk -pdf -interaction=nonstopmode -synctex=1 -outdir=<outdir> <file>
```
Swap the engine flag: `-pdf` (pdflatex), `-pdfxe` (xelatex), `-pdflua`
(lualatex). `latexmk` handles multi-pass, the bib run, and ref-rerun
automatically. Same command on Windows / macOS / Linux. Do **not** pass
`-halt-on-error` — we want the full log to parse all errors at once.

If `--no-bib`, add `-bibtex-`/skip the bib tool.

## Step 3 — Parse the log (file-stack tracker)

Read `<outdir>/<jobname>.log`. Implement the file-stack tracker from
`references/log-patterns.md` §3 so every `file:line` is attributed to the right
`\input`'d sub-file (the `(./sections/x.tex … )` open/close-paren stack), not
the master. Extract: BLOCKING errors (`! ...` + following `l.<N>`), undefined
refs/cites, and overfull/underfull boxes (§4–5).

## Step 4 — Rank & report

Emit in this fixed priority order:

1. **BLOCKING errors** — anything that stopped or corrupted the build. For each:
   `<file>:<line>` + the `! ...` message. If it is `Undefined control sequence`,
   look the token up in the command→package table (§1) and suggest the
   `\usepackage`. If it is a missing `.sty` (file-not-found), emit the
   **platform-specific install hint** (§2): MiKTeX `mpm --install=<pkg>`,
   MacTeX/TeX Live `tlmgr install <pkg>` — detect the platform.
2. **UNDEFINED REFS / CITES** — only those still undefined in the **final** pass
   (drop transients latexmk's rerun already cleared, §4). Separate refs from
   cites; for missing cites, suggest `/cite`.
3. **BOXES** (threshold-gated, §5) — overfull only if `> box-threshold`;
   underfull only if `badness >= 5000`. Show the worst 10, then `+K more`.

Lead with a one-line verdict: `BUILD OK` / `BUILD OK (with warnings)` /
`BUILD FAILED (N blocking errors)` and the output PDF path.

## Step 5 — Diff vs last compile

Per §8: load `~/.claude/state/compile-latex/<project-hash>/last.json` (hash of
the absolute master path). Diff the new warning/box/undef sets against it and
report deltas, e.g. `+2 new overfull boxes, -1 undefined ref since last compile`.
Then write the new set atomically (tmp + rename). If no baseline exists, note
`first compile (no baseline)` and just write.

## Step 6 — Figure detection & auto-handoff to /tikz-iterate

Skip entirely if `--no-iterate`, or if the build failed (Step 4 had blocking
errors), or if no figures are detected.

**No asking.** Do not ask which figures to iterate — iterate **all** detected
ones. Pre-flight already cleared the conflicted-copy guard, so splice in place.

1. `Grep` the master and its `\input`'d sub-files for figure blocks (§7):
   `\begin{tikzpicture}`, `\begin{axis}` / `\begin{groupplot}` (pgfplots),
   and `standalone` figure files.
2. For each block: harvest the parent preamble's `\usepackage` /
   `\usetikzlibrary` / `\usepgfplotslibrary` / `\pgfplotsset` / `\definecolor` /
   `\colorlet` / `\newcommand` / `\def` / `\tikzset` lines into a standalone
   wrapper (so named colors and macros resolve), then hand the wrapped figure to
   `/tikz-iterate` via the `Task` tool (`subagent_type: "tikz-reviewer"` loop,
   or invoke the `/tikz-iterate` workflow). Pass a `--goal` derived from the
   figure's caption if present.
3. On approval, **strip the wrapper** and splice **only the inner figure body**
   back into the source via offset-anchored `Edit` — preserve the surrounding
   `figure` env, `\caption`, `\label`, `\centering`, and any
   `\resizebox`/`\adjustbox` wrapper (§7).
4. After all figures are spliced, **recompile once** (Step 2) to confirm the
   document still builds. Report which figure blocks changed (Dropbox version
   history + git make this recoverable — do not nag with per-figure prompts).

## Step 7 — Cleanup

Aux files already live in `<outdir>/` (isolated). Mention `--clean` /
`--clean-all` as the way to wipe them. Leave the PDF in place. `--watch` is
**deferred** — for a live rebuild loop, tell the user to run
`latexmk -pvc -outdir=<outdir> <file>` manually.

## Cross-platform notes

`latexmk`, `pdftoppm`, and the SyncTeX flag behave identically on Windows
(MiKTeX), macOS (MacTeX), and Linux (TeX Live). The **only** platform branch is
the missing-package install hint: `mpm --install=<pkg>` on Windows vs
`tlmgr install <pkg>` on macOS/Linux. Detect the platform once and reuse.

## Failure modes

| Symptom | Cause | Response |
|---|---|---|
| Conflicted-copy sibling found | Dropbox sync conflict | ABORT in Step 0; list the files; do not compile. |
| `latexmk` not on PATH | No TeX install | `SETUP_MISSING:latexmk`, point to `docs/tex-setup.md`. |
| `! ... .sty not found` | Package not installed | Platform install hint (§2); if MiKTeX auto-install, suggest re-run. |
| Undefined control sequence | Missing `\usepackage` or user macro | §1 table lookup; if user macro, flag missing `\newcommand`/un-`\input`'d file. |
| Refs undefined on pass 1 only | latexmk hadn't converged | Drop as transient (§4) — never report. |
| File-stack desync (depth < 0) | Parens in log output | Reset to master, mark attribution `~approx`. |
| Figure won't converge in `/tikz-iterate` | Hard diagram | Leave that block unspliced; report it; continue with the rest. |
| `pdftoppm` missing | Poppler absent | Skip Step 6 figure loop with a note; compile report still stands. |

## Examples

**Compile a paper, see the errors:**
```
/compile-latex main.tex
→ Engine: pdflatex | Bib: bibtex
→ BUILD FAILED (1 blocking)
  sections/results.tex:212  Undefined control sequence \toprule
    fix: \usepackage{booktabs}
→ 1 undefined cite: Smith2020  (run /cite)
→ since last compile: +0 boxes
```

**Fast compile, no figure loop:**
```
/compile-latex slides.tex --no-iterate
→ BUILD OK (with warnings) | build/slides.pdf
→ 3 overfull boxes >5pt (worst: frame 12, 18.4pt) | +1 since last compile
```

**Full build + figure polish (default):**
```
/compile-latex paper.tex
→ BUILD OK → 4 tikz/pgfplots figures detected → iterating…
  fig:dag      APPROVED (2 rounds) spliced
  fig:coefplot APPROVED (3 rounds) spliced
  …
→ recompiled: BUILD OK | build/paper.pdf
```

## Out of scope

- Live `--watch` rebuilds — use `latexmk -pvc` manually (Step 7).
- Deck pedagogy/content review — `/slide-excellence`.
- Writing or rewriting prose — `/draft`.
- Adding citations — `/cite` (this skill only *reports* missing cites).
- Single isolated figure with no document — `/tikz-iterate` directly.

## Relation to neighbors

- **`/tikz-iterate`** — the per-figure refine loop this skill calls in Step 6.
  Invoke it directly when you have one figure and no document to compile.
- **`/slide-excellence`** — reviews deck *content* (visual / pedagogy /
  proofreading). It defers compilation to this skill. Run `/compile-latex`
  first to get a clean build, then `/slide-excellence` for the content pass.
- **`/create-lecture`** — scaffolds a new deck; compile it here afterward.
