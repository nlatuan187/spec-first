# Calibrating spec-first for Your Codebase

## The key insight

spec-first's fix categories and baseline percentages come from one production codebase.
They are not universal constants — they are calibrated starting points.

What IS universal: the categories of failure, and the protocol for measuring them.

| What spec-first gives you | What you discover yourself |
|---|---|
| What to measure (5 fix categories) | Your ratio for each category |
| Baseline percentages | Your stack's actual distribution |
| Calibration protocol | Your constitution update |

Start with the defaults. Run the protocol. After 2–4 weeks you have your own data.

> **Note (v2):** The numeric routing gate (S1 ≤ 3, S3 ≤ 1 → autonomous) was removed in v2.
> It was removed because the counts were self-reported by the agent being gated, and a
> refactor spec legitimately has no `## Integration` section — scoring zero routed it to
> autonomous, which was the highest-risk case in the dataset. Scope-based section selection
> replaced it: the scope table in `snippet.md` picks mandatory sections by scope, not by
> counted thresholds. See `deep-dives/failure-patterns.md` for the full reasoning.

---

## Baseline (from 626 production commits, Next.js SaaS)

fix commits were 47% of 626 total commits (293). The fix:feat ratio was 2.93:1.

| Fix category | % of fixes |
|---|:---:|
| Cross-module integration | 40% |
| Missing error handling | 25% |
| Security vulnerabilities | 15% |
| i18n hardcoding | 10% |
| Stale state / cleanup | 10% |

---

## Adapting to your stack

The baseline (40%/25%/15%/10%/10%) comes from a React/Next.js SaaS with real-time state
and multiple API integrations. Your stack will have different ratios — and some categories
may not apply.

**Read this before starting Step 1.** Your tag categories should match your project, not
the baseline.

| If your project is... | Adapt like this |
|---|---|
| **Backend API only** (Django, Rails, Go) | Rename `i18n` → `hardcoded-values` (magic strings, config embedded in code, env var misuse) |
| **Mobile** (iOS / Android / React Native / Flutter) | Expect `state` > 10% baseline — local state, navigation state, offline sync all amplify this category |
| **Microservices / event-driven** | Expect `integration` > 40% baseline |
| **Data pipeline / ML** | Replace `i18n` + `state` with `data-corruption` + `schema-drift`; integration failures map to pipeline stage boundaries |
| **Internal tool, no auth** | Remove `security` category entirely; add `performance` if relevant |
| **Monorepo with shared packages** | `integration` failures often come from package boundary mismatches — add `fix(integration/package)` as a sub-tag |

The categories are a starting point. What matters: **5 categories that together cover ≥ 90%
of your fix commits.** If one category is always 0%, replace it with something that isn't.

---

## The calibration protocol

### Step 1: Tag your fix commits for 2 weeks

Add a category tag to every fix commit. **Minimum 20 fix commits OR 4 weeks of data
(whichever comes first)** before adjusting — fewer data points are noise, not signal.
Below 20 commits, treat adjustments as provisional and re-verify at the next calibration
cycle.

Use your adapted categories from above (not necessarily the defaults):

```bash
git commit -m "fix(integration): sidebar badge not updating after notification created"
git commit -m "fix(error): API 429 not handled — silent failure instead of retry prompt"
git commit -m "fix(security): missing ownership check before resource update"
git commit -m "fix(i18n): hardcoded string in component instead of translation key"
git commit -m "fix(state): selected item not cleared on navigation to different section"
```

Use your 5 chosen tags consistently. Anything that doesn't fit: use the closest one.

### Step 2: Pull your ratios after 2 weeks

```bash
# Total fix commits
git log --oneline --grep="^fix" | wc -l

# By category (replace tag names if you adapted them)
git log --oneline --grep="fix(integration)" | wc -l
git log --oneline --grep="fix(error)" | wc -l
git log --oneline --grep="fix(security)" | wc -l
git log --oneline --grep="fix(i18n)" | wc -l
git log --oneline --grep="fix(state)" | wc -l
```

### Step 3: Compare to baseline

| Your ratio vs baseline | What this tells you |
|---|---|
| integration > 50% | Specs touching multiple modules are high-risk; `## Integration` is worth requiring even on `bug` scope |
| integration < 25% | Risk concentrates elsewhere; defaults for your dominant category matter more |
| security > 20% | Auth-touching specs warrant an explicit QA step |
| security < 5% | Security section is low-value overhead for purely internal tooling |
| error > 35% | `## Failure modes` is your highest-value section; enforce it strictly |
| error < 15% | Failure mode surface is narrow; existing defaults are sufficient |

This comparison does not produce numeric thresholds to embed. It identifies where your
project deviates from baseline and which spec sections deliver the most return for your
stack.

### Step 4: Record your ratios

Add measured ratios to your CLAUDE.md. Do not derive autonomous/review thresholds from
them — use them as reference for reviewers deciding whether a spec's section coverage is
adequate for your codebase.

```markdown
## Spec-first calibration (updated [date], based on [N] commits)
Integration: [N]%  Error: [N]%  Security: [N]%  State: [N]%  Other: [N]%
Reconciliation rate: [N]% — target: all specs reconciled within one working day of shipped_at
Scope overrides: [any scope where you require an extra section beyond the defaults]
```

### Step 5: Repeat after 4 weeks

Second calibration point. By now your ratios are yours, not spec-first's defaults.

---

## What this means for teams

Every team's data validates or invalidates spec-first's baseline for their context. When
you run the protocol:

- You're not trusting spec-first's numbers — you're verifying them against your codebase.
- Your constitution becomes evidence-based, not opinion-based.
- "Why do we require `## Integration` on refactor specs?" has an answer: "Because 55% of
  our fixes are cross-module and refactors are our highest-risk case."
- Track reconciliation rate separately: what fraction of shipped specs have `reconciled_at`
  set within one working day of `shipped_at`? A low rate means system documents are not
  getting the corrections that keep them accurate. Aim for 100%.

---

## Publishing your calibration

If you run the protocol and get data from your codebase, open a
[GitHub Discussion](https://github.com/nlatuan187/spec-first/discussions) with this
format:

```markdown
## My calibration
Stack: [Next.js / Django / Rails / mobile / etc.]
Team: [N] devs, [N] months
Commits analyzed: [N]
Integration %: [N]% (baseline: 40%)
Error %: [N]% (baseline: 25%)
Security %: [N]% (baseline: 15%)
State %: [N]% (baseline: 10%)
Scope overrides vs defaults: [what you changed and why]
Notes: [what drove the adjustment]
```

Community calibration data across stacks is the path from "one production SaaS" to
"validated across 50 codebases." The protocol is in place. The data collection is
distributed.
