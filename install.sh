#!/bin/bash
# spec-first installer
#
# Usage (from spec-first repo):
#   bash install.sh
#
# Usage (one-liner, works from any project directory):
#   curl -fsSL https://raw.githubusercontent.com/nlatuan187/spec-first/main/install.sh | sh
#
# What it does:
#   1. Detects your AI tool and appends snippet.md to the right context file
#   2. Copies spec.md and review.md to your project root
#   3. Creates specs/ directory

set -e

REPO="https://raw.githubusercontent.com/nlatuan187/spec-first/main"
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

# ── Step 5: Create specs/ ──────────────────────────────────────────────────

mkdir -p "$PROJECT_DIR/specs"
echo "✓ specs/ ready"

# ── Done ───────────────────────────────────────────────────────────────────

echo ""
echo "Done. Your AI is now spec-first."
echo ""
echo "  Start a new session in this project."
echo "  Say: \"build [feature]\""
echo "  AI will write the spec before any code."
echo ""
echo "  Pairs with:"
echo "    gstack  — execution layer (ship, review, qa)"
echo "    BMAD    — role-based agent orchestration"
echo "    → advanced/INTEGRATIONS.md"
echo ""
