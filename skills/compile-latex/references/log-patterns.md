# Log-parsing reference for compile-latex

Command and environment tables, log regexes, the file-stack tracker, box
thresholds, and the state schema. Companion to `SKILL.md`.

---

## 1. Undefined command and environment tables

Two distinct error classes get confused often:

```
! Undefined control sequence.
l.212 \toprule
! LaTeX Error: Environment tikzpicture undefined.
```

The first is a missing macro; the second is a missing environment. Handle them
separately.

Finding the offending token for `Undefined control sequence`: TeX breaks the
context line right after the culprit, so the token is the **last** control
sequence on the `l.<N>` line (not the first, and not on the continuation line
below it).

| Undefined command | Suggested fix |
|---|---|
| `\toprule` `\midrule` `\bottomrule` `\cmidrule` | `\usepackage{booktabs}` |
| `\cref` `\Cref` `\crefname` | `\usepackage{cleveref}` (load after hyperref) |
| `\bm` | `\usepackage{bm}` |
| `\SI` `\si` `\num` `\qty` `\ang` | `\usepackage{siunitx}` |
| `\includegraphics` `\graphicspath` `\resizebox` `\scalebox` | `\usepackage{graphicx}` |
| `\adjustbox` `\adjincludegraphics` | `\usepackage{adjustbox}` |
| `\tikz` `\tikzset` `\node` `\draw` | `\usepackage{tikz}` |
| `\pgfplotsset` `\addplot` | `\usepackage{pgfplots}` plus `\pgfplotsset{compat=1.18}` |
| `\multirow` | `\usepackage{multirow}` |
| `\rowcolor` `\cellcolor` `\columncolor` | `\usepackage[table]{xcolor}` |
| `\definecolor` `\textcolor` `\color` `\colorlet` | `\usepackage{xcolor}` |
| `\href` `\url` `\hyperref` `\autoref` | `\usepackage{hyperref}` |
| `\citep` `\citet` `\citealt` `\citeauthor` | `\usepackage{natbib}` |
| `\textcite` `\parencite` `\autocite` | `\usepackage{biblatex}` |
| `\mathbb` `\mathfrak` | `\usepackage{amssymb}` |
| `\text` `\dfrac` `\binom` `\substack` `\overset` `\DeclareMathOperator` | `\usepackage{amsmath}` |
| `\State` `\For` `\While` `\Procedure` | `\usepackage{algpseudocode}` |
| `\SetKwInOut` `\KwData` | `\usepackage[ruled]{algorithm2e}` |
| `\FloatBarrier` | `\usepackage{placeins}` |
| `\todo` `\listoftodos` | `\usepackage{todonotes}` |
| `\enquote` | `\usepackage{csquotes}` |
| `\xspace` | `\usepackage{xspace}` |
| `\makecell` | `\usepackage{makecell}` |
| `\Block` `\CodeBefore` | `\usepackage{nicematrix}` |
| `\setmainfont` `\newfontfamily` | `\usepackage{fontspec}` (needs xelatex or lualatex) |
| `\ThisULCornerWallPaper` etc. | `\usepackage{wallpaper}` |

| Undefined environment | Suggested fix |
|---|---|
| `tikzpicture` | `\usepackage{tikz}` |
| `axis` `semilogxaxis` `loglogaxis` | `\usepackage{pgfplots}` |
| `groupplot` | `\usepgfplotslibrary{groupplots}` |
| `subfigure` `subtable` | `\usepackage{subcaption}` |
| `tabularx` | `\usepackage{tabularx}` |
| `threeparttable` | `\usepackage{threeparttable}` |
| `longtable` | `\usepackage{longtable}` |
| `algorithm` | `\usepackage{algorithm}` |
| `algorithmic` | `\usepackage{algpseudocode}` |
| `theorem` `lemma` `proof` | `\usepackage{amsthm}` plus a `\newtheorem` |
| `frame` | document is not Beamer, or `\documentclass{beamer}` is missing |
| `columns` `column` | Beamer, or `\usepackage{multicol}` for `multicols` |

Cascades. An undefined environment throws a second error at its `\end`:

```
! LaTeX Error: Environment tikzpicture undefined.
l.4 \begin{tikzpicture}
! LaTeX Error: \begin{document} ended by \end{tikzpicture}.
l.5 \end{tikzpicture}
```

Report the root cause and suppress the follow-on. The pattern to collapse is a
`\begin{document} ended by \end{X}` that trails an `Environment X undefined` for
the same `X`. Same for `Missing \endgroup`, `Extra }`, and `Emergency stop`
following an earlier hard error in the same file.

If the undefined token looks project-specific (short, lowercase, e.g. `\bphi`,
`\indep`, `\E`), do not suggest a package. Flag it as a missing `\newcommand` or
`\def`, or a macro file that is not `\input`'d, and grep the project for a
definition to confirm.

---

## 2. Missing package (file not found)

The package exists upstream but is not installed. Signatures:

