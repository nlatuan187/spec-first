#!/usr/bin/env bash
# scripts/check.sh — spec-first repo integrity check
#
# Requires: bash, coreutils (wc, head, cat), grep, sed, find
# Exit code: 0 if all checks pass, non-zero if any fail.
# Output format: path:line: message (one line per problem)
#
# Checks:
#   1. Dead markdown links (only [text](target) syntax; not prose paths)
#   2. Orphaned files under advanced/ (no other .md links to them)
#   3. snippet.md line count must not exceed 210
#   4. Number consistency against canonical values in CLAUDE.md
#   5. Spec template must exist in exactly one place
#   6. Front matter (status, scope, owner, created) in every advanced/examples/ file
#   7. Shell syntax — bash -n on every script in hooks/ and on install.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROBLEMS="$(mktemp)"
trap 'rm -f "$PROBLEMS"' EXIT

# problem path:line: message
problem() {
  printf '%s\n' "$1"
  printf '1\n' >> "$PROBLEMS"
}

# ── 1. Dead markdown links ────────────────────────────────────────────────────
# Only check [text](target) and ![alt](target) syntax — not prose path references.
# Per the source-material note: a naive checker produced 13 false positives against
# the parent-prefix prose pattern ("Module map under lib/foo/:"). Scoping to markdown
# link syntax only avoids that entirely.

while IFS= read -r mdfile; do
  relfile="${mdfile#"$REPO_ROOT/"}"
  dir="$(dirname "$mdfile")"
  lineno=0
  while IFS= read -r line; do
    lineno=$((lineno + 1))
    printf '%s' "$line" | grep -q '\](' || continue
    while IFS= read -r target; do
      [ -z "$target" ] && continue
      # Skip external and unsupported schemes
      case "$target" in
        http://*|https://*|mailto:*|ftp://*|"#"*) continue ;;
      esac
      # Strip fragment and link title (title is the quoted part after a space)
      path_part="${target%%#*}"
      path_part="${path_part%% *}"
      [ -z "$path_part" ] && continue
      # Resolve relative to the containing file's directory
      if [ "${path_part#/}" != "$path_part" ]; then
        resolved="$REPO_ROOT$path_part"
      else
        resolved="$dir/$path_part"
      fi
      [ -e "$resolved" ] || problem "$relfile:$lineno: dead link → $path_part"
    done < <(printf '%s\n' "$line" | grep -oE '\]\([^)]+\)' | sed 's/^\](//;s/)$//')
  done < "$mdfile"
done < <(find "$REPO_ROOT" -name "*.md" ! -path "*/.git/*")

# ── 2. Orphaned .md files under advanced/ ────────────────────────────────────
# Four orphans were deleted in v2 (team-scaling.md, the-system.md, tool-matrix.md,
# prompting-guide.md). This check stops the fifth.

LINKED="$(mktemp)"
while IFS= read -r mdfile; do
  dir="$(dirname "$mdfile")"
  while IFS= read -r target; do
    [ -z "$target" ] && continue
    case "$target" in http://*|https://*|mailto:*|ftp://*) continue ;; esac
    path_part="${target%%#*}"
    path_part="${path_part%% *}"
    [ -z "$path_part" ] && continue
    if [ "${path_part#/}" != "$path_part" ]; then
      resolved="$REPO_ROOT$path_part"
    else
      resolved="$dir/$path_part"
    fi
    if [ -e "$resolved" ]; then
      # Canonicalize by changing into the directory
      printf '%s\n' "$(cd "$(dirname "$resolved")" && pwd)/$(basename "$resolved")"
    fi
  done < <(grep -oE '\]\([^)]+\)' "$mdfile" 2>/dev/null | sed 's/^\](//;s/)$//')
done < <(find "$REPO_ROOT" -name "*.md" ! -path "*/.git/*") | sort -u > "$LINKED"

while IFS= read -r mdfile; do
  canon="$(cd "$(dirname "$mdfile")" && pwd)/$(basename "$mdfile")"
  if ! grep -qxF "$canon" "$LINKED"; then
    relfile="${mdfile#"$REPO_ROOT/"}"
    problem "$relfile:1: orphan — not linked from any .md file"
  fi
done < <(find "$REPO_ROOT/advanced" -name "*.md")
rm -f "$LINKED"

