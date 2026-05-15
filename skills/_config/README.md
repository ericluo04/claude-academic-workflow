# Personalization config for skills

Most skills in this repo ship clean — no Notion IDs, no absolute paths, no email addresses, no Telegram chat IDs. That makes the skills publicly shareable and lets you fork them. Every value that would otherwise have been hardcoded lives in **one** gitignored JSON file:

```
~/.claude/state/personal_config.json
```

(On Windows that resolves to `%USERPROFILE%\.claude\state\personal_config.json`. The `~/.claude/state/` directory is the same one Claude Code already uses for ephemeral state.)

Skills read this file at invocation. If a skill needs a field and the field is missing or unset, the skill is required to **surface an error and refuse to proceed** rather than guess. This is by design — guessing produces silently wrong results (wrong Notion page, wrong project Bib, wrong collaborator).

## Setup

1. Copy the template:

   **Mac / Linux:**
   ```bash
   mkdir -p ~/.claude/state
   cp skills/_config/personal_config.example.json ~/.claude/state/personal_config.json
   ```

   **Windows PowerShell:**
   ```powershell
   New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\state" | Out-Null
   Copy-Item skills\_config\personal_config.example.json "$env:USERPROFILE\.claude\state\personal_config.json"
   ```

2. Open `~/.claude/state/personal_config.json` in any editor and replace the placeholder strings with your own values. Fields are documented below.

3. Confirm it's gitignored. The repo's `.gitignore` already blocks `**/personal_config.json` and `**/state/`, but if you've moved the file, add the new path.

4. Sanity-check by running `/task-pulse "any open tasks"` (read-only, hits Notion) once you've filled in `notion.tasks_data_source_id`. If you see "config missing", the skill found the file but a required field is unset.

## Fields, with what consumes them

### `user`

| Field | What it is | Consumed by |
|---|---|---|
| `name` | Your full name | `/replication-package` (README author block), `/evaluate-idea-marketing`, `/evaluate-idea-science` (report Author line), `/notion-meeting-notes` (recognises self-owned action items) |
| `aliases` | Other ways you might appear in a Notion transcript: nickname, initials, `"you"`, `"I"`, `"me"` | `/notion-meeting-notes` |
| `local_username` | Your OS username — used to strip path prefixes during replication-package sanitization | `/replication-package` |
| `personal_email` | Personal email (Gmail etc.) | Optional. Used by `/replication-package` to skip flagging your own email as "third-party PII" |
| `university_email` | Affiliated email | `/replication-package` (contact block in generated README) |
| `affiliation` | Institution string | `/replication-package`, `/evaluate-idea-*` |
| `voice_style_ref` | Absolute path to a `.tex` or `.md` file that captures your writing voice fingerprint (hedging vocabulary, preferred macros, citation idioms). If you don't have one, point to an existing paper of yours | `/draft`, `/referee-response`, `/evaluate-idea-*` |

To find your `local_username` on Mac: `whoami`. On Windows: `$env:USERNAME` in PowerShell.

### `collaborators`

A flat list of first names for the hollow-transcript gate in `/notion-meeting-notes`. The gate refuses to file tasks if a Notion meeting-notes page mentions zero of these names — it's an "are you sure this is the right URL?" sanity check.

Use first names only, casing as it appears in transcripts. Add a name when you start collaborating with someone whose meeting notes you want to ingest.

### `notion`

You need a Notion integration token (configured for the Notion MCP — see `docs/notion-setup.md`) AND the page / database IDs below. Notion IDs are 32 hexadecimal characters; you can pull them from a Notion URL — the trailing chunk after the last `-` or `/`.

| Field | What it is | Consumed by |
|---|---|---|
| `tasks_db_id` | The Tasks **database** ID | (Available for skills that need to identify the DB rather than its data source) |
| `tasks_data_source_id` | The Tasks **data-source** ID (Notion exposes both for databases; the MCP uses data-source IDs for queries) | `/daily-brief`, `/capture`, `/log-todo`, `/task-pulse`, `/notion-meeting-notes` |
| `tasks_parent_page_id` | The 32-char hex ID of the page that holds the Tasks DB and the daily `Brief YYYY-MM-DD` child pages | `/capture` |
| `weekly_agenda_page_id` | The Weekly Agenda page (off-limits to `/notion-log` writes) | `/notion-log` |
| `project_pages` | Map of `ProjectName` -> Notion page ID for each research project that gets diary entries | `/notion-log`, `/notion-meeting-notes` |
| `off_limits_pages` | Array of page IDs that `/notion-log` must refuse to write to (personal pages, grocery lists, financial ongoing-thoughts, etc.) | `/notion-log` |

### `telegram`

The Telegram bot is optional. It enables the daily-brief / capture loop. If you're not using it, leave fields as placeholders — the orchestration skills will fail loudly if invoked, which is correct.

| Field | What it is | Consumed by |
|---|---|---|
| `bot_username` | Your bot's handle (e.g. `mytasks_bot`) | docs only — not consumed by skill code |
| `chat_id` | Your numeric Telegram chat ID (string is fine) | `/daily-brief`, `/capture` — but read at runtime from `<claude_state_dir>/telegram.json`, not from this file |

**The bot token is NOT in `personal_config.json`.** It belongs in:

- A separate gitignored `~/.claude/state/telegram.json` file (used by the local skills), shaped `{"bot_token": "...", "chat_id": "..."}`.
- GitHub Actions Secrets, for any scheduled cron jobs.

This separation is intentional. `personal_config.json` is something you might back up to Dropbox or copy across machines; the bot token has to roll on compromise.

### `paths`

