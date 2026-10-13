# Review Pipeline: Setup + Checklist

Two parts: (1) one-time pipeline setup, (2) per-PR review checklist.

---

## Part 1: Pipeline Setup (one time, ~30 minutes)

### Layer 1 — Local (before every push)

```bash
build-command       # e.g. cargo build / go build / npm run build
lint-command        # e.g. ruff / golint / npm run lint
test-command        # unit tests — catches regressions
git diff --staged   # read every changed line — no exceptions
```

**Gate**: Build passes + every changed line read.

### Layer 2 — Automated (on PR creation)

Drop an AI-review config in your repo root. Run it on every PR; collect severity-rated findings.

**Gate**: 0 Critical + 0 High findings.

**Alternative — Cold session**: A session that wrote the code applies motivated reasoning when reviewing its own work. Open a new session with no history of the implementation. Paste the diff and this checklist.

Review prompt:
```
Read the project context file, then run: <diff command for your VCS>

Apply the review checklist (Pass 1 first, then Pass 2).
Format each finding per the template. AUTO-FIX what you can. Flag the rest as NEEDS INPUT.
```

**Gate**: Same as Layer 2.

### Layer 3 — Human (before merge)

Test behavior. Does the product match the spec? Not "does the code look right" — "does the thing work right."

**Gate**: Spec compliance verified. Error states exercised.

---

## Part 2: Per-PR Review Checklist

**Two-pass review.** Run Pass 1 first (highest severity). Then Pass 2.

**Batch rule**: Collect ALL items needing input. Ask in ONE message at the end — never interrupt the review per finding.

**Finding format**: A finding with no attached evidence is not reported at all.

```
AUTO-FIXED:  [file:line] problem → fix applied
             Evidence: `<quoted line or command output>`
NEEDS INPUT: [file:line] problem — recommended fix: ...
             Evidence: `<quoted line or command output>`
SKIPPED:     [check name] — reason
```

Never fold a skipped check into "passed". A green report is meaningless when skips are hidden.

**Review output**:
```
Pass 1 (Critical): N issues, N skipped
  [findings and skips]
Pass 2 (Informational): N issues, N skipped
  [findings and skips]
[If any NEEDS INPUT]: "I found N items: ..."
If no issues: "Review: No issues found."
```

---

### Pass 1 — CRITICAL (block merge if found)

#### Authentication & Authorization

- Endpoint has no identity check → every handler must verify the caller before touching data
- Missing ownership validation → caller A can read or modify caller B's resource by guessing an ID (IDOR)
- Identity check happens after data access (too late) → move it to the first line of the handler
- New data store or table without row-level access control
- Sensitive field (credential, token, private ID) returned in a response
- Internal-only field exposed to the client

#### Security: Input & Output

- User input reaches a query or command without parameterization → injection risk; use prepared statements or a safe ORM
- Unescaped user content rendered as markup or executable code → sanitize before rendering
- Unvalidated URL used in a redirect or resource reference → protocol injection (example: `javascript:`)
- Error message exposes stack trace, internal path, or schema to the client
- Secret or signed token written to a log

#### Data Safety

- Check-then-act without atomicity: `if (balance >= amount) → deduct()` → two concurrent callers both pass; fix: single atomic operation with a lock or constraint
- Missing unique constraint on a column that must be unique
- Status transition without an atomic guard (`UPDATE … WHERE status = expected`)
- Destructive operation (delete, truncate, drop) without an existence check

#### Race Conditions

- Find-or-create without a unique index → concurrent calls create duplicates
- Deduction or credit change outside a transaction that includes the balance check
- Shared mutable state accessed from concurrent handlers without a lock
- Recurring job without idempotency → two instances run simultaneously → duplicate side effects (fix: atomic claim query, e.g. `UPDATE … WHERE claimed_at IS NULL RETURNING id`)

#### Platform Constraints

- Long-running work inside a short-lived handler → exceeds platform timeout → move to a queue or webhook
- Unbounded query against a large table → silent truncation with no error (example: Supabase PostgREST silently caps at 1 000 rows)
- Secret passed as a URL query parameter → written to access logs, proxy logs, CDN logs → use an `Authorization` header instead

#### Database

- Unique constraint on a nullable column → two NULL rows may both satisfy it, depending on the DB engine (example: PostgreSQL 14 allows this; use `NULLS NOT DISTINCT` or a partial index in PG 15+)

---

### Pass 2 — INFORMATIONAL (fix before merge; most can AUTO-FIX)

#### Static typing

- Overly wide type where a narrow type is known (example: `any` in TypeScript; `interface{}` in Go without a guard) → use a concrete type or a type guard
- Unchecked cast or type assertion instead of a runtime guard — assertions skip runtime checks
- Non-null / non-nil assertion on a value that can realistically be absent → use optional chaining or a guard

#### Async / concurrency

- Async operation not awaited or its error not checked → silent fire-and-forget
- Missing error handling around external I/O (network, DB, file system)
- Background task or listener started without a cancellation or cleanup path → leaked resource on fast navigation or unmount (example: fetch in a React `useEffect` without an `AbortController`)

#### API / service layer

- Handler missing error recovery → unhandled exception returns an opaque response to the client
- Read endpoint with a side effect → reads must be idempotent
- Data access bypasses the designated repository or service layer (example: direct DB call inside a UI component)
- Response shape breaks the client's parser contract

#### State / UI

- Loading, error, and empty states not all handled → blank screen or crash on real traffic
- Persisted state (browser storage, disk, cookie) stores sensitive data (tokens, PII)

#### i18n

- Hardcoded user-facing string → use the translation system
- Key added to code but not to all locale files → missing-key error at runtime in other locales
- Technical error text surfaced to users ("500", "null", "undefined") → use human language

#### Performance

- Unbounded query without a result limit → silent truncation or OOM
- Linear lookup inside a hot loop → replace with an O(1) map or dict lookup
- Dependency added without checking its size impact on build output

---

## Fix-First Heuristic

| AUTO-FIX (no input needed) | NEEDS INPUT (ask first) |
|-|-|
| Missing error recovery around I/O | Auth / authorization logic |
| Unhandled async call | Race condition fixes |
| Hardcoded string → translation key | Security-sensitive changes |
| Log statement left in production | Architectural changes |
| Unused imports or dead code | Changes altering user-visible behavior |
| | Changes > 20 lines |
| | Removing existing functionality |

**Rule**: If a senior engineer applies it in 30 seconds without discussion → AUTO-FIX. If reasonable engineers could disagree → NEEDS INPUT.

---

## Suppressions — do NOT flag these

- Redundant null checks that aid readability
- Threshold values and tuned constants — intentionally set
- Wide types in test files (acceptable in tests, not in production code)
- Dev-only log statements clearly gated by an environment check
- Already-fixed issues — read the full diff before commenting
- Style preferences not enforced by the linter
- Optimizations targeting non-existent bottlenecks
- Tests that cover multiple behaviors — test isolation is not a requirement

---

## Health Metrics

Track weekly. Trends matter more than absolute values.

| Metric | Target | Warning |
|---|:-:|:-:|
| First-try pass rate (0 Critical/High on first push) | > 80% | < 60% → specs missing Failure modes or Integration |
| Median time PR → merge | < 90 min | > 4 hrs → review bottleneck |
| Critical/High findings per PR | < 0.5 | > 1.5 → systematic spec gap |
| Reverts per week | 0–1 | > 2 → architecture misalignment |
| Fix:feat ratio | 1.5–2.5:1 | > 3:1 → improve Failure modes and Integration sections |
