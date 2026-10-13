---
name: spec-check
preamble-tier: 3
version: 2.0.0
description: |
  Reconciliation gate: compare the merged diff against its spec. Checks that every
  failure-mode row maps to a code path, every QA checkbox has evidence, and every
  path/route/symbol in the spec still resolves. Produces the system-doc append text.
  Run within one working day of merge.
effort: medium
allowed-tools:
  - Read
  - Bash
  - Grep
---

{{PREAMBLE}}

# /spec-check: Reconciliation Gate

A spec is a prediction written before the code; by merge time, some predictions will be
wrong. Surface every one that did not survive the build and produce the corrected text
that belongs in the living system document.

---

## Step 0: Find the matching spec

**A spec matches when its `## File changes` section names a file present in the diff.**

```bash
git diff --name-only HEAD~1 2>/dev/null
grep -rln "## File changes" specs/ 2>/dev/null
```

Read the `## File changes` section of each candidate and check for overlap with the diff.
If no spec matches:

```
⛔ NO MATCHING SPEC — no spec names these files.
Modified: [list]
Action: write a retroactive bug spec (Failure modes + QA + File changes), same day.
```

---

## Step 1: Read the spec

Read the full spec file. Extract:

- Every row of `## Failure modes`
- Every checkbox in `## QA`
- Every path, route, and named symbol in `## File changes`, `## Code flow`, `## Data contract`, and `## Integration`

---

## Step 2: Locate then read

Grep locates; reading decides. A grep hit confirms a file exists, not that a feature works.

```bash
# Locate the handler
grep -rn "[condition, symbol, or error code]" [dir]/
# Then read it to verify the guard and response
```

Do not mark a failure mode HANDLED from a grep hit alone. Read the handler.

---

## Step 3: Check failure modes

For every row in `## Failure modes`:

1. Grep the codebase for the condition (error code, guard, catch, HTTP status).
2. Read the located file to confirm the guard exists and the response matches the spec.
3. Report:
   - **HANDLED** — code path confirmed, response matches spec
   - **UNHANDLED** — no handler found, or handler does not produce what the spec requires

A row not checked is UNHANDLED.

---

## Step 4: Check QA

For every checkbox in `## QA`:

- **VERIFIED** — evidence exists: test output, CI run URL, screenshot, or log line
- **UNVERIFIED** — no evidence, or check was skipped

A skipped check is never reported as a pass.

---

## Step 5: List stale references

Every path, route, and symbol named in the spec that does not exist in the merged code is
stale. These are what the build changed and the spec did not record.

```bash
# Path
git show HEAD:[path-from-spec] 2>/dev/null || echo "STALE: [path]"
# Symbol (zero hits = stale)
grep -rn "[symbol-from-spec]" [dir]/ 2>/dev/null | wc -l
```

---

## Step 6: Produce the system-doc text

Output text ready to append to `docs/system/<area>.md`. Include the post-build, corrected
versions of:

- **Invariants** — corrected against the merged code
- **Thresholds** — values confirmed in the build
- **Data contract** — routes and shapes as they now exist
- **Known issues** — spec's list plus any found during this check

Label each: `[corrected]` or `[unchanged]`.

---

## Step 7: Verdict

```
## Spec Check: [spec title]
Spec: specs/[filename].md
Diff: [N] files, reconcile date: [YYYY-MM-DD]

Failure modes: [N] HANDLED / [N] UNHANDLED
  UNHANDLED: [condition — where a handler is missing or wrong]

QA: [N] VERIFIED / [N] UNVERIFIED
  UNVERIFIED: [scenario — what evidence is absent]

Stale refs: [N]
  [path or symbol] — named in [spec section], not found in merged code

System doc append: [ready below / blocked by stale refs]

[paste system-doc text here]

STATUS: RECONCILED
```

STATUS is RECONCILED only when: 0 unhandled failure modes + 0 unverified QA items +
0 stale references. Otherwise: `NOT RECONCILED — [list what remains]`.

Set `reconciled_at` in the spec only when STATUS is RECONCILED.
