## Spec-First — AI Development Methodology

> Paste into your AI context file — CLAUDE.md, .cursorrules, .windsurfrules, AGENTS.md,
> or .github/copilot-instructions.md. Works with any AI tool that reads a context file.

---

### The Fundamental Law

**AI generates the most statistically probable next token — not the correct one. It has no judgment. Only probability.**

Every rule in this methodology derives from this single law. When you understand it, you can engineer AI behavior for any situation not covered here.

---

### Project Constitution

Your AI context file (CLAUDE.md / .cursorrules / etc.) **is your project constitution** — the document that anchors every AI decision to your stack, conventions, and constraints.

Before any session: the AI reads the constitution. Every spec, every review, every debug starts from the same ground truth.

*If you don't have one, create it now. Minimum: tech stack, key file paths, API patterns, auth method.*

---

### Four Session Types

Features move through sessions based on scope. Small scope (bug fix, small change): Spec + Build collapse into one session. New features and above: four cold sessions, each starting with zero context from the previous:

| Session | AI reads | AI produces | Terminal action |
|---------|----------|-------------|-----------------|
| **Clarify** | Constitution + feature request | 3 questions max | Wait for answers |
| **Spec** | Constitution + answers | `specs/[slug].md` | Scope Routing (see below) |
| **Build** | Constitution + spec | Working code | "Start new session to review" |
| **Review** | Constitution + diff | Pass 1 + Pass 2 findings | "No new session needed" |

Scope Routing collapses Spec + Build into one session for small scope (bug fixes, small changes). New features and above always use a cold Build session.

*Derives from: Each session type has a different most-probable-next-token profile. Mixing types imports probability bias. The exception: bug fix scope is small enough that spec-build contamination risk is tolerable — 1.5:1 fix ratio even without session separation. New feature scope is not.*

---

### TRIGGER: When asked to build, implement, create, add, fix, refactor, or debug

**Step 0 — Route the intent**: Match the user's request to the **Formality Dial** below — one table, one lookup, correct format.

**Step 1 — Clarify** (skip if intent is unambiguous):

Read the constitution. Then check: can you answer all three?
- What is the exact trigger (user action or system event)?
- What is the success outcome (what does the user see when it works)?
- Is this one operation, or multiple features bundled?

If any is unclear from the request + constitution, ask those questions. Maximum 3. About observable behavior only — never about implementation. Wait for answers.

**Terminal state**: Do not write the spec until all questions have answers.

*Derives from: The most probable next token after an ambiguous request is a confident-sounding wrong answer.*

---

**Step 2 — Spec:**

1. Say "Writing spec first…"
2. Use the format from Step 0 (Formality Dial match)
3. Create `specs/[feature-slug].md` with YAML frontmatter (title, status, scope, s1_count, s3_count)
4. Fill every section — no placeholder text
5. Update `s1_count` and `s3_count` in frontmatter after writing S1 and S3
6. End with the **Scope Routing** block below.
7. Write **zero implementation code** until Scope Routing has run.

**Terminal state**: Scope Routing determines what happens next — not a fixed "open new session" rule.

*Derives from: "Continue with implementation" is 10x more probable than "stop and wait." Scope Routing replaces the blanket stop with a data-driven decision.*

---

### Scope Routing — runs after every spec

After writing the spec, read what you just wrote and output the matching block:

| S1 error states | S3 integration points | Category | Route |
|---|---|---|---|
| ≤ 3 | ≤ 1 | Standard | **Autonomous** |
| 4–7 | 2–3 | Standard | **Recommend review** |
| ≥ 8 | ≥ 4 | Any | **Review required** |
| any | any | High-risk† | **Review required** |

†High-risk: auth, payments, database schema changes, data migration, user PII, infrastructure-as-code (Terraform/K8s).
Autonomous requires **both** thresholds met (AND). All other routes trigger on **either** column alone (OR).

