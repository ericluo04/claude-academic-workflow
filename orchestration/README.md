# Orchestration

This directory is intentionally minimal — the skills layer is installable without any orchestration. Two orchestration patterns are documented here. Pattern A is what the author currently runs; Pattern B was the original design and still works.

## Pattern A (recommended): a Claude Code cloud routine

A single hourly cloud routine (claude.ai → scheduled agents) replaces the GitHub-Actions-plus-Python stack. The routine is stateless between runs and owns the whole loop. Each tick:

1. **Poll Telegram** — `getUpdates` via the Bot API with plain `curl`. The bot token lives in the routine's configuration (see token handling below).
2. **Parse the capture grammar** — `remind me to X by <date>`, `remind me to X every <cadence>`, `remind me to X N weeks before <date>`, plus `add: <text>`, `<N> done`, and `?` (status query).
3. **Write rows to the Notion Tasks DB** — via the **Notion REST API with an internal-integration token**, not the Notion MCP connector (see the connector caveat below).
4. **Compute reminder times** — category lead-times (defaults: travel 7 weeks, registration 17 days, visa paperwork 60 days, errands 2 days) combined with a free-window pick from Google Calendar: pings land between 8am and 9pm, preferentially in post-meeting gaps, and never inside calendar blocks whose titles match deep-work keywords.
5. **Fire only "forgettable" reminders** — a `Reminder class` select property gates pinging. Forgettable deadlines and recurring life-admin fire; normal work tasks never do (the daily brief covers those, and pinging them would train you to ignore the bot).
6. **Re-arm recurring reminders** — compute the next occurrence and update `Next ping`.
7. **Persist state** — routines keep no state between runs, so cursor state (the Telegram `update_id` offset, etc.) is stored in a dedicated sentinel row (`__REMINDER_CONFIG__`) in the same Tasks DB. The DB doubles as the state store; no extra infrastructure.

The six extra Tasks-DB properties this needs (`Reminder class`, `Remind rule`, `Remind spec`, `Next ping`, `Last pinged`, `Ping count`) are documented in [../docs/notion-setup.md](../docs/notion-setup.md).

### Connector caveat (empirical, as of mid-2026)

claude.ai's **Notion connector is not exposed to cloud routines** — tool calls that work in interactive chat are simply absent in the routine's headless environment. The Google Calendar, Gmail, and Drive connectors DO work headless. Hence the split above: Calendar free/busy via the connector, Notion reads/writes via the REST API with an integration token. This may change; re-test before building around it.

### Token handling under Pattern A

The Telegram bot token and the Notion integration token live in the routine's configuration, visible only inside the owner's claude.ai account. Two consequences:

- No GitHub Actions secrets layer is needed.
- **Treat routine exports as sensitive.** Anything that dumps the routine definition — exports, screenshots, shared transcripts — contains live tokens verbatim. Rotate both tokens if a routine body ever leaks.

### Why Pattern A

GitHub Actions scheduled workflows routinely fire 1–4 hours late under queue load; a reminder that arrives "sometime this afternoon" is not a reminder. Cloud routines fire within minutes of the scheduled tick. Pattern B still works — it is just less punctual.

## Pattern B (legacy, still functional): GitHub Actions cron + Python

The original orchestration — a Telegram bot poller, GitHub Actions cron jobs, a Notion API client, and a daily-brief scheduler — lives in a companion repo:

**[ericluo04/lan-daily-brief](https://github.com/ericluo04/lan-daily-brief)** — currently private. The public version will be linked here once the codebase is cleaned (env-var migration for hardcoded Notion IDs, redaction sweep, `.env.example` written). In the meantime, see [../docs/notion-setup.md](../docs/notion-setup.md) and [../docs/telegram-setup.md](../docs/telegram-setup.md) for the workflow design.

**Known caveat:** GitHub Actions scheduled crons are best-effort — under queue load they fire 1–4 hours late, which is what motivated Pattern A. For anything time-sensitive, prefer Pattern A; Pattern B remains fine for daily summaries and other latency-tolerant jobs.

### What is in the companion repo

At a high level:

- **4 GitHub Actions workflows** — morning brief at a fixed local time, Telegram capture poll every 30 min, Friday recap, Weekly Agenda reconcile, and a meeting-notes ingest trigger.
- **~12 Python scripts** — Notion API client, Telegram bot poller, brief scorer, capture parser, and a handful of small task-mutation utilities (`mark_done.py`, `push_task.py`, `add_task.py`, etc.).
- **Telegram bot poller** — long-poll `getUpdates`, parse the typed reply (`<N> done`, `<N> push <day>`, `add: <text>`, free-form natural-language adds), apply the change to the Notion Tasks DB.
- **Daily-brief scorer** — re-implements the same scoring logic that lives in the `/daily-brief` skill, but runs unattended on the GitHub Actions schedule.

### Why it is a separate repo

Two reasons:

1. **Secrets management is per-fork.** Every adopter has their own Notion workspace, their own Telegram bot, and their own GitHub Actions secrets layer. Keeping orchestration in a separate repo means a friend can fork it, set their own secrets, and run the cron jobs without inheriting anyone else's tokens, page IDs, or chat IDs.
2. **The skills layer should be installable without the orchestration layer.** Someone who just wants the `/draft`, `/seven-pass-review`, and `/tikz-iterate` skills shouldn't need to set up Telegram. Splitting the repos lets you adopt the skills now and add orchestration later if you want it.

(Under Pattern A neither concern arises — there is no fork and no secrets layer; tokens live in the routine config.)

### Required GitHub Actions secrets in your fork

When you fork the orchestration repo, populate these as GitHub Actions secrets (Settings -> Secrets and variables -> Actions -> New repository secret):

| Secret | Value (placeholder) | Source |
|---|---|---|
| `NOTION_TOKEN` | `<your-notion-integration-secret>` | Notion integration secret (starts with `secret_` or `ntn_`) — see [../docs/notion-setup.md](../docs/notion-setup.md) |
| `NOTION_TASKS_DB_ID` | `<32-hex-uuid>` | Notion DB URL of your Tasks database |
| `NOTION_TASKS_PAGE_ID` | `<32-hex-uuid>` | Notion page URL of the parent page that contains the Tasks DB |
| `TELEGRAM_BOT_TOKEN` | `<9-or-10-digit>:<35-char-alphanumeric>` | BotFather — see [../docs/telegram-setup.md](../docs/telegram-setup.md) |
| `TELEGRAM_CHAT_ID` | `<numeric>` | Your personal chat ID from `getUpdates` |
| `CALENDAR_ICS_URLS` (optional) | `https://outlook.office365.com/.../calendar.ics,https://...` | Comma-separated published iCal URLs — see [../docs/outlook-gmail.md](../docs/outlook-gmail.md) |

The bot token does not live in `personal_config.json` or any file in `~/.claude/`. It only lives in the GitHub Actions secrets layer of your orchestration-repo fork, and optionally as a shell env var for local testing.

### Setting up the orchestration repo

The full step-by-step is in step 10 of [../SETUP.md](../SETUP.md). Summary: fork, populate the secrets above, enable Actions, trigger the morning-brief workflow manually once to verify.
