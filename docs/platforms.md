# Platforms cheat sheet

Side-by-side reference for Windows, macOS, and (where relevant) Linux. Every other doc in this folder defers here for platform-specific paths and commands.

## Toolchain matrix

| Tool | Windows | macOS | Linux |
|---|---|---|---|
| Home directory | `%USERPROFILE%` (e.g., `C:\Users\<you>`) | `$HOME` (e.g., `/Users/<you>`) | `$HOME` (e.g., `/home/<you>`) |
| Claude config dir | `%USERPROFILE%\.claude\` | `~/.claude/` | `~/.claude/` |
| Default shell | PowerShell 5.1 (or PowerShell 7) | zsh | bash |
| Package manager | `winget` (built-in) or `scoop` | Homebrew (`brew`) | `apt` / `dnf` / `pacman` |
| Node.js install | `winget install OpenJS.NodeJS.LTS` | `brew install node` | `sudo apt install nodejs npm` |
| Python (3.12+) install | `winget install Python.Python.3.12` | `brew install python@3.12` | `sudo apt install python3.12` |
| `uv` / `uvx` install | `winget install astral-sh.uv` | `brew install uv` | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| git | `winget install Git.Git` | preinstalled or `brew install git` | `sudo apt install git` |
| GitHub CLI | `winget install GitHub.cli` | `brew install gh` | `sudo apt install gh` |
| LaTeX distribution | MiKTeX (`winget install MiKTeX.MiKTeX`) | MacTeX (`brew install --cask mactex`) or BasicTeX | TeX Live (`sudo apt install texlive-full`) |
| PDF to PNG | MiKTeX bundles `pdftoppm.exe`; or `winget install poppler` | `brew install poppler` | `sudo apt install poppler-utils` |
| Dropbox install | `winget install Dropbox.Dropbox` | `brew install --cask dropbox` | Dropbox `.deb` from dropbox.com |

See [clis.md](clis.md) for a recommended install order.

## Dropbox directory location

| OS | Path | Notes |
|---|---|---|
| Windows | `%USERPROFILE%\Dropbox\` | Stable across versions |
| macOS (legacy) | `~/Dropbox/` | Older Dropbox releases |
| macOS (CloudStorage) | `~/Library/CloudStorage/Dropbox/` | Newer releases route here; create a symlink `ln -s ~/Library/CloudStorage/Dropbox ~/Dropbox` if tooling expects legacy |
| Linux | `~/Dropbox/` | Stable |

## Overleaf project convention

Every paper lives at `<Dropbox>/Apps/Overleaf/<Project Name>/`. See [overleaf-dropbox.md](overleaf-dropbox.md) for the sync setup.

| OS | Resolved example |
|---|---|
| Windows | `C:\Users\<you>\Dropbox\Apps\Overleaf\ProjectA\` |
| macOS | `/Users/<you>/Library/CloudStorage/Dropbox/Apps/Overleaf/ProjectA/` |

In `personal_config.json` capture the root as `paths.overleaf_root` (Windows) and `paths.overleaf_root_mac` (macOS) so skills resolve project paths per-OS.

## Path-separator conventions

- Windows accepts both `\` and `/`. Forward slashes work in most CLIs (git, node, python) and avoid escape-character pain in JSON/Python strings.
- Skill code should use `pathlib.Path` (Python) or `path.join` (Node) to build paths. Never hard-code `\\` or `/` in shared skill source.
- In Markdown docs use forward slashes for cross-platform clarity; use `<HOME>` as a portable home-dir placeholder.

## Node MCP launch path workaround

MCP servers launched via `npx` or `node` choke on Windows paths containing spaces (e.g., `C:\Program Files\nodejs\node.exe`). Mitigations:

- **Windows**: install Node via `winget` (lands in `C:\Program Files\nodejs\` — still has a space). Use the 8.3 short path in MCP config: `C:\PROGRA~1\nodejs\node.exe`. Confirm with `cmd /c "for %I in (\"C:\Program Files\nodejs\node.exe\") do @echo %~sI"`.
- **macOS / Linux**: no workaround needed; Homebrew installs to `/opt/homebrew/bin/node` (Apple Silicon) or `/usr/local/bin/node` (Intel).

See [mcps.md](mcps.md) for example MCP entries that apply this workaround.

## PowerShell vs bash command differences

| Concept | PowerShell 5.1 | bash / zsh |
|---|---|---|
| Set env var (session) | `$env:FOO = "bar"` | `export FOO=bar` |
| Set env var (persistent, user) | `setx FOO "bar"` | `echo 'export FOO=bar' >> ~/.zshrc` |
| Read env var | `$env:FOO` | `$FOO` |
| Discard stderr | `2>$null` | `2>/dev/null` |
| Discard all output | `*>$null` | `>/dev/null 2>&1` |
| Command chaining (AND) | `A; if ($?) { B }` (PS 5.1) or `A && B` (PS 7+) | `A && B` |
| Conditional | `if (Test-Path foo) { ... }` | `if [ -f foo ]; then ... fi` |
| For loop | `foreach ($x in Get-ChildItem) { ... }` | `for x in *; do ... done` |
| HTTP POST | `Invoke-RestMethod -Method Post -Uri ... -Body @{k="v"}` | `curl -X POST ... -d 'k=v'` |
| Here-string (literal) | `@'...'@` with closing `'@` at column 0 | `<<'EOF' ... EOF` |

When a doc shows a curl one-liner, the PowerShell equivalent uses `Invoke-RestMethod` or `Invoke-WebRequest`; do not paste curl into PowerShell unless `curl.exe` is explicitly invoked.

## PDF → PNG (`pdftoppm`)

Several visual-review skills rasterize compiled PDFs to inspect them. The standard tool is `pdftoppm` from `poppler-utils`.

| OS | Source |
|---|---|
| Windows | MiKTeX bundles `pdftoppm.exe` under `C:\Users\<you>\AppData\Local\Programs\MiKTeX\miktex\bin\x64\`. Otherwise `winget install poppler`. |
| macOS | `brew install poppler` |
| Linux | `sudo apt install poppler-utils` |

Verify: `pdftoppm -v` (the version banner is printed to stderr; both `pdftoppm -v 2>&1 | head -1` and the PowerShell equivalent work).

## Verifying a fresh install

```powershell
# Windows PowerShell
git --version; gh --version; node --version; python --version; uv --version; latexmk -v
```

```bash
# macOS / Linux
git --version && gh --version && node --version && python --version && uv --version && latexmk -v
```

Every other doc in this folder uses this table as the source of truth — if a command in another doc looks platform-specific, cross-reference here.
