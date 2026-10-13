---
name: spec-review
preamble-tier: 3
version: 2.0.0
description: |
  Gate that reads a spec and returns APPROVED or BLOCKED before a Build session starts.
  APPROVED is this gate's verdict — never placed in the spec's front matter. The human
  approver sets status: approved and approved_at as a separate deliberate act.
  Use when asked to "review this spec", "is this spec ready?", or "spec-review [slug]".
effort: medium
allowed-tools:
  - Read
  - Bash
  - Edit
---

{{PREAMBLE}}

# /spec-review

Read the spec. Return a verdict with evidence. A finding with no quoted evidence is not reported. A check that was skipped is reported as SKIPPED, never as passed.

---

## Step 1: Find the spec

```bash
ls specs/ 2>/dev/null
```

Use the given path, or ask if multiple specs exist and none was named.

---

## Step 2: Read the spec

Collect: `status` from front matter · `## Why` (Pain, Need, Proposed) · `## Verification` contents · `## Known issues` contents · every number in the body · every `## Thresholds` entry · every `## File changes` path · severity label counts.

---

## Step 3: Hard blocks — check first, stop if any fire

Evidence required for each. If any fires, output BLOCKED and stop.

**VER — Verification empty.** `## Verification` is empty, has only placeholder text, or has no recorded command output (paths, counts, "no hits"). Evidence: paste the section. A spec with no contact with the code is a draft.

**KNI — Known issues empty.** Section is blank, contains an empty `-`, or says "none" or "n/a". Evidence: paste the section. "None" is not an entry.

**PRO — Proposed missing rejection.** Any `Proposed` line lacks a `not [Y]` clause (`We will X, not Y, because Z`). Evidence: quote the offending line.

**NUM — Number not in Thresholds.** Any number in the body (timeouts, row limits, percentages, counts) absent from `## Thresholds`. Evidence: quote the number and location. Dates and path components are exempt.

---

## Step 4: Mechanical checks

### 4a. Pain validity

Each Pain line must contain a frequency, a quantity, or a blocking fact, and must not contain the product's own feature nouns.

Valid: `"Without a connected account, publishing is blocked."` (blocking fact)
Invalid: `"Brokers need a content plan view."` (backlog item in pain's clothing)

Flag: `PAIN — "[quoted line]" — [missing frequency/quantity/blocking fact | contains product feature noun]`

### 4b. Severity calibration

Count all severity labels. CRITICAL must be ≤ 20% of total. CRITICAL = data loss, security exploit, production crash only. HIGH = broken for a subset, regression risk.

If CRITICAL > 20%: review each against the criteria. Auto-fix: downgrade non-qualifying items inline with evidence (count before → after).

### 4c. File:line references

For every `file:line` in the spec: use Read with offset/limit to verify the line still contains what the spec claims. Auto-fix stale numbers. Flag removed code as `[STALE — CODE REMOVED]` with the original reference quoted.

---

## Step 5: Judgment checks — flag, do not auto-fix

### 5a. Integration scan

This check is stack-agnostic. First discover the repo layout, then search. Do not assume any framework or file extension.

```bash
# Discover source directories — skip dependencies and build artifacts
find . -maxdepth 3 -type d \
  \( -name node_modules -o -name .git -o -name __pycache__ \
     -o -name dist -o -name build -o -name vendor -o -name target \) -prune \
  -o -type d -print 2>/dev/null | head -40

# Search the main entity in at least three spellings (adapt extensions to this repo)
grep -rn "ENTITY\|entity_name\|entityName\|ENTITY_NAME" \
  --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor \
  . 2>/dev/null | head -30
```

Compare hits to `## Integration`. Flag anything the scan found that the spec omitted.

`⚠️ INTEGRATION — [path] touches [entity] but is absent from the Integration table. Evidence: [quoted grep line]`

If the scan could not run: `SKIPPED — integration scan — [reason]`

### 5b. Deduplication

```bash
ls specs/ 2>/dev/null
gh issue list --state open --limit 50 2>/dev/null | grep -i "[feature_keyword]"
```

`⚠️ OVERLAP — [spec/issue] may cover [behavior]. Evidence: [quoted title or description]`

### 5c. Deployment constraints

Flag if the spec contains: a loop that may exceed platform timeout · a DB query without pagination · a secret in a URL query string · a check-then-write without an atomic lock.

`⚠️ CONSTRAINT — [quoted description of the risk]`

---

## Step 6: Output the gate

```
## Spec Review: [Feature Name]
Spec: specs/[filename].md  |  Scope: [scope]

### Auto-fixed
- [x] [description] — evidence: [before → after]

### Findings — require human decision
⚠️ PAIN        — "[quoted line]" — [reason]
⚠️ INTEGRATION — [path] absent from Integration table — evidence: [grep line]
⚠️ OVERLAP     — [spec/issue] may cover [behavior] — evidence: [quoted]
⚠️ CONSTRAINT  — [risk description]
SKIPPED        — [check name] — [reason]

---
APPROVED ✅  →  Open Build session with: context file + specs/[slug].md + KNOWLEDGE.md
This verdict does not update the spec's front matter.
The human approver sets status: approved and approved_at.
```

or:

```
BLOCKED ❌  —  [N] issue(s) before Build:
1. VER — Verification section is empty. Evidence: [quoted section]
2. KNI — Known issues empty. Evidence: [quoted section]
3. PRO — Proposed line missing "not [Y]". Evidence: "[quoted line]"
4. NUM — "[number]" at [location] not in Thresholds.
```

---

## What this is not

Not a spec rewrite — flag gaps, the author fills them. Not a code review (`review.md` runs after Build). Not implementation verification (`/spec-check` runs after Build). APPROVED is not written into the spec's front matter — that is the human approver's act.
