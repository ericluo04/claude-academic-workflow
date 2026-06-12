# Setup

This is the full step-by-step. Plan on ~45 minutes of active work the first time, mostly waiting for installers and OAuth redirects. Skills will not function until at least Notion, Telegram, and the core MCPs are configured.

Every step has a checkbox so you can resume if you get interrupted.

---

## 1. Prerequisites

- [ ] Install Claude Code (latest). See [docs/clis.md](docs/clis.md) for the OS-specific install command.
- [ ] Install git and the GitHub CLI (`gh`). [docs/clis.md](docs/clis.md).
- [ ] Install Node.js >= 20. [docs/clis.md](docs/clis.md).
- [ ] Install Python >= 3.12 and `uv`. [docs/clis.md](docs/clis.md).
- [ ] Install LaTeX — MiKTeX on Windows, MacTeX or BasicTeX on macOS. [docs/tex-setup.md](docs/tex-setup.md).
- [ ] Authenticate the GitHub CLI: `gh auth login`. The GitHub MCP reuses this token.

Optional but recommended: pandoc, jq, ripgrep, R. [docs/clis.md](docs/clis.md).

---

## 2. Clone the repo

```bash
# Windows or macOS — same command
git clone https://github.com/ericluo04/claude-academic-workflow.git
cd claude-academic-workflow
```

- [ ] Clone is complete and `cd`'d into.

---

## 3. Run the installer

The installer copies `skills/`, `agents/`, `hooks/` into `~/.claude/`, renders `config/settings.example.json` into your real `~/.claude/settings.json` with paths normalized for your OS, and seeds `~/.claude/state/personal_config.json` from the template with placeholders.

**Windows (PowerShell, run as your user, not admin):**

```powershell
.\scripts\install.ps1
```

**macOS (bash or zsh):**

```bash
./scripts/install.sh
```

What the installer does, in order:

1. Detects OS and confirms Claude Code is installed.
2. Backs up any existing `~/.claude/skills/`, `~/.claude/agents/`, `~/.claude/hooks/` to `~/.claude/_backup_<timestamp>/`.
3. Copies the repo's `skills/`, `agents/`, `hooks/` into `~/.claude/`.
4. Renders `config/settings.example.json` -> `~/.claude/settings.json` with `${HOME}` placeholders replaced by your real home directory.
5. If `~/.claude/state/personal_config.json` does not exist, copies `skills/_config/personal_config.example.json` to it. If it does exist, leaves it alone.
6. Prints a summary of which MCPs are wired and which still require OAuth or API keys.

What it does **not** do: install MCPs, set Telegram secrets, configure Notion. Those come below. See [docs/adapting.md](docs/adapting.md) for the full breakdown of what the installer touches.

- [ ] Installer completed without errors.
- [ ] `~/.claude/state/personal_config.json` exists (check with `ls` or `Get-ChildItem`).

---

## 4. Edit `~/.claude/state/personal_config.json`

Open the file in your editor and fill in every placeholder you can. Most fields you cannot fill in yet — Notion IDs come from step 5, Telegram chat ID from step 6. The minimum for a first smoke test is `user.name` and one entry in `projects`.

Field-by-field reference:

- `user.name`, `user.personal_email`, `user.university_email` — free-text.
- `user.voice_style_ref` — absolute path to a `.tex` file in your writing voice, used by `/draft`. Leave as empty string if you do not have one yet.
- `notion.tasks_data_source_id`, `notion.tasks_db_id`, `notion.weekly_agenda_page_id`, `notion.tasks_parent_page_id` — fill from [docs/notion-setup.md](docs/notion-setup.md).
- `notion.project_pages` — map of `ProjectName -> Notion page UUID`. One entry per active research project. [docs/notion-setup.md](docs/notion-setup.md).
- `notion.off_limits_pages` — UUIDs that `/notion-log` must refuse to write to (personal pages, weekly agenda, the Tasks DB itself).
- `telegram.bot_username` — your bot's `@handle` from BotFather. [docs/telegram-setup.md](docs/telegram-setup.md).
- `telegram.chat_id` — your numeric chat ID. [docs/telegram-setup.md](docs/telegram-setup.md).
- `paths.overleaf_root` (Windows) / `paths.overleaf_root_mac` (macOS) — root of your Overleaf-on-Dropbox tree. [docs/overleaf-dropbox.md](docs/overleaf-dropbox.md).
- `paths.research_root`, `paths.scratch` — your research and scratch directories.
- `projects` — array of project records. Each has `name`, `kind` (e.g. `research-paper`, `dissertation-chapter`), `overleaf_subdir`, `bib_file`, `main_tex`.

The bot token does **not** go in this file. It only lives in your shell environment or in GitHub Actions secrets — see step 6.