# ── 3. snippet.md line count ──────────────────────────────────────────────────
# snippet.md is appended to the user's context file by the installer.
# The file itself advises keeping context files under ~200 lines; the check
# limit is 210 to leave a small buffer.

SNIPPET="$REPO_ROOT/snippet.md"
if [ -f "$SNIPPET" ]; then
  SNIPPET_LINES=$(wc -l < "$SNIPPET")
  if [ "$SNIPPET_LINES" -gt 210 ]; then
    problem "snippet.md:$SNIPPET_LINES: file exceeds 210-line limit ($SNIPPET_LINES lines)"
  fi
else
  problem "snippet.md:0: file not found"
fi

# ── 4. Number consistency ─────────────────────────────────────────────────────
# Canonical numbers from CLAUDE.md: Week 1 fix:feat 5:1, Week 4 fix:feat 1.5:1.
# From the measured corpus: 626 commits total, fix: was 47% of all commits.
# CHANGELOG notes the previously wrong claim: "75% of commits were fixing" (now fixed
# to 47% of all commits; 75% is the share among fix-or-feat commits only).

# 4a. Verify no file reinstates "75% of commits" as a fix rate claim.
while IFS= read -r hit; do
  [ -n "$hit" ] || continue
  relpath=$(printf '%s' "$hit" | sed "s|^$REPO_ROOT/||" | cut -d: -f1)
  lineno=$(printf '%s' "$hit" | sed "s|^$REPO_ROOT/||" | cut -d: -f2)
  problem "$relpath:$lineno: number contradiction — '75% of commits' is wrong; fix: was 47% of 626 commits (CLAUDE.md)"
done < <(grep -rn "75%.*commit\|commit.*75%" "$REPO_ROOT" --include="*.md" 2>/dev/null \
  | grep -i "fix" | grep -v '^Binary' | grep -v "CHANGELOG")

# 4b. Verify no file claims "100x" productivity outside a negating context.
# CLAUDE.md says: 10–15x (never "100x"). evidence.md uses "Why Not 100x?" correctly.
while IFS= read -r hit; do
  [ -n "$hit" ] || continue
  line_text=$(printf '%s' "$hit" | sed "s|^$REPO_ROOT/[^:]*:[0-9]*:||")
  # Allow lines where "100x" is explicitly negated (allow quotes/punct between words)
  printf '%s' "$line_text" | grep -iqE "(not|never|why not|avoid).{0,10}100x|100x.{0,10}(not|never)" && continue
  relpath=$(printf '%s' "$hit" | sed "s|^$REPO_ROOT/||" | cut -d: -f1)
  lineno=$(printf '%s' "$hit" | sed "s|^$REPO_ROOT/||" | cut -d: -f2)
  problem "$relpath:$lineno: number contradiction — '100x' productivity claim; CLAUDE.md says 10–15x (never 100x)"
done < <(grep -rn "100x" "$REPO_ROOT" --include="*.md" 2>/dev/null \
  | grep -v '^Binary' | grep -v "CHANGELOG")

# 4c. Week 1 fix:feat must be 5:1. Flag any line that pairs "Week 1" with a
# ratio other than 5:1 or its tilde approximation.
while IFS= read -r hit; do
  [ -n "$hit" ] || continue
  line_text=$(printf '%s' "$hit" | sed "s|^$REPO_ROOT/[^:]*:[0-9]*:||")
  # Extract first ratio-shaped token on the line
  ratio=$(printf '%s' "$line_text" | grep -oE '[0-9]+(\.[0-9]+)?:[0-9]+(\.[0-9]+)?' | head -1)
  [ -z "$ratio" ] && continue
  # Accept 5:1 and its tilde form
  case "$ratio" in 5:1|5.0:1|5:1.0|5.0:1.0) continue ;; esac
  relpath=$(printf '%s' "$hit" | sed "s|^$REPO_ROOT/||" | cut -d: -f1)
  lineno=$(printf '%s' "$hit" | sed "s|^$REPO_ROOT/||" | cut -d: -f2)
  problem "$relpath:$lineno: number contradiction — Week 1 ratio shown as $ratio; CLAUDE.md says 5:1"
done < <(grep -rni "week.1" "$REPO_ROOT" --include="*.md" 2>/dev/null \
  | grep -E "[0-9]+:[0-9]" | grep -iv "5:1" | grep -i "fix" | grep -v '^Binary' | grep -v "CHANGELOG")

