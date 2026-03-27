# AI's Five Failure Modes

> Understanding *why* AI fails is more valuable than knowing *that* it fails.
> Each failure mode has a cause. Each cause has a structural fix.

This document explains the mechanism behind each failure — not just the symptom — so you can design your workflow to prevent them, not just react to them.

---

## Why mechanism matters

Most "AI best practices" say: "do X." Few explain why.

Without the mechanism, rules become cargo cult: you follow them when they're convenient and skip them when you're in a hurry. With the mechanism, you can reason about when a rule applies, how to adapt it to your situation, and what the real cost is of ignoring it.

The five failure modes below each have:
1. **The phenomenon** — what you observe when it occurs
2. **The mechanism** — the underlying reason AI behaves this way
3. **The fix** — the spec-first structural solution
4. **How to verify** — how to know the fix worked

---

## Failure Mode 1: Context Dilution

### Phenomenon
You write a spec with specific constraints at the start of a session. By message 30, the AI has forgotten or is deprioritizing those constraints. The code it writes violates rules you established at the beginning.

### Mechanism
Transformer-based AI models use attention — every token "attends" to every other token, but with different weights. In a long context window, earlier content gets less attention weight than recent content. This is not a memory failure. The model hasn't forgotten the constraints. It's weighting them less because they're distant in the token sequence.

The practical effect: a 5000-token spec at the start of a session has less influence on output at message 40 than it did at message 2. The drift is gradual and invisible — there's no error message, no indication the model is paying less attention to your constraints.

This compounds with a second effect: **accumulated error propagation.** An incorrect assumption in step 5 of a session gets encoded into subsequent steps. By step 15, the AI is confidently building on a foundation that was wrong.

### The Fix
**One session, one job.** Each development phase runs in a fresh context:
- Spec session: reads problem, generates spec, saves file. Ends.
- Implementation session: reads CLAUDE.md + spec file cold. Implements. Ends.
- Review session: reads diff cold. Reviews. Ends.

The spec file, the diff, the review findings — these are the handoff artifacts. They carry information across session boundaries without carrying accumulated error.

**The implementation brief** (`during-coding/implementation-brief.md`) handles the case where a single implementation session runs long. Compress state to 40 lines at the halfway point, start fresh, paste the brief.

### How to Verify
- You can restart the implementation session mid-feature and get consistent output
- Review session catches things the implementation session didn't flag (if they're the same, something is wrong)
- No "I thought I specified X but AI did Y" on the 10th iteration

---

## Failure Mode 2: Happy-Path Training Bias

### Phenomenon
AI generates perfectly working code for the success case. Error handling is absent, superficial ("catch any error and log it"), or handles only the most obvious case. Edge cases are missing. The feature works in demo and breaks in production.

### Mechanism
AI models learn from training data. GitHub, documentation, tutorials, Stack Overflow — the vast majority of this content describes how things work when they work. The ratio of success-path to failure-path examples in AI training data is roughly 10:1 in documentation, higher in tutorials.

This isn't a capability failure. Ask AI to write error handling explicitly and it will. The bias is about **defaults** — what AI reaches for first when not told otherwise. And the default is success path.

There's a secondary mechanism: **error handling is often platform-specific.** A generic AI trained on all of the internet doesn't know that Supabase returns `{ data: null, error: { code: 'PGRST116' } }` for "not found" (not an HTTP 404) unless explicitly told. Even if it wanted to handle your specific errors, it often doesn't have the platform knowledge to do it correctly.

### The Fix
**S1 (Error States) is the first spec section you fill.** Not the last. Not "optional if time allows." First.

By making error states mandatory before acceptance criteria, you force yourself to reason about failures before AI reasons about successes. The spec then gives AI an explicit list of failure cases to handle, with specific expected behaviors.

The deployment constraints block at the top of S1 addresses the platform-specific gap: you write down your infrastructure constraints (Vercel timeout: 10s, Supabase truncation at 1000 rows) so AI has the context it needs to handle them correctly.

### How to Verify
- Every error state in S1 has a corresponding code path (use `/spec-check`)
- Error messages are specific (not "Something went wrong")
- Concurrent execution has a handling strategy (not ignored)

---

## Failure Mode 3: Isolation Blindness

### Phenomenon
Each file looks correct. The feature works standalone. In integration, things break: credits aren't deducted, caches aren't invalidated, notifications aren't triggered, other features don't update.

This is the single largest source of bugs in AI-generated code. In our production codebase, it accounted for 40% of all fix commits.

### Mechanism
AI builds what it can see. When implementing `createPost()`, AI sees the posts table, the posts API route, the post component. It does not see that:
- A new post should trigger credit deduction in `lib/usage.ts`
- The post list in `store/postsStore.ts` needs to be invalidated
- The dashboard counter in a different component needs to update
- A cron job that processes posts runs every 2 hours and must handle the new post correctly

These connections are implicit in a production codebase. They're in the heads of the developers who built the system. AI doesn't have access to that implicit knowledge unless you explicitly provide it.

There's also a **cross-file pattern gap.** AI tends to implement patterns it sees nearby. If the implementation file doesn't already have credit deduction code, AI won't add it — even if it exists in adjacent files.

### The Fix
**S3 (Cross-Feature Integration)** makes implicit connections explicit. Before AI writes any code, you define:
- What upstream events trigger this feature
- What downstream effects this feature triggers
- What shared state is read and written
- What cleanup is required when the user leaves

This section should be the hardest to fill. If it's easy, you're probably missing connections.

**Deployment constraints in S1** address the infrastructure layer: "this runs as a serverless cron job that may execute concurrently" forces you to think about concurrency before AI writes the first line.

### How to Verify
- After implementation, run `/spec-check` and look only at S3 results
- The most common gap: "creates X → refreshes list in Y" not implemented
- Second most common: cleanup on unmount not implemented

