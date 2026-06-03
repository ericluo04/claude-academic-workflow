# Log-parsing reference for `/compile-latex`

Companion to `SKILL.md`. Holds the command→package table, the log regexes, the
file-stack tracker rules, and the box thresholds so the main file stays terse.

---

## 1. Command → package table (BLOCKING-error fix suggestions)

When the log shows `Undefined control sequence` and the offending token on the
next `l.<N>` line matches a known command, suggest the `\usepackage` that
defines it. Map (extend freely):

| Undefined command | Suggested fix |
|---|---|
| `\toprule` `\midrule` `\bottomrule` `\cmidrule` | `\usepackage{booktabs}` |
| `\Cref` `\cref` `\Crefname` | `\usepackage{cleveref}` (load **after** hyperref) |
| `\bm` | `\usepackage{bm}` |
| `\SI` `\si` `\num` `\ang` | `\usepackage{siunitx}` |
| `\includegraphics` `\graphicspath` | `\usepackage{graphicx}` |
| `\adjustbox` `\adjincludegraphics` | `\usepackage{adjustbox}` |
| `\tikz` `\begin{tikzpicture}` | `\usepackage{tikz}` |
| `\pgfplotsset` `\begin{axis}` `\addplot` | `\usepackage{pgfplots}` (then `\pgfplotsset{compat=1.18}`) |
| `\begin{groupplot}` | `\usepgfplotslibrary{groupplots}` |
| `\multirow` | `\usepackage{multirow}` |
| `\rowcolor` `\cellcolor` `\columncolor` | `\usepackage[table]{xcolor}` |
| `\definecolor` `\textcolor` `\color` | `\usepackage{xcolor}` |
| `\href` `\url` `\hyperref` | `\usepackage{hyperref}` |
| `\citep` `\citet` `\citealt` | `\usepackage{natbib}` |
| `\Cite` `\textcite` `\parencite` | `\usepackage[...]{biblatex}` (biblatex API) |
| `\subcaption` `\subfloat` `\begin{subfigure}` | `\usepackage{subcaption}` |
| `\FloatBarrier` | `\usepackage{placeins}` |
| `\mathbb` `\mathfrak` | `\usepackage{amssymb}` |
| `\text` `\dfrac` `\binom` `\substack` | `\usepackage{amsmath}` |
| `\bmod` issues / `\overset` | `\usepackage{amsmath}` |
| `\begin{algorithm}` | `\usepackage{algorithm}` |
| `\begin{algorithmic}` `\State` `\For` | `\usepackage{algpseudocode}` (algorithmicx) |
| `\SetKwInOut` `\KwData` | `\usepackage[ruled]{algorithm2e}` |
| `\todo` `\listoftodos` | `\usepackage{todonotes}` |
| `\enquote` | `\usepackage{csquotes}` |
| `\xspace` | `\usepackage{xspace}` |
| `\resizebox` (ok in graphicx) / `\scalebox` | `\usepackage{graphicx}` |
| `\tabularx` `\begin{tabularx}` | `\usepackage{tabularx}` |
| `\makecell` | `\usepackage{makecell}` |
| `\dashedline` / `\Block` (nicematrix) | `\usepackage{nicematrix}` |
| `\bmqty` / physics macros | `\usepackage{physics}` |

If the undefined command is a user macro (lowercase, project-specific, e.g.
`\bphi`, `\indep`), do **not** suggest a package — flag it as a likely missing
`\newcommand`/`\def` in the preamble or an un-`\input`'d macro file.

---

## 2. Missing-package (file-not-found) errors

These are distinct from undefined control sequences — the package exists but is
not installed. Log signatures:

