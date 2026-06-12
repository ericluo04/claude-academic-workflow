---
name: capture
description: Poll Telegram for new messages and write parsed task actions into the user's Notion Tasks DB. Handles "<N> done", "<N> push <day>", "<N> drop", "add: <text> [P<n>] [<n>min] [#type]", "morning <hours>", and free-form natural-language adds like "remind me to email a coauthor by Wednesday". Use this skill whenever the user says /capture, asks to check Telegram, says "process my replies", "did I get any messages", "pull new tasks from telegram", or otherwise wants to sync inbound Telegram messages into Notion. Also trigger when they paste a Telegram-style reply ("1 done", "add: ...") into the chat and want it logged.
---

# /capture — Telegram → Notion task ingest

> **Status.** The author has migrated orchestration to an hourly Claude Code cloud routine that polls Telegram and writes to Notion directly — see [orchestration/README.md](../../orchestration/README.md) (Pattern A). This skill documents the local / GitHub-Actions-era pattern (Pattern B), which remains fully usable for setups without cloud routines.

## Personalization

This skill resolves placeholders against `~/.claude/state/personal_config.json`. See `_config/README.md` and `_config/personal_config.example.json` for setup. If the config is missing or a needed field is unset, the skill must surface an error to the user and refuse to proceed rather than guess.

Required config fields:
- `personal_config.notion.tasks_data_source_id`
- `personal_config.notion.tasks_parent_page_id` (parent page that holds the Tasks DB plus the `Brief YYYY-MM-DD` child pages)
- `personal_config.paths.claude_state_dir`

Telegram credentials live in `<claude_state_dir>/telegram.json` (gitignored), not in `personal_config.json`. The bot itself is provisioned per docs/telegram-setup.md; bot tokens never go in the repo.

## Purpose

The user sends short replies and ad-hoc captures to their Telegram bot all day. This skill polls those messages, classifies each one, and writes the result into the unified Notion Tasks DB. It is the inbound half of the task orchestration system (the outbound half is `/daily-brief`).

The system is designed so the user never has to open Notion or even Telegram to file a task — they tap a one-line reply on their phone and Claude does the bookkeeping.

## Live state and IDs

