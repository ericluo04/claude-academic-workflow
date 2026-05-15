---
name: notion-log
description: End-of-session diary logger for the user's research projects — append a dated, timestamped entry to the bottom of the relevant Notion project page. Use this skill WHENEVER the user says "/notion-log <project>: <summary>", "log to notion: X", "update notion with what I did", "diary: X", "append to project page", "end-of-session log", "session log: X", "log my work on <project>", "note in notion that I…", "record today's progress on <project>", or otherwise asks to capture session work into their Notion research subtree. Append-only — never edits or deletes historical entries, never writes to personal pages, Weekly Agenda, the Tasks DB, or daily-brief pages. Strictly distinct from /log-todo (which files individual todos into the Tasks DB) and /capture (which processes inbound Telegram messages) — this is a diary/journal for a project page, not task creation.
---

# notion-log

## Personalization

This skill resolves placeholders against `~/.claude/state/personal_config.json`. See `_config/README.md` and `_config/personal_config.example.json` for setup. If the config is missing or a needed field is unset, the skill must surface an error to the user and refuse to proceed rather than guess.

Project page IDs come from `personal_config.notion.project_pages[<project>]`. Off-limits pages (Weekly Agenda, Tasks DB, personal pages) come from `personal_config.notion.off_limits_pages` and `personal_config.notion.tasks_db_id` / `personal_config.notion.weekly_agenda_page_id`. Filesystem locations for project subdirs come from `personal_config.paths.overleaf_root` and `personal_config.projects[].overleaf_subdir`.

## Purpose

Append-only diary for the user's active research projects in Notion. The user finishes a coding or writing session and wants a single timestamped paragraph at the bottom of the relevant project page recording what got done, with bullets for sub-items and a `follow-ups:` tail listing open todos surfaced in the summary.

This is a **diary skill**, not a task skill. It writes prose to a project page. It does not file todos (that's `/log-todo`), it does not process Telegram replies (that's `/capture`), it does not edit historical bullets in place (loses history — never do this).

## When to invoke

Invoke whenever the user signals end-of-session reporting on a research project. Triggers include:

- `/notion-log ProjectA: finished tertile robustness, started Section 4`
- "log to notion: spent 2 hours on ProjectB identification section"
- "update notion with what I did on ProjectC today"
- "diary: ProjectD — added dataset descriptives"
- "append to project page"
- "end-of-session log for ProjectE"
- "session log: ProjectF pivot discussion with coauthor"
- "log my work on ProjectB"
- "note in notion that I finished the IV first stage"

If the user just describes work but doesn't say "log it," ask once whether they want it logged before doing anything — don't auto-log unsolicited.

## Project page mapping

Map the project tag in the invocation to a Notion page ID, resolved from `personal_config.notion.project_pages`. The tag is whatever appears before the first colon (case-insensitive, common abbreviations resolved). Each project entry in `personal_config.projects[]` may declare `aliases` to absorb common shorthand.

