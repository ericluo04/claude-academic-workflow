<#
.SYNOPSIS
    Verify a Claude Academic Workflow install at ~/.claude/.

.DESCRIPTION
    Checks for expected skills, agents, hooks, settings.json validity,
    personal_config.json presence, and lists MCPs.

.EXAMPLE
    .\verify.ps1
#>
[CmdletBinding()]
param()

function Write-Info($m) { Write-Host "[..] $m" -ForegroundColor Cyan }
function Write-Ok($m)   { Write-Host "[ok] $m" -ForegroundColor Green }
function Write-Warn($m) { Write-Host "[!!] $m" -ForegroundColor Yellow }
function Write-Err($m)  { Write-Host "[XX] $m" -ForegroundColor Red }
function Write-Step($m) { Write-Host ""; Write-Host "=== $m ===" -ForegroundColor Magenta }

$ClaudeHome = Join-Path $env:USERPROFILE ".claude"
$Issues = @()

Write-Step "Verifying $ClaudeHome"

# ---------- Skills ----------
$ExpectedSkills = @(
    "academic-pptx","academic-slides","audit-reproducibility","bibcheck","blindspot",
    "capture","cite","council","create-lecture","daily-brief","draft",
    "evaluate-idea-marketing","evaluate-idea-science","litreview","log-todo",
    "notion-log","notion-meeting-notes","posterskill","preregister","referee-response",
    "referee2","replication-package","review-grant","review-pap","review-paper",
    "review-paper-code","review-paper-light","seven-pass-review","skill-creator",
    "slide-excellence","task-pulse"
)
Write-Step "Skills"
$present = 0; $missing = @()
foreach ($s in $ExpectedSkills) {
    $p = Join-Path $ClaudeHome "skills\$s\SKILL.md"
    if (Test-Path $p) { $present++ } else { $missing += $s }
}
if ($present -ge 25) {
    Write-Ok "$present/$($ExpectedSkills.Count) skills present (>=25 required)"
} else {
    Write-Err "Only $present/$($ExpectedSkills.Count) skills present (need >=25) -- see docs/skills.md"
    $Issues += "skills"
}
if ($missing.Count -gt 0) { Write-Warn ("Missing: " + ($missing -join ", ")) }

# ---------- Agents ----------
$ExpectedAgents = @("tikz-reviewer.md","slide-auditor.md","pedagogy-reviewer.md","proofreader.md")
Write-Step "Agents"
foreach ($a in $ExpectedAgents) {
    $p = Join-Path $ClaudeHome "agents\$a"
    if (Test-Path $p) { Write-Ok "agents\$a" } else { Write-Err "Missing agents\$a -- see docs/agents.md"; $Issues += "agent:$a" }
}

# ---------- Hooks ----------
$ExpectedHooks = @("format-on-edit.py","post-compact-restore.py","pre-compact.py")
Write-Step "Hooks"
foreach ($h in $ExpectedHooks) {
    $p = Join-Path $ClaudeHome "hooks\$h"
    if (Test-Path $p) { Write-Ok "hooks\$h" } else { Write-Err "Missing hooks\$h -- see docs/hooks.md"; $Issues += "hook:$h" }
}

# ---------- settings.json ----------
Write-Step "settings.json"
$settings = Join-Path $ClaudeHome "settings.json"
if (-not (Test-Path $settings)) {
    Write-Err "Missing $settings -- run scripts/install.ps1"
    $Issues += "settings"
} else {
    try {
        $json = Get-Content -Raw $settings | ConvertFrom-Json
        Write-Ok "settings.json is valid JSON"
        $hooksFound = 0
        foreach ($h in $ExpectedHooks) {
            if ((Get-Content -Raw $settings) -match [regex]::Escape($h)) { $hooksFound++ }
        }
        if ($hooksFound -eq $ExpectedHooks.Count) {
            Write-Ok "All $hooksFound hooks registered"
        } else {
            Write-Warn "Only $hooksFound/$($ExpectedHooks.Count) hooks registered in settings.json"
            $Issues += "settings:hooks"
        }
    } catch {
        Write-Err "settings.json is NOT valid JSON: $_"
        $Issues += "settings:json"
    }
}

# ---------- personal_config.json ----------
Write-Step "personal_config.json"
$pc = Join-Path $ClaudeHome "state\personal_config.json"
if (Test-Path $pc) {
    Write-Ok "Present: $pc"
} else {
    Write-Err "Missing $pc -- see docs/notion-setup.md"
    $Issues += "personal_config"
}

# ---------- MCPs ----------
Write-Step "MCPs"
$ExpectedMcps = @("github","notion","zotero","arxiv","semantic-scholar","openalex","playwright")
try {
    $out = & claude mcp list 2>&1 | Out-String
    foreach ($m in $ExpectedMcps) {
        if ($out -match [regex]::Escape($m)) { Write-Ok "wired   : $m" }
        else { Write-Warn "pending : $m  -- see docs/mcps.md" }
    }
} catch {
    Write-Warn "Could not run 'claude mcp list' -- see docs/mcps.md"
}

# ---------- Summary ----------
Write-Step "Summary"
if ($Issues.Count -eq 0) {
    Write-Ok "All checks passed."
    exit 0
} else {
    Write-Err "$($Issues.Count) issue(s): $($Issues -join ', ')"
    Write-Err "See docs/ for fixes."
    exit 1
}
