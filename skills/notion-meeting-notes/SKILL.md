---
name: notion-meeting-notes
description: Pull a Notion AI meeting-notes page, extract the `### Action Items` list from its `<summary>` block, keep only the items whose owner is the user, and file each as a new task in the user's Notion Tasks DB with inferred Priority/Type/Project/Due and `Source = Meeting`. Use this skill whenever the user says "/notion-meeting-notes <url-or-id>", "process meeting notes: <url>", "extract action items from <url>", "file meeting tasks", "log action items from the meeting", or "what did I commit to in that meeting", and also whenever they paste a Notion URL alongside phrases like "co-author meeting notes", "advisor meeting", or any collaborator name from `personal_config.collaborators` — even when they don't explicitly say the word "skill". Trigger on any combination of a Notion URL or page-ID and the words "meeting", "action items", "co-author meeting", or a known collaborator name — that combination is this skill's signal. Strictly distinct from `/log-todo` (single inline todo, no Notion read), `/notion-log` (append diary entry to a project page, no task creation), and `/capture` (process inbound Telegram replies). Does not modify the meeting page, does not mark anything done, does not call Telegram.
---

# notion-meeting-notes

## Personalization

This skill resolves placeholders against `~/.claude/state/personal_config.json`. See `_config/README.md` and `_config/personal_config.example.json` for setup. If the config is missing or a needed field is unset, the skill must surface an error to the user and refuse to proceed rather than guess.

Required config fields:
- `personal_config.user.name` (to recognise self-owned action items, e.g. "Alex to draft section 3")
- `personal_config.user.aliases` (optional — additional ways the user may appear in transcripts: nickname, initials, "you", "I", "me")
- `personal_config.collaborators` (list of first names of frequent collaborators; used for the hollow-transcript gate and for owner detection)
- `personal_config.notion.tasks_data_source_id`
- `personal_config.notion.project_pages` (used by the project inference rules below)

## Purpose

Turn a Notion AI meeting-notes page into filed tasks in the user's Tasks DB. The meeting transcription feature drops a `<meeting-notes>` block on the page with a `<summary>` containing `### Action Items`. Most items are formatted `- [ ] <Owner> to <task> [^citation]` — this skill reads them, keeps only the ones owned by the user, and creates one Notion task per item with sensible defaults.

A dedicated skill helps here because `/log-todo` handles one-off inline captures, but a meeting frequently produces 3-8 commitments at once with different owners. Filing them by hand is tedious and it is easy to lose track of which items were the user's vs. their co-authors'. This skill does the split.

## When to invoke

Invoke immediately when the user provides a Notion URL or page ID together with any of:

- `/notion-meeting-notes <url-or-id>`
- "process meeting notes: <url>"
- "extract action items from <url>"
- "file meeting tasks"
- "log action items from the meeting"
- "what did I commit to in that meeting"
- "<collaborator name> meeting notes" with a URL pasted in

Also invoke if the user pastes a Notion URL alongside a known collaborator name from `personal_config.collaborators` and any meeting/action-item keyword — that combination is the canonical signal.

Do **not** invoke for arbitrary Notion pages without a `<meeting-notes>` block; defer to `/notion-log` or `/log-todo` instead.

## Workflow

1. **Parse input.** Accept either a full URL or a bare page ID. Strip query strings and dashes; the trailing 32-char hex is the page ID.

2. **Fetch the page** with `mcp__notion__notion-fetch`. Look for a `<meeting-notes>` block. Within it, locate `<summary>` and the `### Action Items` heading. The `<transcript>` block is omitted by fetch — that's fine, this skill only needs the summary.

3. **Hollow-transcript gate.** Before parsing in earnest, sanity-check the page is actually a substantive meeting. Count action items by regexing `- \[ \]` lines inside the `### Action Items` block, and collect capitalized first-name tokens anywhere in the page body, intersected with `personal_config.collaborators`. If the page has **< 2 action items** OR **zero known names appear**, pause and surface this message to chat:

   > Page has N action items, M owned by you. Page does not mention any of the usual collaborators by first name. Proceed with task creation, or did you paste the wrong URL?

   Wait for confirmation before continuing. Do not call `mcp__notion__notion-create-pages` until the user says go. If the page is dense (>=2 action items AND >=1 known name), skip the gate silently and proceed to step 4. This guards against pasting the wrong URL, an empty stub page, or a Notion meeting that never got transcribed.

