# spec-first installer for Windows (PowerShell)
#
# Usage (one-liner from any project directory):
#   iwr -useb https://raw.githubusercontent.com/nlatuan187/spec-first/main/install.ps1 | iex
#
# What it does:
#   1. Detects your AI tool and appends snippet.md to the right context file
#   2. Copies spec.md and review.md to your project root
#   3. Creates specs/ directory
#   4. Installs /spec /spec-review /spec-check for Claude Code (if detected)

$ErrorActionPreference = "Stop"
$REPO = "https://raw.githubusercontent.com/nlatuan187/spec-first/main"
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
Write-Host "─────────────────────"
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
    Write-Host "✓ $CONTEXT_FILE already has spec-first methodology (skipping)"
} else {
    if (Test-Path $target) {
        Add-Content $target "`n`n---`n`n$snippet"
    } else {
        Set-Content $target $snippet
    }
    Write-Host "✓ Appended to $CONTEXT_FILE"
}

# ── Step 2: Copy spec.md ───────────────────────────────────────────────────

(Invoke-WebRequest "$REPO/spec.md" -UseBasicParsing).Content | Set-Content "spec.md" -Encoding UTF8
Write-Host "✓ spec.md → project root"

# ── Step 3: Copy review.md ─────────────────────────────────────────────────

(Invoke-WebRequest "$REPO/review.md" -UseBasicParsing).Content | Set-Content "review.md" -Encoding UTF8
Write-Host "✓ review.md → project root"

# ── Step 4: Create specs/ ──────────────────────────────────────────────────

New-Item -ItemType Directory -Force -Path "specs" | Out-Null
Write-Host "✓ specs/ ready"

# ── Step 5: Install Claude Code slash commands (if detected) ───────────────

$claudeDir = Join-Path $PROJECT_DIR ".claude"

if ((Test-Path $claudeDir) -or ($CONTEXT_FILE -eq "CLAUDE.md")) {
    Write-Host ""
    Write-Host "Claude Code detected — installing /spec /spec-review /spec-check commands..."
    $commandsDir = Join-Path $claudeDir "commands"
    New-Item -ItemType Directory -Force -Path $commandsDir | Out-Null

    (Invoke-WebRequest "$REPO/advanced/skills/spec/SKILL.md"        -UseBasicParsing).Content | Set-Content "$commandsDir\spec.md"         -Encoding UTF8
    (Invoke-WebRequest "$REPO/advanced/skills/spec-review/SKILL.md" -UseBasicParsing).Content | Set-Content "$commandsDir\spec-review.md"  -Encoding UTF8
    (Invoke-WebRequest "$REPO/advanced/skills/spec-check/SKILL.md"  -UseBasicParsing).Content | Set-Content "$commandsDir\spec-check.md"   -Encoding UTF8
    Write-Host "✓ /spec → /spec-review → /spec-check installed"
}

# ── Done ───────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "Done. Your AI is now spec-first."
Write-Host ""
Write-Host "  Start a new session in this project."
Write-Host "  Say: 'build [feature]'"
Write-Host "  AI will write the spec before any code."
Write-Host ""
Write-Host "  Ecosystem pairs → advanced/INTEGRATIONS.md"
Write-Host ""
