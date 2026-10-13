---
title: "Atomic credit deduction"
status: reconciled
scope: bug
owner: "backend-eng"
approver: "lead-eng"
created: 2026-04-13
approved_at: 2026-04-13
shipped_at: 2026-04-13
reconciled_at: 2026-04-14
---

# Atomic credit deduction

> **Source**: CodeRabbit review comment on PR #312; race condition confirmed by backend-eng on
> 2026-04-12 via load test (2 of 10 concurrent pairs double-charged).

<!--
  Scope: bug. Sections: Why · Verification · Failure modes · QA · File changes · Known issues.
  Acceptance, Invariants and Integration are not written at bug scope.
-->

---

## Why

**Pain** — Two concurrent requests (double-click, or two browser tabs) can both pass the credit
balance check before either writes a deduction. Both charges succeed. The user pays twice for one
action.

**Need** — "I clicked once and was charged twice."

**Proposed** — We will replace the check-then-deduct pair with a single atomic database operation,
not add an application-layer lock, because an application-layer lock does not survive multiple
server instances and introduces a deadlock surface.

**Non-goals** — Credit pricing. Refund UI. Idempotency across different action types.

---

## Verification

Run 2026-04-12 against `main` @ `d4e8a21`.

1. Naming — `usage` table: column is `credits_remaining`. Transaction log table is
   `credit_transactions`, also uses `user_id`. Consistent across three checked locations.
2. Paths — credits logic is in `lib/credits.ts`. No `lib/usage.ts` — the bug report used a
   wrong name; corrected here.
3. Dependencies — database client already installed; no new package required.
4. Env — `DATABASE_URL` present in all environments. No new env vars.
5. Secrets in URLs — no hits for `?key=`, `?token=`, `?session=` in the credits path.
6. Atomicity — confirmed: `lib/credits.ts:44` reads balance then writes in two separate
   queries. Race window exists. Load test result: 2 of 10 concurrent pairs double-charged.
7. Prior art — searched `deduct`, `atomicDeduct`, `credit_deduct`, `CREDIT_DEDUCT` — no
   existing atomic helper. Migration file `db/migrations/012_credits_schema.sql` defines the
   table structure but not a deduction function.

---

## Failure modes

**Deployment constraints**
- Timeout: serverless, 10 s limit. The database call must complete under 2 s to leave margin.
- Data limits: balance column is integer; no silent truncation risk.
- Auth: database credentials are server-side only. They must not appear in client responses or
  URL query strings.
- Concurrency: the fix itself — one atomic database operation. No application-layer lock.

| Condition | System does | User sees | Recovery |
|---|---|---|---|
| Insufficient credits (race-safe check) | Atomic operation returns failure without writing | HTTP 402; body names required and current balance | User adds credits or chooses a cheaper action |
| Negative deduction amount | Rejected at input validation before the database is reached | HTTP 400 | Caller corrects the amount |
| User record not found | Operation returns not-found | HTTP 404 | Re-authenticate; if persistent, contact support |
| Database call times out | No write occurs; timeout propagates as an error | HTTP 503 | Retry is safe — no partial write |
| Duplicate request (same idempotency key) | Returns the original result; no second write | Same 200 as the first call | No action needed |
| Deduction succeeds but downstream action fails | Credits already deducted; refund recorded as a new transaction | Notification: "Credits refunded" | Automatic; no user action |
| Deduction amount is zero | silently does nothing | nothing — by design | — |

---

## QA

- [ ] Happy path: submit one request with sufficient credits → balance decreases by the correct
  amount, one transaction row written.
- [ ] Concurrent: two simultaneous requests, sufficient credits for exactly one → exactly one
  succeeds (HTTP 200), the other returns HTTP 402, balance reflects one deduction only.
- [ ] Insufficient: balance 5, deduction 10 → HTTP 402, balance unchanged, no transaction row.
- [ ] Idempotency: same idempotency key sent twice → one transaction row, balance changed once.
- [ ] Rollback: deduction succeeds, downstream action fails → refund transaction inserted,
  balance restored to pre-deduction value.
- [ ] Timeout: stub the database call to exceed 2 s → HTTP 503 returned, balance unchanged.

---

## File changes

```
MODIFIED:  lib/credits.ts — replace checkCredits()+deductCredits() with atomicDeduct(userId,
           amount, idempotencyKey); callers updated in the same file
ADDED:     db/migrations/014_atomic_credit_deduction.sql — database function that checks
           balance, deducts and logs in a single transaction; returns success flag and new balance
MODIFIED:  api/generate/route.ts — call atomicDeduct() instead of the two-step sequence
MODIFIED:  api/chat/route.ts — same substitution
```

---

## Known issues

- The refund path records a new positive transaction rather than rolling back the deduction
  row. The audit log shows a deduction-then-refund pair instead of a clean no-op. The balance
  is always correct; the optics are not. Accepted for now.
- The idempotency key is caller-supplied. Two of the four callers do not yet provide one;
  deduplication is not guaranteed for those paths. Tracked in issue #319.