# 4d. Week 4 fix:feat must be 1.5:1.
while IFS= read -r hit; do
  [ -n "$hit" ] || continue
  line_text=$(printf '%s' "$hit" | sed "s|^$REPO_ROOT/[^:]*:[0-9]*:||")
  ratio=$(printf '%s' "$line_text" | grep -oE '[0-9]+(\.[0-9]+)?:[0-9]+(\.[0-9]+)?' | head -1)
  [ -z "$ratio" ] && continue
  case "$ratio" in 1.5:1|1.5:1.0) continue ;; esac
  relpath=$(printf '%s' "$hit" | sed "s|^$REPO_ROOT/||" | cut -d: -f1)
  lineno=$(printf '%s' "$hit" | sed "s|^$REPO_ROOT/||" | cut -d: -f2)
  problem "$relpath:$lineno: number contradiction — Week 4 ratio shown as $ratio; CLAUDE.md says 1.5:1"
done < <(grep -rni "week.4" "$REPO_ROOT" --include="*.md" 2>/dev/null \
  | grep -E "[0-9]+:[0-9]" | grep -iv "1.5:1" | grep -i "fix" | grep -v '^Binary' | grep -v "CHANGELOG")

# ── 5. Spec template divergence ───────────────────────────────────────────────
# spec.md is the one canonical spec template. Three divergent copies existed before
# v2 (advanced/templates/feature-spec.md and review-checklist.md, and one other).
# This check catches a new copy being added.
# Exclusions: spec.md itself; advanced/examples/ (those are instances, not templates).

MANDATORY_SECTIONS="## Why ## Verification ## Failure modes ## Invariants ## File changes ## QA ## Known issues"
while IFS= read -r mdfile; do
  case "$mdfile" in
    "$REPO_ROOT/spec.md") continue ;;
    "$REPO_ROOT/advanced/examples/"*) continue ;;
  esac
  count=0
  for section in "## Why" "## Verification" "## Failure modes" "## Invariants" "## File changes" "## QA" "## Known issues"; do
    grep -qxF "$section" "$mdfile" 2>/dev/null && count=$((count + 1))
  done
  if [ "$count" -ge 7 ]; then
    relfile="${mdfile#"$REPO_ROOT/"}"
    problem "$relfile:1: duplicate spec template — all 7 mandatory section headers present; spec.md is the canonical template"
  fi
done < <(find "$REPO_ROOT" -name "*.md" ! -path "*/.git/*")

# ── 6. Front matter in advanced/examples/ ────────────────────────────────────
# Every example spec must have YAML front matter with status, scope, owner, created.
# These fields are machine-readable and drive /spec-stats and other tooling.

while IFS= read -r mdfile; do
  relfile="${mdfile#"$REPO_ROOT/"}"
  # Front matter must begin on line 1
  if [ "$(head -1 "$mdfile")" != "---" ]; then
    problem "$relfile:1: missing YAML front matter — first line must be '---'"
    continue
  fi
  # All four required fields must appear before the closing ---
  for field in status scope owner created; do
    if ! sed -n '2,30p' "$mdfile" | grep -qE "^${field}:"; then
      problem "$relfile:1: front matter missing required field: $field"
    fi
  done
done < <(find "$REPO_ROOT/advanced/examples" -name "*.md" 2>/dev/null)

# ── 7. Shell syntax ───────────────────────────────────────────────────────────
# bash -n parses without executing. Run it on install.sh and every file in hooks/
# that is not a README or a Windows batch file.

check_shell_syntax() {
  local script="$1"
  local relfile="${script#"$REPO_ROOT/"}"
  local output
  output=$(bash -n "$script" 2>&1) || {
    while IFS= read -r line; do
      [ -n "$line" ] && problem "$relfile:0: shell syntax: $line"
    done <<< "$output"
  }
}

check_shell_syntax "$REPO_ROOT/install.sh"

while IFS= read -r script; do
  check_shell_syntax "$script"
done < <(find "$REPO_ROOT/hooks" -type f ! -name "*.md" ! -name "*.cmd" ! -name "*.txt")

# ── Summary ───────────────────────────────────────────────────────────────────
count=$(wc -l < "$PROBLEMS" | tr -d ' ')
if [ "$count" -gt 0 ]; then
  printf '\ncheck.sh: %d problem(s) found.\n' "$count" >&2
  exit 1
fi
printf 'check.sh: all checks passed.\n' >&2
exit 0
