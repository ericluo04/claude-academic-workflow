---
name: daily-brief
description: Build the user's morning task brief — pull open tasks from their Notion Tasks DB, score and rank by priority × urgency × type-balance × energy fit (with wait-factor scoring and type-balance rotation), pick the top 3–7 that fit available time, and push the formatted list to their Telegram bot. Saves the selection to today_brief.json so /capture can resolve "1 done" / "2 push thu" replies. Use this skill whenever the user says /daily-brief, asks for "today's tasks", "what should I work on", "morning brief", "rebuild my todo list", "what's on my plate", or wants their daily plan refreshed. Also use when they give a capacity hint like "I have 4 hours today" — pass --hours 4.
---

# /daily-brief — score, rank, send the morning push

> **Status.** The author has migrated orchestration to an hourly Claude Code cloud routine — see [orchestration/README.md](../../orchestration/README.md) (Pattern A). This skill documents the local / GitHub-Actions-era pattern (Pattern B), which remains fully usable for setups without cloud routines.

## Personalization

This skill resolves placeholders against `~/.claude/state/personal_config.json`. See `_config/README.md` and `_config/personal_config.example.json` for setup. If the config is missing or a needed field is unset, the skill must surface an error to the user and refuse to proceed rather than guess.

Required config fields:
- `personal_config.notion.tasks_data_source_id` — the data-source ID of the Tasks DB.
- `personal_config.paths.claude_state_dir` — local directory holding ephemeral state files (e.g. `~/.claude/state`).
- Telegram credentials are read from a separate gitignored file at `<claude_state_dir>/telegram.json` with fields `{bot_token, chat_id}`. Bot tokens never go in `personal_config.json`.

## Purpose

This is the outbound half of the task orchestration system. Once per weekday morning (and on demand), it converts the unified Notion Tasks DB into a 3–7 item ranked list and pings Telegram. The brief is the daily contract: if it's not on the brief, it doesn't need to happen today.

The capture half (`/capture`) reads replies and writes back. This skill is also the writer of `today_brief.json`, which `/capture` reads to resolve `"<N> done"`-style replies.

## Invocation modes

- `/daily-brief` — full run: query → score → pick → send Telegram → write `today_brief.json`.
- `/daily-brief --hours <N>` — override available deep-work hours.
- `/daily-brief --dry` — print the brief to chat, do not call Telegram, do not write state. Useful for previewing.

Flags can combine: `/daily-brief --hours 4 --dry`.

## Live state and IDs

- Notion Tasks data source URL: `collection://{{personal_config.notion.tasks_data_source_id}}`
- Notion Tasks data source ID: `{{personal_config.notion.tasks_data_source_id}}`
- Telegram credentials: `<claude_state_dir>/telegram.json` — read and parse as JSON. Fields: `bot_token`, `chat_id`.
- Telegram API base: `https://api.telegram.org/bot<bot_token>/`
- Brief state output: `<claude_state_dir>/today_brief.json`

## Workflow

### 1. Query open tasks from Notion

Use `mcp__notion__notion-query-database-view` with:
- `data_source_url`: `collection://{{personal_config.notion.tasks_data_source_id}}`
- A filter restricting `Status` to `To-do` or `In progress`.
- Page size large enough to return everything (a few hundred max; this DB is small).

Hydrate each row's `Task`, `Status`, `Priority`, `Due`, `Est min`, `Type`, `Project`, `Energy`, `created_time`, and `page_id`. Tasks missing a Priority should be treated as `P2`; missing `Est min` as 30; missing `Energy` as `Shallow`.

### 2. Determine available deep-work hours

Order of precedence:
1. `--hours <N>` flag wins. Use `<N> × 60` as `available_minutes`.
2. Otherwise, default to `available_hours = 3`. (If a calendar source is available, replace this with a real busy-time query; see `docs/outlook-gmail.md`.)

`available_minutes = available_hours × 60`.

### 3. Score every open task

For each task, compute:

