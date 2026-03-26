# PRP: [Feature Name]

<!--
PRP = Implementation Blueprint for AI agents.
Different from spec.md (requirements for humans to approve).

When to write this:
  After spec.md is approved → write PRP in a new session → implement PRP in another new session.

Why this exists:
  spec.md answers WHAT to build.
  PRP answers HOW — with enough context that AI needs zero discovery during implementation.
  No discovery = no context wasted = higher quality output = one-pass success.

Bad line of research = thousands of bad lines of code.
Bad line of plan = hundreds of bad lines of code.
This file is the plan.
-->

> **Spec**: `specs/[slug].md` — read this first. PRP does not repeat requirements.
> **Status**: Draft | Ready | In Progress
> **Confidence**: [1–10] — [one sentence on the main risk to one-pass success]

*Score < 7: add more patterns to follow and gotchas before starting implementation.*

---

## Implementation Context

### Patterns to follow

| File | What to mirror |
|------|---------------|
| `[path/to/similar-service.ts]` | [Specific function signature, error handling pattern] |
| `[path/to/api-route.ts]` | [Auth check placement, response wrapper usage] |
| `[path/to/component.tsx]` | [State management approach, loading/error state pattern] |

### Known gotchas
<!-- Things that WILL cause a bug if unknown. Be specific. -->
- [e.g., "`.eq()` on nullable column returns 0 rows for null — use `.is(null)` instead"]
- [e.g., "Supabase PostgREST silently truncates at 1000 rows — always add `.range()`"]
- [e.g., "Gemini structured output requires `responseMimeType: 'application/json'` in config"]
- [e.g., "This endpoint is called from mobile — response must be < 200KB"]

### File plan

```
Current state (files being touched):
src/
└── [existing file that changes] *

Target state (after implementation):
src/
├── [existing file] *           ← modified: [what changes]
└── [new file]                  ← created: [one-line responsibility]
```

---

## Task Sequence

<!-- Each task ≤ 30 min. One concern per task where possible.
     _Req: S1.auth_ links each task back to an acceptance criterion in spec.md. -->

- [ ] **1. [Task name]**
  - File: `[exact path to create or modify]`
  - What: [one sentence — what this task does]
  - _Req: [S1.X, S3.Y — which spec sections/criteria this satisfies]_

- [ ] **2. [Task name]**
  - File: `[exact path]`
  - What: [one sentence]
  - _Req: [S2.X]_

- [ ] **3. [Task name]**
  - File: `[exact path]`
  - What: [one sentence]
  - _Req: [S6 — enables QA scenario X]_

### Key logic decisions
<!-- Pseudocode for non-obvious decisions. Not full implementation.
     Only write this for decisions where a wrong choice = hours of debugging. -->

```
[feature operation]:
  step 1: [description]  // why: [reason, or pattern reference]
  step 2: [description]  // why: [avoids gotcha X above]
  on error: [description]  // why: matches S1 row for [condition]
```

---

## Validation Gates

<!-- Run in order. Fix before moving to next gate. Never mark complete until all pass. -->

```bash
# Gate 1: Type check (catches structural errors before runtime)
npx tsc --noEmit

# Gate 2: Lint
npm run lint

# Gate 3: Unit tests for this feature
[specific test command — not "npm test", but the exact test for this feature]
# Expected: all pass, 0 failures

# Gate 4: Behavior (manual or curl)
[specific curl command or manual step]
# Expected: [exact response or behavior]
```

---

## Confidence Score

**[X]/10**

[One paragraph: what makes this high/low confidence. What information is missing. What could cause the implementation to need a second pass.]

Score guide:
- **9–10**: All patterns identified, no ambiguous logic, all gotchas documented, validation commands tested
- **7–8**: Minor unknowns, likely resolvable during implementation without context loss
- **5–6**: One significant unknown — add research before implementing
- **< 5**: Do not implement yet — fill in patterns and gotchas first
