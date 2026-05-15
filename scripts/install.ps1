<#
.SYNOPSIS
    Install Lan Luo's Claude Code academic workflow (skills, agents, hooks) into ~/.claude/.

.DESCRIPTION
    Copies skills/, agents/, hooks/ from this repo into $env:USERPROFILE\.claude\.
    Renders config/settings.example.json -> ~/.claude/settings.json (HOME placeholder expanded).
    Seeds ~/.claude/state/personal_config.json from skills/_config/personal_config.example.json.
    Reports missing MCPs. Idempotent. Does not require admin.

.PARAMETER DryRun
    Print actions without writing anything.

.PARAMETER Force
    Skip the y/N confirmation and overwrite existing installs.

.EXAMPLE
    .\install.ps1
    .\install.ps1 -DryRun
    .\install.ps1 -Force
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force
)

# ---------- Pretty output ----------
function Write-Info($msg)  { Write-Host "[..] $msg" -ForegroundColor Cyan }
function Write-Ok($msg)    { Write-Host "[ok] $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "[!!] $msg" -ForegroundColor Yellow }
function Write-Err($msg)   { Write-Host "[XX] $msg" -ForegroundColor Red }
function Write-Step($msg)  { Write-Host ""; Write-Host "=== $msg ===" -ForegroundColor Magenta }

# ---------- Resolve repo root ----------
$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $RepoRoot "skills"))) {
    Write-Err "Could not resolve repo root from `$PSScriptRoot ($PSScriptRoot)."
    Write-Err "Expected a 'skills/' directory at: $RepoRoot"
    exit 2
}
$ClaudeHome = Join-Path $env:USERPROFILE ".claude"

Write-Step "Claude Academic Workflow Installer (Windows)"
Write-Info "Repo root  : $RepoRoot"
Write-Info "Claude home: $ClaudeHome"
if ($DryRun) { Write-Warn "DRY RUN -- no files will be written." }

# ---------- Detect Claude Code ----------
Write-Step "Detecting Claude Code"
$claude = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claude) {
    Write-Err "claude CLI not found on PATH."
    Write-Err "Install Claude Code first: https://docs.anthropic.com/en/docs/claude-code"
    exit 3
}
Write-Ok "Found claude at $($claude.Source)"

# ---------- Detect OS ----------
Write-Step "Detecting OS"
$osVer = [System.Environment]::OSVersion
if ($osVer.Platform -ne 'Win32NT') {
    Write-Err "This installer is for Windows. Detected: $($osVer.Platform). Use install.sh on Mac/Linux."
    exit 4
}
if ($env:WSL_DISTRO_NAME) {
    Write-Warn "WSL detected ($env:WSL_DISTRO_NAME). Consider running install.sh from inside WSL instead."
}
Write-Ok "Windows $($osVer.Version)"

# ---------- Inventory source ----------
$SrcSkills   = Join-Path $RepoRoot "skills"
$SrcAgents   = Join-Path $RepoRoot "agents"
$SrcHooks    = Join-Path $RepoRoot "hooks"
$SrcSettings = Join-Path $RepoRoot "config\settings.example.json"
$SrcPersonal = Join-Path $RepoRoot "skills\_config\personal_config.example.json"

$skillCount = 0
$agentCount = 0
$hookCount  = 0
if (Test-Path $SrcSkills) { $skillCount = (Get-ChildItem -Directory $SrcSkills | Measure-Object).Count }
if (Test-Path $SrcAgents) { $agentCount = (Get-ChildItem -File $SrcAgents -Filter "*.md" | Where-Object { $_.Name -ne "README.md" } | Measure-Object).Count }
if (Test-Path $SrcHooks)  { $hookCount  = (Get-ChildItem -File $SrcHooks | Measure-Object).Count }

Write-Step "Plan"
Write-Info "This will install $skillCount skills, $agentCount agents, $hookCount hooks to $ClaudeHome"

# ---------- Confirm ----------
if (-not $Force -and -not $DryRun) {
    $resp = Read-Host "Continue? [y/N]"
    if ($resp -notmatch '^[yY]') {
        Write-Warn "Aborted by user."
        exit 1
    }
}

