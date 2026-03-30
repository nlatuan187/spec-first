#!/bin/bash
# spec-first installer
#
# Usage (from spec-first repo):
#   bash install.sh
#
# Usage (one-liner, works from any project directory):
#   curl -fsSL https://raw.githubusercontent.com/nlatuan187/spec-first/master/install.sh | sh
#
# What it does:
#   1. Detects your AI tool and appends snippet.md to the right context file
#   2. Copies spec.md and review.md to your project root
#   3. Creates specs/ directory

set -e

REPO="https://raw.githubusercontent.com/nlatuan187/spec-first/master"
PROJECT_DIR="${PWD}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "$PWD")"
LOCAL=false

if [ -f "$SCRIPT_DIR/snippet.md" ]; then
  LOCAL=true
fi

# ── Detect which context file to use ───────────────────────────────────────

detect_context_file() {
  if [ -f "$PROJECT_DIR/.cursorrules" ]; then
    echo ".cursorrules"
  elif [ -f "$PROJECT_DIR/.windsurfrules" ]; then
    echo ".windsurfrules"
  elif [ -f "$PROJECT_DIR/AGENTS.md" ]; then
    echo "AGENTS.md"
  elif [ -f "$PROJECT_DIR/.github/copilot-instructions.md" ]; then
    echo ".github/copilot-instructions.md"
  elif [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
    echo "CLAUDE.md"
  else
    echo "CLAUDE.md"   # default — Claude Code
  fi
}

CONTEXT_FILE=$(detect_context_file)

echo ""
echo "spec-first installer"
echo "─────────────────────"
echo "Project: $PROJECT_DIR"
echo "Context file: $CONTEXT_FILE"
echo ""

# ── Fetch snippet ───────────────────────────────────────────────────────────

if [ "$LOCAL" = true ]; then
  SNIPPET=$(cat "$SCRIPT_DIR/snippet.md")
else
  SNIPPET=$(curl -fsSL "$REPO/snippet.md")
fi

# ── Step 1: Append to context file ─────────────────────────────────────────

TARGET="$PROJECT_DIR/$CONTEXT_FILE"

if grep -q "Spec-First — AI Development Methodology" "$TARGET" 2>/dev/null; then
  echo "✓ $CONTEXT_FILE already has spec-first methodology (skipping)"
else
  # Create parent dir if needed (e.g. .github/)
  mkdir -p "$(dirname "$TARGET")"

  if [ -f "$TARGET" ]; then
    printf "\n\n---\n\n%s\n" "$SNIPPET" >> "$TARGET"
  else
    printf "%s\n" "$SNIPPET" > "$TARGET"
  fi
  echo "✓ Appended to $CONTEXT_FILE"
fi

# ── Step 2: Copy spec.md ───────────────────────────────────────────────────

if [ "$LOCAL" = true ]; then
  cp "$SCRIPT_DIR/spec.md" "$PROJECT_DIR/spec.md"
else
  curl -fsSL "$REPO/spec.md" -o "$PROJECT_DIR/spec.md"
fi
echo "✓ spec.md → project root"

# ── Step 3: Copy review.md ─────────────────────────────────────────────────

if [ "$LOCAL" = true ]; then
  cp "$SCRIPT_DIR/review.md" "$PROJECT_DIR/review.md"
else
  curl -fsSL "$REPO/review.md" -o "$PROJECT_DIR/review.md"
fi
echo "✓ review.md → project root"

# ── Step 4: Create specs/ ──────────────────────────────────────────────────

mkdir -p "$PROJECT_DIR/specs"
echo "✓ specs/ ready"

# ── Step 5: Install Claude Code slash commands + hooks (if detected) ───────

CLAUDE_DIR="$PROJECT_DIR/.claude"
CLAUDE_COMMANDS="$CLAUDE_DIR/commands"
CLAUDE_HOOKS="$CLAUDE_DIR/spec-first"

if [ -d "$CLAUDE_DIR" ] || [ "$CONTEXT_FILE" = "CLAUDE.md" ]; then
  echo ""
  echo "Claude Code detected — installing /spec /spec-review /spec-check commands..."
  mkdir -p "$CLAUDE_COMMANDS"

  if [ "$LOCAL" = true ]; then
    cp "$SCRIPT_DIR/advanced/skills/spec/SKILL.md"        "$CLAUDE_COMMANDS/spec.md"
    cp "$SCRIPT_DIR/advanced/skills/spec-review/SKILL.md" "$CLAUDE_COMMANDS/spec-review.md"
    cp "$SCRIPT_DIR/advanced/skills/spec-check/SKILL.md"  "$CLAUDE_COMMANDS/spec-check.md"
  else
    curl -fsSL "$REPO/advanced/skills/spec/SKILL.md"        -o "$CLAUDE_COMMANDS/spec.md"
    curl -fsSL "$REPO/advanced/skills/spec-review/SKILL.md" -o "$CLAUDE_COMMANDS/spec-review.md"
    curl -fsSL "$REPO/advanced/skills/spec-check/SKILL.md"  -o "$CLAUDE_COMMANDS/spec-check.md"
  fi
  echo "✓ /spec → /spec-review → /spec-check installed"

  # ── Install SessionStart hook ─────────────────────────────────────────────
  mkdir -p "$CLAUDE_HOOKS"

  if [ "$LOCAL" = true ]; then
    cp "$SCRIPT_DIR/hooks/session-start" "$CLAUDE_HOOKS/session-start"
    cp "$SCRIPT_DIR/hooks/pre-compact"   "$CLAUDE_HOOKS/pre-compact"
    cp "$SCRIPT_DIR/hooks/session-end"   "$CLAUDE_HOOKS/session-end"
    cp "$SCRIPT_DIR/hooks/run-hook.cmd"  "$CLAUDE_HOOKS/run-hook.cmd"
  else
    curl -fsSL "$REPO/hooks/session-start" -o "$CLAUDE_HOOKS/session-start"
    curl -fsSL "$REPO/hooks/pre-compact"   -o "$CLAUDE_HOOKS/pre-compact"
    curl -fsSL "$REPO/hooks/session-end"   -o "$CLAUDE_HOOKS/session-end"
    curl -fsSL "$REPO/hooks/run-hook.cmd"  -o "$CLAUDE_HOOKS/run-hook.cmd"
  fi
  chmod +x "$CLAUDE_HOOKS/session-start" "$CLAUDE_HOOKS/pre-compact" "$CLAUDE_HOOKS/session-end" "$CLAUDE_HOOKS/run-hook.cmd" 2>/dev/null || true

  # Register hooks in .claude/settings.json (merge safely with python3, fallback to create)
  SETTINGS_FILE="$CLAUDE_DIR/settings.json"
  HOOK_CMD=".claude/spec-first/run-hook.cmd session-start"
  HOOK_CMD_COMPACT=".claude/spec-first/run-hook.cmd pre-compact"
  HOOK_CMD_STOP=".claude/spec-first/run-hook.cmd session-end"

  if command -v python3 &>/dev/null; then
    python3 - "$SETTINGS_FILE" "$HOOK_CMD" "$HOOK_CMD_COMPACT" "$HOOK_CMD_STOP" << 'PYEOF'
import json, sys, os

settings_path, hook_start, hook_compact, hook_stop = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
settings = {}
if os.path.exists(settings_path):
    try:
        with open(settings_path) as f:
            settings = json.load(f)
    except Exception:
        pass

hooks = settings.setdefault("hooks", {})
changed = False

for event, cmd in [("SessionStart", hook_start), ("PreCompact", hook_compact), ("Stop", hook_stop)]:
    entries = hooks.setdefault(event, [])
    if not any("spec-first" in str(h) for h in entries):
        entries.append({"hooks": [{"type": "command", "command": cmd}]})
        changed = True
        print(f"✓ {event} hook registered in .claude/settings.json")
    else:
        print(f"✓ {event} hook already registered (skipping)")

if changed:
    os.makedirs(os.path.dirname(settings_path), exist_ok=True)
    with open(settings_path, "w") as f:
        json.dump(settings, f, indent=2)
PYEOF
  else
    # No python3 — create settings.json only if it doesn't exist
    if [ ! -f "$SETTINGS_FILE" ]; then
      cat > "$SETTINGS_FILE" << JSON
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOOK_CMD"
          }
        ]
      }
    ]
  }
}
JSON
      echo "✓ SessionStart hook registered in .claude/settings.json"
    else
      echo "  (python3 not found — add hooks manually to .claude/settings.json)"
      echo "  See: https://github.com/nlatuan187/spec-first/tree/master/hooks"
    fi
  fi
