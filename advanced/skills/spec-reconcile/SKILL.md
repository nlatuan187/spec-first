---
name: spec-reconcile
preamble-tier: 3
version: 2.0.0
description: |
  Post-merge reconciliation: re-reads a shipped spec against the merged diff, corrects
  every stale reference in place, appends build learnings to Known issues, extracts
  durable content into docs/system/<area>.md, sets reconciled_at, and moves the spec to
  specs/done/. Run within one working day of merge.
effort: medium
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

{{PREAMBLE}}

# /spec-reconcile

A spec is a prediction. This command corrects every prediction that did not survive the
build and extracts what is now true into the living system document.

Two labels matter: "the code changed and the spec is wrong" is a correction. "the spec
was always wrong" is a lesson. Both get fixed; only the second goes into Known issues.
A check that could not be performed is NOT PERFORMED, never passed.

---

## Step 0: Locate spec and diff

```bash
git diff --name-only HEAD~1 2>/dev/null
ls specs/ 2>/dev/null
```

Match the diff to a spec: a spec matches when its `## File changes` section names a file
present in the diff. If none matches, stop and output:

```
NO MATCHING SPEC — write a retroactive spec with /spec before reconciling.
Modified: [list]
```

---

## Step 1: Extract from the spec

Read the full spec. Collect: every path, route, HTTP method, symbol in `## File changes`,
`## Code flow`, `## Data contract`, `## Integration`; every field and column name in
`## Data contract` and `## Verification`; every number in `## Thresholds` and the body;
every row in `## Failure modes`; `area` from the front matter.

---

## Step 2: Read the diff and merged files

```bash
git diff HEAD~1 2>/dev/null
git show HEAD:[path] 2>/dev/null | head -120
```

Do not classify from grep hits alone. Read the relevant portion of each changed file.

---

## Step 3: Classify every extracted item

| Label | Meaning |
|---|---|
| **MATCHES** | Exists in merged code exactly as spec states. |
| **CHANGED** | Renamed, moved, or removed during the build. Correct the spec. |
| **ALWAYS WRONG** | Never in the code at any point in the diff. Correct + add to Known issues. |
| **NOT PERFORMED** | Check could not run. State why. |

If a spec section has no counterpart in the merged code, report it under "Sections with
no code counterpart". Never silently drop it.

---

## Step 4: Correct the spec in place

Replace each stale token (path, name, number, route) with the correct value. Do not
rewrite prose. Do not add sections the spec did not have.

For ALWAYS WRONG items, append to `## Known issues`:
`- Spec claimed [X]; code never had it. Assumed at spec time. Actual: [Y].`

---

## Step 5: Extract durable content into the system document

Durable: invariants (rules, not file names), threshold values with reasons, never-exposed
field names, known issues. Perishable: anything referencing a specific path or line.

```bash
area=$(grep '^area:' specs/[slug].md 2>/dev/null | awk '{print $2}')
ls docs/system/ 2>/dev/null
```

**Absent:** create `docs/system/<area>.md` from `system.md`. Fill Invariants, Thresholds,
Data contract (field names only), Known issues from the corrected spec.

**Present:** read it first, then merge: append new invariants (deduplicate by claim);
update or append threshold rows; extend Known issues; append to `## Changes folded in`:
`| [YYYY-MM-DD] | specs/done/[slug].md | [one-line summary] |`

Never replace the system document wholesale.

---

## Step 6: Finalize

Set in the spec's YAML front matter: `status: reconciled` and `reconciled_at: [today]`.

```bash
mkdir -p specs/done
mv specs/[slug].md specs/done/[slug].md
```

---

## Step 7: Output the verdict

```
## Reconciliation: [spec title]
Spec: specs/done/[slug].md  |  Diff: [N] files  |  Date: [YYYY-MM-DD]

### Corrections ([N] total)
CHANGED       [N]  — spec was right at design time; code evolved
ALWAYS WRONG  [N]  — spec was never accurate; added to Known issues
MATCHES       [N]
NOT PERFORMED [N]  — [reason for each]

### Detail
- [item] — CHANGED — was: [old] → now: [new]
- [item] — ALWAYS WRONG — was: [old] → actual: [new]; lesson added

### Sections with no code counterpart
- [section] — [what the spec claimed; nothing in the diff corresponds]

### System document
[created | updated]: docs/system/[area].md

STATUS: RECONCILED
```

STATUS is RECONCILED only when every item is classified, no section was silently dropped,
and `reconciled_at` is set. Otherwise: `STATUS: NOT RECONCILED — [list what remains]`
