# System document — one per area of the product

> Template for `docs/system/<area>.md`. This is where shipped specs go to become useful.
> Copy it, fill it, and keep it. One file per area, not one per change.

---

## Why this file exists

A spec describes a change. It is written before the code and stops being true the moment
the change ships. A system document describes **what is there now**. It is written after
the code and is corrected whenever it stops matching.

The difference is measurable. In a corpus of sixteen hand-written feature documents,
the twelve written *after* their code kept **70 of 70** path references and **46 of 49**
route references accurate across five months. The one written *ahead* of the code held
two of the three dead references in the entire set, and its companion index promised
sixteen documents while shipping one.

So: write specs forward, write system docs backward, and make the second one the
destination of the first. Without that destination, `specs/done/` becomes an archive of
predictions nobody dares trust and nobody dares delete.

---

## The shape

Keep the mandatory half short and the optional half absent unless it earns its place.
A system document that restates the code is worse than no document, because it will
disagree with the code and the reader will not know which one is lying.

```markdown
# <Area name>

> **Source**: <the specs that fed this, by filename; interviews; measurements; vendor docs>
> **Owner**: <person> · **Last reconciled**: <YYYY-MM-DD> against `<sha>`

## What it is for
<Two or three sentences. Who uses this, to do what. No feature list.>

## Invariants
<The rules the code cannot state for itself. Addressed to a person.>
- **<claim>.** <mechanism>. Do not <specific tempting wrong move>.

## Thresholds
| Rule | Value | Reason | Source |
|---|---|---|---|

## Code flow
<4–8 numbered steps. One symbol per step. Describe the effect, not the implementation.>
1. `<symbol or path>` <verb> <effect>.

## Data contract
`METHOD /route` → Query/Body → Response → Client store → Database

Never exposed: <field names that must not leave the server>

## Failure modes
| Condition | System does | User sees | Recovery |
|---|---|---|---|

## Known issues
<At least one. "None" is not an entry. Observation plus mechanism, no proposed fix.>
-

## Changes folded in
| Date | Spec | What changed here |
|---|---|---|
```

---

## Three conventions that make it survive

**1. Name the directory once, the leaves relatively.**

```markdown
Module map under `lib/modules/campaign/`:
  - `model.ts` — re-exports the public types
  - `service.ts` — the only writer
  - `ai/stages/strategist.ts` — holds the ratio table
```

When the module moves, one line changes instead of ten. Measured: every reference written
this way survived five months of churn. A link checker that does not understand the
convention will report them all as broken — fix the checker, not the convention.

**2. Say the same security rule in two places.**

The document says it; the code comment says it. Deleting the document does not delete the
rule, and refactoring the query trips over the comment.

```
docs:  Never exposed: f1_source — excluded from every select path.
code:  // SECURITY: f1_source is NEVER selected or exposed in any query.
```

This is the one duplication worth keeping. It is also the one that actually held.

**3. Prefer sentences a refactor cannot falsify.**

`Without a connected account, publishing is blocked` and `Do not add a parallel
execution-log table` make no claim about the filesystem, so no rename can make them wrong.
Maximise the share of the document written in that register; everything else needs the
reconciliation pass.

---

## What not to put here

- **A file inventory.** The repository already has one, and it is always more accurate.
- **Code.** Pasted code gets used verbatim by whoever reads it next, bugs included.
- **A promissory index.** Do not link to documents that do not exist yet. Generate the
  index from what is on disk, or mark the missing rows `(not written)` in plain text.
  A thirty-five line index with fifteen dead links is worse than no index.
- **Prose that restates the heading.** If `## What user needs` would just be
  `## Pain` with the sign flipped, delete the section rather than padding it.
