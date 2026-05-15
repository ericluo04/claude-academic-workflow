# LaTeX setup

Several skills compile or read LaTeX: `/slide-excellence`, `/create-lecture`, `/tikz-iterate`, `/posterskill`, `/replication-package`, `/audit-reproducibility`, `/referee-response`, `/draft`. A working TeX install is non-optional if you use any of these.

## 1. Install

### Windows — MiKTeX

```powershell
winget install MiKTeX.MiKTeX
```

MiKTeX installs ~200 MB initially and downloads additional packages on first use ("package-on-demand"). On first compile of a paper it may pause to fetch missing packages; click "Install" or set `Always install missing packages` in the MiKTeX Console once.

### macOS — MacTeX (full, recommended)

```bash
brew install --cask mactex
```

~5 GB download but it's all-inclusive — no on-demand fetching, no surprises mid-compile. After install, open a new shell so `/Library/TeX/texbin` lands on `PATH`.

### macOS — BasicTeX (minimal)

```bash
brew install --cask basictex
sudo tlmgr update --self
sudo tlmgr install latexmk biblatex biber  # plus whatever you actually need
```

~100 MB initial; you install packages manually with `tlmgr install <pkg>`. Use this if disk is tight.

### Linux — TeX Live

```bash
sudo apt install texlive-full
# or, smaller:
sudo apt install texlive-latex-extra latexmk biber
```

`texlive-full` is ~5 GB and matches MacTeX in coverage.

## 2. Build with `latexmk`

Always invoke `latexmk` rather than `pdflatex` directly — it handles bibliography passes, multi-pass references, and cleanup.

```bash
latexmk -pdf paper.tex      # build
latexmk -c paper.tex        # clean intermediate files
latexmk -C paper.tex        # clean everything including PDF
```

For continuous rebuilds while editing:

```bash
latexmk -pdf -pvc paper.tex
```

## 3. PDF → PNG (for slide review skills)

`/slide-excellence` and `/tikz-iterate` rasterize PDF pages to inspect them visually. They use `pdftoppm`.

| OS | Source |
|---|---|
| Windows | MiKTeX bundles `pdftoppm.exe`, or `winget install poppler` |
| macOS | `brew install poppler` |
| Linux | `sudo apt install poppler-utils` |

## 4. Skills that need LaTeX

| Skill | What it does with LaTeX |
|---|---|
| `/slide-excellence` | Compiles Beamer decks, rasterizes pages, reviews visuals + pedagogy |
| `/create-lecture` | Scaffolds new Beamer `.tex` from sources |
| `/tikz-iterate` | Compiles isolated TikZ snippets and iterates on visual feedback |
| `/posterskill` | Renders a conference poster from HTML→PDF (LaTeX optional for fallback) |
| `/replication-package` | Reads paper `main.tex` to extract claims and verify numbers |
| `/audit-reproducibility` | Compares numbers in `main.tex` against code outputs |
| `/referee-response` | Reads `main*.tex` to pin location references (Section 3, Footnote 7) |
| `/draft` | Writes new prose into the project's `.tex` files in your voice |

## 5. Verify

```bash
latexmk -v
pdftoppm -v
```

Both should print version strings. If `latexmk` is missing on macOS after a BasicTeX install, run `sudo tlmgr install latexmk`.

A more thorough check is to compile a minimal `.tex`:

```bash
cat > /tmp/hello.tex <<'EOF'
\documentclass{article}
\begin{document}
hello world
\end{document}
EOF
latexmk -pdf -outdir=/tmp /tmp/hello.tex
```

On Windows the equivalent in PowerShell:

```powershell
@'
\documentclass{article}
\begin{document}
hello world
\end{document}
'@ | Out-File -Encoding utf8 $env:TEMP\hello.tex
latexmk -pdf -outdir=$env:TEMP $env:TEMP\hello.tex
```

Both should produce `hello.pdf` without errors.
