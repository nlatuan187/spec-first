---
title: "[NAME]"
status: draft          # draft | in-review | approved | implementing | shipped | reconciled
scope: feature         # trivial | bug | small | refactor | feature | large | discovery
owner: "[who writes this]"
approver: "[who may set status: approved — must not be the same person as owner on large/high-risk]"
created: YYYY-MM-DD
approved_at:           # set by the approver, never by the author
shipped_at:
reconciled_at:         # set after the post-merge reconciliation pass
---

# [NAME]

> **Source**: [where the facts in this spec came from — issue link, user interview, measurement, platform docs URL]

<!--
  LENGTH RULE: if this spec is longer than the diff it describes, it is too long for
  this change. Drop to a lighter scope. Scope picks the sections:

    trivial   → the Trivial block below. Nothing else. No verification checks.
    discovery → Why + Open questions + Options. NO solution sections. Stop there.
    bug       → Why + Failure modes + QA + File changes
    small     → Why + Acceptance + Failure modes + QA + File changes
    refactor  → Why + Invariants + Integration + QA + File changes
    feature   → all mandatory sections
    large     → all, plus Mental model and Pre-reading

  MANDATORY for every scope except discovery:
    Why · Verification · Failure modes · Invariants · File changes · QA · Known issues
  MANDATORY for feature and large:
    Guards
  MANDATORY for discovery:
    Options
  OPTIONAL, include only when they carry information:
    Mental model · Pre-reading · Thresholds · Code flow · Data contract · Copy · State

  SURFACE RULE: a capability is scoped to the flow it was asked for. Do not add a second
  entry point — a toolbar button, a menu item, an empty state — because the backend now
  exists. "The API is already there" justifies a cheap implementation, never an extra
  surface. Anything worth adding beyond the ask goes under Known issues as "not doing",
  never folded into File changes.

  EDIT RULE: when review finds a defect, rewrite the affected text in place and delete
  what it replaced. Do not append a correction below the wrong sentence. A spec that
  narrates its own review history makes the reader work out which half is current, and
  the build session will read the wrong half.
-->

---

## Trivial scope — the whole spec

<!-- For wording, a label, a copy string, a constant. Reversible, no new behaviour, no new
     data, one file. Delete this block for any other scope; delete the rest for this one. -->

```markdown
---
status: draft
scope: trivial
owner: "[you]"
approver: "[who says yes]"
created: YYYY-MM-DD
---
# [what changes, in six words]

Now: "[the current text or value]"
To:  "[the new text or value]"
Why: [the reason, and where it came from]
Touches: [the one file]
```

Nothing else is required at this scope, and nothing above is optional. A person still sets
`status: approved`. If it turns out to touch behaviour, data or a second file, it was never
trivial — move up a level and fill in the rest of this template.

---

## Why

**Pain** — the state the user is already in, independent of this product.

<!--
  A pain is valid only if it contains EITHER a frequency/quantity OR a blocking fact.
  It must not contain this product's own feature nouns.

  ✅ "Without a connected account, publishing is blocked."     (blocking fact)
  ✅ "Brokers receive inventory as spreadsheets and PDFs and copy it in by hand."
  ❌ "Brokers need a content plan view, not just a list of drafts."   ← that is a backlog item
-->

**Need** — in the user's own words. One sentence, first person, quoted verbatim.

<!--
  If you cannot quote anyone, write: "No user said this. Assumed by [name] on [date]."
  That is a legitimate answer and it is far better than inventing a quote.
-->

**Proposed** — `We will [X], not [Y], because [Z].`

<!--
  The "not [Y]" half is mandatory. It records the design you rejected, which is the part
  that otherwise lives in one person's head and gets re-proposed every six months.

  ✅ "We will treat the campaign row as a plan plus provenance, not a workflow engine,
      because the plan is the artifact and execution only writes downstream."
-->

**Non-goals** — what this change deliberately does NOT do.

<!-- Each line is a refusal someone might otherwise reasonably attempt. -->

---

## Guards

<!--
  The constraints that must survive a context window. Every decision the approver made,
  every "do not merge until", every hazard that is not visible from the code being
  edited. Mandatory on feature and large scope.

  This section exists because of how the build fails: not by forgetting the spec, but by
  keeping the part it was last reading and dropping the ruling made four hours earlier.
  A long session, a compaction, a fresh subagent — each one is a chance to lose it.

  Paste this section, and only this section, into every subagent prompt. Re-read it
  after any compaction. Keep it short enough that doing so costs nothing.

  ✅ "Approver ruled on 03-14: no second entry point for quick-create. Only the upload modal."
  ✅ "Do not merge before the migration runs on staging — the backfill is not idempotent."
  ✅ "`supplier_id` must not appear in any response body, including error payloads."
