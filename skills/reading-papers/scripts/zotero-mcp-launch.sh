#!/bin/zsh
# Launch zotero-mcp with credentials from the shared secrets file,
# keeping keys out of any settings.json.
set -a
source ~/.claude/secrets/scholar.env 2>/dev/null
set +a
exec "$HOME/.local/bin/zotero-mcp" "$@"
