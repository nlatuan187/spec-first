## Spec-First — AI Development Methodology

> Paste into your AI context file — CLAUDE.md, .cursorrules, .windsurfrules, AGENTS.md,
> or .github/copilot-instructions.md. Works with any AI tool that reads a context file.

---

### The Fundamental Law

**AI generates the most statistically probable next token — not the correct one. It has no judgment. Only probability.**

Every rule in this methodology derives from this single law. When you understand it, you can engineer AI behavior for any situation not covered here.

---

### Project Constitution

Your AI context file (CLAUDE.md / .cursorrules / etc.) **is your project constitution** — the document that anchors every AI decision to your stack, conventions, and constraints.

Before any session: the AI reads the constitution. Every spec, every review, every debug starts from the same ground truth.

*If you don't have one, create it now. Minimum: tech stack, key file paths, API patterns, auth method.*

---

### Four Session Types

Every feature moves through four cold sessions — each one starts with zero context from the previous:

| Session | AI reads | AI produces | Terminal action |
|---------|----------|-------------|-----------------|
| **Clarify** | Constitution + feature request | 3 questions max | Wait for answers |
| **Spec** | Constitution + answers | `specs/[slug].md` | "Start new session to implement" |
| **Build** | Constitution + spec | Working code | "Start new session to review" |
| **Review** | Constitution + diff | Pass 1 + Pass 2 findings | "No new session needed" |

*Derives from: Each session type has a different most-probable-next-token profile. Mixing types in one session imports the previous type's probability bias. Clarify contaminated with spec → over-specified questions. Build contaminated with spec → rationalized-away error states. Review contaminated with build → motivated reasoning.*

---

### TRIGGER: When asked to build, implement, create, or add any feature

**Session 1 — Clarify** (skip if feature is unambiguous):

Read the constitution. Then check: can you answer all three?
- What is the exact trigger (user action or system event)?
- What is the success outcome (what does the user see when it works)?
- Is this one operation, or multiple features bundled?

If any is unclear from the request + constitution, ask those questions. Maximum 3. About observable behavior only — never about implementation. Wait for answers.

**Terminal state**: Do not write the spec until all questions have answers.

*Derives from: The most probable next token after an ambiguous request is a confident-sounding wrong answer.*

---

**Session 2 — Spec:**

1. Say "Writing spec first…"
2. Choose spec format based on scope (see Formality Dial below)
3. Create `specs/[feature-slug].md`
4. Fill every section — no placeholder text
5. End with exactly:
   ```
   ━━━ Spec written: specs/[slug].md ━━━
   Start a NEW session to implement. Do not continue here.
   ```
6. Write **zero implementation code** in this session.

**Terminal state**: After writing the spec, the ONLY valid next action is opening a new session.

*Derives from: "Continue with implementation" is 10x more probable than "stop and wait." The terminal state overrides the probability.*

---

### Formality Dial — match spec depth to scope

| Scope | Spec format | Sections required |
|---|---|---|
| **Bug fix** | `[Bug] title` + what breaks + expected behavior | S1 (error states) + S6 (regression) |
| **Small change** (< 1 day) | S1 + S3 + S6 | 3 sections |
| **New feature** | Full S1–S6 | All 6 sections |
| **Large feature / team** | Full S1–S6 + Implementation Notes | All 6 + notes |
| **Brownfield delta** | See Delta Format below | Depends on scope |

*The trigger still applies at all formality levels: spec first, zero code in spec session, new session to implement. Formality scales down. Session separation does not.*

---

### Delta Format — for changes to existing code

When modifying existing behavior (not adding new features), use delta format:

```
## What's changing
ADDED: [new behavior or field]
MODIFIED: [existing behavior → new behavior]
REMOVED: [behavior being deleted and why]

## What it touches (scan, don't rely on memory)
ls lib/services/ app/api/ components/features/ 2>/dev/null | head -40

## S1: What breaks if this delta regresses
[error states specific to the change — not the whole feature]

## S6: Regression scenarios
[specific test: before delta → after delta → expected diff]
```

*Derives from: Describing the whole system when only a delta is changing is low-probability-of-accuracy. Delta format forces contact with what's actually different, reducing hallucination of the full system state.*

---

### S1 Rule — Write failures BEFORE the happy path

Open S1 by answering: *"What breaks? Who is unauthorized? What's missing or null?"*
List those first. The happy path is last.

Fill **Deployment Constraints** before writing any error rows:

