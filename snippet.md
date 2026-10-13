## Spec-First — AI Development Methodology

> Paste into your AI context file — CLAUDE.md, AGENTS.md, .cursorrules, .windsurfrules,
> or .github/copilot-instructions.md. Works with any tool that reads a context file.

---

### The bet

A capable model does not need to be told to be careful. It needs to be told **what is
true about this repository** — the facts it cannot derive by reasoning: which column
name this table actually uses, which number was measured and which was guessed, which
design was already tried and rejected, what must never leave the server.

Everything below exists to capture one of those facts, or to stop work until one is
captured. Nothing below is here to make the model try harder.

---

### Three artifacts

| File | Direction | Lifespan |
|---|---|---|
| `specs/<slug>.md` | written **before** the code | until the change ships and is reconciled |
| `docs/system/<area>.md` | written **after** the code | permanent — corrected, never discarded |
| `KNOWLEDGE.md` | written when you discover something | permanent |

A spec is a prediction. A system document is an observation. Predictions go stale and
observations do not, so every spec must end by feeding the system document. A `specs/done/`
folder that nobody folds back into a living document is an archive of stale predictions.

---

### Scope — pick the lightest thing that fits

| Scope | Trigger | Write |
|---|---|---|
| **Discovery** | the solution is not known yet | Why + Open questions + Options. **Stop.** Do not write a solution spec for a guess. |
| **Emergency** | production is down | fix first, then a retroactive bug spec the same day |
| **Bug** | something is broken | Why + Failure modes + QA + File changes |
| **Small** | under a day, behaviour change | add Acceptance |
| **Refactor** | structure moves, behaviour must not | Why + Invariants + Integration + QA + File changes |
| **Feature** | new capability | all mandatory sections |
| **Large / high-risk** | auth, payments, money, PII, schema, infra | all, plus Mental model and Pre-reading, plus a human reader |

**The length rule overrides the table**: if the spec is longer than the diff it describes,
drop a scope level. Spec artifacts that outrun the change are how spec-driven development
earns its reputation for ceremony.

---

### The loop

**1. Clarify.** Read the context file. If the trigger, the observable success condition,
or the number of distinct changes is unclear, ask. Then wait. Do not write a spec over an
unanswered question.

**2. Verify.** Run the seven checks in `verify.md` and record the output. These replace
assumptions about the codebase with observed facts. A spec whose `## Verification`
section is empty is a draft, whatever else it contains.

*This rule was bought with 11 review gaps in two specs written from memory on a single day:
invented paths, the wrong column convention, a missing dependency, a token in a URL.*

**3. Spec.** Create `specs/<slug>.md` from `spec.md`. Fill every mandatory section with
real content. Placeholders are not content.

**4. Approve.** The approver sets `status: approved` and `approved_at`. On large or
high-risk scope the approver is not the author. Until then, status stays `draft`.

**5. Build.** A fresh session, reading the context file + the approved spec + `KNOWLEDGE.md`.
Handle every row of Failure modes explicitly in code. If the project has tests, write them
from QA first.

**6. Review.** A different session than the one that wrote the code. A session that wrote
code cannot review it — not because it lacks the ability, but because "this is correct" is
the continuation its own context is pulling toward.

**7. Reconcile.** Within a working day of merge: re-read the spec against the merged diff,
correct every path and symbol that changed during the build, append what you learned to
`## Known issues`, fold the durable parts into `docs/system/<area>.md`, set `reconciled_at`.

*Measured, on a corpus of sixteen hand-written feature documents: the twelve written after
their code kept 70 of 70 path references and 46 of 49 route references accurate over five
months. The one written ahead of the code held two of the three dead references in the set.
Forward-written documentation is not wrong — it is perishable. Step 7 is the refrigeration.*

---

### Hard rules

**1. No source edit without an approved spec that names the file.**
Not "a spec exists somewhere". The spec's `## File changes` must name this path or a
directory above it, and its status must be `approved` or `implementing`. The `pre-tool-use`
hook enforces this; without the hook, this paragraph is the enforcement.
Emergency: `touch .spec-first-bypass`, fix, then write the retroactive spec.

**2. Failure rows before the happy path.**
Open `## Failure modes` by answering: what breaks, who is unauthorised, what is missing or
null? Fill the deployment constraints — timeout, silent truncation limits, where secrets
may and may not appear, what makes an operation atomic — before writing any row. Those are
properties of your platform and will not be inferred.

**3. Every proposal names what it rejects.**
`We will [X], not [Y], because [Z].` The "not [Y]" half is the part that otherwise lives in
one person's head and gets re-proposed every six months.

