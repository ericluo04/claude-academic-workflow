#!/usr/bin/env bash
# verify.sh -- Sanity-check the Claude Academic Workflow install at ~/.claude/
set -euo pipefail

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

[[ "${1:-}" == "--help" || "${1:-}" == "-h" ]] && { sed -n '2p' "$0"; echo "Usage: $0"; exit 0; }

CLAUDE_HOME="$HOME/.claude"
ISSUES=()

step "Verifying $CLAUDE_HOME"

# ---------- Skills ----------
EXPECTED_SKILLS=(
    academic-pptx academic-slides audit-reproducibility bibcheck blindspot
    capture cite council create-lecture daily-brief draft
    evaluate-idea-marketing evaluate-idea-science litreview log-todo
    notion-log notion-meeting-notes posterskill preregister referee-response
    referee2 replication-package review-grant review-pap review-paper
    review-paper-code review-paper-light seven-pass-review skill-creator
    slide-excellence task-pulse
)
step "Skills"
present=0; missing=()
for s in "${EXPECTED_SKILLS[@]}"; do
    if [[ -f "$CLAUDE_HOME/skills/$s/SKILL.md" ]]; then
        present=$((present+1))
    else
        missing+=("$s")
    fi
done
total=${#EXPECTED_SKILLS[@]}
if [[ $present -ge 25 ]]; then
    ok "$present/$total skills present (>=25 required)"
else
    err "Only $present/$total skills present (need >=25) -- see docs/skills.md"
    ISSUES+=("skills")
fi
[[ ${#missing[@]} -gt 0 ]] && warn "Missing: ${missing[*]}"

# ---------- Agents ----------
EXPECTED_AGENTS=(tikz-reviewer.md slide-auditor.md pedagogy-reviewer.md proofreader.md)
step "Agents"
for a in "${EXPECTED_AGENTS[@]}"; do
    if [[ -f "$CLAUDE_HOME/agents/$a" ]]; then
        ok "agents/$a"
    else
        err "Missing agents/$a -- see docs/agents.md"
        ISSUES+=("agent:$a")
    fi
done

# ---------- Hooks ----------
EXPECTED_HOOKS=(format-on-edit.py post-compact-restore.py pre-compact.py)
step "Hooks"
for h in "${EXPECTED_HOOKS[@]}"; do
    if [[ -f "$CLAUDE_HOME/hooks/$h" ]]; then
        ok "hooks/$h"
    else
        err "Missing hooks/$h -- see docs/hooks.md"
        ISSUES+=("hook:$h")
    fi
done

# ---------- settings.json ----------
step "settings.json"
SETTINGS="$CLAUDE_HOME/settings.json"
if [[ ! -f "$SETTINGS" ]]; then
    err "Missing $SETTINGS -- run scripts/install.sh"
    ISSUES+=("settings")
else
    if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$SETTINGS" 2>/dev/null; then
        ok "settings.json is valid JSON"
        hooks_found=0
        for h in "${EXPECTED_HOOKS[@]}"; do
            grep -qF "$h" "$SETTINGS" && hooks_found=$((hooks_found+1)) || true
        done
        if [[ $hooks_found -eq ${#EXPECTED_HOOKS[@]} ]]; then
            ok "All $hooks_found hooks registered"
        else
            warn "Only $hooks_found/${#EXPECTED_HOOKS[@]} hooks registered in settings.json"
            ISSUES+=("settings:hooks")
        fi
    else
        err "settings.json is NOT valid JSON"
        ISSUES+=("settings:json")
    fi
fi

# ---------- personal_config.json ----------
step "personal_config.json"
PC="$CLAUDE_HOME/state/personal_config.json"
if [[ -f "$PC" ]]; then
    ok "Present: $PC"
else
    err "Missing $PC -- see docs/notion-setup.md"
    ISSUES+=("personal_config")
fi

# ---------- MCPs ----------
step "MCPs"
EXPECTED_MCPS=(github notion zotero arxiv semantic-scholar openalex playwright)
if OUT="$(claude mcp list 2>&1)"; then
    for m in "${EXPECTED_MCPS[@]}"; do
        if grep -qF "$m" <<<"$OUT"; then ok "wired   : $m"; else warn "pending : $m  -- see docs/mcps.md"; fi
    done
else
    warn "Could not run 'claude mcp list' -- see docs/mcps.md"
fi

# ---------- Summary ----------
step "Summary"
if [[ ${#ISSUES[@]} -eq 0 ]]; then
    ok "All checks passed."
    exit 0
else
    err "${#ISSUES[@]} issue(s): ${ISSUES[*]}"
    err "See docs/ for fixes."
    exit 1
fi
