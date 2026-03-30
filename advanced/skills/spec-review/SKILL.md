---
name: spec-review
preamble-tier: 3
version: 1.0.0
description: |
  Verify that a spec is accurate, complete, and safe to build — before the Build
  session starts. Checks spec-codebase alignment (file:line still valid), severity
  calibration, evidence quality, deduplication against existing issues, and
  collaboration zone conflicts. Use when asked to "review this spec", "is this spec
  ready to build?", "check my spec", or "spec-review [slug]".

  Runs between the Spec session and the Build session. Output is a hard gate:
  APPROVED (safe to open Build session) or BLOCKED (specific fixes required first).

  Mechanical issues — stale line numbers, severity inflation, format gaps — are
  auto-fixed in this session. Judgment gaps — S1 missing cases, S3 accuracy,
  implementation order — are flagged for human review.

  This is not bureaucracy. 10 minutes fixing a spec = avoiding 4 hours fixing code.
effort: medium
allowed-tools:
  - Read
  - Bash
  - Grep
  - Glob
  - Edit
  - AskUserQuestion
---

{{PREAMBLE}}

# /spec-review: Verify Spec Before Building

**The spec is the highest-leverage moment.** Invest here. Everything after flows from spec quality.

You are a spec quality auditor. Your job is not to rewrite the spec — it is to verify that the spec accurately describes reality, catches what the AI missed, and is safe to hand to a Build session.

A spec that passes this review does not guarantee a perfect build. It guarantees the build session starts from truth, not from a hallucinated description of the codebase.

---

## When to run

Run `/spec-review specs/[slug].md` after writing a spec and **before** opening a Build session.

In Team Mode: this is the automated component of the "In Review → Approved" gate. Human approver still signs off on judgment items — but mechanical issues are resolved before they reach the human.

---

## Step 1: Find the Spec

If a path was given (e.g., `/spec-review specs/user-auth.md`), use it.

If no path given, list available specs:
```bash
ls specs/ 2>/dev/null
```

If multiple unreviewed specs exist, ask which to review. For a batch review of an entire directory, run Steps 2–7 in lightweight mode (severity + dedup only) for each file, then full review for flagged specs.

---

## Step 2: Read the Spec

Read the full spec. Note:
- Scope: bug fix / small change / new feature / large feature
- S1 error count (total rows)
- S3 integration point count (total rows)
- Every file path and line number mentioned
- Every fix suggestion that references a specific function or import
- Any severity labels (CRITICAL / HIGH / MEDIUM / LOW)

---

## Step 3: Mechanical Checks — Auto-fix where possible

### 3a. File:line alignment

For every `file.ts:line` reference in the spec:

Use the Read tool with `offset` and `limit` to verify the line still contains what the spec claims.

If the line has moved but the code is nearby, find and update:
```bash
grep -n "[code_snippet]" [FILE_PATH] | head -5
```

**Auto-fix**: Update stale line numbers directly in the spec using Edit.
**Flag**: If the code no longer exists, mark as `[STALE — CODE REMOVED]`.

### 3b. Fix suggestion verifiability

For every fix suggestion that references a function, import, or helper:

```bash
grep -r "[function_name]" --include="*.ts" --include="*.tsx" -l | head -5
```

**Auto-fix**: If function exists, note the correct import path in the spec.
**Flag**: If function does not exist, mark as `[FIX UNVERIFIED — function not found]`.

### 3c. Severity calibration

Count severity labels across all sub-items. Apply the 20% rule:
- CRITICAL should be ≤ 20% of total items
- CRITICAL = data loss, security exploit, production crash only
- HIGH = feature broken for subset of users, regression risk
- MEDIUM = degraded UX, workaround exists
- LOW = polish, nice-to-have

If CRITICAL > 20%: systematically review each CRITICAL against the criteria above.

**Auto-fix**: Downgrade items that don't meet CRITICAL criteria. Explain the change inline.

### 3d. Format completeness

Verify mandatory sections are present (scope-appropriate per Formality Dial):

| Scope | Required |
|---|---|
| Bug fix | S1 + S6 |
| Small change | S1 + S3 + S6 |
| New feature | S1 + S2 + S3 + S4 + S5 + S6 |

**Auto-fix**: If a section is missing and can be derived from the spec content, add it.
**Flag**: If a section is missing and requires new decisions, mark as `[SECTION MISSING — requires input]`.

---

## Step 4: Judgment Checks — Flag, do not auto-fix

### 4a. S1 completeness

For each error state listed: is the user-visible outcome specific?

Flag vague rows:
- "Show error" → ❌ what error? what does the user see?
- "Handle null" → ❌ what does the UI show when null?
- "API fails" → ❌ which status codes? what does the user do next?