**Autonomous** — implement in this session, no break:
```
━━━ Spec written: specs/[slug].md ━━━
Scope: [Bug fix / Small change] — [N] error states, [N] integration points.
Implementing now. Key risks from S1: [list items].
```
Then immediately, without waiting:
1. Re-read the spec you just wrote
2. If the project has a test framework: write failing tests from S6 scenarios before implementing
3. Implement — handle every S1 error state explicitly in code
4. If S3 has integration points: verify those touchpoints are covered
5. If stuck after 2 attempts: follow Debugging Protocol (write debug file, new session)
6. When done: run `/spec-check specs/[slug].md` and surface any gaps

**Recommend review** — output block, then wait:
```
━━━ Spec written: specs/[slug].md ━━━
Scope: New feature — [N] error states, [N] integration points.
Review recommended before implementing.
→ Run /spec-review specs/[slug].md in a new session — APPROVED to build, BLOCKED to fix.
→ Say "skip review" to implement now — accepts ~25% higher error rate (Pattern 2 data).
```
If user says "skip review": follow the Autonomous steps above in this session.
If user says "implement" (after /spec-review returns APPROVED): tell user to start a new session with the spec loaded.

**Review required** — output block, then stop:
```
━━━ Spec written: specs/[slug].md ━━━
Scope: [Large / High-risk] — [N] error states, [N] integration points.
Human review required. [Auth/payment: 15% security bug rate in production data.]
Run /spec-review specs/[slug].md — must return APPROVED.
Then: a human must read specs/[slug].md before implementing. /spec-review is a mechanical gate — it does not replace adversarial judgment for auth/payments/PII.
```
Do not implement regardless of user override request.

*Derives from: Scope maps to failure probability — not preference. Bug fixes tolerate autonomous (1.5:1 fix ratio). Auth features do not (15% security bugs in production data). The data determines the route.*

---

### Formality Dial — route intent, match spec depth to scope

| Scope | Trigger keywords | Spec format | Sections |
|---|---|---|---|
| **Emergency** | production down, urgent, hotfix | Fix first → retroactive Bug Format | S1 + S6 |
| **Bug fix** | fix, broken, bug, error, crash | Bug Format | S1 + S6 |
| **Small change** | change, update, modify (< 1 day) | S1 + S3 + S6 | 3 sections |
| **Spike** | explore, spike, investigate | No spec yet → spec chosen approach | S1 + S3 |
| **Refactor** | refactor, reorganize, move, split | Refactor Format below | S3 + S6 |
| **Brownfield delta** | *(modify existing behavior)* | Delta Format below | Depends on scope |
| **New feature** | build, add, create, implement | Full S1–S6 | All 6 |
| **Large feature** | *(scope assessment)* | Full S1–S6 + Implementation Notes | All 6 + notes |

If intent is unclear, default to **New feature** (Full S1–S6).

*Derives from: Without explicit routing, AI defaults to Full S1–S6 — the most probable format, not the correct one. A bug fix doesn't need S2/S4/S5. A refactor doesn't need S1. One table, correct format.*

*Formality scales down for small scope. Session separation scales down too — bug fixes implement in the same session as the spec. New features and above always use a cold Build session.*

**Skill dial — which tools to use:**

| Scope | Skills |
|---|---|
| Bug fix | `/spec` → [Build] → `/spec-check` |
| Small change | `/spec` → [Build] → `/spec-check` |
| New feature | `/spec` → `/spec-review` → [Build] → `/spec-check` |
| Large / Auth | `/spec` → `/spec-review` → [human reads spec] → [Build] → `review.md` → `/spec-check` |

**Measuring health**: Run `/spec-stats` weekly — shows fix:feat ratio, spec coverage, S1/S3 quality, and a health score out of 10.

Claude Code: `install.sh` auto-installs all four when `.claude/` is detected. Other tools: copy each `SKILL.md` from `advanced/skills/` to your commands directory.

---

### Delta Format — for changes to existing code

When modifying existing behavior (not adding new features), use delta format:

```
## What's changing
ADDED: [new behavior or field]
MODIFIED: [existing behavior → new behavior]
REMOVED: [behavior being deleted and why]

## What it touches (scan, don't rely on memory)
ls [your-source-dirs] 2>/dev/null | head -40

## S1: What breaks if this delta regresses
[error states specific to the change — not the whole feature]

## S6: Regression scenarios
[specific test: before delta → after delta → expected diff]
```

*Derives from: Describing the whole system when only a delta is changing is low-probability-of-accuracy. Delta format forces contact with what's actually different, reducing hallucination of the full system state.*

---

### Refactor Format — for structural changes that preserve behavior

When restructuring code (renaming, moving, splitting, merging) without changing what the code does:

```
## What's being restructured
[describe the structural change — what moves where, what gets renamed/split/merged]

## Behavior that MUST NOT change
[list specific behaviors that must work identically after refactoring]

## What references it (scan, don't rely on memory)
grep -r "FunctionName\|ClassName\|import_path" [your-source-dirs] --include="*.[ext]" | head -30

## S3: Every file that needs migration
| File | How it references the thing being changed | Migration needed |
|------|------------------------------------------|-----------------|

## S6: Regression — verify behavior is preserved
- [ ] [Specific behavior] still works after refactoring
- [ ] [Specific behavior] still works after refactoring
```

*Derives from: Refactoring is the #1 case where AI skips the scan — "I'm just moving code, nothing can break." But grep reveals 15 files importing the old path. Without the scan, 15 files break silently.*

---

### S1 Rule — Write failures BEFORE the happy path

Open S1 by answering: *"What breaks? Who is unauthorized? What's missing or null?"*
List those first. The happy path is last.

Fill **Deployment Constraints** before writing any error rows. Check your stack — common constraints by platform:

| Constraint | Web / Serverless | Mobile | Backend / Infra |
|---|---|---|---|
| **Timeout** | Vercel 10s, Lambda 15s, Cloud Run 300s | iOS background task 30s, Android ANR 5s | Queue visibility timeout, gRPC deadline |
| **Data limits** | PostgREST 1000-row silent truncation | Core Data batch fetch limits, SQLite page size | Connection pool exhaustion, Redis maxmemory |
| **Auth / secrets** | Never token in URL (server logs capture) | Keychain / Keystore only (not UserDefaults/SharedPrefs) | Secrets in env vars, not config files (rotate via vault) |
| **Concurrency** | Atomic lock for cron/background jobs | App killed mid-write → atomic save required | Dead-letter queue for failed messages, circuit breaker for downstream |
| **Offline / network** | Service worker cache strategy | Offline queue + sync on reconnect (mandatory for mobile) | Health checks, DNS propagation, cert expiry |

*Derives from: Training data is ~10:1 success-to-failure. Low-frequency patterns (serverless timeouts, DB truncation) have low probability — they must be stated explicitly.*

---

### S3 Rule — Enumerate ALL integrations before writing the section

Before writing S3, enumerate existing features from the codebase — not from memory:

```bash
# Find what actually exists — adapt paths to your stack:
# Web: lib/services/ app/api/ components/   Mobile: src/screens/ src/services/ src/navigation/
# Backend: cmd/ internal/ pkg/ src/main/    Infra: modules/ terraform/ k8s/
ls [your-source-dirs] 2>/dev/null | head -40
```

For each result: does this new feature read from it or write to it?
An S3 with no rows is almost always wrong.

**Brownfield addition — find who else touches the same data:**

```bash
grep -r "ServiceName\|table_name" [your-source-dirs] --include="*.[ext]" | head -20
```

`ls` finds files. `grep` finds relationships. For any delta to existing code, run both.

*Derives from: Memory-based enumeration misses features that exist in code but weren't mentioned in conversation. Scanning forces contact with reality.*

---

### Code Rule — Never write code without reading a spec

This rule exists because the TRIGGER workflow above is the first thing AI rationalizes away. The TRIGGER defines the workflow. This rule is the safety net.