- [ ] `user.*` filled in.
- [ ] At least one project record in `projects`.

---

## 5. Set up the Notion workspace

Notion is the backbone — `/log-todo`, `/notion-log`, `/capture`, `/task-pulse`, `/notion-meeting-notes`, and `/daily-brief` all read or write to it. Full walkthrough in [docs/notion-setup.md](docs/notion-setup.md). Summary:

1. Duplicate the template workspace (link in [docs/notion-setup.md](docs/notion-setup.md)) into your Notion account.
2. Create an internal integration: Notion Settings -> Integrations -> "+ New" -> name it -> Internal -> copy the secret.
3. Share the parent page with the integration (the integration sees only what you explicitly share).
4. Extract page and database UUIDs from URLs (last 32 hex chars).
5. Paste the UUIDs into the relevant fields of `~/.claude/state/personal_config.json`.

- [ ] Notion template duplicated.
- [ ] Integration created and connected to the parent page.
- [ ] All Notion UUIDs in `personal_config.json` populated.

---

## 6. Set up the Telegram bot

The bot pushes your morning brief and receives your one-line replies (`1 done`, `add: email Heather`, etc.). Full walkthrough in [docs/telegram-setup.md](docs/telegram-setup.md). Summary:

1. Open Telegram, search `@BotFather`, run `/newbot`, pick a name and handle, save the bot token.
2. Message your new bot once from your personal Telegram (anything — `hi`).
3. Hit `https://api.telegram.org/bot<TOKEN>/getUpdates` in a browser, grab `result[0].message.chat.id`.
4. Put `chat_id` (numeric) into `personal_config.json`.
5. Put `bot_token` into **GitHub Actions secrets only**: `gh secret set TELEGRAM_BOT_TOKEN -R <your-fork-of-lan-daily-brief>`. Or for local-only testing, `export TELEGRAM_BOT_TOKEN=<token>` in your shell (Windows: `$env:TELEGRAM_BOT_TOKEN = "<token>"`).

**The bot token never goes in `personal_config.json` or any committed file.** That file lives on disk and is gitignored, but the orchestration repo's secrets layer is the canonical home for the token.

- [ ] Bot created with BotFather.
- [ ] `telegram.chat_id` filled in.
- [ ] Bot token stored in shell env or GitHub Actions secrets (and verified not in any file).

---

## 7. Install MCPs

Eight MCP servers connect Claude Code to Notion, Zotero, arXiv, Semantic Scholar, OpenAlex, Playwright, GitHub, and Google Drive. Two install paths: stdio MCPs are installed locally via `claude mcp add`; claude.ai web-portal connectors (Google Drive plus optional Gmail, Hugging Face, Scholar Gateway) are added through the browser at the claude.ai Settings → Connectors page. Per-MCP install commands, secrets, and OAuth flows are in [docs/mcps.md](docs/mcps.md). Checklist:

- [ ] `arxiv` installed (`uvx arxiv-mcp-server`). No secrets.
- [ ] `semantic-scholar` installed. No secrets.
- [ ] `openalex` installed. Needs `OPENALEX_API_KEY` (free, email-based).
- [ ] `zotero` installed. Needs `ZOTERO_API_KEY`, `ZOTERO_LIBRARY_ID`, `ZOTERO_LIBRARY_TYPE`.
- [ ] `playwright` installed. No secrets.
- [ ] `github` installed. Reuses `gh auth token`.
- [ ] `notion` connected via browser OAuth.
- [ ] `google-drive` connected via browser OAuth (optional but recommended).

Verify each MCP shows up: `claude mcp list` should print all eight as `connected`.

---

## 8. Set up Outlook -> Gmail forwarding and calendar iCal

If your university uses Microsoft 365, the M365 MCP is usually blocked by tenant admin. Workaround: forward Outlook to a personal Gmail, and publish your Outlook calendar as a secret iCal URL. Walkthrough in [docs/outlook-gmail.md](docs/outlook-gmail.md).

- [ ] University email forwards to personal Gmail (or POP/IMAP add-account if forwarding is admin-blocked).
- [ ] Outlook calendar published as iCal; URL saved for the next step.

---

## 9. Set up Overleaf + Dropbox

Overleaf has native Dropbox sync — no custom code needed. Convention: every paper project lives at `<Dropbox>/Apps/Overleaf/<Project Name>/`. Walkthrough in [docs/overleaf-dropbox.md](docs/overleaf-dropbox.md).

- [ ] Dropbox installed and synced.
- [ ] At least one Overleaf project linked via Project menu -> Sync -> Dropbox.
- [ ] `paths.overleaf_root` (and `..._mac`) in `personal_config.json` points to the right directory.

---

## 10. Fork the orchestration repo

