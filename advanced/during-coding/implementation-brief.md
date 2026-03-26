# Implementation Brief: [FEATURE NAME]

<!--
PURPOSE: This is a compressed spec for long coding sessions.
AI context windows are finite. When a session runs long, paste this brief
into the new session instead of re-reading the full spec.

HOW TO USE:
1. Fill this in at the START of an implementation session (from your full spec)
2. Keep it under 40 lines
3. When starting a new session, begin with: "Continue implementing [feature]. Brief:"
   then paste this document.
4. Update "Current State" as you make progress.

TIME TO FILL: 5 minutes. Time saved: 15+ minutes of context rebuilding per session.
-->

## What We're Building
[1 sentence. User-visible outcome, not technical task.]

## Business Goal
[Why does this matter? What breaks if we don't ship it?]

## Implementation Scope
**Files being created/modified:**
- `[file path]` — [what it does]
- `[file path]` — [what it does]

**Out of scope (do NOT touch):**
- [file or feature that should not change]

## Critical Requirements (from S1 + S3)
<!-- Only the requirements most likely to be missed. Max 5 bullets. -->
- Error: [condition] → user sees [specific message/UI]
- Error: [condition] → user sees [specific message/UI]
- Integration: [this action] → [downstream effect in another feature]
- State: [data] stored in [location], cleared when [condition]
- Constraint: [performance/security/platform limit]

## Current State
<!-- Update this as you implement. Paste at top of next session. -->
- [ ] [Component/file] — not started
- [x] [Component/file] — done
- [ ] [Component/file] — in progress: [what's left]

## Decisions Made
<!-- Record non-obvious choices so the next session doesn't re-litigate them. -->
- Used [approach A] instead of [approach B] because [reason]
- [data] stored in [location] instead of [alternative] because [reason]

## Known Issues / Blockers
- [Issue]: [what's blocking or needs attention]

---
*Spec: `specs/[slug].md` — read the full spec for S2/S4/S5/S6 details*
*Session started: [DATE/TIME]*
