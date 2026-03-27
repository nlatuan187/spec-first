# Feedback Triage Workflow

## What this is

Feedback triage is not the same as the developer spec workflow. They are separate workflows with separate failure modes.

| Developer spec workflow | Feedback triage workflow |
|---|---|
| Input: feature request or bug report | Input: batch of raw user feedback |
| Output: `specs/[slug].md` | Output: verified, grouped GitHub issues |
| Failure mode: AI writes happy path, skips S1 | Failure mode: AI evaluates while reading, confuses "file exists" with "works" |
| Fix: spec structure (S1–S6) | Fix: phase separation |

This document covers only feedback triage. For developer spec workflow, see `snippet.md`.

---

## The Cost of Mixing Phases

Running feedback triage without phase separation produces this pattern:

```
Session 1: Read 94 feedback items, evaluate + classify simultaneously
→ Ambiguous classifications, re-read round
→ Write specs, find gaps, re-verify round
→ Re-verify again...
Total: 5 verification rounds, ~145K tokens

Optimal (phases separated):
→ 1 read pass, 1 verify pass, 1 write pass
Total: ~50K tokens, 0 re-verification rounds
```

**Root cause**: Mixing phases means each decision depends on context that isn't fully established yet. You re-evaluate items you already evaluated, re-read files you already read, re-write specs you already drafted.

Phase separation eliminates re-verification rounds entirely.

---

## Five Phases

### Phase 1 — Gather

**Input**: Raw feedback (spreadsheet, user interview notes, bug reports, support messages)
**Output**: Structured list — one row per feedback item, nothing evaluated yet

Gather requirements before this session starts:

```
□ Screenshots for every UI bug claim
□ Reproduction steps for every functional bug
□ Platform/device info where relevant (mobile vs desktop, browser)
□ The user's exact words (don't paraphrase — paraphrasing evaluates)
```

Format each item as:
```
ID: FB-001
Source: [user type, not name] — [date]
Verbatim: "[exact quote or observation]"
Attachment: [screenshot path or None]
```

**Terminal state**: Every feedback item has an ID and attachment status. Nothing is categorized yet.

*Derives from: Categorizing while reading imports evaluation bias. Items read first get more context than items read last. A separate gather pass creates a stable, complete input before any evaluation begins.*

---

### Phase 2 — Verify

**Input**: Structured list from Phase 1
**Output**: Each item marked as one of 4 statuses

For each item, check the codebase:

```
CONFIRMED — Reproduced. Bug exists or feature gap is real.
FIXED — Already addressed in a recent commit. Link the commit.
WONT_FIX — Works as designed. Explain why.
UNCLEAR — Cannot reproduce without more information. Note what's missing.
```

**The verification rule**: Read the file, don't grep it.

```bash
# Wrong: establishes that a file exists, not that the feature works
grep -r "feature-name" lib/ --include="*.ts" -l

# Right: read the actual handler and check what it does
# Then read the UI component to see what the user sees
```

"File exists" ≠ "feature works." Grep confirms a path — it doesn't confirm behavior. For every UI bug claim with a screenshot, compare the screenshot to what the code actually renders. For every functional bug, trace the code path that the user triggers.

**Do not group or write during this phase.** Mark status only.

*Derives from: Verification requires reading. Evaluation requires thinking. Running both simultaneously produces unstable outputs — you revisit items when later context changes earlier assessments. Two mental modes; one pass each.*

---

### Phase 3 — Group

**Input**: Verified list from Phase 2 (CONFIRMED + UNCLEAR items only)
**Output**: Clusters — related feedback items that belong in one issue

Rules:
1. Only CONFIRMED items become issues. UNCLEAR items go to a "needs more info" bucket.
2. Feedback items about the same behavior → 1 issue (even if different users reported it)
3. Feedback about related behaviors in the same feature area → consider 1 issue if fixing one fixes the others
4. Feedback that crosses feature boundaries → separate issues (cross-boundary fixes have independent S3)

