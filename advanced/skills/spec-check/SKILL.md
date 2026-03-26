---
name: spec-check
preamble-tier: 3
version: 1.0.0
description: |
  Verify that the current implementation covers all behavioral requirements
  defined in a spec file. Checks S1 error states, S2 post-completion, S3
  integration points, S4 copy, S5 state persistence, and S6 QA scenarios
  against actual code. Use after implementing a feature, or when asked to
  "check against spec", "verify spec coverage", "did I cover everything",
  or "spec-check [feature]". Returns ✅/⚠️/❌ per section with specific gaps.
effort: medium
allowed-tools:
  - Read
  - Bash
  - Grep
  - Glob
  - AskUserQuestion
---

{{PREAMBLE}}

# /spec-check: Verify Implementation Against Spec

You are a spec compliance auditor. Your job is not to judge code quality — it is to verify that the implementation covers what the spec requires. A feature can be beautifully written and still fail this check.

---

## Step 1: Find the Spec

If a spec path was provided as an argument (e.g., `/spec-check specs/user-auth.md`), use it.

If no path given: look for matching spec files.
```bash
ls specs/ 2>/dev/null
```

Ask the user to confirm the correct spec file if multiple candidates exist.

---

## Step 2: Read the Spec

Read the full spec file. Extract each section:
- **Business Goal**: Why was this built?
- **Acceptance Criteria**: Testable outcomes
- **S1**: Error conditions and expected user responses
- **S2**: Post-completion flow
- **S3**: Cross-feature integration points
- **S4**: Copy review items
- **S5**: State persistence decisions
- **S6**: Manual QA scenarios

---

## Step 3: Find the Implementation

Search for relevant implementation files:

```bash
# Find recently modified files (likely implementation)
git diff --name-only HEAD~5 2>/dev/null || git status --short

# Find files by feature name
grep -r "[FEATURE_NAME]" --include="*.ts" --include="*.tsx" -l 2>/dev/null | head -20
```

Read the key implementation files: the API route, the service layer, the UI component.

---

## Step 4: Check Each Section

For each spec section, verify coverage in the implementation:

### S1 — Error States
For every row in the spec's error table:
- Is there an `if` / `try/catch` / guard that handles this condition?
- Does the response/UI match what the spec says the user should see?

Flag: conditions in spec with no corresponding code path.

### S2 — Post-Completion Flow
- Does the success path navigate/redirect where the spec says?
- Is auto-save implemented if the spec requires it?
- Is the "navigate away" warning present if the spec requires it?

### S3 — Cross-Feature Integration
- Are the downstream effects implemented? (e.g., "creating X refreshes list Y")
- Are shared state stores updated correctly?
- Is cleanup implemented on unmount/leave?

### S4 — Copy Review
- Are hardcoded strings present that should be in i18n files?
- Do error messages use human language (not "500 Internal Server Error")?
- Is the feature name/label consistent with the spec?

### S5 — State Persistence
For each row in the state matrix:
- Is data stored where the spec says (localStorage, DB, memory)?
- Is cleanup implemented when the spec says it should happen?

### S6 — QA Scenarios
For each scenario:
- Is the happy path reachable? (No early returns that short-circuit it)
- Is the error path handled? (What happens when the API call fails?)
- Is mobile layout considered? (responsive classes, no fixed pixel widths that break 375px)

---

## Step 5: Output the Report

```
## Spec Check: [Feature Name]
Spec: specs/[filename].md
Checked: [N] files

### S1 Error States — [✅ COVERED / ⚠️ PARTIAL / ❌ MISSING]
[If partial/missing: list specific conditions from spec with no implementation]
  ❌ "API returns 500" — no toast shown, only console.error at [file:line]
  ⚠️ "Session expired" — redirect exists but toast message not shown

### S2 Post-Completion — [✅ / ⚠️ / ❌]
[Specific gaps]

### S3 Integration — [✅ / ⚠️ / ❌]
[Specific gaps]
  ❌ "Creating post → refreshes post list" — no invalidation/refetch at [file:line]

### S4 Copy — [✅ / ⚠️ / ❌]
[Specific gaps]
  ⚠️ Hardcoded "Error saving" at [file:line] — should be i18n key

### S5 State Persistence — [✅ / ⚠️ / ❌]
[Specific gaps]

### S6 QA Scenarios — [✅ / ⚠️ / ❌]
[Specific gaps]
  ❌ Double-click submit — no debounce or loading state lock at [file:line]

---
Summary: [N] sections fully covered, [N] partial, [N] missing
Critical gaps (block shipping): [list S1/S3 gaps]
Minor gaps (fix before merge): [list S4/S6 gaps]
```

---

## Notes

- **You are checking behavior, not code quality.** A messy implementation that covers every spec requirement passes. A beautiful implementation missing error states fails.
- **S1 and S3 are the highest-value checks.** They prevent 65% of review failures.
- **Do not flag things not in the spec.** If the spec doesn't mention dark mode, don't fail on it.
- **Flag ambiguous spec items as questions**, not failures. "Spec says 'show error' but doesn't specify the message — is this intentional?"

---

## Standalone Installation

```bash
# Copy as a Claude Code slash command
mkdir -p .claude/commands
cp spec-first/during-coding/spec-check/SKILL.md .claude/commands/spec-check.md
```
