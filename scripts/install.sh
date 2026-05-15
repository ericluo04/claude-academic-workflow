#!/usr/bin/env bash
# install.sh -- Install Lan Luo's Claude Code academic workflow into ~/.claude/
#
# Usage:
#   ./install.sh              # interactive
#   ./install.sh --dry-run    # show actions without writing
#   ./install.sh --force      # skip prompt; overwrite existing
#   ./install.sh --help
set -euo pipefail

# ---------- Pretty output ----------
if [[ -t 1 ]]; then
    C_INFO=$'\e[36m'; C_OK=$'\e[32m'; C_WARN=$'\e[33m'; C_ERR=$'\e[31m'; C_STEP=$'\e[35m'; C_RESET=$'\e[0m'
else
    C_INFO=""; C_OK=""; C_WARN=""; C_ERR=""; C_STEP=""; C_RESET=""
fi
info() { printf '%s[..] %s%s\n' "$C_INFO" "$*" "$C_RESET"; }
ok()   { printf '%s[ok] %s%s\n' "$C_OK"   "$*" "$C_RESET"; }
warn() { printf '%s[!!] %s%s\n' "$C_WARN" "$*" "$C_RESET"; }
err()  { printf '%s[XX] %s%s\n' "$C_ERR"  "$*" "$C_RESET" >&2; }
step() { printf '\n%s=== %s ===%s\n' "$C_STEP" "$*" "$C_RESET"; }

# ---------- Args ----------
DRY_RUN=0
FORCE=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --force)   FORCE=1 ;;
        --help|-h)
            sed -n '2,8p' "$0"; exit 0 ;;
        *) err "Unknown arg: $arg"; exit 2 ;;
    esac
done

# ---------- Resolve repo root ----------
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
if [[ ! -d "$REPO_ROOT/skills" ]]; then
    err "Could not resolve repo root from $SCRIPT_DIR (no skills/ dir)"
    exit 2
fi
CLAUDE_HOME="$HOME/.claude"

step "Claude Academic Workflow Installer (Unix)"
info "Repo root  : $REPO_ROOT"
info "Claude home: $CLAUDE_HOME"
[[ $DRY_RUN -eq 1 ]] && warn "DRY RUN -- no files will be written."

# ---------- Detect claude CLI ----------
step "Detecting Claude Code"
if ! command -v claude >/dev/null 2>&1; then
    err "claude CLI not found on PATH."
    err "Install Claude Code first: https://docs.anthropic.com/en/docs/claude-code"
    exit 3
fi
ok "Found claude at $(command -v claude)"

# ---------- Detect OS ----------
step "Detecting OS"
UNAME="$(uname -s)"
case "$UNAME" in
    Darwin)  ok "macOS detected ($UNAME)" ;;
    Linux)   ok "Linux detected ($UNAME)" ;;
    MINGW*|MSYS*|CYGWIN*)
        warn "Windows shell ($UNAME) detected -- prefer install.ps1 on native Windows." ;;
    *) warn "Unknown OS ($UNAME) -- proceeding anyway." ;;
esac

# ---------- Inventory source ----------
SRC_SKILLS="$REPO_ROOT/skills"
SRC_AGENTS="$REPO_ROOT/agents"
SRC_HOOKS="$REPO_ROOT/hooks"
SRC_SETTINGS="$REPO_ROOT/config/settings.example.json"
SRC_PERSONAL="$REPO_ROOT/skills/_config/personal_config.example.json"

