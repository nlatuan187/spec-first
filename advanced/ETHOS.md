# Ethos

---

## Who This Is For

Solo developers and small teams shipping an existing product, several features a week.

For multi-agent orchestration, role-based handoffs, or formal ratification workflows, see the
alternatives table in [INTEGRATIONS.md](INTEGRATIONS.md).

---

## The Core Bet

AI generates implementation faster than any human. It has no judgment about what to build,
no adversarial thinking about what could break, and no product intuition about what users need.

Spec-first divides labor on that asymmetry:

- **You**: define intent, set constraints, verify outcomes, make judgment calls.
- **AI**: translate intent into implementation, across as many files as needed.

The spec is not documentation. The spec is where the engineering judgment lives.

---

## Five Principles

### 1. Specs Compound

A spec with missing failure modes produces output that fails on the cases nobody wrote down.
You fix it. The measured fix:feat ratio over 626 commits was **2.93:1** — roughly three in
four commits that were either a feature or a fix were fixes.

Fix ratio improves as spec quality improves. The improvement compounds: every week of writing
better specs lowers the ratio and raises the net output per day.

Track your fix:feat ratio. It is the single metric that tells you whether your specs are improving.

---

### 2. The Tax Is Real

The fix ratio is not a failure. It is the price of AI-generated output, and nobody in this field
reports it honestly. The 2.93:1 figure is from a period before the spec template matured.
The ratio fell as the mandatory sections — Failure modes, Invariants, Integration, QA — were
enforced on every spec. Each of those sections targets a category where AI output fails
systematically without being told to look.

---

### 3. Context Is the Constraint

AI output quality is bounded by the context it receives, not by its capabilities.

**The context file** carries project facts: stack, conventions, what is off-limits. Without it,
every session invents patterns that conflict with the codebase. This file travels under different
names — `CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.windsurfrules`,
`.github/copilot-instructions.md` — but the content is the constraint, not the name.

**The spec** carries task facts: what the user sees, what happens on error, how state persists.
Without it, the AI builds the happy path and ignores everything else.

**KNOWLEDGE.md** accumulates what you discovered in prior sessions: ordering constraints, silent
failures, platform limits, conventions. Read it at the start of every build session.

---

### 4. Session Boundaries Are Knowledge Boundaries

Use more sessions, not fewer. Accumulated context is accumulated bias. A session that implemented
a feature will rationalise that implementation when asked to review it.

One session per phase. The spec session writes and ends. The build session reads the spec cold
and implements. The review session reads the diff cold and reviews. No shared context between phases.

The handoff between sessions is a file, not a continuing conversation.

---

### 5. A Spec Is a Prediction

A spec is written before the code exists. It describes what should be there. The moment the code
ships, the spec is the past tense of a decision.

A system document (`docs/system/<area>.md`) is written from the code in front of you. It describes
what is there now. It is corrected as the code changes and never discarded.

**The spec is not the deliverable. The system document is.**

Measured on a corpus of sixteen feature documents: the twelve written after their code kept 70 of
70 path references and 46 of 49 route references accurate across five months. The one written
ahead of the code held two of the three dead references in the entire set.

Forward-written documentation is not wrong — it is perishable. Reconciliation (re-reading the spec
against the merged diff and folding what is durable into the system document) is step 7 of the
loop because it is the step that makes the previous six reusable. A `specs/done/` folder that
nobody folds back into a living document is an archive of stale predictions.

On an existing codebase, do not begin with a spec. Begin with `docs/system/<area>.md`, written
from the code in front of you. It is what every subsequent spec reads.

---

## What This Changes and What It Does Not

**Changes**: typing speed is irrelevant; breadth across the stack matters more than depth in one
framework; architecture must happen before implementation, not interleaved with it.

**Does not change**: security requires adversarial thinking, which AI does not do. Systems
architecture requires holistic thinking — AI builds components, humans build systems. Product
judgment is irreducible: the AI builds what you specify, correctly, including the wrong thing.