-->

- [constraint, and who set it, and when]

---

## Verification

<!--
  Paste the recorded output of the eight checks in verify.md. One line per check.
  "No hits" is a result — write it down.
  A spec with this section empty is a draft, whatever else it contains.
-->

Run [YYYY-MM-DD] against `[branch]` @ `[sha]`.

1. Naming —
2. Paths —
3. Dependencies —
4. Env —
5. Secrets in URLs —
6. Atomicity —
7. Prior art —
8. Reachability —

---

## Acceptance

<!--
  EARS notation. WHEN = event · IF = condition · WHILE = continuous state · SHALL = mandatory.
  Every criterion must be checkable by someone who has not read the code.
-->

- WHEN [trigger] THEN the system SHALL [observable behaviour]
- IF [condition] THEN the system SHALL [observable behaviour]
- WHILE [state] THE system SHALL [continuous behaviour]

---

## Failure modes

<!--
  Write these BEFORE the happy path. Training data is roughly 10:1 success-to-failure,
  so the failure rows are the ones that do not appear unless you demand them.

  The last column is the one people skip. "Silently does nothing" is a legitimate entry
  and must be written down as a decision, not left as an accident.

  Fill the deployment constraints first — they are facts about your platform, not opinions:
    Timeout:      [serverless limit? mobile background limit? queue visibility timeout?]
    Data limits:  [silent row truncation? batch size? payload cap? connection pool?]
    Auth:         [where do credentials live, and where must they never appear?]
    Concurrency:  [idempotency key? atomic lock? dead-letter queue? circuit breaker?]
-->

| Condition | System does | User sees | Recovery |
|---|---|---|---|
| Not authenticated | | | |
| Permission denied | | | |
| Upstream unavailable / timeout | | | |
| Input invalid — [name the specific input] | | | |
| Required data missing / null | | | |
| Duplicate or concurrent submit | | | |
| [a case where the correct behaviour is to do nothing] | silently does nothing | nothing — by design | |

---

## Invariants

<!--
  Things that must stay true after this change, addressed to a PERSON, not to a file.
  This is the register that does not rot: a sentence a refactor cannot falsify.

  Shape: **[bold claim].** [one-line mechanism]. Do not [the specific tempting wrong move].

  ✅ "**Execution mutates the plan in place.** Per-item status is part of the plan
      document. Do not add a parallel execution-log table — the audit trail is the plan
      plus the records it produced."

  Security belongs here. State the deny-list by name:
  ✅ "**`supplier_id` is never exposed.** It is excluded from every select path. Any new
      query that reaches this table must carry the same exclusion, with a code comment
      saying so."
-->

- **[claim].** [mechanism]. Do not [tempting wrong move].

---

## Integration

<!--
  Enumerate from the codebase, not from memory. `ls` finds files; `grep` finds relationships.
  Run both. A spec that touches existing code and lists no integration points is almost
  always wrong.

  BLAST-RADIUS RULE. When the change touches a function more than one caller uses, or adds
  a value that travels between layers, list the whole chain, not the two ends. Name every
  caller of the changed function, in both directions — what now reaches it that did not
  before, and what it now returns that a caller did not expect. For a new field, name every
  hop that must carry it: sender, each intermediate reader, handler, store, render. An
  intermediate reader that quietly drops the field produces no error and no null — just a
  wrong result, which is indistinguishable from the feature never having been built.
-->

| Touches | Reads or writes | What breaks if this is wrong |
|---|---|---|
| | | |

---

## Thresholds

<!--
  Every number that a reader could not derive from the repository. Optional section —
  but if a number appears anywhere above and is not listed here, the spec is incomplete.

  "Reason" may be "arbitrary, chosen [date]". That is honest, and it tells the next
  reader the number is free to change. A constant in code loses this entirely.
-->

| Rule | Value | Reason | Source |
|---|---|---|---|
| | | | |

---

## QA

<!--
  Checkable by a human who has not read the code. Each line names a specific input and a
  specific expected output — "works correctly" is not a scenario.
-->

- [ ] Happy path: [exact steps] → [exact expected result]
- [ ] Failure: [exact trigger] → [exact message], user can [recover how]
- [ ] Empty state: no data → [what is on screen], next action is [what]
- [ ] Boundary: [the specific bad input] → [the specific response]
- [ ] Repeat submit: twice rapidly → [prevented how]
- [ ] Small screen: [narrowest supported width] → no overflow, all actions reachable
- [ ] Interrupted: restart mid-flow → [preserved / returned to start — state which]

---

## File changes

```
ADDED:
MODIFIED:    [path] — [which function or section changes]
REMOVED:     [path] — [why]
```

---

## Known issues