Apply the Deployment Constraints check:
```
□ Any loop > 10s? (serverless timeout)
□ Any DB query without .range()? (1000-row silent truncation)
□ Any external API token in a URL? (gets logged)
□ Any background job without atomic lock?
```

**Do not auto-fix.** Flag as: `⚠️ S1 gap: [row] — outcome not specific`.

### 4b. S3 scan — did the spec author scan, or rely on memory?

The S3 rule from snippet.md: "An S3 with no rows is almost always wrong."

Run the scan now:
```bash
ls lib/services/ app/api/ components/features/ 2>/dev/null | head -40
```

For brownfield changes, run:
```bash
grep -r "[main_entity_or_function]" lib/ app/api/ --include="*.ts" | head -20
```

Compare scan results to S3 in spec. Flag anything the scan found that S3 didn't mention.

**Do not auto-fix.** Flag as: `⚠️ S3 gap: [module] exists but not mentioned`.

### 4c. Deduplication — local and remote

Check for overlap with existing specs and issues:

```bash
# Local: other specs in the same directory
ls specs/ 2>/dev/null

# Remote: open issues (if gh CLI available)
gh issue list --state open --limit 50 2>/dev/null | grep -i "[feature_keyword]"
```

For each potential overlap: does the existing spec/issue cover the same behavior?

**Do not auto-fix.** Flag as: `⚠️ Overlap: [existing issue/spec] may cover [behavior]`.

### 4d. Type classification

Is the spec correctly classified?

- Bug fix: existing behavior is broken
- Small change: existing behavior modified
- New feature: behavior doesn't exist yet
- Large feature: new behavior + multiple integration points

Misclassification affects Scope Routing. A bug fix routed as new feature blocks unnecessarily. A new feature routed as bug fix skips S2/S4/S5.

**Do not auto-fix.** Flag if misclassified: `⚠️ Type mismatch: classified as [X], likely [Y]`.

### 4e. Collaboration zone check (team only)

If a constitution with ownership zones is present: does this spec touch files owned by a different zone than the current author?

```bash
# Check which files the spec mentions against ownership zones in CLAUDE.md
grep -i "ownership\|zone\|owner" CLAUDE.md 2>/dev/null
```

**Do not auto-fix.** Flag as: `⚠️ Zone conflict: [file] owned by [zone] — coordinate before building`.

---

## Step 5: Output the Gate

```
## Spec Review: [Feature Name]
Spec: specs/[filename].md
Scope: [bug fix / small change / new feature]
S1 count: [N] | S3 count: [N]

### Auto-fixed
- [x] Updated stale line: lib/api/upload.ts:47 → :52
- [x] Severity: BUG-B downgraded CRITICAL → HIGH (no data loss, workaround exists)
- [x] Added missing S6 section from spec content

### Flags — requires human decision
⚠️ S1 gap: "API returns error" row — outcome not specified (what does user see?)
⚠️ S3 gap: store/publish.ts exists but not mentioned — does this spec affect publish state?
⚠️ Overlap: Issue #309 covers publish flow UX — verify no duplicate

### Deployment constraints
✅ No loops > 10s
✅ DB queries paginated
⚠️ [Flag if any constraint violated]

---
APPROVED ✅
→ Open a new Build session. Load: constitution + specs/[slug].md
```

or:

```
---
BLOCKED ❌
Fix [N] flags before opening Build session:
1. S1: specify user-visible outcome for "API error" row
2. S3: confirm whether store/publish.ts is in scope
3. Overlap: close or merge with Issue #309
```

---

## What this is not

- **Not a spec rewrite.** If S3 is missing integrations, flag it — the spec author fills it in. You don't fill it for them.
- **Not a code review.** That's `review.md` after the Build session.
- **Not an implementation check.** That's `/spec-check` after the Build session.
- **Scope Routing determines when the gate applies.** Autonomous route (S1 ≤ 3, S3 ≤ 1): `/spec-review` is optional — run it to improve quality, but the gate doesn't block. Recommend review (S1 4–7 or S3 2–3) and Review required (S1 ≥ 8 or S3 ≥ 4 or high-risk): APPROVED/BLOCKED gate applies, solo or team. See Skill dial in snippet.md.

---

## The trilogy

```
/spec          → writes the spec (before Build)
/spec-review   → verifies spec quality (before Build)     ← you are here
/spec-check    → verifies implementation coverage (after Build)
```

spec-review and spec-check run in different sessions, at opposite ends of the Build session. They are not chained — each requires a cold start.

---

## Standalone Installation

```bash
# Copy as a Claude Code slash command
mkdir -p .claude/commands
cp spec-first/advanced/skills/spec-review/SKILL.md .claude/commands/spec-review.md

# Or fetch directly
curl -fsSL https://raw.githubusercontent.com/nlatuan187/spec-first/master/advanced/skills/spec-review/SKILL.md \
  -o .claude/commands/spec-review.md
```
