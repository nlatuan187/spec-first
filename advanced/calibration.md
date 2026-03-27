# Calibrating spec-first for Your Codebase

## The key insight

spec-first's thresholds (S1 ≤ 3, S3 ≤ 1 for autonomous) come from one production codebase. They are not universal constants — they are calibrated starting points.

What IS universal: the categories of failure, and the protocol for measuring them.

| What spec-first gives you | What you discover yourself |
|---|---|
| What to measure (5 fix categories) | Your ratio for each category |
| Starting thresholds | Your adjusted thresholds |
| Calibration protocol | Your constitution update |

Start with the defaults. Run the protocol. After 2–4 weeks you have your own data.

---

## Baseline (from 626 production commits, Next.js SaaS)

| Fix category | % of fixes | Autonomous safe? |
|---|:---:|---|
| Cross-module integration | 40% | Only if S3 ≤ 1 |
| Missing error handling | 25% | Only if S1 ≤ 3 |
| Security vulnerabilities | 15% | Never autonomous if auth/PII |
| i18n hardcoding | 10% | Usually autonomous |
| Stale state / cleanup | 10% | Usually autonomous |

Threshold logic: `S1 ≤ 3, S3 ≤ 1` → autonomous is safe because integration failures are minimal (S3 low) and error surface is small (S1 low). Beyond that, human attention adds more value than the overhead of a review session.

---

## The calibration protocol

### Step 1: Tag your fix commits for 2 weeks

Add a category tag to every fix commit:

```bash
git commit -m "fix(integration): platform sync not refreshing after post create"
git commit -m "fix(error): API 429 not handled — silent failure"
git commit -m "fix(security): missing ownership check on resource update"
git commit -m "fix(i18n): hardcoded Vietnamese toast in store"
git commit -m "fix(state): selected item not cleared on navigation"
```

5 tags only: `integration`, `error`, `security`, `i18n`, `state`. Anything that doesn't fit: use the closest one.

### Step 2: Pull your ratios after 2 weeks

```bash
# Total fix commits
git log --oneline --grep="^fix" | wc -l

# By category
git log --oneline --grep="fix(integration)" | wc -l
git log --oneline --grep="fix(error)" | wc -l
git log --oneline --grep="fix(security)" | wc -l
git log --oneline --grep="fix(i18n)" | wc -l
git log --oneline --grep="fix(state)" | wc -l
```

### Step 3: Compare to baseline and adjust

| Your ratio vs baseline | Adjustment |
|---|---|
| integration > 50% | S3 threshold: lower by 1 (stricter) |
| integration < 25% | S3 threshold: raise by 1 (more autonomous) |
| security > 20% | Review required for ALL auth-touching specs |
| security < 5% | Remove high-risk override (pure internal tools) |
| error > 35% | S1 threshold: lower by 1 |
| error < 15% | S1 threshold: raise by 1 |

### Step 4: Update your constitution

Add calibrated thresholds to your CLAUDE.md / .cursorrules:

```markdown
## Spec-first calibration (updated [date], based on [N] commits)
Autonomous: S1 ≤ [N], S3 ≤ [N]
Review recommended: S1 [range], S3 [range]
Review required: S1 ≥ [N], S3 ≥ [N]
High-risk override: [auth only / all external APIs / disabled]
```

### Step 5: Repeat after 4 weeks

Second calibration point. By now your thresholds are yours, not spec-first's defaults.

---

## Risk profile adjustments

If you know your project's profile, apply these before starting:

| Risk factor | Adjustment from default |
|---|---|
| Heavy external API integrations (>3 third-party APIs) | S3 threshold −1 |
| No user auth, no PII (pure internal tools) | Remove high-risk override |
| Regulated industry (fintech, health, legal) | Review required for ALL specs |
| Solo developer, rapid iteration | S1 threshold +1 |
| Legacy codebase, many hidden dependencies | S3 threshold −1 |
| Greenfield, simple domain | Defaults are fine |

These are heuristics. They let you start calibrated rather than starting blind. Still run the 2-week protocol to verify.

---

## What this means for teams

Every team's data validates or invalidates spec-first's thresholds for their context. When you run the protocol:

- You're not trusting spec-first's numbers — you're verifying them against your codebase.
- Your constitution becomes evidence-based, not opinion-based.
- "Why is the threshold S1 ≤ 3?" has an answer: "Because our data shows autonomous is safe below that."

Competitors give you rules. spec-first gives you the protocol to derive your own rules from your own data.

---

## Publishing your calibration

If you run the protocol and get data from your codebase, consider publishing it:

```markdown
## My calibration
Stack: [Next.js / Django / Rails / etc.]
Team: [N] devs, [N] months
Commits analyzed: [N]
Integration %: [N]% (baseline: 40%)
Adjusted S3 threshold: [N] (default: 1)
```

Community calibration data across stacks is the path from "one production SaaS" to "validated across 50 codebases." The protocol is in place. The data collection is distributed.