Before writing implementation code: check if `specs/[slug].md` exists for this change.
- If spec exists: **read it first**, then implement.
- If no spec exists: **write one first**, using the Formality Dial for depth.
- Emergency hotfix: fix first, write retroactive bug spec after.

**Terminal state**: Code written without a spec is code written from the AI's default probability distribution — which includes every failure mode in the table above.

*Derives from: The most probable next token after "implement this feature" is confident-sounding code that skips error states, misses integrations, and works only on the happy path. A spec overrides probability with specificity. This rule is read at session start and decays with conversation length — re-read it if context exceeds 40%.*

**Mechanical enforcement** (Claude Code): The `pre-tool-use` hook blocks Write/Edit on source code when no spec exists in `specs/`. Config, docs, markdown, and test files are never blocked. Bypass: `touch .spec-first-bypass` or `SPEC_FIRST_ENFORCEMENT=off`. Other tools: this text is the enforcement.

---

### Session Rule — Never review code you just wrote

When asked to review: open a **new session** → paste the diff → apply the checklist.

**Terminal state**: A session that wrote code cannot review it. No exceptions. Not even "just a quick check."

*Derives from: "The code is correct" is the most probable continuation of an implementation session. A cold session has no motivated reasoning.*

---

### Debugging Protocol — when implementation is stuck

Before the first fix attempt: state the root cause hypothesis.
*"I believe the error is caused by [X] because [Y evidence]."*
If you cannot state this, investigate first — read the full stack trace, check recent changes, trace data flow to the error source.

*Derives from: "Try a variation" is 10x more probable than "find the cause." Fixing without root cause compounds probability error — each attempt that fails makes the next wrong attempt more probable.*

If the same error persists after 2 fix attempts, stop. Do not try a third variation.

Write `specs/[slug]-debug.md`:
```
Error: [exact message + file:line]
Attempt 1: [what was changed] → [result]
Attempt 2: [what was changed] → [result]
Hypothesis: [what you think is wrong]
Next approach: [one specific different angle]
```

Open a new session → read spec + debug file → fresh context → different approach.

**Terminal state**: After 2 failed attempts, the only valid action is a new session.

*Derives from: After 2 failures, "try a slight variation" is the most probable continuation — and probability compounds errors. A new session breaks the loop.*

---

### Project Memory — accumulate what you discover

After discovering something non-obvious about this codebase that would affect future sessions, append it to `KNOWLEDGE.md`:

```
## [YYYY-MM-DD] [area or feature]
- [specific pattern, gotcha, or rule — concrete enough to act on]
```

Examples of what belongs here:
- Ordering constraints: "DeductCredits must be called AFTER the DB write — calling before causes phantom charges on rollback"
- Silent failures: "PostgREST truncates at 1000 rows with no error — always `.range()` on list queries"
- Platform specifics: "Vercel timeout is 10s — any loop touching external APIs needs chunking"
- Convention discovered: "All mutations go through lib/services/db/ — never write direct Supabase calls in API routes"

At the start of every Build session: read KNOWLEDGE.md before writing any code.

**Signal vs noise**: Only append patterns that recur. One-off quirks are noise. If the same issue appears in 2+ sessions, it belongs in KNOWLEDGE.md. If it appears in 3+ sessions, promote it to your constitution — it's a rule now, not an observation.

*Derives from: Context windows don't persist. A lesson discovered in session 3 is invisible in session 30. KNOWLEDGE.md moves project-specific knowledge from your memory to the codebase — where it survives. The 2+ occurrences filter prevents it from becoming a junk drawer.*

---

### Session state — continuity across sessions

At session end (or when context hits 40–60%), write `.claude/session-state.md`:

```
Goal: [what this session is trying to accomplish]
Spec: specs/[slug].md
Status: speccing | building | reviewing | done
Done: [completed items]
Current state: [what works / what's broken]
Next action: [one specific next step]
Key files: [paths that matter for continuation]
Blocked: [current blocker, if any]
```

Next session: the SessionStart hook auto-injects this file. No manual copy-paste needed. Add `.claude/session-state.md` to `.gitignore` — it's volatile per-session data, not shared.

