# Standing reviewers — four heads

The reviewer in step 6 reads the spec and asks *did the code do what the spec said*.
Nobody in that loop asks *should the system look like this now*. A change can satisfy
its spec exactly and still move the codebase somewhere no one chose to go.

Four standing reviewers ask the second question. Each owns one domain across the whole
product, not one feature, and judges a change against a written standard rather than
against the feature's local intent.

| Head | Owns | Typical blocking finding |
|---|---|---|
| **Architect** | module placement, layering, dependency direction, job and queue design, authorization checks | a route that compares role strings instead of calling the authorizer |
| **Data** | API shape and validation, schema and migrations, domain state models, query keys and invalidation, audit records, logs, PII | a field renamed in one writer and three readers left reading the old name |
| **Design** | visual rendering, reuse of the UI kit, spacing and type scale | a bespoke component where a kit primitive exists |
| **UX** | loading, empty, error and success states, copy, the shape of the flow | an empty-state call to action that renders while the data is still loading |

Split them this way or another way. What matters is that each domain has exactly one
owner, the boundaries are written down, and an observation outside your domain is handed
off rather than scored.

---

## The standard is a file, not a memory

Each head reads `docs/standards/<head>.md` before every run. That file holds the rules,
numbered, each one tagged with the severity it carries by default. A head with no
standard file is a second opinion, which is worth something but is not a gate: it
disagrees differently every time it runs.

Rules that are BLOCKING only for new code carry `(new)`. That is what lets a standard
land on a codebase that does not yet meet it.

---

## Triage first — most changes need no head at all

Running four reviewers on every change is how a gate gets switched off. Before any head
runs, decide per head from the changed-file list plus the risk signals in the diff:

| Verdict | Meaning | What runs |
|---|---|---|
| **SKIP** | nothing in that domain changed | nothing, and it counts as a pass |
| **LIGHT** | small, no risk signal | one combined cheap pass covering every LIGHT head, checking only the rules tagged BLOCKING by default |
| **FULL** | a risk signal is present — migration, auth, a shared parse function, a cross-cutting rename | that head's full review |

The cheap pass escalates to the full head whenever it is less than certain. It never
second-guesses a SKIP and never duplicates a FULL.

Write the triage as a script, not as a judgement call. A judgement call made by the
author of the change is not a triage.

---

## Four classes of finding, one of which blocks

- **BLOCKING** — introduced by this change, or pre-existing in the exact handler, field
  or journey step the diff modifies. Blocks the merge.
- **NIT** — introduced but minor. Does not block.
- **DEBT** — pre-existing, outside what the diff modifies. Goes to the ledger.
- **GAP** — the platform is missing something the standard assumes. Goes to the ledger.

Only BLOCKING blocks. Without the DEBT and GAP classes a standing reviewer turns every
run into a list of everything wrong with the repository, and the list gets ignored as a
whole — including the one line that mattered.

The ledger (`docs/standards/ledger/<head>.md`) is what makes the standard ratchet. Count
the violations on the touched files before and after. A counter that rises is blocking;
a counter that falls is the only evidence that any of this is working.

---

## Three rules that keep it from becoming theatre

**Round cap of two.** If the same head raises the same finding twice, stop re-running it
and put the disagreement in front of a person. A third round is the review arguing with
itself.

**Only the approver may overrule a BLOCKING finding** — the person named `approver` in
the spec's front matter, in writing, with a reason, in the thread. Never the author of
the change. Log the overrule. An overrule that nobody records is indistinguishable from a
review that never ran, and the record is what tells you months later that a rule is
mis-tuned rather than that the team is careless.

**A head reviews a spec, then a diff.** Doc mode before approval, on the spec text:
catches the design before it is built, which is the only time it is cheap. Gate mode at
ready-to-merge, on the diff: once per change, never per push. Give it the spec and the
rulings already made, because a head that re-raises a question the approver has already
settled trains everyone to skim.

---

## What a head cannot do

It cannot read your issue tracker, your chat, or the comment thread. Everything it needs
goes into its prompt: the changed-file list, the diff text, the spec, and a digest of
open findings and settled rulings — the digest, not the whole thread.

It does not edit. A reviewer that can edit will fix what it finds, and what it finds then
stops being reported.

It does not score outside its domain. Out-of-domain observations go under "Hand-offs".

---

## Solo

You are all four. Run them as four separate reads with one standard file open each, one
at a time, and write the verdict down before opening the next. One read that intends to
be thorough is not four reviews; it is one review with a longer prompt, and it will find
what you were already worried about.

Measured, on the repository this layer came from: of the four heads, Data was the one
that caught a cross-file data-path break the other three missed. If you only ever run
one, run that one.
