# Delta: AI Content Consistency Fix (Multi-Platform Fact Alignment)

<!--
This is a REAL production delta spec (anonymized). It fixes a bug where
the same data produced contradictory facts across different platform outputs.
Fix:feat ratio for this spec: 1:1 (clean implementation from clear root cause).
-->

## What's Changing

**MODIFIED**: Content generation pipeline — from independent parallel AI calls to 2-phase generation with locked facts.

**Root cause**: The system generates content for multiple platforms in parallel. Each platform gets its own independent AI call with the same input data as free text. The AI reinterprets free text differently each time:
- Platform A: "2 bedrooms" → AI says "2BR+1" (counted the study as a room)
- Platform B: "2 bedrooms" → AI says "3BR"
- Platform C: "65m²" → AI says "nearly 70m²"

User publishes all three. Customers see contradictory facts. Trust destroyed.

**ADDED**: Structured fact block (JSON instead of free text) + core message generation step (Phase 0) that locks facts before platform-specific adaptation.

**ADDED**: Tone parameter passthrough — the API accepted a `tone` parameter but silently dropped it before reaching the AI. Now it's injected into the prompt.

## What It Touches (scan, don't rely on memory)

```
ls lib/utils/ lib/services/ai/ lib/ai/ app/api/ai/ 2>/dev/null | head -40
```

| Feature | How it's affected |
|---------|-------------------|
| Content generation service | Core change — 2-phase pipeline replaces 1-phase |
| AI provider (prompt layer) | Receives tone + core message injection |
| AI manager (routing layer) | Passes tone parameter through to provider |
| Template generation service | Has the same bug but different pipeline — follow-up issue, not this spec |
| Chat pipeline | Unaffected — uses its own prompt builder |
| Credit system | No change — core message step absorbed into existing cost |

---

## Architecture: Before → After

### Before (buggy)

```
Data (free text) ──┬──► AI call 1 → Platform A content  (facts: 2BR+1, 3.5M)
                   ├──► AI call 2 → Platform B content  (facts: 3BR, ~4M)  ← CONTRADICTS
                   └──► AI call 3 → Platform C content  (facts: 2BR, 3.5M)
```

### After (fixed)

```
Data (structured JSON) ──► AI call 0 → Core Selling Points (facts locked)
                                            │
                            ┌───────────────┼───────────────┐
                            ▼               ▼               ▼
                    AI call 1         AI call 2         AI call 3
                    Platform A        Platform B        Platform C
                    + tone inject     + tone inject     + tone inject
                    (facts locked)    (facts locked)    (facts locked)
```

---

## S1: What Breaks If This Delta Regresses

| Scenario | Handling |
|----------|----------|
| Data record not found | Fallback: skip core message, generate single-phase (log warning) |
| Core message generation fails | Fallback: generate per-platform without core (degrade gracefully) |
| Tone value not in known list | Fallback: use default tone |
| 1 platform fails in parallel | Other platforms still succeed (existing behavior preserved) |
| Data has null fields (no price, no bedroom count) | Structured facts includes nulls → core message skips them → no fabricated data |
| API rate limit hit | Core message = +1 API call. If rate limited → entire generation fails → return error |

---

## S2: Post-Completion Flow

| Scenario | Behavior |
|----------|----------|
| Generation complete | Results returned to frontend as before. Core message NOT exposed to user. |
| User regenerates | 2-phase runs again. Core message may vary in phrasing but facts stay identical. |
| Tone changes between regenerations | OK — core message locks facts, adaptation step changes tone. |
| Credit cost | No increase — core message step absorbed into existing per-platform cost. |

---

## S3: Cross-Feature Integration

| From | To | Impact |
|------|-----|--------|
| `buildStructuredFacts()` | Chat pipeline | Chat can reuse facts for "write a post about this item" |
| `TONE_PROMPTS` map | Chat UI chips | "More professional" chip → same tone key |
| Template pipeline | Template generation service | Follow-up: inject structured facts (separate spec) |
| Frontend tone selector | API endpoint | Frontend passes tone → API already accepted it → now it actually works |

---

## S4: UX Copy Review

- [ ] Tone preset names (`professional`, `friendly`, `dynamic`, `luxury`) — backend only, frontend spec is separate
- [ ] Core message prompt — clear instructions, no ambiguous phrasing
- [ ] Error messages unchanged — "Generation failed. Try again."

---

## S5: State & Persistence Matrix

| Data | Storage | Persist? | Cleanup |
|------|---------|----------|---------|
| Structured facts | In-memory (service layer) | No | Per-request |
| Core message | In-memory (service layer) | No | Per-request |
| Tone | Request param → result object | In result (existing) | N/A |
| Tone prompt map | Constants (code) | Static | N/A |

---

## S6: Regression Scenarios (before → after → expected diff)

### Consistency
- [ ] Generate Platform A + B + C for item with 2 bedrooms, 65m², 3.5M → all three say same facts
- [ ] Generate twice for same item → facts identical (phrasing may vary)
- [ ] Item missing price → content does NOT fabricate a price
- [ ] Item missing bedroom count → content does NOT fabricate a count

### Tone
- [ ] `tone=friendly` → output is conversational, not formal
- [ ] `tone=luxury` → output emphasizes lifestyle, avoids "cheap" language
- [ ] `tone=undefined` → default professional (backward compatible)
- [ ] `tone=invalid_value` → fallback to default

### Backward Compatibility
- [ ] API call WITHOUT structured data → single-phase (existing behavior)
- [ ] API call WITH structured data → 2-phase (new behavior)
- [ ] Template pipeline unaffected
- [ ] Chat pipeline unaffected

### Performance
- [ ] 2-phase total time ≤ 1.5x single-phase (core message is a short prompt)
- [ ] Core message step < 3 seconds
- [ ] Platform calls still parallel (Promise.all)
