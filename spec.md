---
title: "[NAME]"
status: draft                    # draft | in-review | approved | implementing | done
scope: new-feature               # bug-fix | small-change | refactor | new-feature | large-feature | spike | delta
s1_count: 0                     # filled after writing S1 — used by Scope Routing
s3_count: 0                     # filled after writing S3 — used by Scope Routing
created: YYYY-MM-DD
---

# Feature: [NAME]

> **Solo**: self-approve, move to Implementing when ready.
> **Team**: Draft → In Review → **Approved** → Implementing → Done. Build session only starts on Approved specs.
> **Before writing**: Read your project constitution — it defines stack, conventions, constraints that affect every section here.

---

<!-- CHOOSE ONE FORMAT:
  - New feature → use the full S1–S6 template below
  - Existing code change → use Delta Format (faster, brownfield-safe)
  - Bug fix → use the Bug Format (S1 + S6 only)
-->

---

## Delta Format (for changes to existing code)

<!-- Use this when modifying existing behavior. Delete this section if writing a new feature. -->

**What's changing**
```
ADDED:    [new behavior, field, or endpoint]
MODIFIED: [existing behavior → new behavior]
REMOVED:  [what's being deleted and why]
```

**What it touches** (run this — don't rely on memory):
```bash
ls [your-source-dirs] 2>/dev/null | head -40
```
Integration effects: [for each relevant result above: read or write?]

**S1 — What breaks if this delta regresses**

| Condition | User sees / System does |
|-----------|------------------------|
| [Condition specific to the change] | [behavior] |

**S6 — Regression scenario**
- [ ] Before delta: [state] → After delta: [expected diff] → Verify: [how]

---

## Bug Format (for bug fixes)

<!-- Use this for bug fixes. Delete this section if writing a feature or delta. -->

**Bug**: [what currently happens]
**Expected**: [what should happen]
**Trigger**: [exact steps to reproduce]

**S1 — Error states**

| Condition | User sees / System does |
|-----------|------------------------|
| [Root cause condition] | [behavior before fix] → [behavior after fix] |

**S6 — Regression**
- [ ] Fix verified: [specific reproduction → expected resolution]
- [ ] No regression: [related behavior still works]

---

## Refactor Format (for structural changes that preserve behavior)

<!-- Use this when renaming, moving, splitting, or merging code without changing what it does. Delete this section if writing a feature, delta, or bug fix. -->

**What's being restructured**: [what moves where / what gets renamed / what gets split or merged]

**Behavior that MUST NOT change**:
- [specific behavior 1 — must work identically after refactoring]
- [specific behavior 2]

**What references it** (run this — don't rely on memory):
```bash
grep -r "FunctionName\|ClassName\|import_path" [your-source-dirs] --include="*.[ext]" | head -30
```

**S3 — Every file that needs migration**

| File | How it references the thing being changed | Migration needed |
|------|------------------------------------------|-----------------|
| [file path] | [import / function call / type reference] | [rename import / update path / change API] |

**S6 — Regression (verify behavior is preserved)**
- [ ] [Specific behavior] still works after refactoring
- [ ] [Specific behavior] still works after refactoring
- [ ] All existing tests pass

---

## Overview

**Goal**: [What the user accomplishes — one sentence]
**Trigger**: [What causes this feature to activate]
**Users affected**: [Who uses this]

---

## Acceptance Criteria

<!-- Use EARS notation: WHEN / IF / WHILE + SHALL
     WHEN = event trigger   IF = condition   WHILE = continuous state
     SHALL = mandatory       SHOULD = recommended
     Every criterion must be verifiable by a human who hasn't read the code. -->

### Core behaviors
- WHEN [user action / trigger event] THEN the system SHALL [observable behavior]
- WHEN [secondary trigger] THEN the system SHALL [behavior]

### Edge cases (must work correctly)
- WHEN [boundary value / empty state] THEN the system SHALL [behavior]
- IF [concurrent / interrupted state] THEN the system SHALL [behavior]
- WHILE [ongoing condition] THE system SHALL [continuous behavior]

### Failure behaviors (must fail gracefully)
- IF [unauthorized / no permission] THEN the system SHALL [specific redirect or message — not "show error"]
- IF [invalid input: describe specific input] THEN the system SHALL [specific error message]
- IF [external service down] THEN the system SHALL [fallback behavior]

---

## S1: Error States & Validation

**Deployment Constraints** (fill BEFORE error rows — adapt to your stack):
- Timeout: [Web: Vercel 10s, Lambda 15s | Mobile: iOS background 30s, Android ANR 5s | Backend: gRPC deadline, queue visibility timeout]
- Data limits: [DB truncation? Batch size? Connection pool? Redis maxmemory?]
- Auth / secrets: [Never in URL params or logs | Mobile: Keychain/Keystore only | Backend: env vars, rotate via vault]
- Concurrency: [Cron dedup? Offline sync? Circuit breaker? Idempotency keys?]

| Condition | User sees / System does |
|-----------|------------------------|
| Not authenticated | [Web: redirect to /login | Mobile: present login screen | API: 401 response] |
| Session / token expired | [Auto-refresh? Re-prompt? Redirect?] |
| Service unavailable (500 / timeout) | [User-facing message + retry option | Queue retry with backoff] |
| Resource not found (404) | [Empty state? "Not found" message? Fallback?] |
| Invalid input | [Inline validation with specific text | API: 422 with field-level errors] |
| Data missing / null | [Placeholder UI? Default value? Error boundary? Log + skip?] |
| Network unavailable | [Web: banner | Mobile: offline queue + sync | Backend: circuit breaker] |
| Concurrent / duplicate operation | [Idempotency key? Atomic lock? Optimistic locking?] |

## S2: Post-Completion Flow

- **On success**: [Navigate where? Show what confirmation? Auto-save where?]
- **User leaves mid-flow**: [Auto-save? Warning? Discard? Mobile: app backgrounded?]
- **App/page restart mid-flow**: [Restore from local storage / DB? Start over?]
- **Output constraints**: [Max length? File size? Rate limits? Payload size?]

## S3: Cross-Feature Integration

<!-- Before writing this section, enumerate existing features from the codebase:
     ls [your-source-dirs] 2>/dev/null | head -40
     Do not enumerate from memory. Scan what actually exists. -->

- **Triggers**: [Creating X here → refreshes list in Feature Y? Updates count in Feature Z?]
- **Shared state**: [Which store / context / global state is read or written?]
- **Empty state**: [No data yet → show what? Onboarding prompt?]
- **Cleanup**: [Leaving this feature → reset which store? Clear which cache?]

## S4: UX Copy Review

- [ ] All text is plain language — no technical jargon
- [ ] Error messages are specific ("Connection failed. Try again." not "Error 500")
- [ ] Labels and buttons make sense to a non-developer
- [ ] Loading states describe what's happening ("Uploading photo…" not "Loading…")
- [ ] Empty states have a clear next action

## S5: State & Persistence Matrix

| Data | Stored where | Persists on restart? | Cleared when |
|------|-------------|:-------------------:|-------------|
| [User input] | [Memory / local storage / DB / cache] | [Yes/No] | [Leave flow / Submit / Timeout] |
| [Selection state] | [Memory / URL param / ViewModel] | [Yes/No] | [Navigate away / Deselect] |
| [Fetched data] | [Cache / store / in-memory] | [Yes/No] | [Stale time / Leave scope / TTL] |

## S6: Manual QA Scenarios

- [ ] **Happy path**: WHEN [full flow] THEN user sees [specific outcome]
- [ ] **Error — API fails**: trigger API failure → user sees [specific message], can [retry/cancel]
- [ ] **Error — invalid input**: submit [specific bad input] → user sees [specific inline message]
- [ ] **Empty state**: no existing data → user sees [specific UI], can [next action]
- [ ] **Loading**: click [action] → result appears within [X] seconds; indicator visible
- [ ] **Small screen / mobile**: all elements accessible, no overflow, touch targets adequate
- [ ] **Restart mid-flow**: app/page restart at [step N] → [data preserved / user returned to start]
- [ ] **Double-submit**: click twice rapidly → [prevented / deduplicated]

---

## Spec Self-Review

*Run this before handing to AI. Missing items = rework.*

1. **Placeholder scan**: Any "TBD", "TODO", vague "show error"? Fix inline.
2. **Consistency check**: Does S5 storage match S2 post-completion? Do S1 errors match S6 test cases?
3. **Scope check**: Is this one feature or multiple? If multiple, split before implementing.
4. **Ambiguity check**: Can any requirement be interpreted two ways? Pick one, make explicit.
5. **Completeness**: S1 has ≥5 rows with specific user-visible outcomes? S3 has ≥1 upstream + ≥1 downstream? S6 has happy path + error + mobile?

*S1 and S3 prevent 65% of review failures.*

---

## Next step

After spec is approved → open a **new session** to implement.

**Optional: Implementation Notes** (fill this before implementing if the feature is complex)

If confidence is low or the feature touches unfamiliar code, add these before the implementation session:

```
### Patterns to follow
| File | What to mirror |
|------|---------------|
| [path/to/similar.ts] | [Specific pattern — function signature, error handling] |

### Known gotchas
- [Specific trap — e.g., "`.eq()` on nullable column returns 0 rows — use `.is(null)`"]
- [Deployment gotcha — e.g., "This endpoint is called from mobile — response must be < 200KB"]

### File plan
Current state:     Target state:
src/               src/
└── [file] *       ├── [file] *  ← modified: [what changes]
                   └── [new]     ← created: [one-line responsibility]

### Validation gates
# Gate 1: npx tsc --noEmit
# Gate 2: [specific test command]
# Gate 3: [curl command] → Expected: [exact output]
```

*For a full implementation blueprint template, see `advanced/prp.md`.*