**4. Every invariant is addressed to a person.**
`**[claim].** [mechanism]. Do not [the specific tempting wrong move].` A sentence that makes
no claim about the filesystem cannot be falsified by a rename — that is why this register
outlives every other.

**5. Every number carries its reason.**
`## Thresholds` takes `Rule | Value | Reason | Source`. "Arbitrary, chosen [date]" is a
valid reason and a useful one: it tells the next reader the number is free to change. A
bare constant in code loses this permanently.

**6. Known issues is mandatory and "none" is not an entry.**
Observation plus mechanism, no proposed fix — keeping the fix out is what keeps the section
cheap enough to actually write. This is the only part of the document that cannot be
reconstructed from the code, and in practice it is the part still accurate a year later.

**7. Enumerate integrations from the codebase.**
`ls` finds files, `grep` finds relationships, and a single spelling finds neither. Search
hyphenated, camelCase, snake_case and UPPER_SNAKE together. A change to existing code with
no integration rows is almost always an incomplete spec.

**8. After two failed fixes, stop.**
Before the first attempt, state the root cause: *"the error is caused by [X] because [Y]."*
If you cannot, investigate instead of trying something. After two failures, write
`specs/<slug>-debug.md` with each attempt and its result, and open a new session. A third
variation compounds the error that produced the first two.

**9. Record what you discover.**
Append to `KNOWLEDGE.md` when you learn something non-obvious that will outlive this task —
an ordering constraint, a silent failure, a platform limit, a convention. Only patterns that
recur: once is noise, twice belongs in `KNOWLEDGE.md`, three times belongs in the context file
as a rule. Read it at the start of every build session.

---

### Spec sections

Mandatory for every scope except discovery:
`Why` (Pain · Need · Proposed · Non-goals) · `Verification` · `Failure modes` ·
`Invariants` · `File changes` · `QA` · `Known issues`

Include only when they carry information:
`Mental model` · `Pre-reading` · `Thresholds` · `Code flow` · `Data contract` · `Copy` · `State`

Earlier versions numbered six of these S1–S6. The numbers are kept as aliases so older
specs, skills and checklists still resolve:

| Old | Now |
|---|---|
| S1 Error States & Validation | `Failure modes` |
| S2 Post-Completion Flow | folded into `Acceptance` + `State` |
| S3 Cross-Feature Integration | `Integration` |
| S4 UX Copy Review | `Copy` |
| S5 State & Persistence Matrix | `State` |
| S6 Manual QA Scenarios | `QA` |

Two notes on the mandatory half, both learned the hard way:

- **Pain must be a state the user is already in**, independent of your product. It needs a
  frequency, a quantity, or a blocking fact, and it must not contain your product's own
  feature nouns. *"Brokers need a plan view, not a list of drafts"* is a backlog item wearing
  a pain's clothing. *"Without a connected account, publishing is blocked"* is a pain.
- **Need is the user's own sentence, quoted.** If nobody said it, write
  *"No user said this. Assumed by [name] on [date]."* That is a legitimate answer. An
  invented quote is not.

---

### Reject these

| If you think | The answer |
|---|---|
| "Too simple to need a spec" | Simple changes have the most skipped edge cases. Bug scope is four sections. |
| "I'll write it after prototyping" | You will rationalise away the failure modes you found while building. |
| "The spec is in my head" | An unwritten spec has no failure modes. Every bug is a failure mode nobody wrote. |
| "It's just a refactor" | Refactors without Integration break hidden callers. The grep is two minutes. |
| "I don't know what I'm building yet" | Then it is Discovery. Write the questions, not a guessed solution. |
| "Requirements changed, the spec is wrong now" | Update the spec, then build. An outdated spec is an unwritten spec. |
| "It shipped, we're done" | Not until step 7. An unreconciled spec is the next person's wrong map. |

---

### Teams

1. **The context file has an owner.** Changes go through review; anyone proposes, the owner merges.
2. **The approver is not the author** on large and high-risk scope. `approved_at` is set by
   the approver. An agent must never set it.
3. **Every PR names its spec** and has its QA boxes ticked.

*Solo: you are both roles. Still write `approved_at` as a separate act — it is the moment you
stop designing and start building, and conflating the two is how the design gets edited to
match the code.*

---

### Keeping this file short

Rules late in a long context file get less attention than rules early in it. Keep your
context file under about 200 lines: move stack details to their own files and reference
them in one line, delete anything a linter or CI already enforces, and keep only
constraints the model would otherwise violate. Delete the sections above that do not
apply to you — ten relevant rules beat fifty diluted ones.

Spec template → `spec.md` · Pre-spec checks → `verify.md` ·
Living docs → `system.md` · Review checklist → `review.md`