<!--
  MANDATORY. At least one entry. "None" is not an entry.

  List what is wrong with what you just described — observation plus mechanism. Do NOT
  propose the fix here; that is what keeps this section cheap enough to actually write.

  This is the only part of the document that cannot be reconstructed from the code, and
  in practice it is the part that is still accurate a year later.

  ✅ "Price sorting is not truly correct yet, because sorting a parent row by an embedded
      child's price is not expressible in our query layer. Flagged as an RPC candidate."
  ✅ "Export works on the loaded page slice, not the full filtered set."
  ✅ "`lib/modules/campaign/*` is canonical; the older `lib/services/ai/campaign*` paths
      still exist and should be deleted as call sites move over."
-->

-

---

## Open questions

<!-- Only for scope: discovery, or when an answer is genuinely blocking. Name who must answer. -->

| Question | Who answers | Blocking? |
|---|---|---|
| | | |

---

## Options
<!--
  Mandatory on discovery scope, where it is most of the spec. Omit elsewhere.

  At least three, and one of them is "do less" — ship a smaller thing, or change nothing
  and live with the pain. A list of three ways to build it is not a comparison; it is a
  decision already made, written in a format that looks like one that has not been.

  Decompose before you name a tool. Most "A vs B" framings compare transports — a queue
  against a call, one store against another — for a problem with two or three independent
  concerns that each want a different answer. Split the concerns first, choose per concern.

  Mark every claim FACT or ASSUMPTION. A fact carries a file:line, a command's output, or
  a documentation URL. An assumption — the load, the tolerance, the growth — is stated so
  the reader can challenge the one that the recommendation rests on.

  The rejection line is the deliverable. One sentence per rejected option, written now,
  while the reason is known. These lines are what the decision record keeps; nobody can
  reconstruct them in six months, and without them the same option is re-proposed.
-->

| Option | Cost | What it gives up | FACT / ASSUMPTION |
|---|---|---|---|
| Do less: | | | |
| | | | |
| | | | |

**Chosen**: [option] — [why, against this codebase and these users, not against best practice]
**Rejected**: [option] — [one sentence]. [option] — [one sentence].

---

## Optional sections

### Mental model
<!--
  Include ONLY when the feature's state is split across more than two stores. One bold
  sentence, then a partition of the state with an owner for each part.

  Forcing this onto simple features produces restatement. Used once, where it was needed,
  it is the section every later reader actually wanted.
-->

### Pre-reading
<!-- For large scope. What the implementer must read before writing code, and why. -->

| File | Lines | Why |
|---|---:|---|
| | | |

### Code flow
<!--
  4–8 numbered steps. Each step names exactly ONE symbol or path, and describes its
  EFFECT rather than its implementation. The effect is what stays true across refactors.

  ✅ "3. The route calls `withApiProtection(req, "TEXT_ONLY")` for auth and credit control."

  At 8 steps, split into sub-flows rather than growing the list.
-->

### Data contract
<!--
  `METHOD /route` → Query/Body → Response shape → Client store → Database.
  Write the response as literal code, including optional markers:
      success({ items, total, page, has_more, counts? })

  Never exposed: [list the field names that must not leave the server]
-->

### Copy
<!-- Every user-facing string, in the user's own vocabulary, not the system's. -->

| System term | What the user calls it |
|---|---|
| | |

### State
| Data | Lives where | Survives restart? | Cleared when |
|---|---|:---:|---|
| | | | |

---

## Before handing this over

1. **Placeholders** — any `TBD`, `[...]`, or "show an error"? Fix inline.
2. **Consistency** — do the failure modes and the QA scenarios cover the same cases?
   Does State match what the acceptance criteria promise?
3. **One change** — is this one thing, or several? If several, split before implementing.
4. **Ambiguity** — can any line be read two ways? Pick one and say it.
5. **Length** — is this spec longer than the diff it describes? Drop a scope level.
6. **Verification** — is the `## Verification` section filled with real recorded output?

---

## After it ships — reconciliation

**This is a gate, not a suggestion.** A spec is written before the code exists, which
means its concrete references are predictions. Predictions are the first thing to go
stale: in a measured corpus of sixteen feature documents, the twelve written *after* their code kept 70 of 70 path references and 46 of 49 route references accurate across five months, while the one written *ahead* of the code held two of the three dead references in the entire set.

Within one working day of merge:

1. Re-read the spec against the merged diff.
2. Correct every path, route, symbol and field name that changed during the build.
3. Append what you learned to `## Known issues`.
4. Fold the durable parts — invariants, thresholds, the data contract, known issues —
   into the living system document for that area (see `system.md`).
5. Set `reconciled_at` and move the file to `specs/done/`.

A spec that reaches `shipped` and never reaches `reconciled` is the failure mode this
step exists to prevent. The spec is not the deliverable. The living document is.
