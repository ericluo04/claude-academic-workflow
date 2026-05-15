# Notion workspace setup

The workflow assumes a specific Notion layout: a unified Tasks database, a Weekly Agenda page, and one page per active research project. This doc walks through creating that structure, wiring the Notion MCP, and populating `personal_config.json`.

A duplicatable template is `<TBD — public template link to be added>`; until then, build it by hand following the structure below.

## 1. Workspace layout

```
Workspace
├── Research/
│   ├── ProjectA              ← project diary page (one per active paper)
│   ├── ProjectB
│   └── ProjectC
├── Weekly Agenda             ← Mon–Fri columns + "Ongoing Thoughts"
└── Tasks                     ← the unified Tasks DB (table view)
```

### Tasks DB columns

Create a new database, table view, with these properties:

| Property | Type | Notes |
|---|---|---|
| Task | Title | Required. The action sentence. |
| Status | Status | `Open`, `Doing`, `Done`, `Dropped` |
| Priority | Select | `P0`, `P1`, `P2`, `P3` |
| Due | Date | Optional; only set when there's a hard deadline |
| Est min | Number | Estimated minutes — drives `/daily-brief` capacity math |
| Type | Select | `Research`, `Teaching`, `Admin`, `Personal`, `Health`, `Travel`, `Social` |
| Project | Select | One option per project (ProjectA, ProjectB, ...) |
| Energy | Select | `High`, `Medium`, `Low` |
| Context | Multi-select | `computer`, `phone-OK`, `deep-focus`, `shallow` |
| Source | Select | `Manual`, `Telegram`, `Meeting`, `Recurring` |
| Recurring | Checkbox | True if cloned daily/weekly by automation |
| Notes | Text | Free-form context |
| Agenda block | Relation | → Weekly Agenda page (optional) |
| Meeting block | Relation | → Meeting notes pages (optional) |

### Weekly Agenda page

A plain page (not a DB) with five columns labelled Monday through Friday and a final paragraph block titled "Ongoing Thoughts". `/daily-brief` and the recurring reconciler read this page; `/notion-log` does not write to it.

### Project diary pages

One page per active paper, named for the project (e.g., `ProjectA`). `/notion-log` appends dated entries to the bottom of these pages — append-only, never edits history.

## 2. Create the Notion integration

You have two paths; the OAuth gateway is simpler.

### Path A — Notion MCP (OAuth gateway, recommended)

```powershell
# Windows
claude mcp add notion --transport http https://mcp.notion.com/mcp
```

```bash
# macOS / Linux
claude mcp add notion --transport http https://mcp.notion.com/mcp
```

On first tool call the CLI opens a browser. Sign in, pick the workspace that owns the Tasks DB, allow the integration to access **only the parent pages of the structure above** (don't grant whole-workspace access if you can avoid it).

### Path B — Internal integration (legacy, if you also script via REST)

1. Notion → Settings → Integrations → New integration → Internal.
2. Name it something like "claude-workflow". Copy the secret (`secret_...`); store it in env var `NOTION_API_KEY` rather than on disk.
3. Open each parent page (Research, Weekly Agenda, Tasks) → `...` → Connections → Add the integration. **The integration must be added to every parent page individually** — Notion does not cascade permissions.

## 3. Find the page IDs

The skills reference Notion entities by ID. To extract:

1. Open the page in a browser.
2. Copy the URL — e.g., `https://www.notion.so/My-Workspace/Tasks-1234567890abcdef1234567890abcdef`.
3. The trailing 32 hex chars are the ID. Reformat with hyphens to canonical UUID form: `12345678-90ab-cdef-1234-567890abcdef`.

You need IDs for:

- The Tasks DB (database ID).
- The **data source ID** of the Tasks DB (see FAQ below — this is NOT the same as the DB ID).
- The Weekly Agenda page.
- Each project diary page.

## 4. Populate `personal_config.json`

After running the installer (see [adapting.md](adapting.md)) you'll have `~/.claude/state/personal_config.json`. Fill in the Notion section:

```json
{
  "notion": {
    "tasks_db_id": "<your-tasks-db-id>",
    "tasks_data_source_id": "<your-tasks-data-source-id>",
    "weekly_agenda_page_id": "<your-weekly-agenda-page-id>",
    "project_pages": {
      "ProjectA": "<page-id-for-ProjectA>",
      "ProjectB": "<page-id-for-ProjectB>"
    }
  }
}
```

Skills like `/log-todo`, `/task-pulse`, `/notion-log` read these IDs; never hard-code IDs into skill source.

## 5. FAQ — Notion's gotchas

**Q: What's the difference between a database ID and a data source ID?**

A: Notion's API recently introduced "data sources" as a layer beneath databases — one DB can expose multiple data-source views with different filter/sort defaults. The MCP `query` tools take a data-source ID, not the DB ID. To find it: open the DB, inspect a table view, copy the `collection://...` URL from the share menu; the UUID after `collection://` is the data-source ID.

**Q: Why does the integration need to be added to each parent page?**

A: Notion's permission model is per-page, not workspace-wide. Even with the integration installed, it can only see pages explicitly granted via the Connections menu. If a skill returns "not found" for a page you can see in the UI, this is almost always the cause.

**Q: I see a `collection://...` URL — what is that?**

A: Notion's internal URI for a data-source view. The MCP query tools accept either the bare data-source UUID or the full `collection://` URL.

## 6. Verify

```text
/task-pulse "what's open this week"
```

Should return a list of tasks from your Tasks DB. If it errors with a permissions message, recheck step 2 (integration access). If it returns empty, recheck the data-source ID in step 4.

A second verification:

```text
/log-todo "test the workflow"
```

Should create a row in the Tasks DB with `Source = Manual` and return the new page URL. Open the URL to confirm the row landed in the right DB.

## 7. ASCII structure diagram

For reference when fixing a broken layout:

```
Workspace (your private workspace)
│
├── Research/                                          ← parent page
│   ├── ProjectA                                       ← diary page; /notion-log writes here
│   │   ├── 2026-05-15 ─ session log entry
│   │   ├── 2026-05-14 ─ session log entry
│   │   └── ...
│   ├── ProjectB
│   └── ProjectC
│
├── Weekly Agenda                                      ← Mon–Fri layout
│   ├── Mon | Tue | Wed | Thu | Fri (columns)
│   └── Ongoing Thoughts (paragraph at bottom)
│
└── Tasks                                              ← the unified Tasks DB
    └── (table view with the columns listed in §1)
```

The integration (or the OAuth-connected MCP) must be granted access to **Research**, **Weekly Agenda**, and **Tasks** as three separate Connections. Granting access to the parent workspace is not sufficient because Notion's permission model is per-page.

## 8. Common errors

- **"object_not_found" when querying the Tasks DB**: integration is not connected to the Tasks page. Fix: open Tasks → `...` → Connections → Add `claude-workflow`.
- **`/log-todo` succeeds but the row doesn't appear**: you're filtering by a saved view. Switch to the default view to confirm the row exists.
- **`/task-pulse` returns rows from the wrong DB**: `tasks_data_source_id` in `personal_config.json` points to the wrong DB. Re-extract using the `collection://` URL from the share menu.
- **OAuth re-consent loop**: revoke the integration in Notion settings and re-run `claude mcp add notion --transport http ...`.
