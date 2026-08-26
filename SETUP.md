# Setup

Everything here was extracted from one researcher's working configuration, so the skills assume that machine (an Apple-silicon Mac) in places. This file lists the prerequisites, where to install things, and every assumption you may need to adjust. The skills' logic never needs rewriting; the paths and helpers do.

## Prerequisites

- Claude Code.
- Quarto 1.10 or newer, for the slide skills.
- Node 22 or newer, for the two deck gates (`deck-check.mjs`, `stage-check.mjs`; they use node's built-in WebSocket, no npm install).
- A TeX distribution (MacTeX or TeX Live) with `latexmk`, for `compile-latex` and `tikz-iterate`; ghostscript for rasterizing.
- `uv`, for the self-contained Python helpers (`paper.py` and the `pdfread.py` PDF helper run via `uv run` shebangs).
- R 4.1 or newer. The `synthetic-control` script template uses the native pipe (`|>`), which older R does not parse. Add ggplot2 and knitr if you render the example decks (their figures are R chunks run through the knitr engine).
- R with the estimation packages, for the causal-inference skills. Their script templates are the reference implementations, and each one loads only what its own design needs, so install per skill rather than all at once. The CRAN side spans `fixest`, `did`, `didimputation`, `staggered`, `bacondecomp`, `TwoWayFEWeights`, `HonestDiD`, `rdrobust`, `rddensity`, `rdlocrand`, `rdpower`, `rdmulti`, `ivreg`, `ivmodel`, `ivDiag`, `ivmte`, `Synth`, `tidysynth`, `scpi`, `SCtools`, `fect`, `CausalImpact`, `grf`, `policytree`, `WeightIt`, `sensemakr`, `estimatr`, `marginaleffects`, `randomizr`, `DeclareDesign`, `ri2`, `qte`, `clubSandwich`, `summclust`, `fwildclusterboot`, `ShiftShareSE`, `bpbounds`, `dplyr`, and `zoo`. Six live on GitHub and need `remotes::install_github()`: `ebenmichael/augsynth`, `jonathandroth/pretrends`, `synth-inference/synthdid`, `kylebutts/ssaggregate`, `kwuthrich/scinference`, and `kolesarm/ManyIV`. Each skill's `references/details.md` carries a package index with the version the template was written against and the API quirks worth knowing.

## Install

```bash
mkdir -p ~/.claude/skills ~/.claude/agents ~/.claude/assets ~/.claude/output-styles
cp -R skills/* ~/.claude/skills/
cp agents/tikz-reviewer.md ~/.claude/agents/
cp -R slide-tooling ~/.claude/assets/quarto-yale
cp output-styles/concise-research.md ~/.claude/output-styles/
```

The skills refer to the slide tooling at `~/.claude/assets/quarto-yale/`, which is why the copy keeps that name. A new deck then starts with `quarto add ~/.claude/assets/quarto-yale --no-prompt` and `cp -R ~/.claude/assets/quarto-yale/{mathjax,fonts} .`, and uses `format: starter-revealjs`.

## What to adjust

- The `you@example.edu` placeholder, in three files. `skills/bibcheck/SKILL.md` and `skills/reading-papers/scripts/paper.py` use it as the Crossref and OpenAlex contact address; set a real one (or export `SCHOLAR_MAILTO`). The polite pools these APIs run for real contacts are faster and more reliable. `skills/research-talk/assets/starter-template.qmd` uses it on the closing contact slide.
- API keys. `paper.py` and the Zotero launcher source `~/.claude/secrets/scholar.env` if it exists, with `S2_API_KEY`, `OPENALEX_API_KEY`, and optional `ZOTERO_API_KEY`/`ZOTERO_LIBRARY_ID`. All are optional; the tools degrade to the public pools without them.
- House style. `skills/research-talk/style/house.md`, `skills/teaching-lecture/style/house.md`, and `skills/slide-review/style/house.md` are stubs: your author line, closing-slide wording, palette rationale, and density calibration go there. The slide skills read those files for values.
- The output style. Copying `output-styles/concise-research.md` installs it, and nothing selects it until you set `"outputStyle": "concise-research"` in `~/.claude/settings.json` and start a new session. The README says what belongs in a style rather than in `CLAUDE.md`.
- Your theme. `slide-tooling/starter-theme.scss` is deliberately plain and comments mark where taste goes; the example decks under `docs/` are that theme rendered as-is, so what you see is the starting point and the look is yours to build.

## Machine assumptions to know about

- A PDF helper at `~/.claude/assets/bin/pdfread.py` (text extraction and page rasterization). Several skills call it because this machine has no poppler, so the agent cannot open PDFs directly. Any PyMuPDF-style wrapper with `text`, `png`, and `pages` subcommands works; or substitute `pdftotext`/`pdftoppm` calls if you have them.
- Overleaf projects synced through Dropbox at `~/Library/CloudStorage/Dropbox*/Apps/Overleaf/`. The manuscript-finding skills glob that path; point them at wherever your `.tex` lives.
- An optional OCR pipeline for scanned PDFs on an HPC cluster, reachable as `ssh hpc`. Purely optional; the reading skills skip it if absent.
- macOS specifics: `textutil` for `.docx`, headless Chrome findable in the Playwright cache or `/Applications`, `CHROME_BIN` as the override.

## Not included

MCP servers and personal configuration are not part of this repo. The skills mention Zotero, Playwright, and a scholarly-search connector where they can use them, and degrade when they are absent; the README's "Things you may not know" section says what each integration adds. Nothing here contains credentials, and no skill requires an MCP server to run.

If you do add Playwright, register it twice: `playwright` running `npx @playwright/mcp@latest` for work behind a login, whose persistent profile keeps you signed in, and a second server named `playwright-isolated` running `npx @playwright/mcp@latest --isolated` for everything else, so two sessions never queue on the same browser profile.