- Notion Tasks data source ID: `{{personal_config.notion.tasks_data_source_id}}`
- Notion data source URL (for query tools): `collection://{{personal_config.notion.tasks_data_source_id}}`
- Notion Tasks DB parent page: `{{personal_config.notion.tasks_parent_page_id}}`
- Telegram credentials file: `<claude_state_dir>/telegram.json` — parse as JSON. Fields: `bot_token`, `chat_id`.
- Telegram API base: `https://api.telegram.org/bot<bot_token>/`
- Update-offset cursor: `<claude_state_dir>/telegram_offset.json` — shape `{"last_update_id": <int>}`. Create with `last_update_id = 0` if missing.
- Today's brief — read from **Notion first**, fall back to local file:
  - **Primary**: Notion page titled `Brief YYYY-MM-DD` (today's date) as a child of the Tasks parent page. Written by the GitHub Actions cron each morning. Use `mcp__notion__notion-search` with `query="Brief <today>"` scoped to the Tasks parent, or list child pages. The brief contains a JSON code block at the bottom with the shape below.
  - **Fallback**: local file `<claude_state_dir>/today_brief.json` — written only when `/daily-brief` is invoked manually within Claude Code (not by the cron).
  - Shape (both sources): `{"date": "YYYY-MM-DD", "available_hours": <num>, "tasks": [{"n": 1, "page_id": "...", "title": "...", "priority": "P0", "est_min": ..., "due": ..., "project": ..., "type": ...}, ...]}`

## Notion Tasks DB schema (case-sensitive property names)

| Property | Type | Notes |
|---|---|---|
| Task | Title | Required for new rows |
| Status | Status | `To-do`, `In progress`, `Waiting`, `Done`, `Dropped` |
| Priority | Select | `P0`, `P1`, `P2`, `P3` |
| Due | Date | ISO `YYYY-MM-DD` |
| Est min | Number | integer minutes |
| Type | Select | `Research`, `Teaching`, `Admin`, `Personal`, `Health`, `Travel`, `Social` |
| Project | Relation | optional |
| Context | Multi-select | `computer`, `phone-OK`, `on-the-go`, `home`, `deep-focus`, `shallow` |
| Energy | Select | `Deep`, `Shallow` |
| Source | Select | set to `Telegram` for everything this skill creates |
| Notes | Rich text | use for actual-minutes logs and parse residue |
| Created | Created time | auto |

## Workflow

Run these steps in order every time the skill triggers.

### 1. Read credentials and offset

```powershell
$tg = Get-Content "<claude_state_dir>\telegram.json" | ConvertFrom-Json
$offsetPath = "<claude_state_dir>\telegram_offset.json"
$offset = if (Test-Path $offsetPath) { (Get-Content $offsetPath | ConvertFrom-Json).last_update_id } else { 0 }
```

If `telegram_offset.json` exists but fails to parse, treat `last_update_id = 0` and overwrite it after this run. Note the corruption in the final report so the user can investigate if they want.

### 2. Poll Telegram getUpdates

Use `Invoke-RestMethod` to `GET https://api.telegram.org/bot<token>/getUpdates?offset=<last_update_id + 1>&timeout=0`. `timeout=0` is short-poll, which is the right choice here — `/capture` is invoked on demand, not running forever.

```powershell
$url = "https://api.telegram.org/bot$($tg.bot_token)/getUpdates?offset=$($offset + 1)&timeout=0"
$resp = Invoke-RestMethod -Uri $url -Method Get
```

Only process messages where `message.chat.id == $tg.chat_id` — defense in depth in case anyone else ever DMs the bot.

If `resp.result` is empty, send no Notion writes and reply nothing on Telegram. Tell the user "No new messages." and exit. This is the happy path most of the time.

### 3. Classify each message

For each `update` in `resp.result`, take `update.message.text`, trim, lowercase a copy for matching, and route on first match:

1. `^\s*(\d+)\s+done\s*$` — mark task N done.
2. `^\s*(\d+)\s+done\s+(\d+)\s*$` — mark done + log actual minutes.
3. `^\s*(\d+)\s+push\s+(.+?)\s*$` — bump Due to parsed day.
4. `^\s*(\d+)\s+drop\s*$` — set Status=Dropped.
5. `^\s*add:\s*(.+)$` — explicit add line.
6. `^\s*morning\s+(\d+(?:\.\d+)?)\s*$` — capacity override; call `/daily-brief` with `--hours <N>`.
7. `^\s*\?\s*$` — reply with today's brief from the Notion `Brief YYYY-MM-DD` page (or local file fallback). No Notion *writes*.
8. Otherwise — treat as natural-language add (see section 6).

Case-insensitive matching throughout.

### 4. Resolve `<N>` to a Notion page

For done/push/drop, look up the brief in this order:

1. **Notion `Brief YYYY-MM-DD` page** (today's date) under the Tasks parent. Steps:
   - Search Notion for a page titled `Brief <today's date in ISO>` under the Tasks page parent.
   - If found, fetch the page content. The last child block should be a code block with `language: json` containing the brief JSON.
   - Parse that JSON. Find the entry where `n == <N>`.
2. **Local fallback** `<claude_state_dir>/today_brief.json` — only if the Notion brief doesn't exist for today (e.g., the cron didn't run, or `/daily-brief` was invoked manually instead).

If neither source has a matching entry, reply on Telegram with `"Task N not in today's brief — run /daily-brief first or use 'add:'."` and skip the Notion write for that message. Don't advance offset for that message so it can be re-processed after running the brief.

When the brief is from Notion: use the `page_id` field from the parsed JSON exactly as written — it's the task row's Notion ID, not the brief-page ID.

### 5. Notion writes

Use the official Notion MCP tools. Property names must match the schema above exactly (case-sensitive). Status names are also case-sensitive.

**Mark done** (`mcp__notion__notion-update-page`):
- `page_id`: from today_brief
- properties: `Status = "Done"`

**Mark done with actual minutes**:
- Same as above, plus append to `Notes` (rich text): `"actual: <N>min (logged <today>)"`. If Notes already has content, append on a new line; do not overwrite.

**Push**:
- `Due` = parsed date. Day-name parsing (today's date as anchor):
  - `tomorrow` → today + 1
  - `today` → today
  - `mon`/`monday`, `tue`/`tuesday`, `wed`/`wednesday`, `thu`/`thursday`, `fri`/`friday`, `sat`/`saturday`, `sun`/`sunday` → next occurrence (strictly future; if today is Wed and the user says "wed", that means next Wed)
  - `in N days` → today + N
  - ISO date `YYYY-MM-DD` → as-is
  - Anything else → reply "Couldn't parse day '<X>' — try mon/tue/.../tomorrow/in 3 days." and skip.

**Drop**: `Status = "Dropped"`.

**Add** (`mcp__notion__notion-create-pages`):
- `parent`: `{"data_source_id": "{{personal_config.notion.tasks_data_source_id}}"}`
- properties:
  - `Task` (title): the cleaned task text
  - `Status`: `To-do`
  - `Priority`: parsed (default `P2`)
  - `Est min`: parsed (default `30`)
  - `Type`: parsed or inferred (default `Admin` if nothing else fits)
  - `Source`: `Telegram`
  - `Due`: parsed if a day was specified; otherwise omit (no default)

### 6. Parsing `add:` and natural-language adds

For `add: <body>`, extract these from `<body>`:
- Priority: token matching `\bP[0-3]\b` (uppercase or lowercase). Default `P2`.
- Estimate: token matching `(\d+)\s*(min|m|h|hr|hours)\b`. Convert hours to minutes. Default `30`.
- Type tag: token matching `#(\w+)`. Map to Type select: `research`→Research, `personal`→Personal, `admin`→Admin, `teaching`→Teaching, `health`→Health, `travel`→Travel, `social`→Social. Unknown tag → put the raw tag in Notes, infer Type from keywords.
- Due: phrases like `by <day>`, `due <day>`, `tomorrow`, `today`, ISO date. Use the same day parser as push.
- Task title: whatever remains after stripping the above tokens, trimmed.

For natural-language adds (anything that didn't match a prior pattern), do the same extraction over the whole message text. If the message starts with "remind me to ", "remember to ", "todo: ", "need to ", strip that prefix before using the remainder as the title. If a sensible title cannot be extracted (e.g., a single emoji), reply asking the user to rephrase rather than guessing.

Type inference fallback when no `#tag` and Type isn't obvious from keywords:
- Contains `paper`, `draft`, `revision`, `R&R`, `referee`, `JMP`, `analysis`, `regression`, project names from `personal_config.projects[].name` → `Research`
- Contains `email`, `expense`, `form`, `reimburs`, `tax`, `onboarding`, `office` → `Admin`
- Contains `gym`, `dentist`, `doctor`, `appt`, `appointment`, `meds` → `Health`
- Contains `dinner`, `restaurant`, `flight`, `hotel`, `trip`, `reservation` → `Travel` (lean) or `Personal`
- Contains family/friend names, `mom`, `dad`, `birthday` → `Social` or `Personal`
- Default → `Admin`

These heuristics will be wrong sometimes — that's fine. The user can fix Type in Notion or by replying again. Better to file imperfectly than to interrogate them.

### 7. Confirm back to Telegram

After processing all updates, send a single concise reply via `POST https://api.telegram.org/bot<token>/sendMessage` with `chat_id` and `text`. Use one short line per message processed. Examples:

- `OK 1 done (Submit R&R revision)`
- `OK 2 -> Thu May 14 (Email coauthor)`
- `OK 3 dropped`
- `Added: Book restaurants for trip — P2, 15min, Personal, due Wed`
- `Couldn't parse day 'next-ish' — try mon/tue/.../tomorrow/in 3 days.`

Batch all confirmations into one Telegram message (one per line) to avoid rate limits when the user has sent a flurry of replies.

### 8. Advance the offset

Set `last_update_id` to the max `update.update_id` across processed updates and write back to `telegram_offset.json`. Do this even if some Notion writes failed — otherwise a single bad message will block the whole queue. For failures, include them in the Telegram confirmation so the user can retry manually.

Use atomic write (tmp + rename) — cloud sync can read a half-written JSON if `Set-Content` is interrupted, which corrupts the offset and replays processed messages on the next poll.

```powershell
$path = "<claude_state_dir>\telegram_offset.json"
$tmp  = "$path.tmp"
@{ last_update_id = $maxUpdateId } | ConvertTo-Json | Set-Content -Encoding utf8 $tmp
Move-Item -Force $tmp $path
```

Apply the same tmp + `Move-Item -Force` pattern to any other local JSON state file the skill writes. Telegram and Notion API calls are atomic by remote contract — only local state files need the wrapper.

## Examples

**Example 1 — done with time:**
Input message: `1 done 145`
Action: Look up task 1 in today_brief, update page → Status=Done, append `actual: 145min (logged 2026-05-12)` to Notes.
Telegram reply: `OK 1 done in 145min (Submit R&R revision)`

**Example 2 — natural-language add:**
Input message: `remind me to email a coauthor about figures by Wednesday`
Action: Create page → Task="Email coauthor about figures", Priority=P2, Est min=30, Type=Admin, Source=Telegram, Due=next Wed.
Telegram reply: `Added: Email coauthor about figures — P2, 30min, Admin, due Wed May 13`

**Example 3 — explicit add:**
Input message: `add: prep slides for seminar P1 90min #research`
Action: Create page → Task="prep slides for seminar", Priority=P1, Est min=90, Type=Research, Source=Telegram.
Telegram reply: `Added: prep slides for seminar — P1, 90min, Research`

**Example 4 — capacity override:**
Input message: `morning 4`
Action: Invoke `/daily-brief --hours 4`. Don't send a separate confirmation — the new brief is the confirmation.

## Failure modes

- **Notion MCP errors / 5xx**: Don't advance the offset for the failed message(s). Reply on Telegram with `"Notion down — retry with /capture later"`. Advance offset for messages that succeeded.
- **Telegram rate limit (429)**: Telegram's `retry_after` is usually under 60s. Wait and retry once; if it fails again, leave the offset where it is and report the rate limit in the final summary. Don't spam retries.
- **No new messages**: Say "No new messages." and exit silently — do not call Notion.
- **No brief for today** (neither Notion `Brief YYYY-MM-DD` page nor local `today_brief.json`) when `<N>` action arrives: Telegram-reply with `"No brief loaded — run /daily-brief first."` and skip those messages. Don't advance offset for them.
- **Notion brief code block malformed**: log the malformed brief page ID in the final report; fall back to the local file if available; otherwise treat as "no brief".
- **`telegram_offset.json` corrupted**: Reset to `last_update_id = 0`, log the corruption in the final report, continue. Yes, this re-processes some messages — that's safer than dropping them. Notion writes are idempotent enough (done→done, drop→drop) that re-processing rarely causes harm; for add lines this could create duplicates, but the user can dedupe in Notion.
- **Telegram credentials file missing**: Hard fail with a clear error pointing at `<claude_state_dir>/telegram.json`. Don't try to reconstruct.
- **Ambiguous message**: Reply on Telegram with `"Didn't parse: '<text>'. Try '<N> done', 'add: ... P2 30min #type', etc."` rather than silently dropping.

## Out of scope

- Do not run continuously / poll on a timer. Use `/loop` or `/schedule` for that.
- Do not modify or delete existing Notion property options.
- Do not write to any Notion location other than the Tasks DB. Project pages and Weekly Agenda are off-limits here — that's `/notion-log`'s job.
- Do not send unsolicited Telegram messages. Only confirm what the user sent.
- Do not invent task IDs. Always resolve `<N>` via `today_brief.json`.
- Do not change scoring or ranking logic — that lives in `/daily-brief`.
- Do not attempt OCR, image parsing, or voice-note transcription. Text only for now.