```
! LaTeX Error: File `adjustbox.sty' not found.
! Package pgfplots Error: ... could not be found
```

Extract `<pkg>.sty` and emit a platform-specific install hint:

| Platform | Detect | Install command |
|---|---|---|
| Windows (MiKTeX) | `os.name == "nt"` / PowerShell | `mpm --install=<pkg>` |
| macOS (MacTeX / TeX Live) | `uname == Darwin` | `tlmgr install <pkg>` |
| Linux (TeX Live) | `uname == Linux` | `tlmgr install <pkg>` (or distro pkg) |

`<pkg>` is the `.sty` basename without extension. If MiKTeX auto-install is on,
the first compile may already have fetched it — note that and suggest re-running.

---

## 3. File-stack tracker

`latexmk`/`pdflatex` logs interleave open-paren `(` / close-paren `)` tokens
that mark `\input`/`\include` boundaries. A line/error is attributed to the
**innermost currently-open file**, not the master `.tex`.

Algorithm:

1. Scan the log left-to-right, token by token (the log wraps at ~79 cols — strip
   hard newlines inside a paren group before tokenizing, or scan char-stream).
2. On `(<path>` (an open paren immediately followed by a path that ends in a
   known TeX extension `.tex`/`.sty`/`.cls`/`.def`/`.clo` or a relative
   `./...`), **push** `<path>` onto the stack.
3. On a balancing `)`, **pop**.
4. When an error (`! ...`) or `l.<N>` line appears, the **top of stack** is the
   file the line number belongs to. Report as `<stack-top>:<N>`.

Caveats:
- Parens inside `\message`/token output can desync the stack; if depth goes
  negative, reset to the master file and mark attribution `~approx`.
- `pdftex` sometimes prints the path split across lines — re-join continued
  lines (a line that does not start a new log record) before tokenizing.
- Fall back to the master file with an `(unresolved \input)` note if the stack
  is empty when the error fires.

---

## 4. Undefined refs / cites

Log signatures (emitted during the run that needed them):

```
LaTeX Warning: Reference `fig:foo' on page 3 undefined on input line 88.
LaTeX Warning: Citation `Smith2020' on page 2 undefined on input line 40.
LaTeX Warning: There were undefined references.
Package natbib Warning: Citation `Smith2020' on page 2 undefined
```

**Transient-vs-real rule.** `latexmk` reruns until labels stabilize. A
reference that is undefined on pass 1 but defined by the final pass is
*transient* — do **not** report it. Only report a ref/cite as undefined if the
**final** pass's log still lists it. Practically: parse only the last
`Rerun`-free pass, or check that the warning persists in the final
`<jobname>.log` after latexmk converged. If you only have the final `.log`,
trust it — latexmk leaves the last pass's log in place.

Group output as:
- **UNDEFINED REFERENCES**: `\label` never defined → likely typo or missing
  `\label`. List `key → input line`.
- **UNDEFINED CITATIONS**: key absent from `.bib`/`.bbl` → run `/cite` or fix the
  key. List `key → input line`.

---

## 5. Box warnings (threshold-gated)

Log signatures:

```
Overfull \hbox (15.83003pt too wide) in paragraph at lines 102--104
Overfull \vbox (3.2pt too high) has occurred while \output is active
Underfull \hbox (badness 10000) in paragraph at lines 55--57
Underfull \vbox (badness 3000) has occurred while \output is active
```

Gates (defaults; `--box-threshold=` overrides the hbox pt gate):
- **Overfull hbox/vbox**: report only if `too wide`/`too high` value `> 5pt`.
- **Underfull hbox/vbox**: report only if `badness >= 5000`.
- Sort by severity (overfull pt descending, then underfull badness descending).
- Show the worst **10**; append `+K more (suppressed under threshold or beyond
  top 10)`.

Regexes:
```
overfull:  Overfull \\(hbox|vbox) \((\d+(?:\.\d+)?)pt too (?:wide|high)\)(?: in paragraph at lines (\d+)--(\d+))?
underfull: Underfull \\(hbox|vbox) \(badness (\d+)\)(?: in paragraph at lines (\d+)--(\d+))?
```
Attribute `lines A--B` to the file-stack top at the point the warning fired.

