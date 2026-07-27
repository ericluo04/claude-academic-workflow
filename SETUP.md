# Setup

Everything here was extracted from one researcher's working configuration, so the skills assume that machine (an Apple-silicon Mac) in places. This file lists the prerequisites, where to install things, and every assumption you may need to adjust. The skills' logic never needs rewriting; the paths and helpers do.

## Prerequisites

- Claude Code.
- Quarto 1.10 or newer, for the slide skills.
- Node 22 or newer, for the two deck gates (`deck-check.mjs`, `stage-check.mjs`; they use node's built-in WebSocket, no npm install).
- A TeX distribution (MacTeX or TeX Live) with `latexmk`, for `compile-latex` and `tikz-iterate`; ghostscript for rasterizing.
- `uv`, for the self-contained Python helpers (`paper.py` and the `pdfread.py` PDF helper run via `uv run` shebangs).
- R with ggplot2 if you render the example decks (their figures are R chunks).

## Install

```bash
cp -R skills/* ~/.claude/skills/
cp agents/tikz-reviewer.md ~/.claude/agents/
mkdir -p ~/.claude/assets && cp -R slide-tooling ~/.claude/assets/quarto-yale
```

The skills refer to the slide tooling at `~/.claude/assets/quarto-yale/`, which is why the copy keeps that name. A new deck then starts with `quarto add ~/.claude/assets/quarto-yale --no-prompt` and `cp -R ~/.claude/assets/quarto-yale/mathjax .`, and uses `format: starter-revealjs`.

## What to adjust

- The Crossref and OpenAlex contact address. `skills/bibcheck/SKILL.md` and `skills/reading-papers/scripts/paper.py` carry `you@example.edu` placeholders; set a real address (or export `SCHOLAR_MAILTO`). The polite pools these APIs run for real contacts are faster and more reliable.
- API keys. `paper.py` and the Zotero launcher source `~/.claude/secrets/scholar.env` if it exists, with `S2_API_KEY`, `OPENALEX_API_KEY`, and optional `ZOTERO_API_KEY`/`ZOTERO_LIBRARY_ID`. All are optional; the tools degrade to the public pools without them.
- House style. `skills/research-talk/style/house.md`, `skills/teaching-lecture/style/house.md`, and `skills/slide-review/style/house.md` are stubs: your author line, closing-slide wording, palette rationale, and density calibration go there. The slide skills read those files for values.
- Your theme. `slide-tooling/starter-theme.scss` is deliberately plain and comments mark where taste goes; the example decks under `docs/` are that theme rendered as-is, so what you see is the starting point and the look is yours to build.

## Machine assumptions to know about

- A PDF helper at `~/.claude/assets/bin/pdfread.py` (text extraction and page rasterization). Several skills call it because this machine has no poppler, so the agent cannot open PDFs directly. Any PyMuPDF-style wrapper with `text`, `png`, and `pages` subcommands works; or substitute `pdftotext`/`pdftoppm` calls if you have them.
- Overleaf projects synced through Dropbox at `~/Library/CloudStorage/Dropbox*/Apps/Overleaf/`. The manuscript-finding skills glob that path; point them at wherever your `.tex` lives.
- An optional OCR pipeline for scanned PDFs on an HPC cluster, reachable as `ssh hpc`. Purely optional; the reading skills skip it if absent.
- macOS specifics: `textutil` for `.docx`, headless Chrome findable in the Playwright cache or `/Applications`, `CHROME_BIN` as the override.

## Not included

MCP servers and personal configuration are not part of this repo. The skills mention Zotero, Playwright, and a scholarly-search connector where they can use them, and degrade when they are absent; the README's "Things you may not know" section says what each integration adds. Nothing here contains credentials, and no skill requires an MCP server to run.

If you do add Playwright, register it twice: `playwright` running `npx @playwright/mcp@latest` for work behind a login, whose persistent profile keeps you signed in, and a second server named `playwright-isolated` running `npx @playwright/mcp@latest --isolated` for everything else, so two sessions never queue on the same browser profile.
