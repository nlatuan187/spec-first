---
name: spec-stats
preamble-tier: 3
version: 1.0.0
description: |
  Measure spec-first adoption and quality metrics. Shows spec inventory,
  fix:feat ratio, coverage gaps, and methodology health. Use when asked
  "how are we doing", "spec stats", "show metrics", "are specs working",
  or "measure spec quality". Returns a dashboard with actionable insights.

  Designed for team leads and individual devs to self-assess — no external
  tooling required.
effort: low
allowed-tools:
  - Read
  - Bash
  - Grep
  - Glob
---

{{PREAMBLE}}

# /spec-stats: Measure Spec-First Health

**When to run**: Weekly, or when someone asks "is spec-first actually helping?" This gives you numbers instead of feelings.

You are a methodology health auditor. Your job is to count, calculate, and surface insights — not to judge the team or suggest process changes.

---

## Step 1: Spec Inventory

Count all specs and categorize by status and scope.

```bash
# Count total specs
ls specs/*.md 2>/dev/null | wc -l

# Count done specs
ls specs/done/*.md 2>/dev/null | wc -l
```

For each spec file in `specs/`, read YAML frontmatter and extract:
- `status`: draft | in-review | approved | implementing | done
- `scope`: bug-fix | small-change | refactor | new-feature | large-feature | spike | delta
- `s1_count` and `s3_count`
- `created` date

If a spec has no YAML frontmatter, count it as `status: unknown`.

Produce:

```
## Spec Inventory
Total: [N] active + [N] done

By status:
  draft:        [N]
  in-review:    [N]
  approved:     [N]
  implementing: [N]
  done:         [N]
  unknown:      [N]  ← specs without YAML frontmatter

By scope:
  bug-fix:      [N]
  small-change: [N]
  refactor:     [N]
  new-feature:  [N]
  large-feature:[N]
  spike:        [N]
  delta:        [N]
```

---

## Step 2: Fix:Feat Ratio

This is the single most important metric. It measures how many fixes you need per feature — lower is better.

```bash
# Last 7 days of commits
git log --oneline --since="7 days ago" 2>/dev/null | head -100

# Last 30 days for trend
git log --oneline --since="30 days ago" 2>/dev/null | head -200
```

Classify each commit as:
- **feat**: contains "feat", "add", "implement", "create", "build", "new" (case-insensitive)
- **fix**: contains "fix", "bug", "patch", "hotfix", "repair", "correct" (case-insensitive)
- **other**: refactor, docs, chore, test, ci, style, etc.

Calculate:
- `fix:feat ratio = fix_count / feat_count` (if feat_count > 0)
- Show both 7-day and 30-day ratios for trend

```
## Fix:Feat Ratio
Last 7 days:  [N] fixes / [N] features = [X]:1
Last 30 days: [N] fixes / [N] features = [X]:1

Benchmark:
  > 3:1  — spec quality needs attention (AI is generating bugs)
  2-3:1  — average (specs may be missing S1/S3)
  1-2:1  — good (specs are catching edge cases)
  < 1:1  — excellent (mature spec-first adoption)
```

If feat_count is 0, say "Not enough feature commits to calculate ratio."

---

## Step 3: Coverage Gaps

Find code that was written without a spec (orphan code).

```bash
# Recently modified implementation files (last 7 days)
git diff --name-only HEAD~20 2>/dev/null | grep -E '\.(ts|tsx|js|jsx|py|go|rs|swift|kt)$' | head -30

# Available specs
ls specs/*.md 2>/dev/null
```

For each recently changed implementation file, check if a matching spec exists in `specs/`. Match by:
- Feature name in filename (e.g., `chat-service.ts` → `specs/*chat*.md`)
- Directory name (e.g., changes in `app/api/auth/` → `specs/*auth*.md`)

```
## Coverage
Specs with matching implementation: [N]
Implementation without spec:       [N]  ← "orphan code"

Orphan files (code without spec):
  - [file1] — no matching spec found
  - [file2] — no matching spec found
```

---

## Step 4: S1/S3 Quality

For specs with YAML frontmatter, analyze error state and integration coverage.

```
## S1/S3 Distribution
Average S1 count: [X] error states per spec
Average S3 count: [X] integration points per spec

Specs with S1 = 0: [N]  ← likely missing error handling
Specs with S3 = 0: [N]  ← likely missing integration scan (almost always wrong)

Highest complexity:
  [spec-name] — S1:[N] S3:[N] → Review Required
```

---

## Step 5: Methodology Health

Check supporting artifacts:

```bash
# KNOWLEDGE.md entries
grep -c "^## " KNOWLEDGE.md 2>/dev/null || echo "0"

# Session state exists?
ls .claude/session-state.md 2>/dev/null

# Constitution size
wc -l CLAUDE.md 2>/dev/null || wc -l .cursorrules 2>/dev/null || echo "no constitution"
```

```
## Methodology Health
KNOWLEDGE.md entries: [N]  (cross-session learnings captured)
Constitution size:    [N] lines  (> 200 = attention degradation risk)
Session state:        [exists/missing]
Stale specs:          [N]  (status: draft, created > 14 days ago)
```

---

## Step 6: Output Dashboard

Combine everything into a single summary:

```
═══════════════════════════════════════════════
  SPEC-FIRST HEALTH DASHBOARD
═══════════════════════════════════════════════

  Specs:        [N] active / [N] done
  Fix:Feat:     [X]:1 (7d) / [X]:1 (30d)
  Coverage:     [N]% of recent changes have specs
  Avg S1:       [X] error states per spec
  Avg S3:       [X] integration points per spec
  Knowledge:    [N] entries in KNOWLEDGE.md

───────────────────────────────────────────────
  HEALTH SCORE
───────────────────────────────────────────────

  [Calculate score out of 10 based on:]
  - Fix:feat ≤ 2:1        → +3 points
  - Fix:feat ≤ 3:1        → +2 points
  - Fix:feat > 3:1        → +0 points
  - Coverage ≥ 80%        → +2 points
  - Coverage ≥ 50%        → +1 point
  - No specs with S1 = 0  → +1 point
  - No specs with S3 = 0  → +1 point
  - KNOWLEDGE.md ≥ 3      → +1 point
  - Constitution ≤ 200 ln → +1 point
  - No stale specs        → +1 point

  Score: [N]/10
  [One sentence interpretation]

───────────────────────────────────────────────
  ACTION ITEMS
───────────────────────────────────────────────

  [List top 3 actionable improvements, e.g.:]
  1. [N] specs have S3 = 0 — run /spec-review on each
  2. Fix:feat ratio is [X]:1 — check if S1 is covering edge cases
  3. [N] orphan files — write retroactive specs (5 min each)

═══════════════════════════════════════════════
```

---

## Notes

- **This is a snapshot, not a judgment.** First week with spec-first? Score of 3/10 is normal.
- **Fix:feat ratio needs ≥ 10 commits** to be meaningful. Below that, skip the ratio.
- **Orphan detection is fuzzy.** Not every file needs a dedicated spec — utility files, configs, and test helpers are expected orphans. Flag implementation files (routes, services, components), not everything.
- **Run weekly** for trend tracking. The value is in the direction (improving or declining), not the absolute number.
- **Share the dashboard** in standup or PR description. Making metrics visible changes behavior.

---

## Standalone Installation

```bash
# Copy as a Claude Code slash command
mkdir -p .claude/commands
cp spec-first/advanced/skills/spec-stats/SKILL.md .claude/commands/spec-stats.md
```
