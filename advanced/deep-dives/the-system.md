# The System: Spec-First Development

## Core Principle

**Replace code-writing time with spec-writing time.**

You don't write code. You write specifications — detailed behavioral contracts that tell the AI *what* to build. The AI handles the *how*. Your time goes to defining requirements precisely, reviewing output for correctness, and making architectural decisions.

---

## The Four-Phase Cycle

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│   SPEC   │ →  │ GENERATE │ →  │  REVIEW  │ →  │   SHIP   │
│ (Human)  │    │  (AI)    │    │ (Human+  │    │ (Human)  │
│          │    │          │    │  AI)     │    │          │
│ 1-2 hrs  │    │ 3-10 min │    │ 30-60min │    │ 5 min    │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
```

### Phase 1: Spec (Human, 1-2 hours)

Write a specification document. Not a user story. Not a ticket. A **complete behavioral contract**.

A spec answers:
- What does the user see and do? (Acceptance criteria)
- What happens when things go wrong? (S1: Error states)
- What happens after success? (S2: Post-completion flow)
- How does this affect other features? (S3: Integration)
- Is the copy natural and translated? (S4: UX copy)
- Where does each piece of data live? (S5: State matrix)
- How do we verify this works? (S6: QA scenarios)

### Phase 2: Generate (AI, 3-10 minutes)

Feed the spec to Claude Code:

```
Read CLAUDE.md, then implement the spec at specs/[feature-name].md
```

The AI reads your system context (CLAUDE.md), understands your codebase patterns, and generates implementation across multiple files — API routes, services, components, types, tests.

**Key insight**: The AI's output quality is directly proportional to your spec quality. Vague spec → vague code → hours of debugging. Precise spec → correct code → clean merge.

### Phase 3: Review (Human + AI, 30-60 minutes)

Two sub-layers:

**3a. Automated review** (3-5 min, no human effort)
- CodeRabbit scans for security, cross-file issues, severity ratings
- CI/CD runs build, lint, tests
- Gate: 0 Critical + 0 High

**3b. Human behavior review** (15-30 min)
- Does the feature work as the spec describes?
- Do error states show correct messages?
- Mobile layout correct?
- Refreshing page behaves correctly?
- Gate: Spec compliance verified

### Phase 4: Ship (Human, 5 minutes)

Merge the PR. Deploy. Write the next spec.

---

## The Six Sections

Every spec includes 6 mandatory sections. Each targets a specific category of AI-generated bugs. Skip any section and you'll pay the fix tax later.

### S1: Error States & Validation

**Targets**: 25% of AI-generated bugs.

AI writes beautiful happy-path code. It almost never handles:
- Authentication failures
- Session expiration
- API errors (500, 404, 429)
- Network offline
- Missing required fields
- Null/undefined data

**Without S1**: You'll discover these in production when a user reports a blank screen.

**With S1**: Every error scenario has a defined user-visible outcome. AI generates the handling code upfront.

### S2: Post-Completion Flow

**Targets**: 15% of bugs. The "works in demo, breaks in real use" category.

AI builds the action but forgets what happens after:
- Where does the result save? (DB? localStorage? Nowhere?)
- What if the user leaves mid-action?
- What if the user refreshes?
- Are there output limits?

**Without S2**: Data disappears on refresh. Users lose work. No one knows where results went.

**With S2**: Every data path is explicit. The AI generates save, restore, and cleanup logic.

### S3: Cross-Feature Integration

**Targets**: 40% of bugs. The single biggest category.

AI builds features in isolation. Feature A works perfectly. Feature B works perfectly. But A and B don't talk to each other:
- Creating an entity in A doesn't refresh the list in B
- Shared state isn't synced
- Leaving A doesn't clean up state that B depends on

**Without S3**: Integration bugs surface only when testing full user flows.

**With S3**: Every trigger, shared store, empty state, and cleanup action is defined upfront.

### S4: UX Copy Review

**Targets**: 10% of bugs. Death by a thousand paper cuts.

AI defaults to developer jargon:
- "Submit" instead of "Save changes"
- "Error: 500 Internal Server Error" instead of "Something went wrong. Try again."
- Mixing languages in i18n apps
- Technical labels that confuse non-developer users

**Without S4**: Your app feels like a developer tool, not a product.

**With S4**: Every user-facing string is reviewed for naturalness and translation.

### S5: State & Persistence Matrix

**Targets**: 10% of bugs. Subtle, hard to debug.

AI makes random persistence decisions:
- Form data in localStorage (survives refresh but never cleans up)
- API response in component state (lost on navigation)
- User preference in memory (gone after refresh)

**Without S5**: State bugs that only appear in specific navigation sequences.

**With S5**: A table explicitly maps every piece of data to its storage location, persistence behavior, and cleanup trigger.

### S6: Manual QA Scenarios

**Targets**: Regression prevention.

AI doesn't write test scenarios. Your QA engineer would. S6 fills that gap:
- Happy path works
- Error path shows correct UI
- Modal behavior (click outside, escape key)
- Double-click prevention
- Mobile layout (375px)
- Browser refresh mid-flow
- Back button behavior

**Without S6**: Manual testing after merge catches issues that should have been caught before.

**With S6**: The AI generates code that passes these scenarios on the first try. Review becomes verification, not discovery.

---

## Spec Evolution

Specs get better over time. Track your fix:feat ratio to measure progress.

### Gen 1: Bullet Points (Week 1)

```
- User can create an entity
- Entity has name, price, description
- Show list with search
```

**Fix:feat ratio**: ~5:1. AI guesses most of the behavior. You spend 5x more time fixing than building.

### Gen 2: API Contracts + Criteria (Week 2)

```
### POST /api/entities
Request: { name, price, description }
Response: { success: true, data: { id, ... } }

