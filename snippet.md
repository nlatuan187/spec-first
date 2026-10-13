## Spec-First — AI Development Methodology

> Paste into your AI context file — CLAUDE.md, AGENTS.md, .cursorrules, .windsurfrules,
> or .github/copilot-instructions.md. Works with any tool that reads a context file.

---

### The bet

A capable model does not need to be told to be careful. It needs to be told **what is
true about this repository** — the facts it cannot derive by reasoning: which column
name this table actually uses, which number was measured and which was guessed, which
design was already tried and rejected, what must never leave the server.

Everything below captures one of those facts, or stops work until one is captured.
Nothing here is to make the model try harder.

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

**Starting on code that already exists?** Begin with `docs/system/<area>.md` for the area
you are touching, written from the code in front of you — not with a spec. It is what the
next ten specs read.

---

### Scope — pick the lightest thing that fits

| Scope | Trigger | Write |
|---|---|---|
| **Trivial** | wording, a label, a copy string, a constant — reversible, no new behaviour, no new data | four lines (below). Nothing else. |
| **Discovery** | the solution is not known yet | Why + Open questions + Options. **Stop.** Do not write a solution spec for a guess. |
| **Emergency** | production is down | fix first, then a retroactive bug spec the same day |
| **Bug** | something is broken | Why + Failure modes + QA + File changes |
| **Small** | under a day, behaviour change | add Acceptance |
| **Refactor** | structure moves, behaviour must not | Why + Invariants + Integration + QA + File changes |
| **Feature** | new capability | all mandatory sections |
| **Large / high-risk** | auth, payments, money, PII, schema, infra | all, plus Mental model and Pre-reading, plus a human reader |

**The length rule**: if the spec is longer than the diff it describes, drop a scope level.
Spec artifacts that outrun the change are how spec-driven development earns its reputation
for ceremony. **Trivial is the floor** — a one-line diff has somewhere to land, and the rule
stops there rather than demanding a level that does not exist.

**A trivial spec is four lines of front matter plus four lines of body** — see the Trivial
block at the top of `spec.md`. It is still a spec: still named, still approved by a person,
still claiming its file. The seven pre-spec checks do not apply at this scope; they
establish facts about code structure, and a copy string changes none of them. If the change
turns out to touch behaviour, data, or a second file, it was never trivial — move up a level.

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
If you cannot, investigate rather than try something. After two failures write
`specs/<slug>-debug.md` — each attempt and its result — and open a new session.

**9. Record what you discover.**
Append to `KNOWLEDGE.md` when you learn something non-obvious that outlives this task — an
ordering constraint, a silent failure, a platform limit. Once is noise, twice belongs in
`KNOWLEDGE.md`, three times is a rule for the context file. Read it before every build.

---

### Spec sections

Mandatory for every scope except discovery:
`Why` (Pain · Need · Proposed · Non-goals) · `Verification` · `Failure modes` ·
`Invariants` · `File changes` · `QA` · `Known issues`

Include only when they carry information:
`Mental model` · `Pre-reading` · `Thresholds` · `Code flow` · `Data contract` · `Copy` · `State`

Earlier versions numbered six of these. The old names still resolve:
S1 → `Failure modes` · S2 → folded into `Acceptance` + `State` · S3 → `Integration` ·
S4 → `Copy` · S5 → `State` · S6 → `QA`.

Two notes on the mandatory half, both learned the hard way:

- **Pain is a state the user is already in**, independent of your product: a frequency, a
  quantity, or a blocking fact, and never your product's own feature nouns.
  *"Users need a plan view"* is a backlog item. *"Without a connected account, publishing is
  blocked"* is a pain.
- **Need is the user's own sentence, quoted.** If nobody said it, write *"No user said this.
  Assumed by [name] on [date]."* That is legitimate. An invented quote is not.

---

### Reject these

| If you think | The answer |
|---|---|
| "Too simple to need a spec" | Simple changes have the most skipped edge cases. Bug scope is four sections. |
| "The spec is in my head" | An unwritten spec has no failure modes. Every bug is a failure mode nobody wrote. |
| "I don't know what I'm building yet" | Then it is Discovery. Write the questions, not a guessed solution. |
| "It shipped, we're done" | Not until step 7. An unreconciled spec is the next person's wrong map. |

---

### Teams

1. **The context file has an owner.** Anyone proposes, the owner merges.
2. **The approver is not the author** on large and high-risk scope. An agent must never
   set `approved_at`.
3. **Every PR names its spec** and has its QA boxes ticked.

*Solo: you are both roles. Still set `approved_at` as a separate act — it is where you stop
designing and start building, and merging the two is how the design gets edited to fit the code.*

---

### Keeping this file short

Keep your context file under about 200 lines: move stack details to their own files and
reference them in one line, delete anything a linter or CI already enforces, and keep
only constraints that would otherwise be violated. Delete the sections above that do not
apply to you — ten relevant rules beat fifty diluted ones.

Spec template → `spec.md` · Pre-spec checks → `verify.md` ·
Living docs → `system.md` · Review checklist → `review.md`