The scheduled tasks (morning brief, capture poll every 30 min, Friday recap, Weekly Agenda reconcile, meeting-notes ingest) can run as GitHub Actions cron jobs in a separate repo — this is Pattern B in [orchestration/README.md](orchestration/README.md). The recommended alternative (Pattern A, a Claude Code cloud routine) needs no fork and no Actions secrets; see that README before deciding. The steps below cover Pattern B.

1. Fork `ericluo04/lan-daily-brief` to your GitHub.
2. Populate GitHub Actions secrets in your fork:
   - `NOTION_TOKEN` (the integration secret from step 5)
   - `NOTION_TASKS_DB_ID`
   - `NOTION_TASKS_PAGE_ID`
   - `TELEGRAM_BOT_TOKEN`
   - `TELEGRAM_CHAT_ID`
   - `CALENDAR_ICS_URLS` (optional — comma-separated, from step 8)
3. Enable Actions in the fork (Settings -> Actions -> Allow all).
4. Trigger the morning-brief workflow manually once to verify it works end-to-end.

- [ ] Fork created.
- [ ] All GitHub Actions secrets set.
- [ ] First manual workflow run succeeded.

---

## 11. Smoke test

Open Claude Code in any directory and run, in order:

1. `/log-todo "test task — delete me after smoke test"` — should create a task in the Notion Tasks DB and print the new page URL.
2. `/daily-brief --hours 2` — should rank open tasks, pick a handful that fit in 2 hours, and push to Telegram. Check your Telegram client.
3. `/tikz-iterate` — feed it a deliberately broken TikZ snippet (e.g. two overlapping nodes). The skill should compile, render, review with the `tikz-reviewer` agent, and converge to a fix within 3-5 iterations.

Expected outcomes:

- Notion page URL printed for the test todo. Delete the test task from Notion afterward.
- Telegram message arrives with a numbered task list.
- TikZ PNG is produced under the working directory; reviewer returns APPROVED.

- [ ] All three smoke tests pass.

---

## 12. Troubleshooting

**MCP not found / not connected.** Run `claude mcp list`; if it shows `disconnected`, restart Claude Code, then check the per-MCP install in [docs/mcps.md](docs/mcps.md). On Windows, Node-based MCPs sometimes fail because of spaces in the install path — use the 8.3 short path (`C:\PROGRA~1\nodejs\node.exe`) per [docs/platforms.md](docs/platforms.md).

**Notion permission denied.** The integration secret is correct, but you forgot to share the parent page with the integration. Open the page in Notion -> "..." -> Connections -> Add the integration.

**Telegram message did not arrive.** Test with `curl -s -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" -d "chat_id=<ID>&text=hello"`. If that fails: bad token. If it succeeds but the skill still does not push: the orchestration repo's secret is stale, or the chat ID in `personal_config.json` is wrong. See [docs/telegram-setup.md](docs/telegram-setup.md).

**Hook did not fire.** Hooks are registered in `~/.claude/settings.json` — check the `PreCompact` / `PostCompact` / `PostToolUse` entries match the absolute paths the installer wrote. If you moved your `~/.claude/` directory, re-run the installer.

**`/tikz-iterate` cannot find `pdftoppm`.** MiKTeX and MacTeX both ship it, but some BasicTeX installs do not — `sudo tlmgr install poppler` on macOS, or install [poppler for Windows](https://github.com/oschwartz10612/poppler-windows) and add to PATH.

**Hardcoded path errors in skill output.** A skill is reading from `personal_config.json` and a field is empty or has the placeholder still. Open the config and fill it in.

---

## 13. Maintenance

**Pulling updates.**

```bash
cd claude-academic-workflow
git pull
./scripts/install.sh   # or .\scripts\install.ps1 on Windows
./scripts/verify.sh    # or .\scripts\verify.ps1 — confirms hook paths, MCP status, personal_config presence
```

Re-running the installer is safe: it backs up your existing `~/.claude/skills/` etc before overwriting, and never touches `~/.claude/state/personal_config.json` if it already exists.

**Rotating the Telegram bot token.** In Telegram, `/revoke` your old token via BotFather, then `/token` for a new one. Update the GitHub Actions secret in your `lan-daily-brief` fork: `gh secret set TELEGRAM_BOT_TOKEN -R <your-fork>`. Update your shell env if you have it there. No skill or config file change needed.

**Adding a new project.** Add a new entry to `projects` and a new key to `notion.project_pages` in `personal_config.json`. No skill change needed — `/notion-log`, `/draft`, etc. will pick up the new project automatically.

**Removing a skill.** Delete its folder under `~/.claude/skills/`, and remove the corresponding folder from this repo if you want it gone for good. Re-running the installer will not re-add it.