4. **Parse action items.** Each line typically looks like `- [ ] <Owner> to <task> [^citation]`. For each:
   - **Owner** = first token after `- [ ]`, ending at the literal " to " (case-sensitive — "<Name> to" not "<Name> TO").
   - **Task body** = everything between " to " and the first `[^` (or end of line).
   - **Citation footnotes** = anything matching `[^…]` — preserve as a Notes appendix so the transcript moment is recoverable.

5. **Filter to the user.** Keep items where Owner is the user's name from `personal_config.user.name`, any alias in `personal_config.user.aliases`, "you", "I", or "me". Drop items owned by named collaborators. For unowned/ambiguous items (no "X to" prefix, or "we to …"), flag them in the report rather than silently filing or dropping.

6. **Infer defaults per surviving task** (consistent with `/log-todo`):
   - **Priority** = `P1` by default (meeting commitments are time-sensitive — higher than the `/log-todo` default of P2). Bump to `P0` for "ASAP" / "before EOD" / "tomorrow"; demote to `P2` for "eventually" / "when I get to it".
   - **Est min** = 30 default. 60 if task contains "draft", "write up", "code", "run". 15 if "email", "ping", "reply", "forward".
   - **Type** — see action-item parsing rules below.
   - **Project** — see project inference rules.
   - **Due** — explicit date phrases ("by Friday", "next Tuesday", "tomorrow") parse to actual dates. Otherwise default to 7 days from the meeting date (extract meeting date from the page's `<mention-date>` block or from page title; fall back to today + 7).
   - **Source** = `Meeting`.
   - **Notes** = the meeting page URL plus any `[^…]` citations preserved verbatim.

7. **Create tasks.** Call `mcp__notion__notion-create-pages` with `parent: {type: "data_source_id", data_source_id: "{{personal_config.notion.tasks_data_source_id}}"}`. Batch when possible. Each page's title is the cleaned task body (without the `- [ ]` and without the citation footnotes).

8. **Report back** in chat with three sections:
   - **Filed for you (N):** bulleted list with new task URLs.
   - **Not filed — other owners (M):** bulleted list of `<Owner>: <task>` so the user can see what their teammates committed to and chase later.
   - **Ambiguous (K):** items with no clear owner — ask whether to file or skip.

## Action item parsing rules

- Owners are case-sensitive prefixes ending at `" to "`. "<UserName> to fix steering app" → Owner=user, Task=`fix steering app`. "<Collaborator> to run waterfall" → Owner=collaborator, drop.
- First-person phrasings (`"I'll send the draft"`, `"me to ping <name>"`) count as user-owned. Notion's AI sometimes transcribes the user's own voice as "you" — treat second-person ownership as user too, since they are running this skill in their own workspace.
- Compound owners (`"<User> and <Collaborator> to coauthor the intro"`) → file for the user AND list under "Not filed — other owners" so the collaborator's half stays visible.
- Bullets without the `<Owner> to` pattern → ambiguous; report separately.
- Strip Notion's `[^https://…]` transcript-citation footnotes from the task title but preserve them in the Notes field — they're how the user jumps back to the moment in the transcript.

**Type inference from task verbs:**

| Keyword pattern | Type |
| --- | --- |
| `draft`, `write`, `revise`, `analyze`, `run`, `code`, `estimate`, `replicate`, `proofread` | Research |
| `email`, `schedule`, `book`, `submit`, `reimburse`, `file`, `ping`, `forward`, `reply` | Admin |
| `teach`, `prep`, `lecture`, `office hours`, `MBA`, `class` | Teaching |
| `book flight`, `hotel`, `Uber`, `travel` | Travel |
| default | Research (most meeting commitments are research work) |

## Project inference rules

Inherit from `/notion-log`'s mapping so the projects align across skills. Inference order: (1) meeting-page parent in Notion (matched against `personal_config.notion.project_pages` values), (2) keywords in the action-item text, (3) collaborator names declared in `personal_config.projects[].collaborators`.

| Signal | Project |
| --- | --- |
| Page parented under a project page in `personal_config.notion.project_pages` | that project |
| Action-item text matches a project name or alias from `personal_config.projects[]` | that project |
| Collaborator on the action item matches `personal_config.projects[].collaborators` for exactly one project | that project |
| Tie or no signal | leave Project empty and flag in the report |

If two projects tie, prefer the meeting-page parent — that's the strongest signal.

## Examples

**Example 1: project meeting with one collaborator**

Input: `process meeting notes: https://www.notion.so/<id>`

The fetched `### Action Items` contains:
```
- [ ] Collaborator1 to run waterfall on held-out data [^https://...]
- [ ] <User> to fix steering app to use instruction format [^https://...]
- [ ] <User> to draft the prompt v3 by Friday
- [ ] Collaborator2 to retrain on the new split
```

Action: file 2 tasks for the user under Project=ProjectC (resolved via project keyword or page parent), Type=Research. Task 1 gets Due = meeting-date + 7. Task 2 explicitly says "by Friday" → parse to next Friday's date. Report Collaborator1's and Collaborator2's items under "Not filed — other owners".

**Example 2: data-collection meeting**

Input: `Collaborator3 meeting notes https://www.notion.so/<id>`

The summary has:
```
- [ ] Collaborator3 to scrape next 30 cases
- [ ] <User> to email Collaborator4 about access by Wednesday
- [ ] <User> to write up identification strategy section
```

Action: file 2 tasks for the user. The email is Type=Admin, Est=15min, Due=Wednesday. The write-up is Type=Research, Est=60min, Due=meeting+7. Report Collaborator3's scraping task as "Not filed".

**Example 3: advisor meeting, no clear project parent**

Input: `/notion-meeting-notes <id>` for a page where the parent isn't a specific project subpage.

The summary has:
```
- [ ] <User> to revise ProjectB intro framing
- [ ] <User> to send advisor the updated ProjectA draft
- [ ] We to discuss the third paper next week
```

Action: file 2 tasks — first under Project=ProjectB (keyword), second under Project=ProjectA (keyword). The third item ("We to discuss…") has no clear owner — report under Ambiguous and ask whether to file as a user task or a calendar reminder.

## Failure modes

- **No `<meeting-notes>` block on the page.** Report to the user and stop. Suggest confirming the URL is a meeting-notes page; offer `/notion-log` for a diary entry instead, or `/log-todo` for a single task.
- **Page fetch fails.** Surface the MCP error verbatim — usually a permissions or token-refresh issue. Do not retry silently.
- **Malformed action items** (no `### Action Items` heading, free-prose summary, bullets without `- [ ]`). Best-effort parse what looks like commitments; everything that can't be confidently parsed goes to the Ambiguous bucket.
- **Ambiguous owner.** Items like "We to X" or bare action-verb bullets (`"- [ ] follow up on robustness"`) get flagged, not filed. Ask the user to disambiguate before creating the task — silently guessing risks polluting the Tasks DB.
- **Empty action-item list.** Tell the user the meeting produced no commitments and suggest checking the `<notes>` section manually.
- **Duplicate detection** is out of scope — if the same meeting gets processed twice, duplicate tasks will be filed. The user can dedupe in the Tasks DB; flagging this in the report keeps the skill predictable.

## Out of scope

- Does **not** modify the meeting page (no edits, no new blocks appended). The `<meeting-notes>` block is autogenerated and should be untouched.
- Does **not** mark anything as Done in the Tasks DB. Use `/capture` (Telegram replies) or manual Notion UI for completion.
- Does **not** call Telegram. The daily brief skill / capture skill own that surface.
- Does **not** process arbitrary Notion pages — only pages that contain a `<meeting-notes>` block.
- Does **not** build the daily brief (`/daily-brief`) — it only files raw tasks. The brief will pick them up the next morning via its existing query.
- Does **not** write outside the Tasks DB. Project pages, the Weekly Agenda, and the Research subtree are not touched.
