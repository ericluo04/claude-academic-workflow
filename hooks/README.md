# Hooks

Claude Code hook scripts that run on harness lifecycle events (compaction, session start, tool use). Drop them in `~/.claude/hooks/` (or anywhere on disk) and register them in your `settings.json` — see `config/settings.example.json` for the registration shape.

All three hooks are **fail-open**: any internal error exits 0 silently so a bug in a hook can never block Claude Code itself. They log structured failures to `~/.claude/state/formatter.log` (and similar) for after-the-fact debugging. The `state/` directory is gitignored by this repo's `.gitignore`.

## Index

| Filename | Event | What it does | Optional tooling |
|---|---|---|---|
| `pre-compact.py` | `PreCompact` | Snapshots the current active plan (from `quality_reports/plans/*.md`), the first unchecked task in it, and recent decisions from the latest session log into `~/.claude/sessions/<project-hash>/pre-compact-state.json` so `post-compact-restore.py` can surface them after compaction. Opt-in DRAFT-plan guard (set `CLAUDE_PRECOMPACT_BLOCK_ON_DRAFT=1`) blocks compaction once per DRAFT plan to prevent losing mid-plan context. | Python 3.10+ |
| `post-compact-restore.py` | `SessionStart` (matcher `compact\|resume`) | Reads the pre-compact state snapshot, locates the most recent plan and session log under `quality_reports/`, and prints a "Context Restored" preamble to stdout so the model knows where it left off. Deletes the snapshot after reading. | Python 3.10+ |
| `format-on-edit.py` | `PostToolUse` (matcher `Edit\|Write\|MultiEdit`) | Auto-formats files just edited by Claude. `.py` → `ruff format`; `.R` / `.r` → `Rscript -e "styler::style_file(...)"`. Other extensions → no-op. Silent on success. Failures append to `~/.claude/state/formatter.log`. 10 s subprocess timeout per file. | Python 3.10+; `ruff` on PATH (for `.py`); `Rscript` + `styler` R package (for `.R`). All optional — the hook detects missing tools via `shutil.which` and silently skips. |

## Registration

Wire them into `~/.claude/settings.json` (user-scope) or `<project>/.claude/settings.json` (project-scope) under the `hooks` section. See `config/settings.example.json` in this repo for the full shape; the relevant entries look like:

```json
{
  "hooks": {
    "PreCompact": [
      { "matcher": "*", "hooks": [{ "type": "command", "command": "python ~/.claude/hooks/pre-compact.py" }] }
    ],
    "SessionStart": [
      { "matcher": "compact|resume", "hooks": [{ "type": "command", "command": "python ~/.claude/hooks/post-compact-restore.py" }] }
    ],
    "PostToolUse": [
      { "matcher": "Edit|Write|MultiEdit", "hooks": [{ "type": "command", "command": "python ~/.claude/hooks/format-on-edit.py" }] }
    ]
  }
}
```

On Windows, replace `python` with the full path to your Python interpreter if `python` is not on PATH, and expand `~` to `%USERPROFILE%` if your shell doesn't expand tildes.

## Project conventions assumed by the compact hooks

`pre-compact.py` and `post-compact-restore.py` look in the active project (`$CLAUDE_PROJECT_DIR`) for:

- `quality_reports/plans/*.md` — plan files with status keywords `DRAFT` / `APPROVED` / `COMPLETED` somewhere in the body and GitHub-flavored `- [ ]` task checkboxes for the first-unchecked-task heuristic.
- `quality_reports/session_logs/*.md` — append-only session journal; the pre-compact hook appends a "Context compaction at HH:MM" note to the newest file and the post-compact hook surfaces its name.

If neither directory exists, both hooks no-op gracefully. They never create these directories — they just won't surface plan/session context until you start using that convention.

## State directory

Both compaction hooks write to `~/.claude/sessions/<md5(project_dir)[:8]>/`:

- `pre-compact-state.json` — written by `pre-compact.py`, consumed and deleted by `post-compact-restore.py`.
- `precompact-block-sentinel.json` — written by `pre-compact.py` only when the DRAFT-plan guard fires; remembers the last plan path that triggered a block so the same plan can't trigger a second block.

`format-on-edit.py` writes failure notes to `~/.claude/state/formatter.log`. The `state/` directory tree is gitignored by this repo's `.gitignore`.

## Attribution

Authored by Lan Luo (https://github.com/ericluo04).
