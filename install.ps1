# spec-first installer for Windows (PowerShell)
#
# Usage (one-liner from any project directory):
#   iwr -useb https://raw.githubusercontent.com/nlatuan187/spec-first/master/install.ps1 | iex
#
# What it does:
#   1. Detects your AI tool and appends snippet.md to the right context file
#   2. Copies spec.md, verify.md, system.md and review.md to your project root
#   3. Creates specs/ and docs/system/ directories
#   4. Installs /spec /spec-review /spec-check /spec-reconcile /spec-stats for Claude Code (if detected)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$REPO = "https://raw.githubusercontent.com/nlatuan187/spec-first/master"
$PROJECT_DIR = (Get-Location).Path
$SCRIPT_DIR = if ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { $PROJECT_DIR }
$LOCAL = Test-Path (Join-Path $SCRIPT_DIR "snippet.md")

# ── Detect which context file to use ───────────────────────────────────────

function Get-ContextFile {
    if (Test-Path ".cursorrules")                        { return ".cursorrules" }
    if (Test-Path ".windsurfrules")                      { return ".windsurfrules" }
    if (Test-Path "AGENTS.md")                           { return "AGENTS.md" }
    if (Test-Path ".github\copilot-instructions.md")     { return ".github\copilot-instructions.md" }
    if (Test-Path "CLAUDE.md")                           { return "CLAUDE.md" }
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

if ($LOCAL) {
    $snippet = Get-Content (Join-Path $SCRIPT_DIR "snippet.md") -Raw
} else {
    $snippet = (Invoke-WebRequest "$REPO/snippet.md" -UseBasicParsing).Content
}

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

# ── Step 2-3: Copy the four templates ─────────────────────────────────────
# Existing files are left alone — a project that has already tailored its
# spec template must not have that work overwritten by a re-run.

foreach ($t in @("spec.md", "verify.md", "system.md", "review.md")) {
    $dest = Join-Path $PROJECT_DIR $t
    if (Test-Path $dest) {
        Write-Host "[OK] $t already exists (skipping)"
        continue
    }
    if ($LOCAL) {
        Copy-Item (Join-Path $SCRIPT_DIR $t) $dest
    } else {
        (Invoke-WebRequest "$REPO/$t" -UseBasicParsing).Content | Set-Content $dest -Encoding UTF8
    }
    Write-Host "[OK] $t -> project root"
}

# ── Step 4: Create specs/ and docs/system/ ─────────────────────────────────

New-Item -ItemType Directory -Force -Path (Join-Path $PROJECT_DIR "specs") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $PROJECT_DIR "docs\system") | Out-Null
Write-Host "[OK] specs/ ready"

# ── Step 5: Install Claude Code slash commands + hooks (if detected) ───────

$claudeDir      = Join-Path $PROJECT_DIR ".claude"
$CLAUDE_COMMANDS = Join-Path $claudeDir "commands"
$CLAUDE_HOOKS    = Join-Path $claudeDir "spec-first"

