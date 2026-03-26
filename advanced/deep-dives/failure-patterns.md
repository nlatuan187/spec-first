# Failure Patterns: What AI Gets Wrong

This document catalogs every category of bug encountered in 626 commits of AI-generated code building a production SaaS. Each pattern includes: frequency, root cause, real examples, and the spec section that prevents it.

**Project**: Production SaaS — 107 API routes, 19 DB tables, 119 React components. 2 developers, 24 days.

---

## The Fix Tax

**Fix:feat ratio: 2.93:1** — for every feature commit, nearly 3 fix commits.

| Commit Type | Count | % |
|-------------|:-----:|:-:|
| `fix:` | 293 | 47% |
| `feat:` | 100 | 16% |
| Merge | 131 | 21% |
| Other | 102 | 16% |

This ratio is NOT a sign of failure. It's the cost of AI-generated code. The question isn't "can we eliminate it?" but "can we reduce it?" We went from 5:1 (week 1) to 1.5:1 (week 4).

---

## Pattern 1: Cross-Module Integration (40% of fixes)

**What happens**: AI builds Feature A perfectly. Builds Feature B perfectly. A and B don't talk to each other correctly.

**Real examples:**
```
fix: platform-to-post mapping race condition in non-blocking loading
fix(chat): align credit deduction branch with pre-check
fix(review): stale context, overflow, cleanup
fix: reply uses structured.message, fallback uses contextMessage
fix(notifications): event not propagating to sidebar badge after creation
fix: search results not clearing when switching between views
```

**Root cause**: AI generates each feature in isolation. It doesn't spontaneously consider how state flows between modules, how events propagate, or how cleanup affects dependent features.

**Why it's 40%**: This is the hardest category because it requires understanding the WHOLE system, not just the file being edited. AI's context window captures the file; the system lives beyond it.

**Prevention**: S3 (Cross-Feature Integration) in every spec. Explicitly state:
- What triggers this feature sends to other features
- What shared state it reads and writes
- What cleanup happens when the user leaves
- What empty state looks like (no data yet)

---

## Pattern 2: Error Handling (25% of fixes)

**What happens**: Happy path works flawlessly. First user with a slow connection, expired session, or missing data hits a blank screen or cryptic error.

**Real examples:**
```
fix(security): prevent error.message leak in ErrorBoundary
fix(chat): validate session ownership to prevent IDOR vulnerability
fix: address 5 review issues in PR #155 [error handling gaps]
fix(ux): missing null check on user.profile before render
fix: API 429 rate limit not handled — silent failure instead of retry prompt
fix: form submission proceeds when required fields are empty
```

**Root cause**: AI optimizes for the successful case. Error handling is "defensive" code — the AI doesn't generate it unless explicitly asked because it doesn't imagine failure scenarios.

**Prevention**: S1 (Error States & Validation). For every API call, specify:
- What the user sees on 401, 403, 404, 429, 500
- What happens when the network is offline
- What happens when required data is null

---

## Pattern 3: Security Vulnerabilities (15% of fixes)

**What happens**: AI doesn't think adversarially. It trusts input, logs sensitive data, and doesn't check authorization.

**Real examples caught via automated review:**
```
fix(chat): validate session ownership to prevent IDOR vulnerability
fix(security): sanitize href in ReactMarkdown to prevent XSS
fix(security): stop logging full resource URL with signed access tokens
fix(security): prevent error.message leak in ErrorBoundary
fix(api): add ownership check before resource update — missing authz
```

**Specific vulnerabilities found:**
- **IDOR**: Resources accessible without ownership check (3 instances)
- **XSS**: Unsanitized markdown rendering in user-generated content (2 instances)
- **Token leakage**: Signed access tokens logged to server logs (1 instance)
- **Information leakage**: Error messages exposing internal stack traces (4 instances)
- **Missing input validation**: API endpoints accepting unvalidated payloads (multiple)

**Root cause**: Security is adversarial thinking. AI generates code for cooperative users. It doesn't imagine attackers manipulating parameters, injecting scripts, or escalating privileges.

