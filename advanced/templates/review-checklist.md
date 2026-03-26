# Review Pipeline: Setup + Checklist

Two parts: (1) one-time pipeline setup, (2) per-PR review checklist.

---

## Part 1: Pipeline Setup (30 minutes, one time)

### Layer 1 — Local (Before Every Push)

```bash
# Run these before pushing any branch
# (adapt commands to your stack)

npm run build       # or: cargo build / go build / python -m pytest
npm run lint        # or: ruff / golint / rubocop
npm test -- --run   # unit tests — catches regressions

git diff --staged   # READ every changed line. No exceptions.
```

**Layer 1 gate**: Build passes + you've read every changed line.

### Layer 2 — Automated (On PR Creation)

Drop `.coderabbit.yaml` in your repo root (template included). CodeRabbit runs automatically on every PR, posts severity-rated findings.

**Layer 2 gate**: 0 Critical + 0 High findings.

### Layer 2 Alternative: Cold AI Session (No CodeRabbit)

**Why cold?** An AI session that implemented the code knows *why* every decision was made. It applies motivated reasoning when reviewing its own work. A cold session — zero context from implementation — sees what the code does, not what it was intended to do. It catches different bugs.

A cold session catches ~70% of CodeRabbit's value — auth/security issues, data safety, integration gaps.

**How to open a cold review session by tool:**

| Tool | How |
|------|-----|
| Claude Code (CLI) | Open a **new terminal window** → run `claude` → do NOT continue the previous session |
| Claude Code (Superset/conductor) | Open a **new tab** → new session starts fresh |
| Cursor | `Cmd+I` or Cursor tab → click **"New Conversation"** at top |
| Windsurf | New conversation window (not a continuation of the current one) |
| Codex / API | New API call with empty `messages` array — no session history |
| Worktree approach | `git worktree add ../review-branch origin/main` → open Claude Code there → sees only the diff, not the implementation context |

**The review prompt (paste into the cold session):**
```
Read CLAUDE.md, then:
git diff origin/main

Apply the review checklist below (Pass 1 first, then Pass 2).
Format each finding: [file:line] Problem → recommended fix
AUTO-FIX what you can without asking. Flag the rest as NEEDS INPUT.
```

If you have gstack: `/review` runs the checklist automatically.

### Layer 3 — Human Behavior (Before Merge)

Test behavior in browser. Does it match the spec? Not "does the code look right" — "does the thing work right."

**Layer 3 gate**: Spec compliance verified. Mobile tested. Error states verified.

### Branch Protection (GitHub Settings → Branches)

```
Branch: main
☑ Require pull request before merging
☑ Require status checks: build, lint
☑ Do not allow bypassing the above settings
```

---

## Part 2: Per-PR Review Checklist

**Two-pass review.** Run Pass 1 first — these are highest severity. Then Pass 2.

**Review output format:**
```
Pass 1 (Critical): N issues
  AUTO-FIXED: [file:line] Problem → fix applied
  NEEDS INPUT: [file:line] Problem — Recommended fix: ...

Pass 2 (Informational): N issues
  [file:line] Problem → fix applied (or needs input)

If no issues: "Review: No issues found."
```

---

### Pass 1 — CRITICAL (Block merge if found)

#### Authentication & Authorization

- API route has no auth check → every endpoint must call `requireAuth(req)` or equivalent at the top
- Missing ownership validation → user A can access user B's resource by guessing an ID (IDOR)
- Auth check happens after DB query (too late) → auth must come before any data access
- Row-Level Security (RLS) missing on new database table → check `db/migrations/*.sql` for RLS policies
- Sensitive field (token, password, private ID) returned in API response
- `f1_source` / primary source field exposed to frontend

#### Security: Input & Output

- User input passed to SQL without parameterization → use prepared statements / Prisma ORM
- `dangerouslySetInnerHTML` with user-controlled data → XSS vector, sanitize first
- Unvalidated URL in `href` or `src` → `javascript:` protocol injection
- Error message exposes stack trace, internal path, or DB schema to client → sanitize errors
- Signed token or secret logged to `console.log` or `console.error`

#### Data Safety

- Check-then-act without atomicity (TOCTOU): `if (balance >= amount) → deduct(amount)` → two concurrent requests both pass the check
- Missing unique constraint on DB column that must be unique
- Status transition without atomic `WHERE old_status = X UPDATE SET new_status = Y` guard
- `DELETE` or `DROP` operation without existence check

#### Race Conditions

- `find-or-create` pattern without unique DB index (concurrent calls create duplicates)
- Credit/balance deduction not in single DB transaction with check
- Shared mutable state accessed from concurrent API routes without locking
- Cron job with no idempotency protection → two instances run simultaneously → duplicate external API calls, double cost (fix: `UPDATE ... WHERE status IS NULL RETURNING id` atomic lock)

#### Serverless / Platform Constraints

- Polling loop inside serverless function → function runtime exceeds platform timeout (Vercel: 10s default, 60s max) → use webhook or queue instead
- Bulk DB query without `.limit()` or pagination → Supabase PostgREST silently truncates at 1000 rows without error
- External API credentials passed as URL query param (`?token=...`) → logged in server logs, Vercel logs, CDN access logs → use `Authorization: Bearer` header