---

## 6. Engine / bib detection signatures

**Engine magic comment** (honor over auto-detect):
```
% !TEX program = xelatex      (also: %!TEX TS-program = lualatex)
```
Regex: `%\s*!TEX\s+(?:TS-)?program\s*=\s*(pdflatex|xelatex|lualatex)`

**xelatex/lualatex triggers** in preamble (auto-detect when no magic comment):
- `\usepackage{fontspec}` / `\usepackage{unicode-math}` → xelatex (default for
  Unicode fonts) or lualatex.
- `\setmainfont` / `\setsansfont` / `\setmonofont` → xelatex.
- `\usepackage{xeCJK}` / `\usepackage{ctex}` / CJK chars in source → xelatex.
- `\directlua{...}` / `\usepackage{luacode}` / `luatextra` → lualatex.

Default when none match: **pdflatex**.

latexmk engine flags:
| Engine | latexmk flag |
|---|---|
| pdflatex | `-pdf` |
| xelatex | `-pdfxe` (or `-xelatex`) |
| lualatex | `-pdflua` (or `-lualatex`) |

**Bib backend**:
- `\usepackage[...]{biblatex}` (or `\addbibresource`) → **biber**.
- `\usepackage{natbib}` + `\bibliographystyle{...}` + `\bibliography{...}` →
  **bibtex**.
- Mismatch warnings: biblatex present but `\bibliographystyle` also present
  (natbib leftover) → warn; `\addbibresource` with no biblatex → warn.
latexmk auto-runs the right backend; just **report which ran** by inspecting for
a `.bcf` (biber) vs `.aux`→`.bbl` via bibtex, and warn on mismatch.

---

## 7. Figure-block detection (Step 6 handoff)

Grep the source (and any `\input`'d sub-files) for:
- `\begin{tikzpicture}` … `\end{tikzpicture}`
- `\begin{axis}` / `\begin{groupplot}` (pgfplots) — usually nested in
  `tikzpicture`; treat the outermost `tikzpicture` as the block.
- `\documentclass[...]{standalone}` files referenced via `\includestandalone`
  or compiled separately.

Harvest from the **parent preamble** into the standalone wrapper so colors/macros
resolve: every `\usepackage{...}` / `\usepackage[...]{...}`,
`\usetikzlibrary{...}`, `\usepgfplotslibrary{...}`, `\pgfplotsset{...}`,
`\definecolor{...}`, `\newcommand{...}`, `\renewcommand{...}`, `\def\...`,
`\tikzset{...}`, `\colorlet{...}`.

Splice-back: replace **only** the inner figure body (between and including the
`\begin{tikzpicture}`…`\end{tikzpicture}`), preserving the surrounding
`figure` env, `\caption`, `\label`, `\centering`, and `\resizebox`/`\adjustbox`
wrappers. Use offset-anchored `Edit` (unique `old_string` from the captured
original body) so the right block is replaced even if several figures share
similar code.

---

## 8. Diff-vs-last-compile state

Persist after each successful compile to:
```
~/.claude/state/compile-latex/<project-hash>/last.json
```
`<project-hash>` = stable hash of the absolute master `.tex` path. Schema:
```json
{
  "ts": "2026-06-02T14:03:00Z",
  "engine": "pdflatex",
  "bib_backend": "bibtex",
  "undefined_refs": ["fig:foo"],
  "undefined_cites": ["Smith2020"],
  "overfull": [{"file": "sections/intro.tex", "lines": "102--104", "pt": 15.83}],
  "underfull": [{"file": "main.tex", "lines": "55--57", "badness": 10000}]
}
```
On the next compile, diff the new set against `last.json` and report deltas:
`+2 new overfull boxes, -1 undefined ref since last compile`. Write atomically
(tmp + rename). If `last.json` is absent, skip the diff and note "first
compile (no baseline)".
