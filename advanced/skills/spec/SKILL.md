---
name: spec
preamble-tier: 2
version: 2.0.0
description: |
  Generate a v2 feature spec. Routes by scope, runs seven verification checks,
  writes specs/<slug>.md from spec.md, sets status: draft. Use when asked to
  "write a spec for", "spec out a feature", or "I want to build [feature]".
effort: medium
allowed-tools:
  - Read
  - Write
  - Bash
---

# /spec — Generate Feature Spec (v2)

You are writing a behavioral contract that comes BEFORE the code.
Read `snippet.md` and `spec.md` at the start of every run. Never embed a copy of the
template here — the only way the two cannot diverge is to read the source.

---

## Step 1: Read context

Read in order; stop at the first file found:
`CLAUDE.md` · `AGENTS.md` · `.cursorrules` · `.windsurfrules` · `.github/copilot-instructions.md`

Extract: stack, API patterns, directory structure, naming conventions.
If none found, note it and proceed.

Also read `spec.md` now. That is the template you will fill.

---

## Step 2: Clarify and pick scope

If arguments were provided (e.g. `/spec User Authentication`), use them.
If not: ask once — "What do you want to spec? (one sentence)"

Then pick the scope that fits. Use the lightest one that covers the change:

| Scope | Trigger | Sections required |
|---|---|---|
| **discovery** | solution not known | Why + Open questions + Options — **stop, no solution sections** |
| **emergency** | production down | fix first; retroactive bug spec same day |
| **bug** | something is broken | Why + Failure modes + QA + File changes |
| **small** | under a day, behaviour change | add Acceptance |
| **refactor** | structure moves, behaviour must not | Why + Invariants + Integration + QA + File changes |
| **feature** | new capability | all mandatory sections |
| **large** | auth, payments, PII, schema, infra | all + Mental model + Pre-reading + human reader |

**For scope: discovery** — write questions and options, then stop. Do not write a solution
spec for a guess. The output file still goes to `specs/<slug>.md` with `status: draft`.

---

## Step 3: Verify (gate — do not skip)

Read `verify.md`. Run all seven checks against the actual codebase.

The checks are:
1. Naming convention — what column/field names does this area actually use?
2. Paths that exist — do the directories and files you plan to reference actually exist?
3. Dependencies present — are the packages you plan to use installed?
4. Env var names — what are the exact names in use?
5. Secrets in URLs — any token/session/key in query strings near this code?
6. Atomicity — any read-then-write that needs an atomic operation?
7. Prior art — does something like this already exist? Search at least three spellings.

Record one line per check. "No hits" is a valid result — write it down.
If a check cannot be run (e.g. no codebase present), write why and what assumption
you are substituting.

**Do not continue to Step 4 until every check has a recorded result.**

---

## Step 4: Write the spec

Create `specs/` if it does not exist:
```bash
ls specs/ 2>/dev/null || mkdir -p specs
```

Convert the feature name to a kebab-case slug.

Write `specs/<slug>.md` by filling the template from `spec.md`. Rules:

- Copy the YAML front matter. Set `status: draft`. Leave `approved_at` blank — you must
  never set it. Leave `shipped_at` and `reconciled_at` blank.
- Fill `## Verification` with the seven recorded results from Step 3.
- Fill every mandatory section for the chosen scope. Replace every placeholder with
  real content — placeholders are not content.
- Failure modes: fill the table rows before writing the happy path. The last column
  ("Recovery") is the one people skip; it must have an answer.
- Invariants: address each one to a person, not to a file. Shape:
  `**[bold claim].** [mechanism]. Do not [tempting wrong move].`
- Known issues: mandatory; at least one entry; "None" is not an entry.
- Optional sections (Mental model, Pre-reading, Thresholds, Code flow, Data contract,
  Copy, State): include only when they carry information not already in the mandatory
  sections.
- Length rule: if the spec is longer than the diff it describes, drop a scope level.

Checkable rules replacing the old "be thorough here" notes:
- **Failure modes**: every row must have entries in all four columns. An empty "Recovery"
  cell is a gap, not a decision.
- **Integration**: a change to existing code with zero integration rows is a gap.
  Run `ls` and `grep` before claiming there are none.

---

## Step 5: Confirm and stop

After writing `specs/<slug>.md`, output exactly this block (fill the brackets):

```
Spec written: specs/[slug].md
Scope: [scope]
Status: draft

Verification recorded: [list the seven check results as one-liners]

Nothing will build until a human sets status: approved and approved_at in the YAML
front matter. The pre-tool-use hook enforces this — any source edit without an approved
spec that names the file is rejected.

Do not ask an agent to set approved_at. That is the moment you stop designing and
start building; conflating the two is how the design quietly gets edited to match the code.
```

Do not implement. Do not suggest implementing. Wait for explicit human approval.