```
priority_weight   = {P0: 8, P1: 4, P2: 2, P3: 1}[Priority]
days_until_due    = (Due - today).days   if Due present else 999
urgency_factor    = max(1.0, 7.0 / max(1, days_until_due))
   # due-today → 7×; in 3 days → 2.33×; in 7+ days or no due → 1×
type_balance[T]   = 1.5 if T not in last_3_briefs
                    else 0.85 if T in all of last_3_briefs
                    else 1.0
energy_match      = 1.2 if (Energy == "Deep" and available_hours >= 2) else 1.0
days_since_created = (today - created_time.date()).days
wait_factor        = min(2.0, 1 + 0.1 × days_since_created)
   # cap at 2.0× so wait_factor never dominates a P0 deadline
score = priority_weight × urgency_factor × type_balance × energy_match × wait_factor
```

`last_3_briefs` is read from `<claude_state_dir>/last_3_briefs.json`. Each entry is `{date, types: [Type, ...]}`. If the file is missing, treat as empty — every Type is "not seen", so all get the 1.5× boost. Compute the set of Types appearing in the last 3 entries to evaluate the rule.

`wait_factor` uses Notion's `created_time` property; for any task missing it, fall back to `days_since_created = 0` (→ 1.0×).

Overdue tasks (`days_until_due < 0`) get `urgency_factor = 7.0` (capped — equivalent to due-today). Don't let the math explode for tasks 30 days overdue.

### 4. Select top N

Sort tasks descending by score. Walk down the list, adding tasks to the brief while `cumulative Est min ≤ available_minutes`. Stop at 7 tasks even if more fit (the brief loses its bite past 7). Always include at least 3 tasks if at least 3 are open, even if they overflow `available_minutes` slightly — the user would rather see 3 things than be told "your plate is full" with one item.

Number the selected tasks 1..N in the order they appear in the brief.

### 5. Format the Telegram message

Follow this exact template:

```
Morning brief — <Day> <Mon> <DD> — <H> deep hrs available

P0 > (1) <Task title> (<est>) [#<Project or Type>]
P1 > (2) <Task title> (<est>) [#<Project or Type>]
P2 > (3) <Task title> (<est>) [#<Project or Type>]
...

Reply: "1 done", "2 push thu", "add: X P2 30min #personal"
```

Formatting rules:
- Day/Mon/DD use today's local date (e.g. `Tue May 12`).
- `<H>` shows one decimal only if non-integer.
- `<est>` formatted as `90min` or `3h` (use hours when >= 60min and a clean multiple, else minutes).
- `[#<tag>]` — prefer Project name (relation resolved); if no Project, use Type (`#Personal`, `#Admin`, etc.).
- Keep titles tight; truncate at ~60 chars with a trailing ellipsis if needed.

### 6. Send Telegram

```powershell
$tg = Get-Content "<claude_state_dir>\telegram.json" | ConvertFrom-Json
$body = @{ chat_id = $tg.chat_id; text = $message } | ConvertTo-Json
Invoke-RestMethod -Uri "https://api.telegram.org/bot$($tg.bot_token)/sendMessage" -Method Post -Body $body -ContentType "application/json"
```

Bash equivalent:

```bash
TG=$(cat "$CLAUDE_STATE_DIR/telegram.json")
TOKEN=$(echo "$TG" | jq -r .bot_token)
CHAT=$(echo "$TG" | jq -r .chat_id)
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
     -d "chat_id=$CHAT" --data-urlencode "text=$MESSAGE"
```

Skip this entirely if `--dry` is set.

### 7. Write today_brief.json

Always (unless `--dry`) write the current selection to `<claude_state_dir>/today_brief.json`:

```json
{
  "date": "2026-05-12",
  "available_hours": 3,
  "tasks": [
    {"n": 1, "page_id": "...", "title": "Submit R&R revision", "priority": "P0", "est_min": 180, "due": "2026-05-12"},
    {"n": 2, "page_id": "...", "title": "Email collaborator re: travel", "priority": "P1", "est_min": 10, "due": "2026-05-13"}
  ]
}
```