Acceptance:
- [ ] Form validates required fields
- [ ] Success shows toast + redirects
- [ ] Error shows localized message
```

**Fix:feat ratio**: ~3:1. Better, but still missing error handling and integration.

### Gen 3: Full S1-S6 (Week 3+)

[Complete spec with all 6 sections filled in]

**Fix:feat ratio**: ~1.5-2:1. Most issues caught at spec time, not fix time.

### Measuring Spec Quality

```
Fix:feat ratio > 3:1  →  Your specs are too vague. Add more detail to S1 and S3.
Fix:feat ratio 2-3:1  →  Normal for early adoption. Keep improving.
Fix:feat ratio 1.5-2:1 → Good. Your specs are working.
Fix:feat ratio < 1.5:1 → Great. You might be over-specifying — check if specs take too long.
```

---

## CLAUDE.md as Operating System

The system context file (CLAUDE.md) is what makes AI output consistent across sessions. Without it, every session starts from scratch and the AI invents its own patterns.

### What Goes In CLAUDE.md

| Section | Purpose | Example |
|---------|---------|---------|
| Tech stack | Prevent vendor drift | "TypeScript strict. No `any`." |
| Critical rules | Prevent recurring mistakes | "All DB access via services, never direct." |
| Directory structure | Navigate the codebase | Where routes, services, types live |
| API contract | Prevent shape mismatches | Response wrapper format |
| Ownership zones | Prevent scope creep | Who can modify which directories |
| Conventions | Consistent style | Naming, imports, error logging |

### CLAUDE.md Lifecycle

| Project Phase | CLAUDE.md Focus |
|--------------|----------------|
| Week 1 | Tech stack + directory structure + 3-5 critical rules |
| Month 1 | Add ownership zones + API contract + common mistakes |
| Month 3 | Refine rules based on recurring review feedback |
| Month 6+ | Prune rules that no longer apply, add new patterns |

**Keep it under 150 lines.** Every line consumes AI context. Only rules that prevent actual observed mistakes earn their place.