```
! LaTeX Error: File `adjustbox.sty' not found.
! I can't find file `foo.tex'.
! Package pgfplots Error: ... could not be found
```

Regex: `^! LaTeX Error: File \`([^']+)' not found`

Before reporting, confirm with `kpsewhich <file>` (empty output means genuinely
absent; a hit means the failure is a path or `TEXINPUTS` problem instead).

macOS only, MacTeX / TeX Live:

```bash
sudo tlmgr install <name>
```

`<name>` is the `.sty` basename without extension. That guess is wrong whenever
the file's CTAN package differs (`algpseudocode.sty` ships in `algorithmicx`,
`subcaption.sty` in `caption`). If `tlmgr install` reports the package does not
exist, find the real one:

```bash
tlmgr search --global --file "/<file>.sty"
```

The MacTeX tree is root-owned, so `tlmgr install` needs `sudo`. Print the
command for the user; never run a `sudo` install unprompted. `sudo tlmgr update
--self` first if tlmgr complains about being out of date.

---

## 3. File-stack tracker

pdflatex logs mark `\input` / `\include` boundaries with `(<path>` … `)`. Any
`file:line` belongs to the innermost open file, not the master.

The pop rule is the part that is easy to get wrong. Ordinary log text contains
balanced parens that open nothing (`Overfull \hbox (15.83003pt too wide)`,
`(Font) ...`, `[13] (\end occurred ...)`). If a `)` pops while its `(` pushed
nothing, every subsequent attribution is off by one file. Push a placeholder for
non-path parens so the stack stays balanced. On a 170-line log from a trivial
two-file document, popping without a placeholder underflowed 19 times; with the
placeholder the stack closed at exactly zero.

Algorithm:

1. Unwrap first. pdftex wraps output at `max_print_line` (79 in TeX Live), so a
   path can be split mid-token. Join line *n+1* onto *n* when *n* is >= 79 chars
   and *n+1* does not start a new record (does not begin with `!`, `l.`, `[`,
   `Overfull`, `Underfull`, `LaTeX Warning`, `LaTeX Font Warning`, `Package `,
   `Class `, `Missing`, `Runaway`).
2. Scan the joined text as a character stream.
3. On `(`, read the following run of characters up to the next whitespace,
   `(`, or `)`. If it looks like a file (starts with `.` or `/`, or ends in
   `.tex` `.sty` `.cls` `.def` `.clo` `.cfg` `.ldf` `.fd` `.bbl` `.aux` `.toc`
   `.out` `.bbx` `.cbx` `.lbx`), push that path. Otherwise push a placeholder.
4. On `)`, pop one entry if the stack is non-empty.
5. Current file is the nearest real path from the top of the stack; the master
   if there is none.

Caveats:

- Depth below zero means the stack desynced. Reset to the master and mark the
  attribution `~approx` rather than reporting a confidently wrong file.
- Page markers `[12]` and `[13 <./fig.pdf>]` carry no paren state, but the
  bracketed paths inside them must not be mistaken for `\input` boundaries.
- `\include`d files show up as `(./chap1.tex ... )` with the `.aux` opened and
  closed inside them; that nesting is legitimate and the placeholder rule keeps
  it balanced.

---

## 4. Undefined refs and cites

```
LaTeX Warning: Reference `fig:foo' on page 3 undefined on input line 88.
LaTeX Warning: Citation `Smith2020' on page 2 undefined on input line 40.
LaTeX Warning: There were undefined references.
Package natbib Warning: Citation `Smith2020' on page 2 undefined
Package biblatex Warning: Please (re)run Biber on the file: main
```

Regexes:

```
ref:  Reference \`([^']+)' on page \d+ undefined on input line (\d+)
cite: Citation \`([^']+)' on page \d+ undefined(?: on input line (\d+))?
```

Transient rule. latexmk reruns until the `.aux` stabilizes and each pass
overwrites `<jobname>.log`, so the file on disk is the final pass and its
warnings are real. The one exception is a build that did not converge: if the
final log still contains `Rerun to get cross-references right` or `Please
(re)run Biber`, the refs are transient. Re-run latexmk once and re-parse instead
of reporting them.

Report as two lists, refs (`\label` never defined, so a typo or a missing
`\label`) and cites (key absent from the `.bib`), each as `key -> input line`.

---

## 5. Box warnings

```
Overfull \hbox (15.83003pt too wide) in paragraph at lines 102--104
Overfull \hbox (2.4pt too wide) in alignment at lines 40--52
Overfull \hbox (7.1pt too wide) detected at line 88
Overfull \vbox (3.2pt too high) has occurred while \output is active [12]
Underfull \hbox (badness 10000) in paragraph at lines 55--57
Underfull \vbox (badness 3000) has occurred while \output is active
```

The location clause has four shapes, so match the amount and the location
separately rather than with one regex:

