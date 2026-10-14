# KNOWLEDGE.md — what goes in it, and how it stays usable

`KNOWLEDGE.md` is the third artifact. The spec is a prediction, the system document is an
observation of one area, and this is what you learned that belongs to no area.

The rule in the snippet is when to write: once is noise, twice belongs here, three times
is a rule for the context file. This file is the rest of it — what an entry looks like,
and what stops the file from becoming a diary nobody opens.

---

## Four kinds, and they are not interchangeable

| Kind | What it is | Where it ends up |
|---|---|---|
| **lesson** | something you did wrong and the mechanism that let you | stays in `KNOWLEDGE.md` |
| **bug** | a defect with a reproduction, still open or recently closed | `KNOWLEDGE.md` until fixed, then deleted |
| **decision** | a fork in the road, the branch taken, and the branch rejected | `docs/system/<area>.md` once the area exists |
| **reference** | an external fact with a source — a platform limit, an API quirk | stays, with the date you checked it |

Classify before writing. An entry filed as a lesson that is really a decision gets lost,
because nobody searching for "why do we do it this way" reads a file of mistakes.

---

## One fact per entry

```markdown
### Queue consumers must be idempotent          <!-- the claim, as a sentence -->
**Kind**: lesson · **Date**: 2026-03-14 · **Cost**: half a day

The queue delivers at least once. A consumer that assumed exactly once double-charged
four accounts before anyone noticed, because the retry looked like a new message.

Do not key side effects on message arrival. Key them on an id the producer sets.
```

The claim is the heading, so the file can be skimmed by headings alone. The cost line is
what makes the entry get read: an entry that cost half a day gets a different amount of
attention than one that cost ten minutes, and you cannot reconstruct that later.

If an entry cannot be written without naming three files, it is a system document
section, not a knowledge entry.

---

## It has to be read, which means it has to be short

Every build session reads this file. That is the whole mechanism, and it is also the
constraint: past a few hundred lines nobody reads it, and the entries that matter are
buried by the entries that were true for one afternoon.

Three things keep it short:

1. **Delete fixed bugs.** A bug entry is a warning to a future session. Once the defect
   is gone, the warning is a lie. Delete it; the git history keeps it.
2. **Promote repeats.** The third time a lesson applies, it stops being knowledge and
   becomes a rule in the context file. Move it and delete the entry.
3. **Fold decisions into the system document.** As soon as the area has one, the decision
   belongs under its invariants, where the next spec for that area will read it.

What is left is small on purpose.

---

## Where it lives

In the repository, committed, next to the code — not in an assistant's private memory and
not on one machine. Knowledge that lives in one person's tool dies when that person
switches tools, and it was never reviewable in the first place.

If your assistant also keeps a machine-local memory, decide once which store gets what,
write the rule down, and keep anything the team needs in the repository file.
