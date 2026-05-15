# CLI inventory

Recommended install order. Each tool has a one-line install per OS and a `--version` check. Cross-reference [platforms.md](platforms.md) for the underlying package manager.

## 1. git

| | Install | Verify |
|---|---|---|
| Windows | `winget install Git.Git` | `git --version` |
| macOS | preinstalled, or `brew install git` | `git --version` |
| Linux | `sudo apt install git` | `git --version` |

Why it matters: every skill that touches a paper assumes the paper is in git; the workflow repo itself is git-tracked.

## 2. gh (GitHub CLI)

| | Install |
|---|---|
| Windows | `winget install GitHub.cli` |
| macOS | `brew install gh` |
| Linux | `sudo apt install gh` |

Verify: `gh --version`. After install, run `gh auth login` once and accept the browser prompt. The orchestration repo uses `gh secret set` for the Telegram token (see [telegram-setup.md](telegram-setup.md)).

## 3. Node.js (≥20) and npm

| | Install |
|---|---|
| Windows | `winget install OpenJS.NodeJS.LTS` |
| macOS | `brew install node` |
| Linux | `sudo apt install nodejs npm` (verify version; consider `nvm` if your distro ships Node <20) |

Verify: `node --version` (should be `v20.x` or newer), `npm --version`. Most of the stdio MCPs and Playwright depend on this.

## 4. Python (≥3.12), uv, uvx

| | Install Python | Install uv |
|---|---|---|
| Windows | `winget install Python.Python.3.12` | `winget install astral-sh.uv` |
| macOS | `brew install python@3.12` | `brew install uv` |
| Linux | `sudo apt install python3.12` | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |

Verify: `python --version` and `uv --version`. `uvx` ships with `uv` and is how the arxiv / semantic-scholar / zotero MCPs launch (see [mcps.md](mcps.md)).

## 5. LaTeX

See [tex-setup.md](tex-setup.md) for the full story. Summary:

| | Install |
|---|---|
| Windows | `winget install MiKTeX.MiKTeX` |
| macOS | `brew install --cask mactex` (full) or `brew install --cask basictex` (minimal) |
| Linux | `sudo apt install texlive-full` |

Verify: `latexmk -v`.

## 6. R (optional, for econometric workflows)

| | Install |
|---|---|
| Windows | `winget install RProject.R` |
| macOS | `brew install --cask r` |
| Linux | `sudo apt install r-base` |

Verify: `R --version`. Needed by `/audit-reproducibility`, `/referee2`, `/review-paper-code` when the underlying project uses R. Skippable if all your code is Python.

## 7. Cursor or VS Code

| | Install Cursor | Install VS Code |
|---|---|---|
| Windows | `winget install Anysphere.Cursor` | `winget install Microsoft.VisualStudioCode` |
| macOS | `brew install --cask cursor` | `brew install --cask visual-studio-code` |
| Linux | download from `cursor.sh` | `sudo snap install code --classic` |

Either works. The Claude Code CLI integrates with both via the `code`/`cursor` command.

## 8. Optional but recommended

### pandoc

Convert between document formats — useful for `/draft` exports and `/posterskill`.

| | Install |
|---|---|
| Windows | `winget install JohnMacFarlane.Pandoc` |
| macOS | `brew install pandoc` |
| Linux | `sudo apt install pandoc` |

Verify: `pandoc --version`.

### jq

JSON parsing on the command line — handy for inspecting MCP responses and `today_brief.json`.

| | Install |
|---|---|
| Windows | `winget install jqlang.jq` |
| macOS | `brew install jq` |
| Linux | `sudo apt install jq` |

Verify: `jq --version`.

### ripgrep

Faster `grep` over big codebases. The Claude Code Grep tool uses ripgrep under the hood; installing it system-wide lets you use it in your own shells too.

| | Install |
|---|---|
| Windows | `winget install BurntSushi.ripgrep.MSVC` |
| macOS | `brew install ripgrep` |
| Linux | `sudo apt install ripgrep` |

Verify: `rg --version`.

## Full verification

```powershell
# Windows
git --version; gh --version; node --version; python --version; uv --version; latexmk -v; pandoc --version; jq --version; rg --version
```

```bash
# macOS / Linux
for c in git gh node python uv latexmk pandoc jq rg; do
  echo "=== $c ==="
  $c --version 2>&1 | head -1
done
```

If any line errors, revisit the install steps above for that tool.