```
overfull:   ^Overfull \\(hbox|vbox) \((\d+(?:\.\d+)?)pt too (?:wide|high)\)(.*)$
underfull:  ^Underfull \\(hbox|vbox) \(badness (\d+)\)(.*)$
location, applied to the trailing group:
  (?:in paragraph|in alignment|in hbox) at lines (\d+)--(\d+)
  detected at line (\d+)
  has occurred while \\output is active     -> no line; use the last [N] page marker
```

Gates (defaults; `--box-threshold=` moves the pt gate for overfull hbox and
vbox alike):

- Overfull: report only above 5pt.
- Underfull: report only at badness >= 5000. Badness 10000 on a `\raggedright`
  or `sloppypar` paragraph is expected, so mention it and move on.
- Sort by severity, overfull pt descending first, then underfull badness.
- Show the worst 10, then `+K more (below threshold or beyond top 10)`.

Attribute `lines A--B` to the file-stack top at the moment the warning fired.

---

## 6. Engine and bib detection

Magic comment, honored over auto-detection:

```
% !TEX program = xelatex
%!TEX TS-program = lualatex
```

Regex: `%\s*!TEX\s+(?:TS-)?program\s*=\s*(pdflatex|xelatex|lualatex|latexmk)`

Auto-detect from the preamble when there is no magic comment:

| Signal | Engine |
|---|---|
| `fontspec`, `unicode-math`, `\setmainfont`, `\setsansfont`, `\setmonofont` | xelatex |
| `xeCJK`, `ctex`, CJK characters in the source | xelatex |
| `\directlua`, `luacode`, `luatextra`, `luaotfload` | lualatex |
| nothing above | pdflatex |

Both `fontspec` and `\directlua` present means lualatex wins.

| Engine | latexmk flag |
|---|---|
| pdflatex | `-pdf` |
| xelatex | `-pdfxe` |
| lualatex | `-pdflua` |

Bib backend: `\usepackage[...]{biblatex}` or `\addbibresource` means biber;
`natbib` plus `\bibliographystyle` plus `\bibliography` means bibtex. Mismatches
worth warning about are biblatex loaded alongside a leftover
`\bibliographystyle`, and `\addbibresource` with no biblatex. latexmk picks the
backend itself; confirm which ran by checking for a `.bcf` in the outdir (biber)
versus a `.blg` naming BibTeX.

---

## 7. Figure blocks (opt-in `--figures` pass)

Grep the master and every `\input`'d file for:

- `\begin{tikzpicture}` … `\end{tikzpicture}`
- pgfplots `\begin{axis}` / `\begin{groupplot}`, normally nested inside a
  `tikzpicture`; the outermost `tikzpicture` is the block
- `\includestandalone{...}` and separately compiled `standalone` files

Harvest into the standalone wrapper from the parent preamble so colors and
macros resolve: `\usepackage` (with options), `\usetikzlibrary`,
`\usepgfplotslibrary`, `\pgfplotsset`, `\definecolor`, `\colorlet`,
`\newcommand`, `\renewcommand`, `\def`, `\tikzset`.

Splice-back safety, in order:

1. At extraction, store the file path, the exact body text (from
   `\begin{tikzpicture}` through `\end{tikzpicture}` inclusive), and
   `sha1(body)`.
2. Before editing, re-`Read` the file and recompute. Splice only if the stored
   body still occurs exactly once and its hash is unchanged.
3. Zero occurrences, more than one, or a changed hash means skip, and report
   `not spliced (source changed)`. Do not fall back to a fuzzy match.
4. Replace the body only. The surrounding `figure` env, `\caption`, `\label`,
   `\centering`, and any `\resizebox` / `\adjustbox` wrapper stay untouched.

---

## 8. Diff-vs-last-compile state

```
~/.claude/state/compile-latex/<hash>/last.json
```

`<hash>` is `sha1(absolute master path)[:12]`:

```bash
python3 -c 'import hashlib,sys;print(hashlib.sha1(sys.argv[1].encode()).hexdigest()[:12])' "$ABS"
```

Schema:

```json
{
  "ts": "2026-07-24T14:03:00Z",
  "master": "/Users/you/Library/CloudStorage/Dropbox-Personal/Apps/Overleaf/Proj/main.tex",
  "engine": "pdflatex",
  "bib_backend": "bibtex",
  "status": "ok",
  "undefined_refs": ["fig:foo"],
  "undefined_cites": ["Smith2020"],
  "overfull": [{"file": "sections/intro.tex", "lines": "102--104", "pt": 15.83}],
  "underfull": [{"file": "main.tex", "lines": "55--57", "badness": 10000}]
}
```

Refs and cites diff by key; boxes diff by `file:lines:kind`, ignoring the pt or
badness value, so a box shifting by a fraction of a point is not counted as new.
Report deltas as `+2 overfull, -1 undefined ref since last compile`.

Write atomically (temp file in the same directory, then rename) so an
interrupted run cannot leave a truncated baseline. Write on every parsed build,
failed ones included, with `status` recording which. If the file is absent or
unparseable, report `first compile (no baseline)` and write a fresh one.