count_dir() { [[ -d "$1" ]] && find "$1" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ' || echo 0; }
count_files() { [[ -d "$1" ]] && find "$1" -mindepth 1 -maxdepth 1 -type f -name "$2" ! -name "README.md" | wc -l | tr -d ' ' || echo 0; }

SKILL_COUNT=$(count_dir "$SRC_SKILLS")
AGENT_COUNT=$(count_files "$SRC_AGENTS" "*.md")
HOOK_COUNT=$(count_files "$SRC_HOOKS"  "*")

step "Plan"
info "This will install $SKILL_COUNT skills, $AGENT_COUNT agents, $HOOK_COUNT hooks to $CLAUDE_HOME"

# ---------- Confirm ----------
if [[ $FORCE -eq 0 && $DRY_RUN -eq 0 ]]; then
    read -r -p "Continue? [y/N] " resp
    if [[ ! "$resp" =~ ^[yY] ]]; then
        warn "Aborted by user."
        exit 1
    fi
fi

# ---------- Helper: copy with backup ----------
install_dir() {
    local src="$1" name="$2"
    local dst="$CLAUDE_HOME/$name"
    if [[ ! -d "$src" ]]; then
        warn "Source missing: $src (skipping)"
        return 0
    fi
    if [[ -d "$dst" ]] && [[ -n "$(ls -A "$dst" 2>/dev/null || true)" ]]; then
        if [[ $FORCE -eq 0 ]]; then
            local stamp; stamp=$(date +%Y%m%d_%H%M%S)
            local backup="$CLAUDE_HOME/_backup_$stamp/$name"
            warn "$name already populated -- backing up to $backup"
            if [[ $DRY_RUN -eq 0 ]]; then
                mkdir -p "$(dirname "$backup")"
                mv "$dst" "$backup"
            fi
        else
            warn "$name already populated -- --force given, overwriting"
            [[ $DRY_RUN -eq 0 ]] && rm -rf "$dst"
        fi
    fi
    info "Copying $name -> $dst"
    if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$dst"
        cp -R "$src"/. "$dst"/
    fi
    ok "$name installed"
}

# ---------- Ensure ~/.claude exists ----------
step "Installing to $CLAUDE_HOME"
[[ $DRY_RUN -eq 0 ]] && mkdir -p "$CLAUDE_HOME"

install_dir "$SRC_SKILLS" "skills"
install_dir "$SRC_AGENTS" "agents"
install_dir "$SRC_HOOKS"  "hooks"

# ---------- Render settings.json + settings.local.json ----------
step "Rendering settings.json and settings.local.json"
SRC_SETTINGS_LOCAL="$REPO_ROOT/config/settings.local.example.json"
DST_SETTINGS="$CLAUDE_HOME/settings.json"
DST_SETTINGS_LOCAL="$CLAUDE_HOME/settings.local.json"
RENDER="python3 $SCRIPT_DIR/_render_settings.py"

render_one() {
    local src="$1" dst="$2" name="$3"
    if [[ ! -f "$src" ]]; then
        warn "$name not found at $src -- skipping render"
        return 0
    fi
    if [[ -f "$dst" && $FORCE -eq 0 ]]; then
        warn "$dst already exists -- leaving in place (use --force to overwrite)"
        return 0
    fi
    info "Writing $dst"
    if [[ $DRY_RUN -eq 0 ]]; then
        $RENDER "$src" "$dst" || { err "Render failed for $src"; return 1; }
    fi
    ok "$name rendered (HOME -> $HOME)"
}

render_one "$SRC_SETTINGS"       "$DST_SETTINGS"       "settings.json"
render_one "$SRC_SETTINGS_LOCAL" "$DST_SETTINGS_LOCAL" "settings.local.json"

# ---------- Seed personal_config.json ----------
step "Seeding personal_config.json"
STATE_DIR="$CLAUDE_HOME/state"
DST_PERSONAL="$STATE_DIR/personal_config.json"
if [[ ! -f "$SRC_PERSONAL" ]]; then
    warn "skills/_config/personal_config.example.json not found -- skipping seed"
elif [[ -f "$DST_PERSONAL" ]]; then
    ok "Existing config preserved -- edit it manually: $DST_PERSONAL"
else
    info "Creating $DST_PERSONAL"
    if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "$STATE_DIR"
        cp "$SRC_PERSONAL" "$DST_PERSONAL"
    fi
    ok "Seeded -- edit $DST_PERSONAL with your IDs"
fi

# ---------- MCP inventory ----------
step "MCP inventory"
EXPECTED_MCPS=(github notion zotero arxiv semantic-scholar openalex playwright)
if MCP_OUT="$(claude mcp list 2>&1)"; then
    echo "$MCP_OUT"
    for m in "${EXPECTED_MCPS[@]}"; do
        if grep -qE "$m" <<<"$MCP_OUT"; then
            ok   "MCP present : $m"
        else
            warn "MCP missing : $m  -- see docs/mcps.md"
        fi
    done
else
    warn "Could not run 'claude mcp list' -- see docs/mcps.md to add MCPs"
fi

# ---------- Next steps ----------
step "Next steps"
echo "  1. Edit $DST_PERSONAL (see docs/notion-setup.md for Notion IDs)"
echo "  2. Set up Telegram bot (see docs/telegram-setup.md)"
echo "  3. Add any missing MCPs (see docs/mcps.md)"
echo "  4. Run scripts/verify.sh to sanity-check the install"
echo ""
ok "Install complete."
exit 0