**Prevention**:
1. Security rules in constitution ("RLS on all tables. Never expose internal IDs.")
2. Automated security review on every PR
3. Explicit security requirements in specs for any auth-adjacent feature

---

## Pattern 4: Hardcoded Strings & Copy (10% of fixes)

**What happens**: AI hardcodes strings inline. Uses developer jargon in user-facing text. Picks terminology inconsistently across features.

**Real examples:**
```
fix(i18n): rename action label — inconsistent with rest of UI
fix: 35 items stuck because i18n key referenced before translation loaded
fix(copy): "Error 500" shown to users instead of plain-language message
fix(copy): button label uses internal API term, not user-visible term
fix(copy): loading state shows "Loading..." instead of descriptive text
```

**Root cause**: AI generates the string that "makes sense" to it in context. It doesn't cross-reference existing terminology, translation files, or check for consistency across features.

**Prevention**: S4 (UX Copy Review) + explicit constitution rule: "No hardcoded user-facing strings. All text via translation system."

---

## Pattern 5: State Management (10% of fixes)

**What happens**: Data saved in wrong location. State not cleaned up on navigation. Persistence inconsistent — some data survives refresh, some doesn't, with no clear pattern.

**Real examples:**
```
fix: keep status indicators visible + add retry button
fix(ux): hide input when item selected, sticky action button
fix(cleanup): add useEffect unmount cleanup for timer refs
fix: selected item not cleared when navigating to different section
fix: form pre-fills from previous session — localStorage not cleared on submit
```

**Root cause**: AI doesn't have a consistent mental model of where data should live. It picks useState, Zustand, localStorage, or URL params based on what "seems right" in the moment, not based on a coherent persistence strategy.

**Prevention**: S5 (State & Persistence Matrix). The table forces a decision for every piece of data:
- Where is it stored?
- Does it survive refresh?
- When is it cleaned up?

---

## War Stories

### The Parallel Session Collision (Day 16)

Two AI coding sessions running simultaneously on the same git branch. One session ran `git checkout` which silently reverted files the other session was editing. Hours of work lost.

**Lesson**: Never run parallel AI sessions on the same working directory. Always use git worktrees for isolation.

**Permanent fix**: Added to project constitution: "CRITICAL: Multiple AI sessions share the same working directory — always use worktrees for parallel work."

---

### The Three Reverted Features (Days 18–22)

Three features were built, tested, merged — then fully reverted:
```
revert: remove TikTok Thumbnail feature
revert: remove Section Selection feature
Revert "feat(auth): Add phone OTP sign-in/sign-up"
```

These weren't technical failures. The code worked. They were **product failures** — features that didn't fit the product vision despite being technically sound.

**Lesson**: AI can build anything you spec. The question is whether you should spec it at all. Product judgment is the irreducible human skill. Spec-first prevents bad *implementation*. It doesn't prevent bad *decisions*.

---

### The 113 Context Exhaustions

Over 24 days, we hit context window limits 113 times (~5 per day). Each time required re-establishing context in a new session — re-explaining the project, re-loading relevant files, re-aligning the AI's understanding.

**Cost estimate**: ~15 minutes per context re-establishment × 113 = ~28 hours lost to context management.

**Lesson**: Keep sessions focused and short. Use your project constitution as persistent context. Don't try to accomplish everything in one mega-conversation.

**Permanent fix**: Session handoff rule in snippet.md — at 40–60% context, compress state to a brief file and start a new session. Don't wait until broken.

---

## Failure Prevention Checklist

Before feeding a spec to AI, verify:

- [ ] S1 has a specific user-visible outcome for every error scenario (not vague "show error")
- [ ] S2 defines where data saves and what happens on refresh/navigation
- [ ] S3 lists every shared store, trigger, and cleanup action — scanned from codebase, not from memory
- [ ] S4 confirms all strings are in translation files (or are brand names)
- [ ] S5 maps every piece of data to storage + lifecycle
- [ ] S6 includes: happy path, error path, mobile, refresh, double-submit

Time spent on this checklist: ~10 minutes.
Time saved by preventing bugs: ~2–4 hours per feature.

S1 + S3 alone prevent 65% of the patterns listed here.
