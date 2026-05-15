---
name: task-pulse
description: Answer ad-hoc questions about the user's Notion Tasks DB. Query by project, type, due date, status, or staleness and return a concise readout. Use whenever the user asks "what's open for X", "what's due Friday", "anything stale", "what did I finish this week", "any P0 tasks", or similar status checks against the unified Tasks DB. Read-only — never writes, never marks done, never reschedules.
---

# /task-pulse — read-only status checks against the Tasks DB

## Personalization

This skill resolves placeholders against `~/.claude/state/personal_config.json`. See `_config/README.md` and `_config/personal_config.example.json` for setup. If the config is missing or a needed field is unset, the skill must surface an error to the user and refuse to proceed rather than guess.

Required config fields:
- `personal_config.notion.tasks_data_source_id`
- `personal_config.projects[].name` and optional `aliases` (used for project-name shortcuts)

## Purpose

The user wants quick on-demand visibility into the task pipeline without opening Notion. This skill takes a free-text question, builds one or two filtered queries against the Tasks data source, and returns a concise bulleted readout.

It is **strictly read-only**. Never call any tool that mutates Notion. To change a task, use `/capture` (via Telegram) or edit Notion directly.

## Live IDs

- Tasks data source: `{{personal_config.notion.tasks_data_source_id}}`
- Use URL form `collection://{{personal_config.notion.tasks_data_source_id}}` with `mcp__notion__notion-fetch`, or pass the bare UUID to query tools.

## Schema (case-sensitive)

| Property | Type | Values |
|---|---|---|
| Task | title | — |
| Status | select | To-do / In progress / Waiting / Done / Dropped |
| Priority | select | P0 / P1 / P2 / P3 |
| Due | date | — |
| Est min | number | — |
| Type | select | Research / Teaching / Admin / Personal / Health / Travel / Social |
| Project | select | values from `personal_config.projects[].name` |
| Source | select | Manual / Meeting / Email / Telegram / Weekly-Agenda |
| Recurring | select | Daily / Weekly / Biweekly / Monthly |
| Created | created_time | auto |
| (page-level `last_edited_time`) | — | use for "completed recently" |

## Question → filter map

| Phrase | Filter |
|---|---|
| "what's open for X" / "everything left for X" / "X tasks" | `Status` in {To-do, In progress} AND `Project` = X |
| "what's due Friday / today / tomorrow / this week" | `Due` range |
| "anything stale" / "old tasks" / "what's been sitting" | `Status` in {To-do, In progress} AND `Created` > 30 days ago |
| "what did I finish this week" / "last week" | `Status` = Done AND `last_edited_time` within 7d |
| "what's P0" / "high priority" | `Priority` in {P0, P1} |
| "what's on <project>" | shortcut for "open for <project>" |
| "what meetings am I behind on" | `Source` = Meeting AND `Status` in {To-do, In progress} |
| "what's recurring" | `Recurring` != null |

If multiple filters fit, combine with AND. If the query is ambiguous (e.g., just a project name), default to the open-for-X interpretation.

## How to query

Use the Notion MCP. Prefer one filtered query over fetching all tasks. If the MCP exposes a query-data-source tool (e.g., `notion-query-database-view` or similar), use it with the filter. If only `notion-fetch` is available, fetch the data source and filter in code (it returns rows).

When in doubt about which tool to use, search for tools whose names include "query" and "database" via ToolSearch — never invent tool names.

## Output

Cap at 20 results unless the question explicitly asks for everything.

Format each row as one line:
`- [P1] task title — due Fri Aug 1 (12d) #Project`

- `[P_]` priority tag at the front.
- `due ...` shown only if there's a Due. For overdue, prefix with `OVERDUE`: `due OVERDUE Mon Jul 28 (3d ago)`.
- `(Nd)` is days from today. Positive = future, negative = overdue, omit if no Due.
- `#Project` only if Project is set.

Group sensibly:
- Multi-project results → group by Project, oldest-first within each.
- Stale queries → sort oldest-first, show age in days as the lead bit: `- 47d: long-overdue task #Project`.
- "What did I finish this week" → group by day-of-week, newest-first.

After the bulleted list, give a one-line summary: `N tasks shown; M total open across Y projects.` If results were truncated, say `N more — refine your query.`

## Examples

**Query:** "what's open for ProjectB"

**Output:**
```
Open for ProjectB (5):
- [P0] draft Section 5 empirics — due Mon Aug 4 (3d) #ProjectB
- [P1] tertile robustness check #ProjectB
- [P2] coauthor email re: revision plan #ProjectB
- [P2] analysis tasks outline (no due) #ProjectB
- [P3] check Fong & Grimmer 2024 citation #ProjectB

5 open on ProjectB; oldest 18 days.
```

**Query:** "anything stale"

**Output:**
```
Stale (>30d in To-do/In progress):
- 47d: long-pending admin task #Admin
- 41d: software access transfer #Admin
- 38d: travel reservations #TripProject
- 34d: CV update #Admin

4 stale tasks. Mark Done/Dropped or push them forward.
```

## What this skill does NOT do

- Does NOT write to the Tasks DB (no marking Done, dropping, rescheduling).
- Does NOT touch the Weekly Agenda. (`/notion-log` and the cron handle that.)
- Does NOT create tasks. (`/log-todo` does that.)
- Does NOT send Telegram messages.
- Does NOT trigger `/daily-brief`.

If the user asks for any of the above, point them at the right skill instead.
