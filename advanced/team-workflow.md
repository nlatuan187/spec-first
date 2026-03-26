# spec-first — Team Workflow

The Fundamental Law applies at every scale. What changes is process, not methodology.

---

## Which config are you?

| Config | Size | What changes |
|---|---|---|
| **Solo** | 1–3 devs | Self-approve specs. One context file, one owner. |
| **Team** | 3–10 devs | Approval gate + PR template + constitution owner. |
| **Corp** | 10+ devs | Formal constitution governance + distributed approvers + automated S3 + BMAD for orchestration on top. |

---

## Solo config (1–3 devs)

No changes needed beyond installing snippet.md.

- You write the spec and approve it yourself.
- Brief the next session yourself when switching from spec to build.
- Cold review still applies — open a new session, don't review your own build output.

**When to upgrade to Team config**: When two developers start regularly stepping on each other's integrations (S3 conflicts), or when "who approved this spec?" becomes a question.

---

## Team config (3–10 devs)

Three additions to the base workflow: constitution ownership, approval gate, PR template.

---

### 1. Constitution ownership

The project constitution (CLAUDE.md / .cursorrules / etc.) is **owned by one person** — the tech lead or designated senior dev.

Rules:
- Changes to the constitution go through PR review, same as code
- Any team member can propose a change; only the owner merges it
- Version-controlled in git — `git log CLAUDE.md` shows the history
- New team member onboarding: read the constitution before writing any code or spec

What belongs in the team constitution (beyond the solo defaults):
```
## Team
- Constitution owner: [name]
- Spec approver(s): [names or role]
- PR template: specs/PR_TEMPLATE.md

## Conventions
[shared patterns, naming, file structure]

## Off-limits
[things AI must never do — specific to your team]
```

---

### 2. Approval gate

Specs move through states. The Build session only starts when status is **Approved**.

```
Draft → In Review → Approved → Implementing → Done
```

**Status field in spec header:**
```markdown
> **Status**: Draft | In Review | Approved | Implementing | Done
> **Spec author**: [name]
> **Approved by**: [name] — [date]
```

**Who approves**: The spec approver (tech lead or senior dev with codebase context) verifies:
- S1 has ≥5 rows with specific user-visible outcomes (not vague "show error")
- S3 enumerates real integrations (not placeholder "none")
- S6 has happy path + at least one error scenario + mobile

**Approval is not a sign-off ceremony** — it's a 10-minute S1/S3/S6 completeness check. If anything is vague or missing, return to Draft with a comment.

**The AI respects this gate**: With the constitution in place, the AI will not start a Build session on a spec that shows Status: Draft or In Review.

---

### 3. PR template

Every PR that implements a spec links to it. Reviewers use S6 as acceptance criteria.

Create `specs/PR_TEMPLATE.md`:

```markdown
## Spec
- Implements: specs/[slug].md
- Approved by: [name]

## S6 QA — did these pass?
- [ ] Happy path: [from S6]
- [ ] Error scenario: [from S6]
- [ ] Mobile (375px): tested
- [ ] Double-submit: [handled / N/A]

## S1 edge cases
- [ ] [Key error state from S1 — copy from spec]
- [ ] [Second key error state]

## Notes
[Any deviation from spec + reason]
```

Link this from your GitHub PR template:
```bash
mkdir -p .github
cp specs/PR_TEMPLATE.md .github/pull_request_template.md
```

---

### 4. Team handoff format

When Dev A writes the spec and Dev B implements it, the brief needs more context than solo handoff:

```
Feature: [name] — specs/[slug].md — Approved by: [name]
Implementer: [Dev B]
Done: [tasks completed so far, if continuing mid-build]
Current state: [what works / what's broken]
Next: [one specific next step]
Key files: [paths relevant to this feature]
Design decisions: [any decisions made during build that differ from spec + why]
Open questions for spec author: [questions Dev B has for Dev A]
```

---

### Team session flow

```
Dev A (spec author)
  Clarify Session  →  writes questions if ambiguous
  Spec Session     →  specs/[slug].md, Status: Draft
                                ↓
Spec Approver (tech lead)
  Reviews S1, S3, S6   →  Status: Approved (or back to Draft with notes)
                                ↓
Dev B (implementer)
  Build Session    →  reads spec cold, implements
  → PR with template filled
                                ↓
Dev C (reviewer) or Dev A
  Review Session   →  cold session, reads diff + review.md
  → S6 acceptance criteria verified
```

---

## FAQ for teams

**Can the spec author also implement?**
Yes, but the Build session must still start cold — new session, no context from the Spec session. The value of session separation holds regardless of whether it's the same person.

**Who opens the Review session?**
Anyone except the person who wrote the code in that Build session. Most teams use the PR reviewer.

**Constitution changed mid-sprint — do specs need updating?**
If the change is additive (new convention added), existing specs don't need retroactive updates. If the change deprecates something existing specs rely on, update those specs before their Build sessions.

**A spec was approved but requirements changed mid-build. What now?**
Return spec to Draft. Dev stops Build session. Spec author updates S1/S3/S6. Re-approve. New Build session starts cold. Cost of change is one spec update + one approval — not a full rework.

**Two devs are building features that touch the same store. How does S3 help?**
S3 on Feature A lists the store. S3 on Feature B lists the same store. The spec approver sees the conflict during review of Feature B's spec (before any code is written). Resolution happens in spec, not in code review.

---

## Corp config (10+ devs)

The methodology is identical to Team config. Coordination becomes more formal.

**Constitution governance:**
- Constitution changes require a formal review — PR with ≥2 approvals from senior devs
- Quarterly audit: review all constraints in the constitution, remove outdated ones
- New team onboarding: constitution is the first document they read, before any code

**Distributed approvers:**
- One approver per domain area (frontend, backend, infra) for their respective specs
- Cross-cutting specs (touching multiple domains) require ≥2 approvers
- Approver assignment goes in spec header: `Approver: [domain owner]`

**Automated S3 enumeration:**
- At 10+ people, manual `ls lib/services/` misses things. Add a script:
  ```bash
  # specs/list-features.sh — run before writing S3 on any spec
  echo "=== API routes ===" && ls app/api/
  echo "=== DB services ===" && ls lib/services/db/
  echo "=== Stores ===" && ls store/
  echo "=== Feature components ===" && ls components/features/
  ```
- Run this script before writing S3 on any spec. Never enumerate from memory.

**BMAD on top (optional):**
If your team needs multi-agent orchestration (PM writes stories, Architect reviews design, Dev implements, QA verifies), add [BMAD](https://github.com/bmad-method/BMAD-METHOD) for the orchestration layer. spec-first's specs become the input to BMAD's dev agent. The 5 failure modes still apply to every spec that BMAD's agents write — spec-first rules are embedded in the constitution that every agent reads.

---

## What changes in snippet.md for team/corp config

Nothing in snippet.md changes — the AI respects spec Status because you add team rules to the constitution. Add this block to your CLAUDE.md / .cursorrules:

```markdown
## Team spec rules
- Spec approver: [name or role — or "domain owner" for corp]
- Build sessions only start on specs with Status: Approved
- Every PR must fill specs/PR_TEMPLATE.md
- Constitution changes require PR review before merging
```

The AI enforces the approval gate automatically once it's in the constitution.