Use UTF-8 (no BOM) encoding so `/capture` reads it cleanly. Write atomically (tmp + rename) — cloud-sync clients can corrupt mid-write JSON on Windows, and `/capture` reading a half-flushed file is the failure mode this guards against:

```powershell
$path = "<claude_state_dir>\today_brief.json"
$tmp  = "$path.tmp"
Set-Content -Path $tmp -Value $json -Encoding utf8
Move-Item -Force $tmp $path
```

Apply the same tmp + rename pattern to `last_3_briefs.json` when updating the rolling type-balance log (prepend today's entry `{date, types}`, truncate to the last 3, write atomically).

Overwrite, don't append `today_brief.json` — each day's brief replaces the last.

### 8. Final chat report

In the chat (not Telegram), report: how many tasks were considered, the chosen N, available_hours and where it came from (flag / default), and any anomalies (overdue tasks not selected, etc.). Keep it to a few lines.

## Examples

**Example 1 — full run, default hours:**
- 23 tasks open in Notion, available_hours = 3 (default; no calendar source), available_minutes = 180.
- Top 4 fit in 170 min; brief sent.
- Chat report: "Sent 4-task brief (P0x1, P1x2, P2x1). 3 deep hrs (default — no calendar). 19 tasks deferred."

**Example 2 — `--hours 1`:**
- Tight day; only 1 task fits if it's <=60min.
- The 3-task floor forces inclusion of 3 items even if they sum to 95min. That's intentional.

**Example 3 — `--dry`:**
- Print the formatted message to chat exactly as it would go to Telegram, plus the score breakdown for the top 10 candidates so the user can sanity-check the ranking. No state file written.

## Failure modes

- **Notion query fails / Notion MCP errors**: Report the failure in chat with the error message; do NOT send a half-built Telegram brief (no brief is better than a wrong one); do NOT overwrite `today_brief.json`. Suggest retry in a few minutes.
- **Telegram send fails (network / 5xx / 429)**: The brief was built successfully. Still write `today_brief.json` so the system has state, then report the Telegram failure in chat and suggest re-running. Don't retry the send automatically — the user might be in a meeting and a stale ping is annoying.
- **No open tasks**: Send a one-liner to Telegram: `Inbox empty <date> — Add tasks with "add: ..." or queue some in Notion.` Write a `today_brief.json` with `tasks: []` so `/capture` still has a valid file.
- **Fewer than 3 open tasks**: Just send what exists (1 or 2 items). Skip the 3-task floor — can't include what doesn't exist.
- **Calendar integration unavailable**: Default to 3 hrs unless `--hours` flag overrides. Mention in chat report only if relevant.
- **Telegram credentials file missing**: Hard fail with a clear pointer to `<claude_state_dir>/telegram.json`. Don't make up a chat_id or token.
- **`--hours` set absurdly high (>12) or low (<0)**: Clamp to [0.5, 12] and note the clamp in the chat report.
- **Tasks with corrupted properties** (e.g., Priority is somehow not P0..P3): Use the defaults from section 1 and continue. Don't fail the whole brief.

## Out of scope

- This skill does not run on a schedule itself. Use `/schedule` for daily 7am runs and `/loop` for on-demand polling. `/daily-brief` is a single-shot.
- It does not read or process inbound Telegram messages — that's `/capture`.
- It does not modify Notion task state (no marking done, no rescheduling). It only reads.
- It does not invent new tasks, suggest tasks, or generate tasks from emails/Slack. If the Tasks DB is empty, the brief is empty.
- It does not touch Notion pages outside the Tasks DB (no Weekly Agenda writes, no project-page edits). Those belong to `/notion-log`.
- It does not maintain a history of past briefs beyond what's needed for the type-balance check. No analytics, no streaks, no week-in-review here.
- It does not handle weekend behavior specially. If invoked on a Saturday, it runs.
