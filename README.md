# spec-first

Write a plan before the code. Ship the plan into a living document after.
Works with any AI tool that reads a context file. No new infrastructure required.

---

## Three artifacts

| File | When | Purpose |
|---|---|---|
| `specs/<slug>.md` | before the code | a prediction — failure modes, invariants, what "done" means |
| `docs/system/<area>.md` | after the code | an observation — what is actually there, permanently corrected |
| `KNOWLEDGE.md` | when you discover something | cross-session memory, patterns that recur |

A spec is a prediction. A system document is an observation. Predictions go stale;
observations do not. The loop exists to turn predictions into observations before they
become a wrong map somebody follows.

---

## The loop

**1. Clarify.** Read the context file. If the trigger, the success condition, or the
scope is unclear, ask once. Do not write a spec over an unanswered question.

**2. Verify.** Run the seven checks in `verify.md` against the codebase. Paste the
output into the spec's `## Verification` section. A spec with an empty Verification
section is a draft, whatever else it contains.

**3. Spec.** Create `specs/<slug>.md` from `spec.md`. Fill every mandatory section
with real content. Placeholders are not content.

**4. Approve.**

> A human sets `status: approved` and `approved_at`.
> An agent must never do this.
> The hook refuses all source edits until this happens.

On large or high-risk scope the approver is not the author. Solo: you are both
roles — still set `approved_at` as a separate act. It is the moment you stop
designing and start building.

**5. Build.** A fresh session, reading the context file + the approved spec +
`KNOWLEDGE.md`. Handle every row of Failure modes explicitly in code.

**6. Review.** A different session than the one that wrote the code. A session that
built the code cannot review it — "this is correct" is the continuation its own
context pulls toward.

**7. Reconcile.** Within a working day of merge: re-read the spec against the merged
diff, correct every path and symbol that changed, fold the durable parts into
`docs/system/<area>.md`, set `reconciled_at`.

---

## Starting on existing code

Do not begin with a spec. Begin with `docs/system/<area>.md`, written from the code
in front of you. That document is what every later spec reads. Then spec the change
against it.

This repo was originally written for greenfield only. That was a recorded weakness.
The brownfield path above is the fix.

---

## The gate

The `pre-tool-use` hook (Claude Code only) blocks Write and Edit on source files
until three conditions hold simultaneously:

1. A spec exists in `specs/`
2. Its `status` is `approved` or `implementing`
3. Its `## File changes` section names the file being edited (or a directory above it)

The old version allowed any edit as soon as any `.md` existed in `specs/`. One file
unlocked the repository permanently. Condition 2 is the part no comparable tool
enforces mechanically — a draft spec and an in-review spec both leave the gate closed.

Emergency: `touch .spec-first-bypass`, fix, then write the retroactive spec the same day.

---

## Evidence

**Why Verify comes before Spec.** On 2026-04-07 two specs were written from memory
without reading the code. They invented file paths, used the wrong column convention
(`user_id` where the table used `created_by`), missed a dependency, and missed a token
in a URL query string. Review found 11 gaps across the two specs. Every gap was a fact
that a single command would have surfaced. The seven checks in `verify.md` exist for
this reason.

**Why Reconcile is a gate, not a suggestion.** In a corpus of sixteen hand-written
feature documents: the twelve written *after* their code kept 70 of 70 path references
and 46 of 49 route references accurate over five months. The one written *ahead* of the
code held 2 of the 3 dead references in the entire set; its companion index promised 16
documents while shipping 1. Forward-written documentation is not wrong — it is
perishable. Reconciliation is the refrigeration.

**Why the fix rate matters.** On 626 production commits, `fix:` labels were 47% of all
commits (293 of 626). The fix:feat ratio was 2.93:1: roughly three in four commits that
were either a feature or a fix were fixes. spec-first does not claim to have resolved
this — these are the numbers that motivated it.

---

## Scope

Pick the lightest scope that fits. A spec longer than the diff it describes is already
too heavy — drop a level.

| Scope | Write |
|---|---|
| Trivial | Wording, a label, a copy string, a constant. Four lines of front matter, four of body. |
| Discovery | Why + Open questions + Options. Stop. Do not spec a guess. |
| Emergency | fix first, retroactive bug spec the same day |
| Bug | Why + Failure modes + QA + File changes |
| Small | add Acceptance |
| Refactor | Why + Invariants + Integration + QA + File changes |
| Feature | all mandatory sections |
| Large / high-risk | all, plus Mental model and Pre-reading, plus a human reader |

Mandatory sections (every scope except discovery):
`Why` · `Verification` · `Failure modes` · `Invariants` · `File changes` · `QA` · `Known issues`

The old S1–S6 names still resolve: S1 → Failure modes · S3 → Integration · S4 → Copy · S5 → State · S6 → QA.

---

## Files

| File | What it is |
|---|---|
| [`snippet.md`](snippet.md) | The product. Paste into any AI context file. |
| [`spec.md`](spec.md) | Spec template — all scopes and sections. |
| [`verify.md`](verify.md) | Seven pre-spec checks. Run before writing a spec. |
| [`system.md`](system.md) | System-document template. Where shipped specs land. |
| [`review.md`](review.md) | Two-pass code review checklist. |
| [`install.sh`](install.sh) | Auto-detect + append installer. |
| [`hooks/`](hooks/) | Enforcement hook (blocks code without approved spec). Claude Code only. |
| [`advanced/README.md`](advanced/README.md) | Index of everything optional — the five slash commands, team workflow, calibration, examples, integrations. |
| [`scripts/check.sh`](scripts/check.sh) | What keeps this repo honest: dead links, orphans, duplicated templates, inconsistent numbers. Runs in CI. |

---

## Install

**macOS / Linux / Git Bash:**
```bash
curl -fsSL https://raw.githubusercontent.com/nlatuan187/spec-first/master/install.sh | sh
```

**Windows (PowerShell):**
```powershell
iwr -useb https://raw.githubusercontent.com/nlatuan187/spec-first/master/install.ps1 | iex
```

Auto-detects your AI tool and appends `snippet.md` to the right context file.

| AI tool | Context file |
|---|---|
| Claude Code | `CLAUDE.md` |
| Cursor | `.cursorrules` |
| Windsurf | `.windsurfrules` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Codex / any other | `AGENTS.md` |

Or manually: copy [`snippet.md`](snippet.md) into your AI's context file.

---

## What this is not

Other toolchains — [superpowers](https://github.com/obra/superpowers),
[GSD-2](https://github.com/gsd-build/gsd-2), [BMAD](https://github.com/bmad-method/BMAD-METHOD) —
cover autonomous execution, multi-agent orchestration, and task management far more
broadly than this repo does. If that is what you need, start there.

What spec-first has that those do not is a gate that actually blocks: the hook refuses
source edits until a human has signed off, not until an agent has written something.
And a reconciliation step that turns a shipped spec into a corrected, living document
rather than an archive of stale predictions.

Those two things are small. They work at any scale, with any stack, with any AI tool.
