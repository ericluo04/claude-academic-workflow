# config/

Templates for the two settings files Claude Code reads from `~/.claude/`.

## Files

- `settings.example.json` -> installs to `~/.claude/settings.json`
- `settings.local.example.json` -> installs to `~/.claude/settings.local.json`

Both target files are user-local and should be gitignored once installed. The
templates ship in this repo; the installed copies live in `~/.claude/` and are
never version-controlled.

## What each file controls

`settings.json` is the global config. It registers the three hooks
(`PreCompact`, `SessionStart`, `PostToolUse`) against scripts in
`~/.claude/hooks/`, sets `autoUpdatesChannel`, `verbose`, and the base
permission mode. Edit this file when you change hook wiring or global defaults.

`settings.local.json` is per-user permission overrides. It is loaded after
`settings.json` and its `permissions.allow` array is merged into (not
substituted for) the base allowlist. Edit this file when you want to skip the
permission prompt for a command pattern you trust.

## `${HOME}` substitution

`settings.example.json` uses `${HOME}` in hook command paths. The installer
script (`install.ps1` / `install.sh`) replaces `${HOME}` with
`$env:USERPROFILE` on Windows or `$HOME` on macOS/Linux before writing the
final file. We use explicit substitution rather than `~` because Claude Code's
hook command runner does not reliably expand tilde inside the `command` string
on Windows.

The `_comments` top-level key documents each section. JSON has no native
comment syntax; the installer strips `_comments` before writing.

## Adding a permission entry

In `settings.local.json`, add a string to `permissions.allow`. Two formats:

- Exact match: `"Bash(git status)"` -- only `git status` is auto-allowed.
- Prefix match: `"Bash(git:*)"` -- any `git ...` invocation is auto-allowed.

Quote paths that contain spaces. Escape backslashes in regex patterns. When
Claude Code prompts to remember a permission, it writes the entry here for you.

## Why we don't ship a full personal allowlist

Lan's working `settings.local.json` has 25+ entries, most of which pin
absolute paths to his Dropbox/Overleaf project directories. Those paths are
worthless to anyone else and would leak project structure. The template ships
with a minimal safe allowlist (read-only git, Python, Node, LaTeX tooling)
plus a `_personalized_examples` block showing the path-templated form. Add
your own entries as you go -- Claude Code will offer to remember each one.

## Platform notes

Path conventions, shell quirks, and tilde-expansion gotchas live in
[`../docs/platforms.md`](../docs/platforms.md). Read it before debugging hook
or permission issues on Windows.