| Constraint | Rule |
|---|---|
| Serverless timeout | No loops > 10s — Vercel default 10s, max 60s |
| Bulk DB queries | Always `.range()` paginate — PostgREST truncates at 1000 rows silently, no error |
| External API auth | `Authorization: Bearer TOKEN` header only — token in URL gets logged in server/CDN/Vercel logs |
| Background / cron | Atomic lock required: `UPDATE ... WHERE status IS NULL RETURNING id` — second runner gets 0 rows |

*Derives from: Training data is ~10:1 success-to-failure. Low-frequency patterns (serverless timeouts, DB truncation) have low probability — they must be stated explicitly.*

---

### S3 Rule — Enumerate ALL integrations before writing the section

Before writing S3, enumerate existing features from the codebase — not from memory:

```bash
# Find what actually exists (adapt paths to your project)
ls lib/services/ app/api/ components/features/ 2>/dev/null | head -40
```

For each result: does this new feature read from it or write to it?
An S3 with no rows is almost always wrong.

*Derives from: Memory-based enumeration misses features that exist in code but weren't mentioned in conversation. Scanning forces contact with reality.*

---

### Session Rule — Never review code you just wrote

When asked to review: open a **new session** → paste the diff → apply the checklist.

**Terminal state**: A session that wrote code cannot review it. No exceptions. Not even "just a quick check."

*Derives from: "The code is correct" is the most probable continuation of an implementation session. A cold session has no motivated reasoning.*

---

### Debugging Protocol — when implementation is stuck

If the same error persists after 2 fix attempts, stop. Do not try a third variation.

Write `specs/[slug]-debug.md`:
```
Error: [exact message + file:line]
Attempt 1: [what was changed] → [result]
Attempt 2: [what was changed] → [result]
Hypothesis: [what you think is wrong]
Next approach: [one specific different angle]
```

Open a new session → read spec + debug file → fresh context → different approach.

**Terminal state**: After 2 failed attempts, the only valid action is a new session.

*Derives from: After 2 failures, "try a slight variation" is the most probable continuation — and probability compounds errors. A new session breaks the loop.*

---

### Session handoff — when context hits 40–60%

At 40–60% context usage, performance degrades — the spec written at message 5 has low attention weight by message 50. Don't wait until the session is broken.

Write `specs/[slug]-brief.md`:

```
Feature: [name] — spec at specs/[slug].md
Done: [comma-separated completed tasks]
Current state: [what works / what's broken]
Next action: [one specific next step]
Key files: [paths that matter for continuation]
Open questions: [unresolved decisions]
```

Start new session → read constitution + brief → continue.

*Derives from: Attention mechanism weights recency. At 40-60% context, early tokens have degraded recall. Writing the brief moves critical context to the start of the next session.*

---

### Rationalizations — reject these

| If you think this | The answer is |
|---|---|
| "This feature is too simple to need a spec" | Simple features have the most skipped edge cases. Spec takes 10 minutes. Debugging takes hours. |
| "I'll write the spec after prototyping" | You will rationalize away the error states you discovered while building. |
| "This is just a bug fix, not a feature" | Bug fixes use Bug Fix format: S1 + S6. Same principle, 10 minutes. |
| "The spec is in my head" | Unwritten specs have no S1. Every bug is an unwritten S1. |

---

### Team Mode (3+ developers, any scale)

The 5 failure modes apply at every team size — they get worse, not better, as teams grow. What scales is process, not methodology.

If this constitution is shared across a team, three additional rules apply:

**1. Constitution has an owner.** Changes go through PR review. Anyone proposes; only the designated owner merges. At 10+ devs: senior dev per domain area, quarterly audit of outdated constraints.

**2. Approval gate.** Specs have a Status field: `Draft → In Review → Approved → Implementing → Done`. The Build session only starts when Status = Approved. Do not implement a Draft spec.

**3. PR template.** Every PR references its spec file and has S6 QA scenarios checked off. See `advanced/team-workflow.md`.

*Solo config: ignore this section. Self-approve specs and proceed.*

---

### The 6 Spec Sections (S1–S6)

| # | Section | Question it answers |
|---|---------|-------------------|
| S1 | Error States & Validation | What breaks, and what does the user see? |
| S2 | Post-Completion Flow | Where does the user go after success? |
| S3 | Cross-Feature Integration | What other features does this touch? |
| S4 | UX Copy Review | Is every user-facing string plain language? |
| S5 | State & Persistence Matrix | Where does each piece of data live? |
| S6 | Manual QA Scenarios | Can a human verify this without reading code? |

Spec template → `spec.md`
Review checklist → `review.md`
