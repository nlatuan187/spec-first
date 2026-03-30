# spec-first

**Better code from AI. Fewer rewrites. One file. Works with any tool.**

> Before writing code, your AI writes a short plan — what can break, what other features are affected, what "done" looks like. The AI didn't get smarter — it got a planning step.

Two developers. 24 days. Same AI tools — but with planning first. Fix:feat ratio: 5:1 → **1.5:1** — the AI stopped generating bugs at the rate it generated code. 65% fewer failed code reviews. These aren't projections — they're from [626 production commits](#evidence).

## What you get

| Without spec-first | With spec-first |
|---|---|
| AI skips error states — they fail in production | Failure cases caught before code is written |
| Broken integrations — AI forgot what else exists | Changes stay in scope — other features stay intact |
| "Looks good" from the AI that just wrote the code | A second pass catches what the builder missed |
| Third variation of the same wrong fix | Fixed in one try because root cause is identified first |
| Messy codebase? AI hallucinates what's there | Map what actually exists, then fix it section by section |

**Better code quality. Better organization. Safer refactoring. Faster shipping.**

<details>
<summary><strong>What a spec actually looks like</strong> (click to expand)</summary>

```markdown
# Feature: Password Reset

## S1: Error States (failures FIRST — happy path last)
| Condition | User sees |
|-----------|-----------|
| Email not found | "Check your email" (same message — don't leak which emails exist) |
| Token expired (>1hr) | "This link has expired. Request a new one." + link |
| Token already used | "This link has already been used." |
| New password = old password | "New password must be different from current password." |
| ✅ Happy path | Email sent → user clicks → sets new password → redirected to login |

## S3: Cross-Feature Integration
| Feature | How it's affected |
|---------|-------------------|
| Login page | Add "Forgot password?" link |
| Email service | New template: password-reset |
| Session management | Invalidate all sessions on password change |
| Rate limiting | Max 3 reset emails per hour per address |

## S6: Manual QA
- [ ] Request reset → email arrives < 30 seconds
- [ ] Click link after 61 minutes → shows expired message
- [ ] Click link twice → second click shows "already used"
- [ ] Reset password → old sessions are logged out
```

→ [More examples](advanced/examples/) — real production specs, anonymized
</details>

<details>
<summary><strong>Same feature, with and without spec-first</strong> (click to expand)</summary>

**Without spec-first** — you say "build password reset." AI generates:

```javascript
async function resetPassword(email) {
  const user = await db.users.findByEmail(email);
  const token = generateToken();
  await sendEmail(user.email, token);
  return { success: true };
}
```

Works in the demo. Crashes in production: email not found → `user.email` throws. No token expiry. No rate limiting. No session invalidation. **4 bugs you'll find after users hit them.**

**With spec-first** — AI writes the spec above first, then generates:

```javascript
async function resetPassword(email) {
  const user = await db.users.findByEmail(email);
  if (!user) return { success: true }; // Don't leak email existence

  const recent = await db.resetTokens.countRecent(email, '1h');
  if (recent >= 3) return { error: 'Too many requests. Try again later.' };

  await db.resetTokens.invalidateExisting(email);
  const token = generateToken({ expiresIn: '1h' });
  await db.resetTokens.create({ email, token, used: false });
  await sendEmail(email, token);
  return { success: true };
}
```

Same AI. Same prompt. The spec told it what to check — so it checked. **The AI didn't get smarter. It got a checklist.**

</details>

---

## The Fundamental Law — why this works

```
AI generates the most statistically probable next token — not the correct one.
It has no judgment. Only probability.
```

Every outcome above is a probability problem.

The most probable token after a vague request is a confident-sounding wrong answer. After a build session, it's "the code is correct." After a happy-path description, it's a missing error state. After two failed fix attempts, it's a third variation of the same wrong approach.

spec-first engineers around the probability — not against it. Every rule derives from this law. When you understand it, you can engineer AI behavior for any situation not covered here.

---

## Install — 30 seconds

**macOS / Linux / Git Bash:**
```bash
curl -fsSL https://raw.githubusercontent.com/nlatuan187/spec-first/master/install.sh | sh
```

**Windows (PowerShell):**
```powershell
iwr -useb https://raw.githubusercontent.com/nlatuan187/spec-first/master/install.ps1 | iex
```

Auto-detects your AI tool, appends to the right context file, copies templates, creates `specs/`. Claude Code users also get `/spec`, `/spec-review`, `/spec-check`, `/spec-stats` installed automatically.

| AI tool | Context file updated |
|---------|---------------------|
| Claude Code | `CLAUDE.md` |
| Cursor | `.cursorrules` |
| Windsurf | `.windsurfrules` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Codex / any other | `AGENTS.md` |

**Or ask your AI**: paste the repo URL into your AI chat and say *"install spec-first into my project"* — it will run the installer for you.

**Or manually**: copy [`snippet.md`](snippet.md) into your AI's context file — the file your AI reads at the start of every conversation (CLAUDE.md, .cursorrules, etc.).

---

## Solo, team, or large corp?

The Fundamental Law applies at every scale. spec-first is the spec quality layer regardless of team size — what changes is process, not methodology.

| Config | Size | What's different |
|---|---|---|
| **Solo** | 1–3 devs | Self-approve specs. One context file. |
| **Team** | 3–10 devs | Approval gate + PR template + constitution owner. |
| **Corp** | 10+ devs | Formal constitution governance + distributed approvers + automated S3 enumeration. |

The 5 failure modes (happy-path bias, isolation blindness, etc.) exist at every scale. spec-first's rules apply regardless. What scales up is coordination — not whether to use spec-first.

→ [Team & corp workflow guide](advanced/team-workflow.md)

---

## Stack with execution tools

spec-first is the thinking layer — what to build and what can break. Pair it with execution tools for the full cycle:

| What you need | Use |
|---|---|
| Better specs, fewer bugs | **spec-first** (this repo) |
| Subagent-driven autonomous execution | spec-first + [superpowers](https://github.com/obra/superpowers) |
| Overnight autonomous builds with crash recovery | spec-first + [GSD-2](https://github.com/gsd-build/gsd-2) |
| Multi-agent team orchestration | spec-first + [BMAD](https://github.com/bmad-method/BMAD-METHOD) |

spec-first writes the plan. These tools execute it. Without the plan, automation runs fast and breaks things. Without automation, the plan is slower to execute. Together: quality at speed.

<details>
<summary><strong>Example: spec-first + superpowers workflow</strong></summary>

```
1. Install both: spec-first (curl | sh) + superpowers (/plugin install)
2. Say: "build user authentication"
3. spec-first activates → writes specs/user-auth.md (S1-S6)
4. Scope Routing: S1=8, S3=4 → "Review required"
5. Run /spec-review → APPROVED
6. New session: "Read specs/user-auth.md, then implement"
7. Skip superpowers brainstorming (spec-first already did it)
8. superpowers' TDD skill writes failing tests from S6 scenarios
9. superpowers' subagent-driven-development dispatches implementation
10. /spec-check verifies all S1/S3/S6 items covered
```

Note: superpowers runs its OWN brainstorming by default. With spec-first, skip brainstorming and use the spec-first spec as the design doc input to `executing-plans` or `subagent-driven-development`.

</details>

<details>
<summary><strong>Example: spec-first + GSD-2 workflow</strong></summary>

```
1. Install both: spec-first (curl | sh) + GSD-2 (npm install -g gsd-pi)
2. Write spec: "build [feature]" → specs/feature.md created
3. /spec-review → APPROVED
4. Start GSD-2: /gsd discuss — paste spec-first's S1-S6 as requirements input
5. GSD-2 restructures into its own format (REQUIREMENTS.md, ROADMAP.md)
6. /gsd auto — runs autonomously:
   - Fresh context per task (no drift)
   - Crash recovery if session dies
   - Cost tracking per unit
7. Come back → feature built with clean git history
8. /spec-check specs/feature.md → verify coverage
```

Note: GSD-2 has its own planning artifacts (PROJECT.md, REQUIREMENTS.md, etc.). Use `/gsd discuss` to translate spec-first's S1-S6 into GSD-2's format before running `/gsd auto`.

</details>

→ [Detailed integration guides](advanced/INTEGRATIONS.md)

---

## First 5 minutes

**If your project has no `CLAUDE.md` yet**: open a new session and say: `"Create a minimal project constitution for this project. Tech stack: [X]. Key file paths: [Y]. Auth method: [Z]. Save to CLAUDE.md."` — 2 minutes, done once.

After install, open a new AI session in your project (new chat in Cursor/Windsurf, `/new` in Claude Code). Say: `build [feature name]`.

Your AI will:
1. Check your project constitution for constraints
2. Clarify anything ambiguous — max 3 questions
3. Write `specs/[feature].md` with S1–S6 filled
4. Tell you to open a new session to implement

Works with your existing AI tool. No new infrastructure required.

---

## Already have a codebase? Start here.

Most people come to spec-first mid-project — not at the beginning. That's fine. Pick your situation:

**Fix a bug** (5 minutes):
> "Fix [describe the bug]. Write a bug spec first: what currently happens, what should happen, exact steps to reproduce, what else could break from the fix. Save to `specs/[name]-bug.md`, then fix it."

**Refactor safely** (10 minutes):
> "I want to refactor [area]. Before changing anything: scan what currently exists, list every file and feature that touches this area, identify what could break if the structure changes. Save to `specs/[name]-refactor.md`, then refactor one piece at a time."

**Add a feature to existing code** (15–20 minutes):
> "Write a retroactive spec for [feature or area]. Scan what actually exists in the codebase, list what's broken (failures first), find what other features it touches, define what done looks like. Save to `specs/[name]-retro.md`"

After any of these: run `/spec-check specs/[name].md` — gaps appear immediately. For each gap: open a new session, load the spec, fix that gap.

**Don't know where to start?** Say: *"Scan this codebase. List what's broken, what's fragile, and what's missing. Prioritize by user impact."* — then pick the first item and use the matching flow above.

<details>
<summary><strong>Building with AI but quality isn't there yet?</strong></summary>

Your AI builds features that "work" in the demo but break with real users. That's not an AI problem — it's a planning problem. The AI handles what you ask about. You don't know to ask about rate limiting, session expiry, or what happens when 2 users click the same button. Neither does the AI — unless something tells it to check.

**Try this right now (2 minutes, no install needed):**

1. Open your AI tool. Say: *"Build a password reset feature."* Look at the code. Count the error cases it handles.
2. Now say: *"Wait — before coding, list every way this can fail. For each failure, what should the user see? What other features does this touch? Write this as a table, then implement."*
3. Count again. The second version handles 3-5x more cases.

That's spec-first in one sentence: **make the AI list what can break before it writes code.** The install just automates this for every task.

</details>

<details>
<summary><strong>Joining a team that uses spec-first?</strong></summary>

Your onboarding checklist:
1. Read `CLAUDE.md` — your team's conventions, constraints, and stack decisions
2. Read `KNOWLEDGE.md` — gotchas and patterns discovered by your teammates
3. Read one spec in `specs/` — see what a real spec looks like in this project
4. Your first task: pick a small bug or change, say `fix [describe the bug]` — the AI will write a spec before fixing

You'll produce consistent specs that teammates can review from day one.

</details>

<details>
<summary><strong>How do I know it's working?</strong></summary>

After 1 week, check 3 things:

1. **Count spec rows vs production bugs.** Your spec listed 8 error states. Did a 9th break in production? If not — the spec caught them. If yes — add it to the spec and the AI handles it next time.
2. **Did something break that WAS in the spec?** → Implementation bug, not spec bug. Re-read the spec, fix the code.
3. **Did something break that WASN'T in the spec?** → Spec gap. That's your learning signal — add it for next time.

The pattern: bugs move from "surprise in production" to "row in a spec." Over time, fewer surprises.

Run `/spec-stats` for hard numbers: fix:feat ratio, spec coverage, health score out of 10.

</details>

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
| Emergency | 0 min | Fix first → retroactive S1 + S6 |
| Bug fix | 5 min | S1 + S6 |
| Small change | 10 min | S1 + S3 + S6 |
| Spike | — | Explore first → spec chosen approach |
| Refactor | 10 min | S3 (dependencies) + S6 (regression) |
| Brownfield delta | 10 min | ADDED/MODIFIED/REMOVED + S1 + S6 |
| New feature | 20 min | Full S1–S6 |
| Large feature | 30 min | Full S1–S6 + Implementation Notes |

---

## Evidence

Two developers. 24 days. A complete production SaaS — 107 API routes, 19 DB tables, 119 React components. 626 commits.

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
| [`advanced/`](advanced/) | Team workflow, calibration protocol, /spec /spec-review /spec-check /spec-stats skills. |

---

## Advanced

- [**Failure patterns**](advanced/deep-dives/failure-patterns.md) — 626 commits analyzed: what breaks, why, which spec section prevents it
- [**Calibration**](advanced/calibration.md) — start with the defaults, tune thresholds to your codebase in 2 weeks
- [**Feedback triage**](advanced/feedback-triage.md) — convert raw user feedback batches into verified GitHub issues: 5-phase workflow, 3x token overhead eliminated
- [Team workflow](advanced/team-workflow.md) — approval gate, PR template, constitution ownership
- [During-coding layer](advanced/during-coding/) — implementation brief for long sessions + /spec-check usage
- [Implementation blueprint](advanced/prp.md) — for complex features
- [/spec, /spec-review, /spec-check, /spec-stats slash commands](advanced/skills/) — for Claude Code: write → verify → check coverage → measure health
- [Ecosystem integrations](advanced/INTEGRATIONS.md) — Claude Code, Cursor, Windsurf, GSD-2
- [Methodology philosophy](advanced/ETHOS.md)