if ((Test-Path $claudeDir) -or ($CONTEXT_FILE -eq "CLAUDE.md")) {
    Write-Host ""
    Write-Host "Claude Code detected — installing /spec /spec-review /spec-check /spec-reconcile /spec-stats commands..."
    New-Item -ItemType Directory -Force -Path $CLAUDE_COMMANDS | Out-Null

    if ($LOCAL) {
        Copy-Item (Join-Path $SCRIPT_DIR "advanced\skills\spec\SKILL.md")         (Join-Path $CLAUDE_COMMANDS "spec.md")
        Copy-Item (Join-Path $SCRIPT_DIR "advanced\skills\spec-review\SKILL.md")  (Join-Path $CLAUDE_COMMANDS "spec-review.md")
        Copy-Item (Join-Path $SCRIPT_DIR "advanced\skills\spec-check\SKILL.md")   (Join-Path $CLAUDE_COMMANDS "spec-check.md")
        Copy-Item (Join-Path $SCRIPT_DIR "advanced\skills\spec-reconcile\SKILL.md") (Join-Path $CLAUDE_COMMANDS "spec-reconcile.md")
        Copy-Item (Join-Path $SCRIPT_DIR "advanced\skills\spec-stats\SKILL.md")   (Join-Path $CLAUDE_COMMANDS "spec-stats.md")
    } else {
        (Invoke-WebRequest "$REPO/advanced/skills/spec/SKILL.md"        -UseBasicParsing).Content | Set-Content (Join-Path $CLAUDE_COMMANDS "spec.md")        -Encoding UTF8
        (Invoke-WebRequest "$REPO/advanced/skills/spec-review/SKILL.md" -UseBasicParsing).Content | Set-Content (Join-Path $CLAUDE_COMMANDS "spec-review.md") -Encoding UTF8
        (Invoke-WebRequest "$REPO/advanced/skills/spec-check/SKILL.md"  -UseBasicParsing).Content | Set-Content (Join-Path $CLAUDE_COMMANDS "spec-check.md")  -Encoding UTF8
        (Invoke-WebRequest "$REPO/advanced/skills/spec-reconcile/SKILL.md" -UseBasicParsing).Content | Set-Content (Join-Path $CLAUDE_COMMANDS "spec-reconcile.md") -Encoding UTF8
        (Invoke-WebRequest "$REPO/advanced/skills/spec-stats/SKILL.md"  -UseBasicParsing).Content | Set-Content (Join-Path $CLAUDE_COMMANDS "spec-stats.md")  -Encoding UTF8
    }
    Write-Host "[OK] /spec -> /spec-review -> /spec-check -> /spec-reconcile -> /spec-stats installed"

    # ── Install hooks ─────────────────────────────────────────────────────────
    New-Item -ItemType Directory -Force -Path $CLAUDE_HOOKS | Out-Null

    if ($LOCAL) {
        Copy-Item (Join-Path $SCRIPT_DIR "hooks\session-start")  (Join-Path $CLAUDE_HOOKS "session-start")
        Copy-Item (Join-Path $SCRIPT_DIR "hooks\pre-compact")    (Join-Path $CLAUDE_HOOKS "pre-compact")
        Copy-Item (Join-Path $SCRIPT_DIR "hooks\session-end")    (Join-Path $CLAUDE_HOOKS "session-end")
        Copy-Item (Join-Path $SCRIPT_DIR "hooks\pre-tool-use")   (Join-Path $CLAUDE_HOOKS "pre-tool-use")
        Copy-Item (Join-Path $SCRIPT_DIR "hooks\run-hook.cmd")   (Join-Path $CLAUDE_HOOKS "run-hook.cmd")
    } else {
        (Invoke-WebRequest "$REPO/hooks/session-start"  -UseBasicParsing).Content | Set-Content (Join-Path $CLAUDE_HOOKS "session-start")  -Encoding UTF8
        (Invoke-WebRequest "$REPO/hooks/pre-compact"    -UseBasicParsing).Content | Set-Content (Join-Path $CLAUDE_HOOKS "pre-compact")    -Encoding UTF8
        (Invoke-WebRequest "$REPO/hooks/session-end"    -UseBasicParsing).Content | Set-Content (Join-Path $CLAUDE_HOOKS "session-end")    -Encoding UTF8
        (Invoke-WebRequest "$REPO/hooks/pre-tool-use"   -UseBasicParsing).Content | Set-Content (Join-Path $CLAUDE_HOOKS "pre-tool-use")   -Encoding UTF8
        (Invoke-WebRequest "$REPO/hooks/run-hook.cmd"   -UseBasicParsing).Content | Set-Content (Join-Path $CLAUDE_HOOKS "run-hook.cmd")   -Encoding UTF8
    }

    # Register hooks in .claude/settings.json (merge safely)
    $settingsFile = Join-Path $claudeDir "settings.json"

    $settings = @{}
    if (Test-Path $settingsFile) {
        try { $settings = Get-Content $settingsFile -Raw | ConvertFrom-Json -AsHashtable } catch { $settings = @{} }
    }
    if (-not $settings.ContainsKey("hooks")) { $settings["hooks"] = @{} }

    $HOOK_CMD         = ".claude/spec-first/run-hook.cmd session-start"
    $HOOK_CMD_COMPACT = ".claude/spec-first/run-hook.cmd pre-compact"
    $HOOK_CMD_STOP    = ".claude/spec-first/run-hook.cmd session-end"
    $HOOK_CMD_ENFORCE = ".claude/spec-first/run-hook.cmd pre-tool-use"

    # Lifecycle hooks (no matcher)
    $hookEntries = @(
        @{ event = "SessionStart"; cmd = $HOOK_CMD },
        @{ event = "PreCompact";   cmd = $HOOK_CMD_COMPACT },
        @{ event = "Stop";         cmd = $HOOK_CMD_STOP }
    )

    $changed = $false
    foreach ($entry in $hookEntries) {
        if (-not $settings["hooks"].ContainsKey($entry.event)) { $settings["hooks"][$entry.event] = @() }
        # Serialize each entry to JSON before matching so the command string is searchable.
        $alreadyRegistered = $settings["hooks"][$entry.event] | Where-Object { ($_ | ConvertTo-Json -Depth 5 -Compress) -match "spec-first" }
        if (-not $alreadyRegistered) {
            $settings["hooks"][$entry.event] += @{ hooks = @(@{ type = "command"; command = $entry.cmd }) }
            $changed = $true
            Write-Host "[OK] $($entry.event) hook registered in .claude/settings.json"
        } else {
            Write-Host "[OK] $($entry.event) hook already registered (skipping)"
        }
    }

    # Enforcement hook (matcher: Write|Edit)
    if (-not $settings["hooks"].ContainsKey("PreToolUse")) { $settings["hooks"]["PreToolUse"] = @() }
    $enforceRegistered = $settings["hooks"]["PreToolUse"] | Where-Object { ($_ | ConvertTo-Json -Depth 5 -Compress) -match "spec-first" }
    if (-not $enforceRegistered) {
        $settings["hooks"]["PreToolUse"] += @{
            matcher = "Edit|Write"
            hooks = @(@{ type = "command"; command = $HOOK_CMD_ENFORCE })
        }
        $changed = $true
        Write-Host "[OK] PreToolUse enforcement hook registered (blocks code edits without a spec)"
    } else {
        Write-Host "[OK] PreToolUse enforcement hook already registered (skipping)"
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
Write-Host "  3. It asks what is unclear, then runs the seven checks in verify.md"
Write-Host "  4. It writes specs/<slug>.md -- no code yet"
Write-Host "  5. YOU set 'status: approved' in the spec front matter. Nothing builds until you do."
Write-Host "  6. New session to build, another to review, then reconcile into docs/system/"
Write-Host ""
Write-Host "  Cross-session memory: append project learnings to KNOWLEDGE.md"
Write-Host ""
Write-Host "  Files installed:"
Write-Host "    $CONTEXT_FILE (AI context file)     -- methodology loaded"
Write-Host "    spec.md                             -- spec template"
Write-Host "    verify.md                           -- the seven pre-spec checks"
Write-Host "    system.md                           -- living system-document template"
Write-Host "    review.md                           -- code review checklist"
Write-Host "    specs/                              -- specs in flight"
Write-Host "    docs/system/                        -- where shipped specs land"
if ((Test-Path $claudeDir) -or ($CONTEXT_FILE -eq "CLAUDE.md")) {
    Write-Host "    .claude/spec-first/session-start    -- auto-inject hook"
    Write-Host "    .claude/spec-first/pre-tool-use     -- blocks source edits without an APPROVED spec"
}
Write-Host ""
Write-Host "  Not sure where to start? Read README.md"
Write-Host ""
