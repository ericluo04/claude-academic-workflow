# Overleaf ↔ Dropbox sync

Overleaf has native Dropbox sync — there's no custom code in this workflow for it. Every paper this workflow touches lives in Dropbox so skills like `/draft`, `/referee-response`, and `/audit-reproducibility` can read and write `.tex` files directly.

## 1. Enable Dropbox sync (per project)

In the Overleaf editor:

1. Menu (top-left) → Sync.
2. Click Dropbox → Authorize.
3. Repeat for each Overleaf project you want synced.

Overleaf creates a folder at `<Dropbox>/Apps/Overleaf/<Project Name>/` mirroring the project tree.

## 2. Path convention

Skills assume the same layout regardless of OS:

```
<Dropbox>/Apps/Overleaf/<Project Name>/
├── main.tex
├── sections/
├── figures/
├── tables/
└── references.bib
```

Resolved per-platform examples:

| OS | Resolved path |
|---|---|
| Windows | `C:\Users\<you>\Dropbox\Apps\Overleaf\ProjectA\` |
| macOS (newer Dropbox) | `~/Library/CloudStorage/Dropbox/Apps/Overleaf/ProjectA/` |
| macOS (legacy Dropbox) | `~/Dropbox/Apps/Overleaf/ProjectA/` |
| Linux | `~/Dropbox/Apps/Overleaf/ProjectA/` |

See [platforms.md](platforms.md) for the canonical Dropbox-root locations.

### macOS CloudStorage workaround

Newer Dropbox releases route the folder into `~/Library/CloudStorage/Dropbox/`. If any of your tooling still expects the legacy `~/Dropbox` path, drop a symlink:

```bash
ln -s ~/Library/CloudStorage/Dropbox ~/Dropbox
```

This is safe and reversible; remove with `rm ~/Dropbox` (the symlink itself, not the real folder).

## 3. `personal_config.json` fields

After running the installer, fill in:

```json
{
  "paths": {
    "overleaf_root": "C:\\Users\\<you>\\Dropbox\\Apps\\Overleaf",
    "overleaf_root_mac": "/Users/<you>/Library/CloudStorage/Dropbox/Apps/Overleaf"
  }
}
```

Skills pick the right field based on `os.platform()` / `sys.platform`. Use forward slashes in JSON or escape backslashes (`\\`) — never single backslashes, which JSON parsers treat as escape sequences.

## 4. Caveats

- **Rate limits**: Overleaf throttles syncs to a few per minute. Burst saves can lag; if you don't see a file appear in Dropbox within ~30 seconds, refresh the Overleaf project.
- **Merge conflicts**: Overleaf wins. If you edit the local file in your editor and someone else (or you on another device) edits in Overleaf, the Overleaf state overwrites yours on next sync. Edit in one place at a time, or use the Overleaf history view to recover.
- **Not synced**: `.aux`, `.log`, `.fls`, `.fdb_latexmk`, and other build artifacts are excluded from sync — Overleaf rebuilds them on its side. If you `latexmk` locally, expect a `build/` or `*.aux` cruft that won't appear in Overleaf.
- **`.bib` edits**: editing the `.bib` locally is fine; `/cite` writes there. Avoid simultaneous edits in Overleaf's bib editor.

## 5. Quick verify

```powershell
# Windows
Test-Path "$env:USERPROFILE\Dropbox\Apps\Overleaf"
```

```bash
# macOS / Linux
ls -la "$HOME/Library/CloudStorage/Dropbox/Apps/Overleaf" 2>/dev/null \
  || ls -la "$HOME/Dropbox/Apps/Overleaf"
```

Should list one folder per Overleaf project. If it's empty, sync hasn't run yet — open any Overleaf project and trigger a save.