Illustrative shape (the live mapping is driven by the user's config):

| Project tag (accepted variants) | Notion page ID |
|---|---|
| ProjectA, ProjectA aliases | `personal_config.notion.project_pages["ProjectA"]` |
| ProjectB, ProjectB aliases | `personal_config.notion.project_pages["ProjectB"]` |
| ProjectC, ProjectC aliases | `personal_config.notion.project_pages["ProjectC"]` |

If the tag is ambiguous or unrecognized, ask the user once which project they mean, then proceed. Never guess silently — wrong-page writes are hard to undo because the skill doesn't read history before appending.

For context references inside log entries (file paths, repos), the canonical filesystem locations come from `personal_config.paths.overleaf_root` joined with `personal_config.projects[*].overleaf_subdir`, e.g. `<OVERLEAF_ROOT>/<PROJECT_SUBDIR>/`.

## Workflow

1. **Parse target project.** Take everything before the first colon in the invocation argument. Lowercase, strip whitespace, look it up against the project table (resolved from `personal_config`). If no colon (e.g., "log my work on ProjectB"), pattern-match a project name out of the surrounding text. If still ambiguous, ask the user once.

2. **Parse work summary.** Take everything after the colon. If the message is a free-form description without a `Project:` prefix, after resolving the project name use the whole remaining text.

3. **Detect follow-ups.** Scan the summary for phrases like "still need to", "todo:", "next time", "follow up on", "haven't done X yet", "should X". Collect these as a comma-separated list for the `follow-ups:` tail. If none, omit the tail.

4. **Compose the append entry.** Use this exact shape:

   ```
   <YYYY-MM-DD> <morning|afternoon|evening|late-night> — <one-sentence summary>
   • <bullet 1>
   • <bullet 2>
   follow-ups: <comma-list>
   ```

   Time-of-day is rough (`morning` before 12, `afternoon` 12–17, `evening` 17–22, `late-night` 22–04). Bullets are optional — only include if the work splits cleanly into multiple sub-items. A one-thing session is fine as a single line with no bullets.

   Format dates as bold (`**2026-05-11**`). Format file paths and commit hashes as inline code. Format URLs as links.

5. **Append via Notion MCP.** Use `mcp__notion__notion-update-page` (or whichever Notion MCP tool appends children — check available tools at invocation time; the correct tool is the one that adds block children to an existing page without modifying existing blocks). Append a single `paragraph` block (or a small group: paragraph + bulleted_list_items + paragraph for follow-ups) to the END of the target project page. Do NOT modify existing blocks. Do NOT delete blocks. Do NOT touch the page's title or properties.

   If the Notion MCP exposes a mention-date block primitive (e.g., `<mention-date start="..." timeZone="America/New_York"/>`), prefer that over a plain text date. If not, plain bold text date is fine.

6. **Cross-link inline.** If the summary mentions:
   - A **file path** → render it as inline code.
   - A **git commit hash** (7+ hex chars) → render as inline code, and if a repo URL is obvious from context, link it.
   - A **PR number** (`#123`) → leave as plain text unless the repo is unambiguous.
   - A **Notion Tasks DB item** ("task XYZ in the Tasks DB") → leave as plain text reference; this skill does not write to the Tasks DB and does not try to create cross-page relations programmatically.

7. **Report back.** Print to chat:

   ```
   Logged to <Project Name> page. <N> follow-up(s) detected.
   ```

   If `N > 0`, append a one-liner suggesting `/log-todo` to file them as actual tasks. If `N == 0`, omit that line.

## What to NEVER write to

These pages are explicitly off-limits for this skill, even if the user asks (confirm and refuse, or redirect to a different skill):

- **Weekly Agenda** (`personal_config.notion.weekly_agenda_page_id`) — that's the active todo surface; appending diary prose pollutes it. If the user wants a weekly recap, suggest a separate weekly-recap page or just write it as part of the relevant project page.
- **Tasks DB** (`personal_config.notion.tasks_db_id`) — that's `/log-todo`'s territory. Diary entries are not tasks.
- **Daily brief / today_brief.json pages** — generated by `/daily-brief`, ephemeral.
- **Meeting Notes pages** — autogenerated by Notion's AI transcription, do not modify.
- **Personal pages** listed in `personal_config.notion.off_limits_pages` (e.g., grocery lists, cook lists, jokes, bucket lists, onboarding details, ongoing-thoughts pages that contain personal finance info).
- **Idea-bank pages** under Research that are not active projects (e.g., Natural Experiments, Substantive Areas, Methodology, Misc). These are quiet thinking spaces; don't auto-append diary entries there.

If the resolved page ID is not in the active-project map, stop and confirm before writing.

## Examples

**Example 1 — ProjectA progress log (with follow-ups).**

Invocation:
```
/notion-log ProjectA: finished reproducing tertile robustness in Section 5.2, started writing the R2 response to Reviewer 2's identification concern. Still need to redo the placebo with the new bandwidth and email a coauthor about the panel data extension.
```

Resolved project: `ProjectA` → `personal_config.notion.project_pages["ProjectA"]`.

Appended entry (rendered as Notion blocks):
```
**2026-05-11** afternoon — Finished tertile robustness in 5.2 and began R2 reply to R2's identification concern.
• Reproduced tertile robustness, Section 5.2 of `<OVERLEAF_ROOT>/<PROJECT_SUBDIR>/`
• Drafted opening of R2-Reviewer2 identification response
follow-ups: redo placebo with new bandwidth, email coauthor re panel data extension
```

Report: `Logged to ProjectA page. 2 follow-ups detected — run /log-todo to file them as tasks.`

**Example 2 — ProjectB idea note (no follow-ups, single bullet).**

Invocation:
```
diary: ProjectB — read Berger & Packard (2022) on linguistic similarity, thinking it could ground the cover-text similarity measure used in Section 3
```

Resolved project: `ProjectB` → `personal_config.notion.project_pages["ProjectB"]`.

Appended entry:
```
**2026-05-11** evening — Reading note: Berger & Packard (2022) on linguistic similarity could ground the similarity measure in Section 3.
```

Report: `Logged to ProjectB page.`

**Example 3 — Post-meeting summary.**

Invocation:
```
session log: ProjectC — met with coauthor, agreed to switch from 16k to 32k SAE features. Need to retrain overnight and update the demo defaults to match new feature IDs.
```

Resolved project: `ProjectC` → `personal_config.notion.project_pages["ProjectC"]`.

Appended entry:
```
**2026-05-11** afternoon — Coauthor meeting: agreed to switch from 16k → 32k SAE features.
• Retrain overnight
• Update demo defaults to match new feature IDs
follow-ups: retrain SAE 32k, update demo defaults
```

Report: `Logged to ProjectC page. 2 follow-ups detected — run /log-todo to file them as tasks.`

## Failure modes

- **Project not recognized.** Tag doesn't match any row in the resolved project map and the surrounding text gives no hint. Stop, list the active projects from `personal_config`, ask the user which one. Do not pick a default.
- **Notion MCP unavailable / page not shared with integration.** If the append tool returns a permissions error, print the error verbatim, suggest checking that the integration has access to the Research subtree, and offer to write the entry to a local fallback file (`~/.claude/skills/notion-log/unsent/<date>.md`) so the work isn't lost. Do not silently swallow the error.
- **Page locked or read-only.** Same handling as above — surface the error, offer the local fallback.
- **Notion API throttled / network down.** Retry once after a few seconds. If still failing, fall back to local file and tell the user.
- **Summary is empty (just `/notion-log ProjectA:` with nothing after).** Don't append a content-free entry. Ask the user what they want logged.
- **Ambiguous project across multiple pages.** Default to the most-specific match, but mention the disambiguation in the chat report so the user can correct.

## Out of scope

- **No edits to historical entries.** Appending only. If the user wants to fix a typo in yesterday's entry, they open Notion and do it manually — automated edits to existing blocks risk corrupting Notion's AI-meeting blocks and structured checklist history.
- **No writes to the Notion Tasks DB.** That's `/log-todo`'s job. This skill mentions follow-ups in prose and suggests `/log-todo`; it does not create task rows itself.
- **No writes to personal / non-research pages.** Listed in "What to NEVER write to" above.
- **No reads of Notion to build context before writing.** This skill is intentionally write-only — it does not pull current page state, does not summarize prior entries, does not dedupe. Project pages are append-only by convention and reading first would be wasted work.
- **No multi-project broadcasts.** One invocation, one project. To log to two projects, run the skill twice.
- **No editing of Notion's AI Meeting Notes blocks.** Those are auto-generated; touching them breaks Notion's transcription feature.
