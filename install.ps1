# spec-first installer for Windows (PowerShell)
#
# Usage (one-liner from any project directory):
#   iwr -useb https://raw.githubusercontent.com/nlatuan187/spec-first/master/install.ps1 | iex
#
# What it does:
#   1. Detects your AI tool and appends snippet.md to the right context file
#   2. Copies spec.md and review.md to your project root
#   3. Creates specs/ directory
#   4. Installs /spec /spec-review /spec-check for Claude Code (if detected)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$REPO = "https://raw.githubusercontent.com/nlatuan187/spec-first/master"
$PROJECT_DIR = (Get-Location).Path

# ── Detect which context file to use ───────────────────────────────────────

function Get-ContextFile {
    if (Test-Path ".cursorrules")                        { return ".cursorrules" }
    if (Test-Path ".windsurfrules")                      { return ".windsurfrules" }
    if (Test-Path "AGENTS.md")                           { return "AGENTS.md" }
    if (Test-Path ".github\copilot-instructions.md")     { return ".github\copilot-instructions.md" }
    return "CLAUDE.md"   # default — Claude Code
}

$CONTEXT_FILE = Get-ContextFile

Write-Host ""
Write-Host "spec-first installer"
Write-Host "---------------------"
Write-Host "Project: $PROJECT_DIR"
Write-Host "Context file: $CONTEXT_FILE"
Write-Host ""

# ── Fetch snippet ───────────────────────────────────────────────────────────

$snippet = (Invoke-WebRequest "$REPO/snippet.md" -UseBasicParsing).Content

# ── Step 1: Append to context file ─────────────────────────────────────────

$target = Join-Path $PROJECT_DIR $CONTEXT_FILE
$targetDir = Split-Path $target -Parent

if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
}

if ((Test-Path $target) -and ((Get-Content $target -Raw -ErrorAction SilentlyContinue) -match "Spec-First — AI Development Methodology")) {
    Write-Host "[OK] $CONTEXT_FILE already has spec-first methodology (skipping)"
} else {
    if (Test-Path $target) {
        Add-Content $target "`n`n---`n`n$snippet"
    } else {
        Set-Content $target $snippet
    }
    Write-Host "[OK] Appended to $CONTEXT_FILE"
}

# ── Step 2: Copy spec.md ───────────────────────────────────────────────────

(Invoke-WebRequest "$REPO/spec.md" -UseBasicParsing).Content | Set-Content "spec.md" -Encoding UTF8
Write-Host "[OK] spec.md -> project root"

# ── Step 3: Copy review.md ─────────────────────────────────────────────────

(Invoke-WebRequest "$REPO/review.md" -UseBasicParsing).Content | Set-Content "review.md" -Encoding UTF8
Write-Host "[OK] review.md -> project root"

# ── Step 4: Create specs/ ──────────────────────────────────────────────────

New-Item -ItemType Directory -Force -Path "specs" | Out-Null
Write-Host "[OK] specs/ ready"

# ── Step 5: Install Claude Code slash commands + hooks (if detected) ───────

$claudeDir = Join-Path $PROJECT_DIR ".claude"