# ---------- Helper: copy with backup ----------
function Install-Dir($src, $name) {
    $dst = Join-Path $ClaudeHome $name
    if (-not (Test-Path $src)) {
        Write-Warn "Source missing: $src (skipping)"
        return
    }
    if (Test-Path $dst) {
        $existing = Get-ChildItem $dst -Force -ErrorAction SilentlyContinue
        if ($existing -and -not $Force) {
            $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $backup = Join-Path $ClaudeHome "_backup_$stamp\$name"
            Write-Warn "$name already populated at $dst -- backing up to $backup"
            if (-not $DryRun) {
                New-Item -ItemType Directory -Force -Path (Split-Path -Parent $backup) | Out-Null
                Move-Item -Path $dst -Destination $backup -Force
            }
        } elseif ($existing -and $Force) {
            Write-Warn "$name already populated -- --Force given, overwriting"
            if (-not $DryRun) { Remove-Item -Recurse -Force $dst }
        }
    }
    Write-Info "Copying $name -> $dst"
    if (-not $DryRun) {
        New-Item -ItemType Directory -Force -Path $dst | Out-Null
        Copy-Item -Path (Join-Path $src "*") -Destination $dst -Recurse -Force
    }
    Write-Ok  "$name installed"
}

# ---------- Ensure ~/.claude exists ----------
Write-Step "Installing to $ClaudeHome"
if (-not (Test-Path $ClaudeHome)) {
    Write-Info "Creating $ClaudeHome"
    if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $ClaudeHome | Out-Null }
}

try {
    Install-Dir $SrcSkills "skills"
    Install-Dir $SrcAgents "agents"
    Install-Dir $SrcHooks  "hooks"
} catch {
    Write-Err "Copy failed: $_"
    exit 5
}

# ---------- Render settings.json + settings.local.json ----------
Write-Step "Rendering settings.json and settings.local.json"
$SrcSettingsLocal = Join-Path $RepoRoot "config\settings.local.example.json"
$dstSettings      = Join-Path $ClaudeHome "settings.json"
$dstSettingsLocal = Join-Path $ClaudeHome "settings.local.json"
$renderScript     = Join-Path $ScriptDir "_render_settings.py"

function Render-Settings {
    param([string]$src, [string]$dst, [string]$name)
    if (-not (Test-Path $src)) {
        Write-Warn "$name not found at $src -- skipping render"
        return
    }
    if ((Test-Path $dst) -and -not $Force) {
        Write-Warn "$dst already exists -- leaving in place (use -Force to overwrite)"
        return
    }
    Write-Info "Writing $dst"
    if (-not $DryRun) {
        $py = (Get-Command python -ErrorAction SilentlyContinue).Source
        if (-not $py) { $py = (Get-Command python3 -ErrorAction SilentlyContinue).Source }
        if (-not $py) { Write-Err "python not found on PATH"; return }
        & $py $renderScript $src $dst
        if ($LASTEXITCODE -ne 0) { Write-Err "Render failed for $src"; return }
    }
    Write-Ok "$name rendered (HOME -> $env:USERPROFILE)"
}

Render-Settings $SrcSettings      $dstSettings      "settings.json"
Render-Settings $SrcSettingsLocal $dstSettingsLocal "settings.local.json"

# ---------- Seed personal_config.json ----------
Write-Step "Seeding personal_config.json"
$StateDir = Join-Path $ClaudeHome "state"
$dstPersonal = Join-Path $StateDir "personal_config.json"
if (-not (Test-Path $SrcPersonal)) {
    Write-Warn "skills/_config/personal_config.example.json not found -- skipping seed"
} elseif (Test-Path $dstPersonal) {
    Write-Ok "Existing config preserved -- edit it manually: $dstPersonal"
} else {
    Write-Info "Creating $dstPersonal"
    if (-not $DryRun) {
        New-Item -ItemType Directory -Force -Path $StateDir | Out-Null
        Copy-Item -Path $SrcPersonal -Destination $dstPersonal
    }
    Write-Ok "Seeded -- edit $dstPersonal with your IDs"
}

# ---------- MCP inventory ----------
Write-Step "MCP inventory"
$expectedMcps = @("github", "notion", "zotero", "arxiv", "semantic-scholar", "openalex", "playwright")
try {
    $mcpOut = & claude mcp list 2>&1 | Out-String
    Write-Host $mcpOut
    foreach ($m in $expectedMcps) {
        if ($mcpOut -match [regex]::Escape($m)) {
            Write-Ok  "MCP present : $m"
        } else {
            Write-Warn "MCP missing : $m  -- see docs/mcps.md"
        }
    }
} catch {
    Write-Warn "Could not run 'claude mcp list' -- see docs/mcps.md to add MCPs"
}

# ---------- Next steps ----------
Write-Step "Next steps"
Write-Host "  1. Edit $dstPersonal (see docs/notion-setup.md for Notion IDs)"
Write-Host "  2. Set up Telegram bot (see docs/telegram-setup.md)"
Write-Host "  3. Add any missing MCPs (see docs/mcps.md)"
Write-Host "  4. Run scripts/verify.ps1 to sanity-check the install"
Write-Host ""
Write-Ok "Install complete."
exit 0