fi

# ── Step 6: Scaffold KNOWLEDGE.md ─────────────────────────────────────────

if [ ! -f "$PROJECT_DIR/KNOWLEDGE.md" ]; then
  cat > "$PROJECT_DIR/KNOWLEDGE.md" << 'TMPL'
# Project Knowledge — Cross-Session Memory

> Add learnings that future sessions need. Only add patterns confirmed 2+ times.
TMPL
  echo "✓ KNOWLEDGE.md scaffolded"
else
  echo "✓ KNOWLEDGE.md already exists (skipping)"
fi

# ── Done ───────────────────────────────────────────────────────────────────

echo ""
echo "Done. Your AI is now spec-first."
echo ""
echo "  Next steps:"
echo "  1. Open your AI tool (Claude Code, Cursor, Windsurf, etc.) in this folder"
echo "  2. Type: build [describe what you want to create]"
echo "  3. Your AI will ask up to 3 clarifying questions"
echo "  4. Then write a spec file in specs/ -- no code yet"
echo "  5. Review the spec, then open a new session to build"
echo ""
echo "  Cross-session memory: append project learnings to KNOWLEDGE.md"
echo ""
echo "  Files installed:"
echo "    $CONTEXT_FILE (AI context file)     -- methodology loaded"
echo "    spec.md                             -- spec template"
echo "    review.md                           -- code review checklist"
echo "    specs/                              -- your specs go here"
if [ -d "$CLAUDE_DIR" ] || [ "$CONTEXT_FILE" = "CLAUDE.md" ]; then
echo "    .claude/spec-first/session-start    -- auto-inject hook"
fi
echo ""
echo "  Not sure where to start? Read README.md"
echo ""