For longer handoffs (different developer, next day), also write `specs/[slug]-brief.md` with full context.

*Derives from: Attention mechanism weights recency. At 40-60% context, early tokens have degraded recall. Writing the brief moves critical context to the start of the next session.*

---

### Spec hygiene — keep specs/ useful

Add `Status: Done` to shipped specs and move them to `specs/done/`. When a done spec contradicts current behavior, update or delete it — a stale spec is worse than no spec.

*Derives from: 50 unorganized files have the same effect as 0 files — AI can't find the relevant one. The rule that matters: done specs can't mislead if they're accurate.*

---

### Constitution maintenance — when your context file gets too long

If your constitution (CLAUDE.md / .cursorrules) exceeds ~200 lines, AI attention to later rules degrades. Prune:

1. **Move stack-specific details** to separate files: `docs/conventions.md`, `docs/security.md`. Reference them with one line, not inline content.
2. **Remove rules encoded in linters, type definitions, or CI checks** — those are enforced without AI reading them.
3. **Keep high-signal rules only** — constraints the AI would violate without being told.

*snippet.md is ~400 lines — trim it before pasting. Include sections that apply to your team; delete the rest. A constitution with 10 relevant rules outperforms one with 50 diluted by 40 irrelevant ones.*

*Derives from: At 500 lines, rules at line 400 have measurably lower compliance than rules at line 50. The constitution read at every session must be worth reading.*

---

### Rationalizations — reject these

| If you think this | The answer is |
|---|---|
| "This feature is too simple to need a spec" | Simple features have the most skipped edge cases. Spec takes 10 minutes. Debugging takes hours. |
| "I'll write the spec after prototyping" | You will rationalize away the error states you discovered while building. |
| "This is just a bug fix, not a feature" | Bug fixes use Bug Fix format: S1 + S6. Same principle, 10 minutes. |
| "This is just a refactor, not a change" | Refactors without S3 break hidden dependencies. The grep takes 2 minutes. The broken imports take hours. |
| "Production is on fire, no time for spec" | Fix first. Then write a 5-minute retroactive bug spec — what broke, what you changed, what else could break. The hotfix that causes a second outage costs more than the spec. |
| "The spec is in my head" | Unwritten specs have no S1. Every bug is an unwritten S1. |
| "I don't know what I'm building yet" | Spike: explore freely. When approach is chosen, write the spec for that approach — not what you tried. One chosen approach, one spec. |
| "Requirements changed mid-build, spec is now wrong" | Update the spec first — 5 minutes. Implement from the updated spec. An outdated spec is an unwritten spec. |

---

### Team Mode (3+ developers, any scale)

The 5 failure modes apply at every team size — they get worse, not better, as teams grow. What scales is process, not methodology.

If this constitution is shared across a team, three additional rules apply:

**1. Constitution has an owner.** Changes go through PR review. Anyone proposes; only the designated owner merges. At 10+ devs: senior dev per domain area, quarterly audit of outdated constraints.

**2. Approval gate.** Specs have a Status field: `Draft → In Review → Approved → Implementing → Done`. The Build session only starts when Status = Approved. Do not implement a Draft spec.

**3. PR template.** Every PR references its spec file and has S6 QA scenarios checked off. See `advanced/team-workflow.md`.

*Solo config: ignore this section. Self-approve specs and proceed.*

---

### The 6 Spec Sections (S1–S6)

| # | Section | Question it answers |
|---|---------|-------------------|
| S1 | Error States & Validation | What breaks, and what does the user see? |
| S2 | Post-Completion Flow | Where does the user go after success? |
| S3 | Cross-Feature Integration | What other features does this touch? |
| S4 | UX Copy Review | Is every user-facing string plain language? |
| S5 | State & Persistence Matrix | Where does each piece of data live? |
| S6 | Manual QA Scenarios | Can a human verify this without reading code? |

Spec template → `spec.md`
Review checklist → `review.md`
