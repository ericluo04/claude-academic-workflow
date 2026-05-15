# Orchestration

This directory is intentionally minimal. The actual orchestration code — the Telegram bot poller, the GitHub Actions cron jobs, the Notion API client, the daily-brief scheduler — lives in a companion repo:

**[ericluo04/lan-daily-brief](https://github.com/ericluo04/lan-daily-brief)** — currently private. The public version will be linked here once the codebase is cleaned (env-var migration for hardcoded Notion IDs, redaction sweep, `.env.example` written). In the meantime, see [../docs/notion-setup.md](../docs/notion-setup.md) and [../docs/telegram-setup.md](../docs/telegram-setup.md) for the workflow design.

## What is in the companion repo

At a high level:

- **4 GitHub Actions workflows** — morning brief at 6:15am local, Telegram capture poll every 30 min, Friday recap, Weekly Agenda reconcile, and a meeting-notes ingest trigger.
- **~12 Python scripts** — Notion API client, Telegram bot poller, brief scorer, capture parser, and a handful of small task-mutation utilities (`mark_done.py`, `push_task.py`, `add_task.py`, etc.).
- **Telegram bot poller** — long-poll `getUpdates`, parse the typed reply (`<N> done`, `<N> push <day>`, `add: <text>`, free-form natural-language adds), apply the change to the Notion Tasks DB.
- **Daily-brief scorer** — re-implements the same scoring logic that lives in the `/daily-brief` skill, but runs unattended on the GitHub Actions schedule.

## Why it is a separate repo

Two reasons:

1. **Secrets management is per-fork.** Every adopter has their own Notion workspace, their own Telegram bot, and their own GitHub Actions secrets layer. Keeping orchestration in a separate repo means a friend can fork it, set their own secrets, and run the cron jobs without inheriting anyone else's tokens, page IDs, or chat IDs.
2. **The skills layer should be installable without the orchestration layer.** Someone who just wants the `/draft`, `/seven-pass-review`, and `/tikz-iterate` skills shouldn't need to set up Telegram. Splitting the repos lets you adopt the skills now and add orchestration later if you want it.

## Required GitHub Actions secrets in your fork

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

## Setting up the orchestration repo

The full step-by-step is in step 10 of [../SETUP.md](../SETUP.md). Summary: fork, populate the secrets above, enable Actions, trigger the morning-brief workflow manually once to verify.