if ((Test-Path $claudeDir) -or ($CONTEXT_FILE -eq "CLAUDE.md")) {
    Write-Host ""
    Write-Host "Claude Code detected — installing /spec /spec-review /spec-check /spec-stats commands..."
    $commandsDir = Join-Path $claudeDir "commands"
    New-Item -ItemType Directory -Force -Path $commandsDir | Out-Null

    (Invoke-WebRequest "$REPO/advanced/skills/spec/SKILL.md"        -UseBasicParsing).Content | Set-Content "$commandsDir\spec.md"         -Encoding UTF8
    (Invoke-WebRequest "$REPO/advanced/skills/spec-review/SKILL.md" -UseBasicParsing).Content | Set-Content "$commandsDir\spec-review.md"  -Encoding UTF8
    (Invoke-WebRequest "$REPO/advanced/skills/spec-check/SKILL.md"  -UseBasicParsing).Content | Set-Content "$commandsDir\spec-check.md"   -Encoding UTF8
    (Invoke-WebRequest "$REPO/advanced/skills/spec-stats/SKILL.md"  -UseBasicParsing).Content | Set-Content "$commandsDir\spec-stats.md"   -Encoding UTF8
    Write-Host "[OK] /spec -> /spec-review -> /spec-check -> /spec-stats installed"

    # ── Install SessionStart hook ─────────────────────────────────────────
    $hooksDir = Join-Path $claudeDir "spec-first"
    New-Item -ItemType Directory -Force -Path $hooksDir | Out-Null

    (Invoke-WebRequest "$REPO/hooks/session-start" -UseBasicParsing).Content | Set-Content "$hooksDir\session-start" -Encoding UTF8
    (Invoke-WebRequest "$REPO/hooks/pre-compact"   -UseBasicParsing).Content | Set-Content "$hooksDir\pre-compact"   -Encoding UTF8
    (Invoke-WebRequest "$REPO/hooks/session-end"   -UseBasicParsing).Content | Set-Content "$hooksDir\session-end"   -Encoding UTF8
    (Invoke-WebRequest "$REPO/hooks/run-hook.cmd"  -UseBasicParsing).Content | Set-Content "$hooksDir\run-hook.cmd"  -Encoding UTF8

    # Register hooks in .claude/settings.json (merge safely)
    $settingsFile = Join-Path $claudeDir "settings.json"

    $settings = @{}
    if (Test-Path $settingsFile) {
        try { $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json -AsHashtable } catch { $settings = @{} }
    }
    if (-not $settings.ContainsKey("hooks")) { $settings["hooks"] = @{} }

    $hookEntries = @(
        @{ event = "SessionStart"; cmd = ".claude/spec-first/run-hook.cmd session-start" },
        @{ event = "PreCompact";   cmd = ".claude/spec-first/run-hook.cmd pre-compact" },
        @{ event = "Stop";         cmd = ".claude/spec-first/run-hook.cmd session-end" }
    )

    $changed = $false
    foreach ($entry in $hookEntries) {
        if (-not $settings["hooks"].ContainsKey($entry.event)) { $settings["hooks"][$entry.event] = @() }
        $alreadyRegistered = $settings["hooks"][$entry.event] | Where-Object { $_ -match "spec-first" }
        if (-not $alreadyRegistered) {
            $settings["hooks"][$entry.event] += @{ hooks = @(@{ type = "command"; command = $entry.cmd }) }
            $changed = $true
            Write-Host "[OK] $($entry.event) hook registered in .claude/settings.json"
        } else {
            Write-Host "[OK] $($entry.event) hook already registered (skipping)"
        }
    }

    if ($changed) {
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding UTF8
    }
}

# ── Step 6: Scaffold KNOWLEDGE.md ─────────────────────────────────────────

$knowledgeFile = Join-Path $PROJECT_DIR "KNOWLEDGE.md"
if (-not (Test-Path $knowledgeFile)) {
    @"
# Project Knowledge — Cross-Session Memory

> Add learnings that future sessions need. Only add patterns confirmed 2+ times.
"@ | Set-Content $knowledgeFile -Encoding UTF8
    Write-Host "[OK] KNOWLEDGE.md scaffolded"
} else {
    Write-Host "[OK] KNOWLEDGE.md already exists (skipping)"
}

# ── Done ───────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "Done. Your AI is now spec-first."
Write-Host ""
Write-Host "  Next steps:"
Write-Host "  1. Open your AI tool (Claude Code, Cursor, Windsurf, etc.) in this folder"
Write-Host "  2. Type: build [describe what you want to create]"
Write-Host "  3. Your AI will ask up to 3 clarifying questions"
Write-Host "  4. Then write a spec file in specs/ -- no code yet"
Write-Host "  5. Review the spec, then open a new session to build"
Write-Host ""
Write-Host "  Cross-session memory: append project learnings to KNOWLEDGE.md"
Write-Host ""
Write-Host "  Files installed:"
Write-Host "    CLAUDE.md (or your AI context file) -- methodology loaded"
Write-Host "    spec.md                             -- spec template"
Write-Host "    review.md                           -- code review checklist"
Write-Host "    specs/                              -- your specs go here"
Write-Host "    .claude/spec-first/session-start    -- auto-inject hook"
Write-Host ""
Write-Host "  Not sure where to start? Read README.md"
Write-Host ""