Use forward slashes everywhere — they work on both Windows and Mac in Python and PowerShell, and they don't get mangled by JSON escape rules. Skills read both the Windows and Mac variants and pick based on `os.name` / `$IsWindows`.

| Field | What it is | Consumed by |
|---|---|---|
| `overleaf_root` (Win) / `overleaf_root_mac` (Mac) | Root directory containing all Overleaf-synced project subdirs | `/draft`, `/cite`, `/referee-response`, `/replication-package`, `/audit-reproducibility`, `/bibcheck`, `/create-lecture`, `/slide-excellence`, `/blindspot`, `/seven-pass-review`, `/preregister` |
| `research_root` | Optional non-Overleaf research dir (for working papers not yet in Overleaf) | `/draft` fallback |
| `claude_state_dir` (Win) / `claude_state_dir_mac` (Mac) | Where ephemeral state files live (`today_brief.json`, `last_3_briefs.json`, `telegram.json`, `telegram_offset.json`) | `/daily-brief`, `/capture` |
| `home_paths_to_redact` | Array of absolute-path prefixes the replication-package sanitizer should strip | `/replication-package` |

### `projects`

An array of objects, one per active research project. Each entry tells the skills:

| Field | What it is | Consumed by |
|---|---|---|
| `name` | Canonical name (matches a key in `notion.project_pages`) | All project-aware skills |
| `aliases` | Common shorthand the user might use in chat (`"projA"`, `"the JMP"`, etc.) | `/log-todo`, `/draft`, `/notion-log` for fuzzy matching |
| `kind` | E.g. `research-paper`, `book-chapter` | Informational |
| `stage` | E.g. `"R&R at MKSCI"`, `"JMP"`, `"working paper"` | `/draft` uses this to set tone |
| `overleaf_subdir` | Subdirectory under `paths.overleaf_root` | `/draft`, `/referee-response`, `/replication-package`, `/cite` |
| `main_tex` | Filename of the main `.tex` (some projects use `mainR2.tex`, others `main.tex`) | `/draft`, `/seven-pass-review`, `/referee-response`, `/audit-reproducibility` |
| `bib_file` | Filename of the `.bib` | `/cite`, `/bibcheck`, `/draft` |
| `preamble_tex` | Filename of the project's preamble (default `preamble.tex`) | `/draft`, `/create-lecture`, `/slide-excellence` |
| `r2r_glob` | Glob for round-by-round response files (default `R2R_*.tex`) | `/referee-response` |
| `paper_slug` | lowercase-hyphenated short name used in zip filenames | `/replication-package` |
| `zotero_collection_key` | Better-BibTeX collection key for this project | `/cite`, `/litreview` |
| `collaborators` | Optional list of collaborators on this specific project — helps `/notion-meeting-notes` infer the right project from the meeting attendees | `/notion-meeting-notes` |

To find a Zotero collection key: open Zotero, right-click the collection, **Edit Collection** → URL bar shows `zotero://select/library/collections/<KEY>`.

## Adding a new project

1. Create the Overleaf project (or pick the existing folder under `paths.overleaf_root`).
2. Create the Notion page under your Research subtree. Copy its 32-char hex ID into `notion.project_pages[<NewProjectName>]`.
3. (Optional) Create a Zotero collection for it; copy the key into the new entry's `zotero_collection_key`.
4. Append a new `projects[]` entry with `name`, `overleaf_subdir`, `main_tex`, `bib_file`, and any aliases.

Save the file. Skills pick up the change on the next invocation — there's no reload step.

## Safe to share vs. never share

| Field | Safe to share? |
|---|---|
| `user.name`, `user.affiliation` | Yes (already public on your CV) |
| `user.aliases`, `user.local_username` | No — local username is a small infosec leak |
| `user.personal_email` | No |
| `user.university_email` | Yes (already public) |
| `notion.*` UUIDs | No — anyone with the integration token + ID can read the page |
| `notion.off_limits_pages` | Especially no |
| `telegram.chat_id` | No — anyone who knows the bot token and chat ID can DM you as the bot |
| `paths.*` | Mildly sensitive (reveals folder structure on your machine) |
| `projects[]` | Varies — names of unpublished WIPs are sensitive, names of accepted papers are not |
| Bot tokens, API keys | **Never** — they don't belong in this file at all |

The repo's `.gitignore` already excludes `**/personal_config.json`. CI runs a secret-scan on every PR. But the easiest way to never leak it is to keep it out of any repo tree — store it only at `~/.claude/state/personal_config.json`.

## Troubleshooting

**"Config missing" from a skill.**
The skill couldn't find `~/.claude/state/personal_config.json`. Check the path. On Windows, `~` resolves to `$env:USERPROFILE`, not `H:\` or the OneDrive root.

**"Required field unset".**
The file exists but the specific key the skill needs is still a placeholder (`<uuid>`, `Your Name`, etc.). The skill prints which field. Open the JSON, replace the placeholder, retry.

**"Notion page not found".**
The UUID is wrong (most likely a transposition), or the Notion integration hasn't been added to the page. In Notion: open the page → top-right `...` → Connections → confirm your integration is listed. Read `docs/notion-setup.md` for the full integration-permission walkthrough.

**Skill works on one machine, fails on another.**
The `personal_config.json` lives on disk and isn't synced by the repo. Copy it across, or store it in a personal Dropbox / iCloud Drive path and symlink to `~/.claude/state/personal_config.json` on each machine.

**Telegram skills fail with "credentials file missing".**
That's `~/.claude/state/telegram.json`, not `personal_config.json`. See `docs/telegram-setup.md`.

**The skill picks the wrong project from a free-form mention.**
Add an alias to that project's `aliases` array. The matcher is case-insensitive against `name` + each alias.
