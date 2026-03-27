# spec-first

**Spec discipline for AI coding. One file. Works with any AI tool.**

Two developers. 24 days. Fix:feat ratio: 5:1 → **1.5:1**. S1 + S3 alone prevented **65% of review failures**. These aren't projections — they're from [626 production commits](#evidence).

---

## The Fundamental Law

```
AI generates the most statistically probable next token — not the correct one.
It has no judgment. Only probability.
```

Every AI coding failure is a probability problem.

The most probable token after a vague request is a confident-sounding wrong answer. After a build session, it's "the code is correct." After a happy-path description, it's a missing error state. After two failed fix attempts, it's a third variation of the same wrong approach.

spec-first engineers around the probability — not against it. Every rule derives from this law. When you understand it, you can engineer AI behavior for any situation not covered here.

---

## Install — 30 seconds

**macOS / Linux / Git Bash:**
```bash
curl -fsSL https://raw.githubusercontent.com/nlatuan187/spec-first/main/install.sh | sh
```

**Windows (PowerShell):**
```powershell
iwr -useb https://raw.githubusercontent.com/nlatuan187/spec-first/main/install.ps1 | iex
```

Auto-detects your AI tool, appends to the right context file, copies templates, creates `specs/`. Claude Code users also get `/spec`, `/spec-review`, `/spec-check` installed automatically.

| AI tool | Context file updated |
|---------|---------------------|
| Claude Code | `CLAUDE.md` |
| Cursor | `.cursorrules` |
| Windsurf | `.windsurfrules` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Codex / any other | `AGENTS.md` |

**Or manually**: copy [`snippet.md`](snippet.md) into whichever context file your AI reads.

---

## Solo, team, or large corp?

The Fundamental Law applies at every scale. spec-first is the spec quality layer regardless of team size — what changes is process, not methodology.

| Config | Size | What's different |
|---|---|---|
| **Solo** | 1–3 devs | Self-approve specs. One context file. |
| **Team** | 3–10 devs | Approval gate + PR template + constitution owner. |
| **Corp** | 10+ devs | Formal constitution governance + distributed approvers + automated S3 enumeration. Add [BMAD](https://github.com/bmad-method/BMAD-METHOD) for multi-agent orchestration on top. |

The 5 failure modes (happy-path bias, isolation blindness, etc.) exist at every scale. spec-first's rules apply regardless. What scales up is coordination — not whether to use spec-first.

→ [Team & corp workflow guide](advanced/team-workflow.md)

---

## First 5 minutes

**If your project has no `CLAUDE.md` yet**: open a new session and say: `"Create a minimal project constitution for this project. Tech stack: [X]. Key file paths: [Y]. Auth method: [Z]. Save to CLAUDE.md."` — 2 minutes, done once.

After install, open a new AI session in your project. Say: `build [feature name]`.

Your AI will:
1. Check your project constitution for constraints
2. Clarify anything ambiguous — max 3 questions
3. Write `specs/[feature].md` with S1–S6 filled
4. Tell you to open a new session to implement

No commands. No orchestration. No new tools.

---

## Already mid-implementation?

Don't start over. Write a retroactive spec in a new session:

> "Write a retroactive spec for [feature]. Scan what exists, list what's broken (S1 format), find all touchpoints (grep S3), define done (S6 scenarios). Follow the Formality Dial for depth — S1+S3+S6 for small changes, full S1–S6 for new features. Save to `specs/[slug]-retro.md`"

Then run `/spec-check specs/[slug]-retro.md` — gaps appear immediately.

- **S3 grep** finds every integration your memory missed
- **S1** forces cataloging what's *actually* broken (not what you think is broken)
- **S6** defines "done" so you stop adding scope

For each gap `/spec-check` surfaces: open a new session, load the retro spec, fix the gap. No rewrite needed — just fill what's missing.

---

## What it solves

| Failure mode | Root cause | Fix |
|---|---|---|
| **Happy-path bias** | Success is 10x more probable in training data | S1 rule: write failures before happy path |
| **Isolation blindness** | Isolated features more probable than integrated systems | S3 rule: scan codebase, enumerate every touchpoint |
| **Same-session review bias** | "Code is correct" = most probable continuation of a build session | Session rule: review always in a new cold session |
| **Missing deployment knowledge** | Serverless timeouts, DB truncation = low-frequency training data | Deployment constraints table in every spec |
| **Context dilution** | Attention weights recency — spec from message 5 fades by message 45 | Methodology in context file, read every session |

---

## Scope → formality

| Scope | Time | Format |
|---|---|---|
| Bug fix | 5 min | S1 + S6 |
| Small change | 10 min | S1 + S3 + S6 |
| New feature | 20 min | Full S1–S6 |
| Brownfield delta | 10 min | ADDED/MODIFIED/REMOVED + S1 + S6 |
| Large feature | 30 min | Full S1–S6 + Implementation Notes |

---

## Evidence

Two developers. 24 days. 107 API routes, 19 DB tables, 119 React components. 626 commits.

| Metric | Week 1 → Week 4 |
|--------|:---------------:|
| Fix:feat ratio | 5:1 → **1.5:1** |
| Productivity vs solo dev | — → **10–15x** |
| Review failures prevented by S1+S3 | **65%** |

**Why the rules exist — from 626 production commits:**

| Bug category | % of fixes | Spec rule that prevents it |
|---|:---:|---|
| Cross-module integration failures | **40%** | S3: scan, don't rely on memory |
| Missing error handling | **25%** | S1: write failures before happy path |
| Security (IDOR, XSS, input validation) | **15%** | review.md: security pass |
| i18n hardcoding | **10%** | S4: UX copy review |
| Stale state, missing cleanup | **10%** | S5: state & persistence matrix |

S1 + S3 alone prevent 65% of fixes. Every other tool in this space derives these rules from theory. These come from the git log.

The same data determines when human review is required — and when autonomous is safe. Bug fixes at 1.5:1 fix ratio: autonomous. Auth features at 15% security bug rate: human review required. Not preference. Data.

---

## Files

| File | What it is |
|------|-----------|
| [`snippet.md`](snippet.md) | **The product.** Paste into any AI context file. |
| [`spec.md`](spec.md) | Spec template — full S1–S6, Delta, and Bug formats. |
| [`review.md`](review.md) | Two-pass code review checklist. |
| [`install.sh`](install.sh) | Auto-detect + append installer. |
| [`advanced/examples/`](advanced/examples/) | Real production specs (anonymized) — see what a complete spec looks like before writing your first one. |
| [`advanced/`](advanced/) | Team workflow, calibration protocol, /spec /spec-review /spec-check skills. |

---

## Advanced

- [**Failure patterns**](advanced/deep-dives/failure-patterns.md) — 626 commits analyzed: what breaks, why, which spec section prevents it
- [**Calibration**](advanced/calibration.md) — start with the defaults, tune thresholds to your codebase in 2 weeks
- [**Feedback triage**](advanced/feedback-triage.md) — convert raw user feedback batches into verified GitHub issues: 5-phase workflow, 3x token overhead eliminated
- [Team workflow](advanced/team-workflow.md) — approval gate, PR template, constitution ownership
- [Implementation blueprint](advanced/prp.md) — for complex features
- [/spec, /spec-review, /spec-check slash commands](advanced/skills/) — for Claude Code: write → verify → check coverage
- [Ecosystem integrations](advanced/INTEGRATIONS.md) — Claude Code, Cursor, Windsurf, GSD-2
- [Methodology philosophy](advanced/ETHOS.md)
