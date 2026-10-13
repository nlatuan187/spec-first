# PRP: [Feature Name]

<!--
PRP = Implementation Blueprint for AI agents.
Different from spec.md (requirements for humans to approve).

When to write this:
  After spec.md is approved → write PRP in a new session → implement in another new session.

What this covers that spec.md does not:
  1. Confidence score — an honest pre-implementation rating of how resolved the HOW is.
     Spec.md describes what to build; this rates whether the implementation path is clear.
  2. Task sequence — time-boxed checkboxes linking each task back to a spec criterion.
     Spec.md has QA checkboxes for acceptance; this tracks implementation progress.

What belongs elsewhere, not here:
  - Patterns to follow → verify.md check 7 (prior art) + system.md code flow
  - Known gotchas    → system.md Known issues (folded in at reconciliation)
  - File plan        → spec.md ## File changes
  - Validation gates → spec.md ## QA + your project CI

Score < 7: stop. Resolve the unknown before opening a Build session.
-->

> **Spec**: `specs/[slug].md` — read this first. PRP does not repeat requirements.
> **Status**: Draft | Ready | In Progress
> **Confidence**: [1–10] — [one sentence on the main risk to one-pass success]

---

## Task Sequence

<!-- Each task ≤ 30 min. One concern per task where possible.
     Link each task back to a criterion in spec.md with _Req: section.label_. -->

- [ ] **1. [Task name]**
  - File: `[exact path to create or modify]`
  - What: [one sentence — what this task does]
  - _Req: [Failure modes.X, Integration.Y — which spec criteria this satisfies]_

- [ ] **2. [Task name]**
  - File: `[exact path]`
  - What: [one sentence]
  - _Req: [Acceptance.X]_

- [ ] **3. [Task name]**
  - File: `[exact path]`
  - What: [one sentence]
  - _Req: [QA — enables scenario X]_

### Key logic decisions

<!-- Pseudocode only for decisions where a wrong choice costs hours of debugging.
     Do not repeat spec.md's Code flow here. -->

```
[feature operation]:
  step 1: [description]  // why: [reason]
  step 2: [description]  // why: [avoids issue from system doc]
  on error: [description]  // why: matches Failure modes row for [condition]
```

---

## Confidence Score

**[X]/10**

[One paragraph: what makes this high or low. What information is missing. What could force a second pass.]

Score guide:
- **9–10**: All tasks sequenced, no ambiguous logic, all non-obvious decisions documented
- **7–8**: Minor unknowns, likely resolvable mid-implementation without context loss
- **5–6**: One significant unknown — research it before implementing
- **< 5**: Do not implement. Resolve the unknown first.
