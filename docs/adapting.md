# Adapting this repo to your workflow

How to fork, install, and customize this workflow for your own research practice. Assumes you've worked through [platforms.md](platforms.md) and have a baseline toolchain.

## 1. Fork the repos

There are two repos to fork:

- `claude-academic-workflow` (this repo) — skills, sub-agents, hooks, installer.
- `lan-daily-brief` — the orchestration repo with GitHub Actions cron, Telegram polling, weekly recap.

```bash
gh repo fork <owner>/claude-academic-workflow --clone
gh repo fork <owner>/lan-daily-brief --clone
```

Both forks should be in your own GitHub account. The skills repo runs locally; the orchestration repo runs in GitHub Actions on your fork.

## 2. Clone and install

```bash
cd claude-academic-workflow
```

### Windows

```powershell
.\scripts\install.ps1
```

### macOS / Linux

```bash
./scripts/install.sh
```

What the installer does:

1. Copies `skills/`, `agents/`, and `hooks/` into `~/.claude/` (`%USERPROFILE%\.claude\` on Windows).
2. Renders `settings.example.json` into `~/.claude/settings.json` with per-OS path defaults.
3. Creates `~/.claude/state/personal_config.json` from the template (empty placeholders).
4. Runs `claude mcp list` and prints which MCPs are connected, missing, or erroring.
5. Prints a checklist of next steps.

The installer is idempotent — safe to rerun after pulling updates.

## 3. Fill in `personal_config.json`

Open `~/.claude/state/personal_config.json` and fill in:

- **Identity**: your name, email, institutional affiliation.
- **Paths**: `paths.overleaf_root` and `paths.overleaf_root_mac` per [overleaf-dropbox.md](overleaf-dropbox.md).
- **Notion**: tasks DB / data-source / project page IDs per [notion-setup.md](notion-setup.md).
- **Telegram**: `chat_id` and `bot_handle` (NOT the token) per [telegram-setup.md](telegram-setup.md).
- **Projects**: an entry per active research project (name, type, abbreviation, project page ID, optional Zotero collection key).

Never put secrets in this file. Token-shaped values live in env vars or `gh secret set`.

## 4. Set up the MCPs

Walk through [mcps.md](mcps.md). At minimum: arxiv, semantic-scholar, openalex, zotero, notion. Skip `microsoft-365` if your tenant blocks it (see [outlook-gmail.md](outlook-gmail.md) for the iCal workaround).

Two install paths to keep separate: stdio MCPs run locally and are installed with `claude mcp add` (arxiv, semantic-scholar, openalex, zotero, playwright, github); claude.ai web-portal connectors are added through the browser at the claude.ai Settings → Connectors page (Gmail, Google Drive, Hugging Face, Scholar Gateway, and the lifestyle set). Notion is a CLI-added HTTP gateway — separate again.

Verify with `claude mcp list`.

## 5. Set up orchestration

In your fork of `lan-daily-brief`:

1. Set the GitHub Actions secrets:
   ```bash
   gh secret set TELEGRAM_BOT_TOKEN
   gh secret set NOTION_TOKEN              # if using internal integration
   gh secret set CALENDAR_ICS_URLS         # comma-separated
   gh secret set ANTHROPIC_API_KEY
   ```
2. Edit `.github/workflows/*.yml` to set your cron times (defaults are UTC; adjust for your timezone).
3. Push and watch the Actions tab. The first run will likely error on missing config — fix and re-run.

See the `lan-daily-brief` README for details on each workflow file.

## 6. First test

```text
/daily-brief --hours 4
```

Should rank your open tasks and push the top few to Telegram.

```text
/log-todo "test the workflow"
```

Should create a row in the Tasks DB and return the URL.

```text
/tikz-iterate "\draw (0,0) -- (1,1);"
```

Should compile a TikZ snippet and return a rendered PNG.

If any of these fail, run `claude mcp list` first; missing MCPs are the most common cause.

## 7. Customizing

### Add a new project

1. Create the Notion project page (Research → New page).
2. Add an entry to `personal_config.json` under `projects`:
   ```json
   "ProjectC": {
     "type": "empirical",
     "abbreviation": "PC",
     "notion_page_id": "<page-id>",
     "zotero_collection_key": "ABC123"
   }
   ```
3. Restart any running Claude session so the config is reloaded.

### Swap voice-style reference for `/draft`

The `/draft` skill reads a "writing style reference" file pointed to in its `SKILL.md`. To use your own voice rather than the bundled examples:

1. Drop one or two of your own clean `.tex` files (intro, lit review) somewhere stable like `~/.claude/state/style-examples/`.
2. Edit `~/.claude/skills/draft/SKILL.md` and update the reference path.
3. Run `/draft <something simple>` and review the output for tone match.

### Add a new sub-agent

Sub-agents live in `~/.claude/agents/` as standalone `.md` files. Each defines a narrow-focus reviewer (e.g., `pedagogy-reviewer.md`). To add one:

1. Copy an existing agent file (e.g., `agents/proofreader.md`) as a starting template.
2. Edit the system prompt to describe the new lens.
3. Reference it from a parent skill via the `Task` tool's `subagent_type` field.

### Write a new skill

Use the bundled `/skill-creator` skill:

```text
/skill-creator "I want a skill that does X"
```

It will scaffold `SKILL.md`, suggest evals, and write a stub. After iteration, drop the result in `~/.claude/skills/<name>/`.

For deeper guidance see Anthropic's skill-authoring docs and the existing skills in this repo — `/litreview` and `/cite` are reasonable templates for MCP-heavy skills; `/draft` is a good template for an in-place file-editing skill.
