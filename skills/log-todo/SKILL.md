---
name: log-todo
description: Mid-session task capture for the user — drop a one-liner into chat and the skill writes it directly to the user's Notion Tasks DB (no Telegram hop). Use whenever the user types a capture phrase mid-conversation, including "/log-todo X", "log this: X", "log: X", "log to notion: X", "todo: X", "TODO: X", "remember: X", "remind me to X", "follow-up: X", "I should X later", "next time: X", "we need to X". Parses inline `P0`/`P1`/`P2`/`P3`, `(\d+)\s*(min|h|hr)` estimates, `by <day>` / `tomorrow` / `today` / ISO due dates, and infers Type (Research/Teaching/Admin/Personal/Health/Travel/Social), Project (from the user's configured project list), and Context (computer / phone-OK / deep-focus / shallow) from keywords. Always sets Source = Manual. Creates the Notion page via `mcp__notion__notion-create-pages` against the configured tasks data source and reports the new task URL back in chat. Does NOT call Telegram, build a daily brief, mark anything done, or fire /capture — capture-only, one-shot, additive.
---

# log-todo

## Personalization

This skill resolves placeholders against `~/.claude/state/personal_config.json`. See `_config/README.md` and `_config/personal_config.example.json` for setup. If the config is missing or a needed field is unset, the skill must surface an error to the user and refuse to proceed rather than guess.

Required config fields:
- `personal_config.notion.tasks_data_source_id`
- `personal_config.notion.tasks_parent_page_id`
- `personal_config.projects[].name` and optional `aliases` (used for project inference below)

## Purpose

Mid-session task capture. The user types a one-liner, the skill writes a row to the Notion Tasks DB and returns the URL.

## When to invoke

Fire on any of these patterns (case-insensitive, trim leading prefix and use the remainder as the task title):

- `/log-todo X`
- `log this: X` / `log: X` / `log to notion: X`
- `todo: X` / `TODO: X`
- `remember: X` / `remind me to X`
- `follow-up: X`
- `I should X later`
- `next time: X`
- `we need to X`

If the message looks like one of these but the intent is ambiguous (e.g. the user is narrating, not capturing), ask once. Otherwise just log and report.

## Live IDs

- Notion Tasks data source ID: `{{personal_config.notion.tasks_data_source_id}}`
- Notion Tasks DB parent page: `{{personal_config.notion.tasks_parent_page_id}}`
- Tool: `mcp__notion__notion-create-pages`

## Workflow

1. **Extract title.** Strip the trigger prefix (`log this:`, `todo:`, `remind me to`, `we need to`, etc.) and any inline flags (`P2`, `45min`, `by Thu`). What remains is the Task title. Capitalize first letter; keep verbs in imperative ("Cite Brady PNAS in section 3").
2. **Parse explicit flags:**
   - **Priority:** match `\bP[0-3]\b` → that priority. Else `P2`.
   - **Est min:** match `(\d+)\s*(min|h|hr|hrs|hour|hours)` → if `h*` multiply by 60. Else `30`.
   - **Due:** match `by (mon|tue|wed|thu|fri|sat|sun|today|tomorrow)` or ISO `YYYY-MM-DD`. Resolve weekday to next occurrence >= today. Else leave blank.
3. **Infer remaining fields:**
   - **Type:** keyword routing —
     - Research: paper, cite, lit review, R2R, referee, code, regression, robustness, table, figure, draft, analysis
     - Teaching: lecture, slides, MBA, syllabus, gradebook, office hours, problem set
     - Admin: email, reimbursement, submit, form, sign, schedule, book travel, IT, login, password
     - Personal: groceries, laundry, errand, family, gift, call mom/dad
     - Health: doctor, dentist, gym, run, sleep, meds, therapy
     - Travel: flight, hotel, AirBnB, conference travel, trip
     - Social: dinner, lunch with, drinks, party, meet up
     - Default `Admin` if no hit.
   - **Project:** match any of the canonical names and aliases declared in `personal_config.projects[]`. Else leave blank.
   - **Context:** `["computer"]` default. If task mentions "call", "text", "DM", "voice memo" → `["phone-OK"]`. If "deep think", "model", "derive", "proof", "write up" → add `"deep-focus"`. If "skim", "tidy", "rename", "file" → add `"shallow"`.
   - **Energy:** `Deep` if Context contains `deep-focus`; else `Shallow`.
   - **Source:** always `Manual`.
   - **Status:** `To-do`.
   - **Notes:** leave blank unless the user provided extra context after a `--` separator in the trigger line.
