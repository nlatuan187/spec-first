# Verify-Before-Spec

> Run this **before** writing a spec. Paste the output into the spec's `## Verification` section.
> A spec with an empty `## Verification` section is a draft, not a spec.

A spec written from memory describes a codebase that does not exist. Every check below
replaces one assumption with one observed fact. The cost is about five minutes. The
alternative is a spec that is confidently wrong in a way nobody notices until the build
session has already followed it.

This file is the origin of the rule, recorded so it does not get rationalised away:

> On 2026-04-07 two specs were written without reading the code first. They invented file
> paths, used the wrong column convention (`user_id` where the table used `created_by`),
> missed a dependency that was not installed, and missed a token leaked in a URL query
> string. Review found 11 gaps across the two specs. Every one of them was a fact that a
> single command would have surfaced.

---

## The eight checks

Adapt the commands to your stack. The check is mandatory; the command is not.

| # | Check | What you are replacing | Example command |
|---|---|---|---|
| 1 | **Naming convention** | "the column is probably `user_id`" | `grep -rh "created_by\|user_id\|owner_id" db/migrations/ \| sort \| uniq -c` |
| 2 | **Paths that exist** | a path invented from REST convention | `ls app/api/<domain>/` · `fd . src/ -t d -d 2` |
| 3 | **Dependencies present** | "we can just use X" | `grep '"<pkg>"' package.json` · `grep <pkg> go.mod` · `pip show <pkg>` |
| 4 | **Env var names** | a prefix guessed from habit | `grep -rho "process.env.[A-Z_]*" lib/ app/ \| sort -u` |
| 5 | **Secrets in URLs** | "auth is handled elsewhere" | `grep -rn "?token=\|?session=\|?key=\|?api_key=" app/ src/` |
| 6 | **Atomicity** | a check-then-write you did not notice | For any dedup / lock / idempotency: confirm a single atomic operation (`INSERT … ON CONFLICT`, unique constraint, compare-and-swap) rather than read-then-write |
| 7 | **Prior art** | a feature you are about to rebuild | `grep -rn "<the-noun>" --include='*.<ext>' . \| head -30` with **at least three spellings** |
| 8 | **Reachability** | "the file is there, so that is the code that runs" | from the file checks 2 and 7 found, walk importers back to a shipped entry point: `grep -rn "from '.*<module>'" --include='*.<ext>' .` |

**Check 7 needs its own rule.** A single spelling misses the thing you are looking for.
A real example: searching `auto-save` missed `autoSaveTimerRef`; searching `tone` missed
`TONE_CONFIGS`. Search the hyphenated, camelCase, snake_case and UPPER_SNAKE forms:

```bash
grep -rn "auto.save\|autosave\|autoSave\|AUTO_SAVE\|debounce.*save" src/ lib/
```

**Check 8 is what stops a spec being written against code that no longer runs.** Checks 2
and 7 prove a path exists and a prior implementation exists. Neither proves it ships. Four
states, and only the first is safe to spec against without a label:

| State | Test | What to write |
|---|---|---|
| **Live** | reachable from a shipped entry point — a route file, a page, a job registration, a `main` | name it as the path |
| **Legacy-but-live** | still imported, kept as a fallback | name it, labelled as the fallback — never as the primary flow |
| **Unreleased** | merged but behind a default-off flag, or not surfaced | name it, labelled not-shipped, with the flag |
| **Dead** | no importer from any entry point, test or script | do not cite it at all |

A filename is not a signal: `v2`, `new`, `old` and `legacy` in a path say what somebody
intended, not what runs. Trust the importer chain. If one area keeps costing you this
check, write the result down once as `docs/system/<area>.md` — that is what the system
document is for, and the next spec reads it instead of re-deriving it.

---

## Recording the result

Each check produces one line in the spec. Lines are facts, not reassurances.

```markdown
## Verification

Run 2026-10-13 against `main` @ `a1b2c3d`.

1. Naming — `db/migrations/` uses `created_by` on 11 of 13 tables; `sessions` and
   `audit_log` use `user_id`. This feature touches `sessions` → use `user_id`.
2. Paths — `app/api/properties/import/confirm/` exists. There is no `import/start`.
3. Dependencies — `tsx` is NOT in package.json. Spec must add it or avoid it.
4. Env — prefix is `NEXT_PUBLIC_` for client-visible vars; `SUPABASE_SERVICE_KEY` is
   server-only and already present.
5. Secrets in URLs — one hit: `app/auth/callback/route.ts:22` reads `?session=`.
   Out of scope for this change; filed as a separate issue.
6. Atomicity — the dedup path at `lib/queue/jobs.ts:88` is read-then-write. This spec
   changes it to `ON CONFLICT DO NOTHING`.
7. Prior art — `retry`, `retries`, `RETRY_LIMIT`, `backoff` → existing helper at
   `lib/net/retry.ts:14`. Reuse it; do not write a second one.
8. Reachability — `lib/net/retry.ts` is imported by `app/api/properties/import/
   confirm/route.ts` → live. The older `lib/retry/index.ts` has no importer outside its
   own test → dead, not cited in this spec.
```

"No hits" is a result. Write it down. A check with no recorded outcome did not happen.

---

## Why this is a gate and not advice

The facts above are inputs to decisions the spec makes. If check 1 is wrong, every query
in the spec is wrong. If check 3 is wrong, the build session stops on an install step
nobody planned. If check 7 is wrong, you ship a second implementation of something that
already works — and now both drift.

**A spec that is missing a `## Verification` section is rejected, even if every other
section is complete.** Completeness of form is not evidence of contact with the code.

---

## What this does not cover

These checks find *facts about the repository*. They do not find facts about **users**,
**production** or **money**. Those come from elsewhere and belong in the spec's
`## Why` and `## Thresholds` sections:

- A user quote comes from a user, not from grep.
- A latency budget comes from a measurement, not from an opinion.
- A platform limit comes from the platform's documentation, with the URL recorded.

If a number appears in your spec and none of the eight checks could have produced it,
`## Thresholds` must say where it came from — including "chosen arbitrarily on
2026-10-13", which is honest and tells the next reader the number is free to change.