Output format:
```
Group A: [issue title]
  Items: FB-003, FB-007, FB-012
  Why grouped: Same root cause — [describe]
  Scope: Bug fix / Small change / New feature

Group B: ...
```

**Do not write specs during this phase.** Finalize groups first.

*Derives from: Writing a spec before grouping is complete means you discover a related item later that should have been in the same spec. The spec gets amended, re-reviewed, and the cycle repeats. Complete the grouping before writing any spec.*

---

### Phase 4 — Write

**Input**: Groups from Phase 3
**Output**: One GitHub issue (with embedded spec) per group

Write one group. Verify it. Then proceed to the next.

**Do not write all issues in one pass.** Writing 10 specs consecutively means an error in issue 2 isn't caught until issue 8. Write one, check it against the original feedback items it covers, then continue.

Each issue must contain:

```markdown
## Problem
[What the user experiences — from verbatim feedback, not paraphrase]
Related feedback: FB-003, FB-007, FB-012 (screenshots attached)

## Expected behavior
[What should happen]

## Spec
[Scope-appropriate spec format — see snippet.md Formality Dial]
```

Scope routing applies here. A cluster of 3 related UI bugs = bug fix format (S1 + S6). A missing feature reported by multiple users = new feature format (full S1–S6).

---

### Phase 5 — Review

**Input**: All written issues from Phase 4
**Output**: Final issue list, ready for backlog

Check each issue:
```
□ Every CONFIRMED item is covered by exactly one issue
□ Reproduction steps are specific enough to hand to a developer who wasn't in this session
□ No item was silently dropped (check your UNCLEAR bucket — were any resolved during writing?)
□ Priorities reflect user frequency, not recency bias (the last 3 items you read ≠ most important)
```

Check the UNCLEAR bucket:
```
□ Do you have enough information now to resolve any UNCLEAR items?
□ If not, create one "needs more info" issue per item so it doesn't get lost
```

---

## Phase Separation Rule

The same principle as spec-first's session separation rule, applied to feedback triage:

**Never evaluate while reading. Never write while verifying. Never group while writing.**

Each phase produces a complete artifact before the next phase begins:
- Phase 1 → complete structured list (no status marks)
- Phase 2 → complete verification (no groups)
- Phase 3 → complete groups (no specs)
- Phase 4 → complete specs (one at a time)
- Phase 5 → complete review

A session that skips phases — reading and evaluating and writing in one pass — is running all five phases concurrently. The context required for phase 5 is not available when phase 1 decisions are made. Feedback items get re-evaluated because later context changes earlier assessments. Verification rounds multiply.

*Derives from: Concurrent phase execution is the most probable behavior in a single-session task. Phase separation is not natural — it requires explicit structure. This document is that structure.*

---

## Common Failures

| Failure | What it produces | Phase that prevents it |
|---|---|---|
| Grep instead of Read | "File exists" ≠ "feature works" — found the route, assumed it worked correctly | Phase 2: read, don't grep |
| Evaluating while reading | Unstable classifications, re-read rounds | Phase 1 before Phase 2 |
| Bulk writing | 10 specs written at once, errors caught late | Phase 4: one at a time |
| No screenshots upfront | Every UI bug requires a re-verify round | Phase 1: screenshots required |
| Writing specs for UNCLEAR items | Developer asks same clarification questions you already had | Phase 2: UNCLEAR ≠ write |
| Grouping by topic instead of root cause | Two issues that fix the same bug in the same file | Phase 3: group by root cause |
| Recency bias in priority | The last 5 items feel urgent, the first 5 feel old | Phase 5: check frequency, not order |

---

## Minimal Checklist

Before starting a triage session:

```
□ All feedback items collected in one place (no "there's also some feedback in Slack")
□ Screenshots attached for every UI claim
□ Reproduction steps written for every functional bug
□ You have a codebase you can Read (not grep) during Phase 2
```

Before the session ends:

```
□ Every CONFIRMED item maps to exactly one issue
□ Every UNCLEAR item is either resolved or has its own "needs more info" issue
□ No item was evaluated only once at the start (before full context was available)
```
