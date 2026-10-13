---
name: spec-stats
preamble-tier: 3
version: 2.0.0
description: |
  Measure spec-first adoption and quality metrics. Shows spec inventory,
  fix:feat ratio, reconciliation rate, verification and known-issues coverage,
  and approval integrity. Use when asked "how are we doing", "spec stats",
  "show metrics", "are specs working", or "measure spec quality".
effort: low
allowed-tools:
  - Read
  - Bash
  - Grep
  - Glob
---

{{PREAMBLE}}

# /spec-stats: Measure Spec-First Health

**When to run**: Weekly, or when someone asks "is spec-first actually helping?"

---

## Step 1: Spec Inventory

```bash
ls specs/*.md 2>/dev/null | wc -l
ls specs/done/*.md 2>/dev/null | wc -l
```

For each spec read YAML frontmatter: `status` · `scope` · `shipped_at` · `reconciled_at` ·
`approved_at` · `owner` · `approver` · `created`. No frontmatter → `status: unknown`.

Statuses: `draft | in-review | approved | implementing | shipped | reconciled`. Scopes: `discovery | bug | small | refactor | feature | large`.

```
## Spec Inventory
Total: [N] active + [N] done
By status: draft [N] · in-review [N] · approved [N] · implementing [N] · shipped [N] · reconciled [N] · unknown [N]
By scope:  discovery [N] · bug [N] · small [N] · refactor [N] · feature [N] · large [N]
```

---

## Step 2: Fix:Feat Ratio

```bash
git log --oneline --since="7 days ago" 2>/dev/null | head -100
git log --oneline --since="30 days ago" 2>/dev/null | head -200
```

Classify each commit with this explicit precedence — no commit may match twice:

1. **Conventional-commit prefix first.** Extract the token before the first colon.
   `fix: add retry on 429` → **fix**. Stop. Do not apply keyword matching.
2. **Keyword fallback** (only when no prefix): feat = "add", "implement", "create",
   "build", "new"; fix = "bug", "patch", "hotfix", "repair", "correct". On a tie, **fix wins**.
3. Anything else → **other**.

If `feat_count = 0` or total commits < 10, say "Not enough data."

```
## Fix:Feat Ratio
Last 7 days:  [N] fixes / [N] features = [X]:1
Last 30 days: [N] fixes / [N] features = [X]:1
```

---

## Step 3: Coverage

```bash
git diff --name-only HEAD~20 2>/dev/null | head -40
ls specs/*.md 2>/dev/null
```

For each recently changed implementation file (routes, services, components — not configs,
tests, utilities), check whether a matching spec exists in `specs/` by feature name or
directory. Do not filter by extension; the methodology is language-agnostic.

```
## Coverage
Matched: [N]   Orphan: [N]   ([N]% coverage)
```

---

## Step 4: V2 Quality Metrics

`s1_count` and `s3_count` frontmatter fields were removed in v2. They were written by the
agent being gated, making the gate's input come from the thing it was gating. Compute
quality by reading the spec body instead.

**Reconciliation rate** (headline metric) — of specs with `shipped_at` set, what fraction
also have `reconciled_at`. An unreconciled shipped spec is the next person's wrong map.

**Verification coverage** — does `## Verification` contain real recorded output (not empty,
not the template placeholder)? Empty = draft, regardless of other sections.

**Known-issues coverage** — does `## Known issues` contain at least one real entry?
"None" is not an entry.

**Approval integrity** — for each spec with `approved_at` set and `scope: large`, flag any
where `approver == owner`. List by filename. An agent must never set `approved_at`.

```
## V2 Quality
Reconciliation:        [N] of [N] shipped specs reconciled ([N]%)
Verification coverage: [N] of [N] specs have recorded output ([N]%)
Known-issues coverage: [N] of [N] specs have at least one real entry ([N]%)
Approval integrity:    [N] violations  [list filenames]
```

---

## Step 5: Dashboard

```
═══════════════════════════════════════════════
  SPEC-FIRST HEALTH DASHBOARD
═══════════════════════════════════════════════

  Specs:        [N] active / [N] done
  Fix:Feat:     [X]:1 (7d) / [X]:1 (30d)
  Coverage:     [N]%
  Reconciled:   [N]% of shipped specs       ← headline
  Verified:     [N]% of specs have recorded output
  Known issues: [N]% of specs have real entries
  Approvals:    [N] integrity violations

───────────────────────────────────────────────
  HEALTH SCORE                          /10
───────────────────────────────────────────────

  Fix:feat ≤ 2:1               → +3
  Fix:feat ≤ 3:1               → +2  (else +0)
  Coverage ≥ 80%               → +2
  Coverage ≥ 50%               → +1  (else +0)
  Reconciliation ≥ 80%         → +2
  Reconciliation ≥ 50%         → +1  (else +0)
  Verification ≥ 80%           → +1
  Known-issues ≥ 80%           → +1
  No approval integrity issues → +1

  Score: [N]/10
  [One sentence: what the score means for the team right now]

───────────────────────────────────────────────
  TOP 3 ACTIONS
───────────────────────────────────────────────

  [List the top 3 by impact, e.g.:]
  1. [N] shipped specs unreconciled — each is the next reader's wrong map
  2. Fix:feat is [X]:1 — check Failure modes coverage in recent specs
  3. [N] orphan files — bug scope is four sections, takes under an hour

═══════════════════════════════════════════════
```

---

## Notes

- Fix:feat needs ≥ 10 commits to be meaningful. Below that, skip the ratio.
- Reconciliation is the headline. Forward-written specs go stale; this is the fix.
- Orphan detection is fuzzy. Configs, tests, and utilities are expected orphans.
- Run weekly; direction matters more than the absolute number.