---

## Failure Mode 4: Same-Session Review Bias

### Phenomenon
You ask the AI that just implemented a feature to review it. It finds a few style issues. Later, CodeRabbit or a human reviewer finds critical security issues, race conditions, or missing error handling that the AI "reviewed."

### Mechanism
An AI session that implemented a feature has the full context of why every decision was made. When asked to review the same code in the same session, it applies **motivated reasoning** — evaluating evidence in a way that supports the decisions it already made.

This is a well-documented phenomenon in human code review psychology. Developers who wrote code find significantly fewer bugs when reviewing their own work. The mechanism is the same for AI: it "knows" why the polling loop was used (the spec said to wait for results), so it doesn't flag the serverless timeout issue. It "knows" the API token is in the URL because that's how the documentation showed it, so it doesn't flag the credential leak.

The [METR finding that AI slows experienced developers by 19%](https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/) is partly this effect: teams that use AI to implement and review in the same session are worse off than those who keep the steps separate.

### The Fix
**Cold review sessions.** A review session has no knowledge of the implementation session. It sees the diff (what changed), not the intent (why it changed).

Every tool has a way to create a cold session:

| Tool | How to Create Cold Review Session |
|------|----------------------------------|
| Claude Code | New tab in Superset / new terminal window |
| Cursor | New Composer instance (`Cmd+I` → "New Conversation") |
| Windsurf | New conversation window |
| Codex | Separate API call, no session history |
| Any tool | Open new window, do NOT continue the implementation conversation |

The review prompt is always the same:
```
git diff origin/main
Apply review-checklist at spec-first/advanced/templates/review-checklist.md
Output Pass 1 (Critical) first.
```

**What a cold session catches that a warm session misses:**
- Security issues the warm session "knew" were intentional
- Race conditions the warm session "knew" the spec had covered
- Missing error states the warm session "knew" would be handled later
- Integration gaps the warm session "knew" were in a different PR

### How to Verify
- The review session flags at least something the implementation session didn't flag
- If cold review finds nothing and warm review found nothing, suspect the review is biased
- Critical findings from automated tools (CodeRabbit, Greptile) should match cold session findings

---

## Failure Mode 5: Missing Deployment Knowledge

### Phenomenon
Code is architecturally correct by general standards. It fails in your specific environment. A polling loop times out on Vercel. A bulk query silently returns 500 rows instead of 2000. An API token in a URL query parameter ends up in your server logs. A UNIQUE constraint allows duplicate NULL rows.

These aren't beginner mistakes. They're environment-specific constraints that require knowing:
- Your specific cloud provider's limits
- Your specific database client's behavior
- Your specific security requirements

AI knows the general patterns but not your specific deployment.

### Mechanism
AI training data includes documentation for all major platforms. But documentation-to-behavior ratio is imperfect: platforms sometimes behave differently than documented, have edge cases that aren't prominent in docs, or have settings that change behavior. AI's knowledge is of the "average" platform behavior, not your specific configuration.

There are also **silent failures** — cases where the platform doesn't error but produces wrong results. Supabase PostgREST doesn't throw an error when you omit `.limit()` on a query that returns 2000 rows. It silently returns 1000. There's no signal to trigger error handling. AI will write the query without `.limit()` because that's the normal pattern, and the code will appear to work until you have more than 1000 rows.

### The Fix
**Deployment Constraints block at the top of S1.** Before writing any error states, you document:
- Runtime environment and its limits
- Database client behaviors that differ from standard SQL
- External API auth requirements
- Background job concurrency behavior

This is the section that's hardest to fill on your first spec because you don't know what you don't know. The review checklist (Pass 1 — Serverless/Platform Constraints) helps catch what you missed.

Over time, your CLAUDE.md accumulates these constraints as project-wide rules, so you don't have to specify them in every spec.

### How to Verify
- Pass 1 of the review checklist covers platform constraints explicitly
- If CodeRabbit or a cold review session catches a platform-specific issue, add it to CLAUDE.md as a project rule
- Your S1 deployment constraints section grows as you learn your environment

---

## The Session Architecture

These five failure modes point to a single structural principle:

**Session boundary = knowledge boundary.**

What happens in Session A stays in Session A. The handoff between sessions is a file — spec, code, diff, review findings — not a continuing conversation.

```
Session 1 (Spec)
  Input: problem statement
  Output: specs/feature.md
  Ends: completely. No continuation.

Session 2 (Implement)
  Input: CLAUDE.md + specs/feature.md (read cold)
  Output: code commits
  Ends: completely.

Session 3 (Review)
  Input: git diff (read cold)
  Output: review findings
  Ends: completely.
```

This architecture:
- Prevents context dilution (fresh attention on every session)
- Eliminates review bias (reviewer has no implementation context)
- Forces explicit handoff artifacts (if it's not in the file, it's lost)
- Enables parallel work (spec and implementation can run in parallel sessions)

The implementation brief (`during-coding/implementation-brief.md`) handles the edge case where Session 2 runs very long and needs to be split — compress current state to 40 lines, open new session, paste brief, continue.

---

## Still need help after reading this?

If you understand the failure modes but still hit them in practice, the cause is usually one of:
1. **Spec is too vague** — S1 has "show error" not a specific message → [failure-patterns.md](failure-patterns.md)
2. **Session discipline slipping** — implementing and reviewing in same session → [worktree-workflow.md](worktree-workflow.md)
3. **CLAUDE.md not updated** — platform constraints learned but not documented → add to CLAUDE.md
4. **S3 was skipped** — integration requirements missing → most common in urgent features

→ [Full workflow guide](worktree-workflow.md)
→ [Failure patterns with examples](failure-patterns.md)
