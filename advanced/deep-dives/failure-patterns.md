# Failure Patterns: What AI Gets Wrong

This document catalogs every category of bug we encountered in 626 commits of AI-generated code. Each pattern includes: frequency, root cause, real examples, and the spec section that prevents it.

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

**Real examples from our project:**
```
fix: platform-to-post mapping race condition in non-blocking loading
fix(chat): align credit deduction branch with pre-check
fix(review): stale context, overflow, cleanup
fix: reply uses structured.message, fallback uses contextMessage
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
fix(security): prevent error.message leak in ErrorBoundary + add i18n
fix(chat): validate session ownership to prevent IDOR vulnerability
fix: address 5 review issues in PR #155 [error handling gaps]
fix(ux): adjust position for mobile bottom nav
```

**Root cause**: AI optimizes for the successful case. Error handling is "defensive" code — the AI doesn't generate it unless explicitly asked because it doesn't imagine failure scenarios.

**Prevention**: S1 (Error States & Validation). For every API call, specify:
- What the user sees on 401, 403, 404, 429, 500
- What happens when the network is offline
- What happens when required data is null

---

## Pattern 3: Security Vulnerabilities (15% of fixes)

**What happens**: AI doesn't think adversarially. It trusts input, logs sensitive data, and doesn't check authorization.

**Real examples we caught (via automated review):**
```
fix(chat): validate session ownership to prevent IDOR vulnerability
fix(security): sanitize href in ReactMarkdown to prevent XSS
fix(security): stop logging full video URL with signed tokens
fix(security): prevent error.message leak in ErrorBoundary
```

**Specific vulnerabilities found:**
- **IDOR**: Chat sessions accessible without ownership check (3 instances)
- **XSS**: Unsanitized markdown rendering in user-generated content (2 instances)
- **SSRF**: Video URL logging included signed S3 tokens (1 instance)
- **Information leakage**: Error messages exposing internal stack traces (4 instances)
- **Missing input validation**: API endpoints accepting unvalidated payloads (multiple)

**Root cause**: Security is adversarial thinking. AI generates code for cooperative users. It doesn't imagine attackers manipulating parameters, injecting scripts, or escalating privileges.

**Prevention**:
1. Security rules in CLAUDE.md ("RLS on all tables. Never expose internal IDs.")
2. Automated security review on every PR (CodeRabbit catches these consistently)
3. Explicit security requirements in specs for auth-adjacent features

---

## Pattern 4: Internationalization (10% of fixes)

**What happens**: AI hardcodes strings in the dominant language. Mixes languages within the same UI. Uses developer jargon in user-facing text.

**Real examples:**
```
fix(i18n): rename Clone/Nhân bản → Duplicate/Tạo bản sao
fix: unblock 35 templates stuck on audience selector [i18n key mismatch]
fix(prompts): revert HUMANSCORE to 5 criteria + CTA to old format
```

**Root cause**: AI generates the string that "makes sense" to it, which is typically English or the most common language in its training data. It doesn't cross-reference i18n key files or check translation completeness.

**Prevention**: S4 (UX Copy Review) + strict CLAUDE.md rule: "No hardcoded user-facing strings. All text via translation system."

---

## Pattern 5: State Management (10% of fixes)

**What happens**: Data saved in wrong location. State not cleaned up on navigation. Persistence inconsistent — some data survives refresh, some doesn't, with no clear pattern.

**Real examples:**
```
fix: keep post status indicators visible + add retry button
fix(ux): hide adaptive input when item selected, sticky create button
fix(cleanup): add useEffect unmount cleanup for timer refs
```

**Root cause**: AI doesn't have a consistent mental model of where data should live. It picks useState, Zustand, localStorage, or URL params based on what "seems right" in the moment, not based on a coherent persistence strategy.

**Prevention**: S5 (State & Persistence Matrix). The table forces a decision for every piece of data:
- Where is it stored?
- Does it survive refresh?
- When is it cleaned up?

---

## War Stories

### The Worktree Collision (Day 16)

Two Claude Code sessions running simultaneously on the same git branch. One session ran `git checkout` which silently reverted files the other session was editing. Hours of work lost.

**Lesson**: Never run parallel AI sessions on the same working directory. Always use git worktrees for isolation.

**Permanent fix**: Added to CLAUDE.md memory: "CRITICAL: Multiple Claude Code tabs share the same working directory — ALWAYS use worktrees."

### The Vietnamese Diacritics Loss (Day 7)

An AI agent generated all documentation without proper Unicode diacritics. Accented characters were stripped throughout — every special character lost. 22 messages of AI interaction produced unusable docs.

**Lesson**: AI strips non-ASCII characters unpredictably, especially in code-adjacent contexts (markdown with code blocks).

**Permanent fix**: Explicit CLAUDE.md rule about preserving Unicode. QA scenario in specs: "Verify all Vietnamese text has correct diacritics."

### The Three Reverted Features (Days 18-22)

Three features were built, tested, merged — then fully reverted:
```
revert: remove TikTok Thumbnail feature
revert: remove Section Selection feature
Revert "feat(auth): Add phone OTP sign-in/sign-up"
```

These weren't technical failures. The code worked. They were **product failures** — features that didn't fit the product vision despite being technically sound.

**Lesson**: AI can build anything you spec. The question is whether you should spec it at all. Product judgment is the irreducible human skill.

### The 113 Context Exhaustions

Over 24 days, we hit context window limits 113 times (~5 per day). Each time required re-establishing context in a new session — re-explaining the project, re-loading relevant files, re-aligning the AI's understanding.

**Cost estimate**: ~15 minutes per context re-establishment × 113 = ~28 hours lost to context management.

**Lesson**: Keep sessions focused and short. Use CLAUDE.md as persistent context. Don't try to do everything in one mega-conversation.

---

## Failure Prevention Checklist

Before feeding a spec to AI, verify:

- [ ] S1 has a specific user-visible outcome for every error scenario
- [ ] S2 defines where data saves and what happens on refresh/navigation
- [ ] S3 lists every shared store, trigger, and cleanup action
- [ ] S4 confirms all strings are in translation files
- [ ] S5 maps every piece of data to storage + lifecycle
- [ ] S6 includes: happy path, error path, mobile, refresh, back button

Time spent on this checklist: ~10 minutes.
Time saved by preventing bugs: ~2-4 hours per feature.
