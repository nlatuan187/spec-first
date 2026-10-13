---
title: "Two-phase content generation for fact consistency"
status: reconciled
scope: small
owner: "ml-eng"
approver: "lead-eng"
created: 2026-05-01
approved_at: 2026-05-01
shipped_at: 2026-05-02
reconciled_at: 2026-05-03
---

# Two-phase content generation for fact consistency

> **Source**: Support tickets #204 and #211 (user-reported contradictory specs across published
> platforms); root cause confirmed by ml-eng on 2026-04-30 via log review.

<!--
  Scope: small. Sections: Why · Verification · Acceptance · Failure modes · QA · File changes ·
  Known issues. Invariants and Integration are not written at small scope.

  This was a "delta" in an earlier naming scheme. "Delta" is not a scope. The correct scope is
  "small": under a day to build, observable behaviour changes.
-->

---

## Why

**Pain** — The system generates content for multiple publishing platforms in parallel. Each call
receives the same source data as free text and reinterprets it independently. Users have published
contradictions: one platform said "8 GB", another said "16 GB" for the same item on the same day.

**Need** — "I published to three places and each one said something different about the specs.
A customer called to complain."

**Proposed** — We will add a Phase 0 call that extracts structured facts from the source data and
locks them before platform-specific generation begins, not deduplicate outputs by post-hoc
comparison, because post-hoc comparison requires choosing a winning version after contradictions
have already been produced — locking facts upstream removes the contradiction at its source.

**Non-goals** — Tone UI (tracked separately). Template pipeline (same root cause; separate spec).
Chat pipeline. Cost reduction.

---

## Verification

Run 2026-04-30 against `main` @ `c7f3b19`.

1. Naming — tone parameter is `tone` in the API request body and `TONE_PROMPTS` in the constants
   file. Consistent across the two checked locations.
2. Paths — `lib/ai/provider.ts` handles the prompt layer; `lib/ai/manager.ts` routes to it. Both
   exist. No `lib/services/ai/` directory — the draft used a wrong path.
3. Dependencies — AI client installed; no new package needed.
4. Env — `AI_API_KEY` present in all environments. No new vars required.
5. Secrets in URLs — no hits.
6. Atomicity — Phase 0 is a single sequential call before the parallel platform calls. Structured
   facts are passed as an argument; no shared mutable state between phases.
7. Prior art — searched `buildStructuredFacts`, `structured_facts`, `STRUCTURED_FACTS`,
   `factBlock` — no existing implementation. `TONE_PROMPTS` exists at `lib/ai/provider.ts:18`;
   reuse it, do not define a second map.

---

## Acceptance

- WHEN a generation request includes structured source data THEN the system SHALL complete a
  Phase 0 call to extract locked facts before issuing any platform-specific calls.
- IF Phase 0 fails THEN the system SHALL fall back to single-phase generation and log a warning;
  no error is surfaced to the user.
- WHEN facts are locked THEN every platform-specific call in that request SHALL receive the same
  fact block.
- IF `tone` is omitted or unrecognised THEN the system SHALL apply the default tone without error.
- WHEN generation completes THEN the locked fact block SHALL NOT appear in the API response.
- WHEN the request does not include structured data THEN Phase 0 SHALL be skipped and the
  existing single-phase behaviour SHALL run unchanged.

---

## Failure modes

**Deployment constraints**
- Timeout: serverless, 10 s limit. Phase 0 adds one sequential AI call; it must complete under
  3 s to leave room for parallel platform calls.
- Data limits: structured fact block lives in memory for the duration of the request; no
  persistence, no truncation risk.
- Auth: AI API key is server-side only.
- Concurrency: Phase 0 is sequential; platform calls remain parallel.

| Condition | System does | User sees | Recovery |
|---|---|---|---|
| Phase 0 AI call fails | Falls back to single-phase generation; logs warning | Same result as before this change | No action needed |
| Source data has null fields | Structured facts carry the nulls; Phase 0 skips missing fields | Content does not mention the missing field | No action needed |
| Tone value unrecognised | Uses default tone constant | Content in default tone | Caller corrects the tone value |
| One platform call fails in parallel | Other platforms still return (existing behaviour) | Partial result for the failing platform | Regenerate that platform |
| Rate limit hit on Phase 0 | Entire generation request fails | HTTP 429 | Retry after the indicated wait period |
| Request without structured data | Phase 0 skipped; single-phase runs | Same as before — by design | — |

---

## QA

- [ ] Consistency: generate for three platforms with a known fact set → all three outputs state
  the same facts (values identical; phrasing may vary).
- [ ] Null field: item has no price → no platform output fabricates a price.
- [ ] Tone — `tone=friendly`: output is conversational, not formal.
- [ ] Tone — `tone=` omitted: default tone applies; no error returned.
- [ ] Tone — `tone=unknown_value`: falls back to default; no error.
- [ ] Phase 0 failure: stub Phase 0 to return an error → response matches pre-change single-phase
  output for the same input.
- [ ] Backward compatibility: request without structured data → single-phase runs, output unchanged.
- [ ] Fact block not exposed: inspect the API response body → no `structuredFacts` or
  `coreMessage` key present.
- [ ] Performance: two-phase total wall-clock time ≤ 1.5× the pre-change single-phase baseline,
  measured on the same item at the same time of day.

---

## File changes

```
MODIFIED:  lib/ai/provider.ts — add buildStructuredFacts(); inject fact block and tone into
           platform prompt builder
MODIFIED:  lib/ai/manager.ts — add Phase 0 call before parallel dispatch; pass structured facts
           as argument to each platform call
MODIFIED:  api/generate/route.ts — pass tone parameter to manager (was silently dropped before
           reaching the AI layer)
```

---

## Known issues

- Phase 0 adds one sequential AI call. Under a slow or rate-limited AI provider the total
  latency increases even when the wall-clock result is within budget. No mitigation is planned
  for this release.
- The template pipeline has the same root cause: independent parallel calls with free-text input.
  It is not fixed here; tracked in issue #228.
- Facts are locked per request only. If the user regenerates, Phase 0 runs again. Values will
  be identical; phrasing may differ. No deduplication across regeneration runs is planned.