4. **Create the Notion page** via `mcp__notion__notion-create-pages`:

   ```json
   {
     "parent": {"type": "data_source_id", "data_source_id": "{{personal_config.notion.tasks_data_source_id}}"},
     "properties": {
       "Task": "<title>",
       "Status": "To-do",
       "Priority": "<P0/P1/P2/P3>",
       "Est min": <int>,
       "Type": "<Type>",
       "Project": "<Project or omit>",
       "Context": ["computer"],
       "Energy": "<Deep|Shallow>",
       "Source": "Manual",
       "Due": "<YYYY-MM-DD or omit>"
     }
   }
   ```

5. **Report back** in chat, one line:

   ```
   logged "<title>" — P2, 30min, Admin[, #Project][, due YYYY-MM-DD]
   <notion-url>
   ```

## Schema reminder (property names, case-sensitive)

| Property | Type | Options |
|---|---|---|
| Task | Title | — |
| Status | Status | To-do / In progress / Done |
| Priority | Select | P0 / P1 / P2 / P3 |
| Due | Date | — |
| Est min | Number | — |
| Type | Select | Research / Teaching / Admin / Personal / Health / Travel / Social |
| Project | Select | values from `personal_config.projects[].name` |
| Context | Multi-select | computer / phone-OK / deep-focus / shallow |
| Energy | Select | Deep / Shallow |
| Source | Select | Manual / Telegram / Email / Calendar |
| Notes | Rich text | — |

## Examples

**1. Keyword inference (mid-coding capture):**

> User: `log this: investigate why mainR2.tex won't compile`

Parse: no explicit flags. Title = "Investigate why mainR2.tex won't compile". Keywords `mainR2.tex` and `compile` → Type `Research`. No project keyword → Project blank. Context `["computer"]`, Energy `Shallow`, Priority `P2`, Est min `30`.

Report: `logged "Investigate why mainR2.tex won't compile" — P2, 30min, Research`

**2. Explicit P/min/type tags:**

> User: `todo: cite Brady PNAS in section 3 P1 15min ProjectA`

Parse: Priority `P1`, Est min `15`, Project `ProjectA` (resolved from `personal_config.projects[]`). Title (after stripping flags) = "Cite Brady PNAS in section 3". `cite` → Type `Research`. Context `["computer"]`, Energy `Shallow`.

Report: `logged "Cite Brady PNAS in section 3" — P1, 15min, Research, #ProjectA`

**3. Due date + natural phrasing:**

> User: `remind me to email a collaborator about the onboarding packet by Thu`

Parse: Title = "Email collaborator about the onboarding packet". `email` → Type `Admin`. `by Thu` → Due = next Thursday. Priority `P2`, Est min `30`, Context `["computer"]`, Energy `Shallow`.

Report: `logged "Email collaborator about the onboarding packet" — P2, 30min, Admin, due 2026-05-14`

## Failure modes

- **Ambiguous text.** If the trigger phrase matches but the title is nonsense or under 3 words ("todo: yes", "we need to that"), ask one clarifying question instead of logging garbage.
- **Notion down / tool error.** If `mcp__notion__notion-create-pages` returns an error, report the error verbatim and offer to retry. Do not silently drop the task — show the parsed payload so the user can re-paste it later.
- **Conflicting flags.** If two priorities or two project tags appear (`P1 P3`, `ProjectA ProjectB`), use the first one and warn in the report (`(ignored second P3)`).
- **Multiple tasks in one message.** If the user strings several with semicolons or "and also", log each as its own row and report one line per task.
- **Unknown Project keyword.** If a project-sounding word appears but isn't in the canonical list from `personal_config.projects[]`, leave Project blank and surface a note in the report (`(no project match for "X")`).

## Out of scope

This skill does NOT:

- Call Telegram or any messaging hop.
- Build, fetch, or post a daily brief — that's `/daily-brief`.
- Mark anything done, push, or drop — that's `/capture`.
- Re-rank or re-prioritize the existing task list.
- Read existing Notion tasks. It is append-only, one row per invocation (or per task in a multi-task line).
- Touch Outlook, Gmail, or the calendar.