#### PostgreSQL

- `UNIQUE` constraint on nullable column → PostgreSQL treats two NULLs as distinct → allows duplicate `NULL` rows. Use `UNIQUE NULLS NOT DISTINCT` (PG 15+) or a partial index `WHERE column IS NOT NULL`

---

### Pass 2 — INFORMATIONAL (Fix before merge, can AUTO-FIX most)

#### TypeScript

- `any` type → use `Record<string, unknown>` or a proper interface
- Type assertion (`as Foo`) instead of type guard (`if (isFoo(x))`) — assertions skip runtime checks
- Non-null assertion (`!`) on value that could realistically be null — use optional chaining or guard
- `Promise` not awaited in async function → silent fire-and-forget (usually a bug)
- Missing `try/catch` around external API call or DB query

#### Next.js / API Routes

- API route missing `try/catch` → unhandled exception returns 500 with no useful info
- Response returned without `success(data)` / `fail(msg, status)` wrapper (breaks frontend parsing)
- `GET` route with side effects (mutations) — GET must be idempotent
- Missing `Content-Type: application/json` header on API responses
- Environment variable accessed without `process.env.X` check for undefined

#### Supabase / PostgreSQL

- `supabase.from('table')` called directly in a component → must go through `lib/services/db/`
- Error check: `if (error)` not `if (error?.code !== 'PGRST116')` for "not found" cases (returns false positive)
- Selecting `*` from table → select only needed columns (performance + security)
- RPC called without checking `data` is not null before accessing fields
- Bulk query without `.range()` pagination → silent 1000-row truncation (no error thrown)

#### State Management (Zustand)

- Zustand store not cleaned up on component unmount → memory leak + stale state on remount
- Store subscribing to external event (websocket, interval) without cleanup in `destroy()`
- Persisted store (`persist` middleware) storing sensitive data (tokens, PII) in localStorage

#### React / Frontend

- `useEffect` with missing dependency → stale closure bug (ESLint usually catches this)
- `useEffect` fetch without `AbortController` → race condition on fast navigation
- Loading state not shown during async operation → UI freezes
- Error state not shown when API fails → blank screen
- Empty state not handled → `undefined.map()` crash

#### i18n

- Hardcoded user-facing string in component → must be in `messages/*.json` via `useTranslations()`
- String added to component but not to ALL translation files → missing key in other locales
- Translation key referenced in code but not defined in messages file (runtime error)
- Technical jargon in user-facing copy ("Error 500", "null", "undefined") → use human language

#### Performance

- `useEffect` → DB/API call → setState on every render without debounce or dependency fix
- `Array.find` in render loop → convert to object lookup (`Record<id, item>`) for O(1)
- Large image without `loading="lazy"` or `width/height` attributes → CLS
- New npm package added → check bundle size impact (`bundlephobia.com`)

---

## Fix-First Heuristic

| AUTO-FIX (no user input needed) | NEEDS INPUT (ask before changing) |
|---------------------------------|----------------------------------|
| Missing `try/catch` around fetch | Auth/authorization logic |
| `any` type → `Record<string,unknown>` | Race condition fixes |
| Missing `loading` attr on image | Security-sensitive changes |
| Hardcoded string → translation key | Architectural changes |
| Missing `await` on obvious Promise | Anything changing user-visible behavior |
| Console.log left in production | Changes > 20 lines |
| Unused imports / dead code | Removing existing functionality |

**Rule**: If a senior engineer would apply it in 30 seconds without discussion → AUTO-FIX. If reasonable engineers could disagree → NEEDS INPUT.

---

## Suppressions — Do NOT flag these

- Redundant checks that aid readability (`value !== null && value !== undefined` instead of just `value`)
- Thresholds, config values, magic numbers that are intentionally tuned
- `any` types in test files (acceptable in tests, not in production code)
- Dev-only `console.log` marked with `// dev:` or inside `if (process.env.NODE_ENV !== 'production')`
- Already-fixed issues — read the FULL diff before commenting
- Style preferences not covered by ESLint (subjective formatting)
- Optimizations that address non-existent bottlenecks (premature optimization)
- Test code that "exercises multiple behaviors" — tests don't need to be hyper-isolated

---

## Health Metrics

Track weekly. Trends matter more than absolute values.

| Metric | Target | Warning |
|--------|:------:|:-------:|
| First-try pass rate (0 Critical/High on first push) | > 80% | < 60% → specs too vague |
| Median time from PR to merge | < 90 min | > 4 hrs → review bottleneck |
| Critical/High findings per PR | < 0.5 | > 1.5 → systematic spec gap |
| Reverts per week | 0–1 | > 2 → architecture misalignment |
| Fix:feat ratio | 1.5–2.5:1 | > 3:1 → improve spec S1 + S3 |

If first-try pass rate drops below 60%, your specs are missing S1 (Error States) or S3 (Cross-Feature Integration). These two sections prevent 65% of review failures.
