# Feature: [NAME]

<!--
INSTRUCTIONS: Fill every section. Sections marked MANDATORY cannot be skipped.
Feed this completed spec to Claude Code: "Read CLAUDE.md, then implement specs/[this-file].md"
-->

## Overview
[1-2 sentences. What does this feature do from the user's perspective? Not technical — behavioral.]

**Business Goal**: [Why are we building this? What metric does it move? What problem does it solve that users have right now?]
<!-- Examples:
  - "Reduce drop-off at the 3rd step of onboarding by giving users a preview of output before commitment"
  - "Let agents share listings without depending on admin to upload photos"
  - "Block credit overuse without requiring a refund flow"
Embedding the 'why' here prevents AI from building the wrong thing correctly. -->

## Acceptance Criteria

<!--
Separate core behaviors, edge cases, and failure behaviors.
AI handles core behaviors well by default. Edge cases and failures are where it needs explicit instruction.
Each criterion must be testable: "User can X" not "system does Y".
-->

### Core behaviors
- [ ] [Primary success: what the user can do when this feature is complete]
- [ ] [Secondary behavior that must also work]

### Edge cases (must work correctly)
- [ ] [Empty state: no data yet → what does the user see?]
- [ ] [Maximum/minimum: boundary value → what happens?]
- [ ] [Concurrent: two users / two requests simultaneously → what happens to each?]
- [ ] [Partial state: user is mid-flow and something interrupts → what's preserved?]

### Failure behaviors (must fail gracefully)
- [ ] [Unauthorized: user without permission → specific redirect or message]
- [ ] [Invalid input: specific bad input → specific error message (not "Something went wrong")]
- [ ] [External service down: fallback behavior clearly defined]

---

## S1: Error States & Validation (MANDATORY)

<!-- What goes wrong and what does the user see? AI skips this 90% of the time. -->

**Deployment Constraints** (fill before writing error rows — these constrain the architecture):
- Runtime: [serverless? timeout? e.g., "Vercel: 10s default, 60s max" → no polling loops > 60s]
- DB limits: [e.g., "Supabase PostgREST: 1000 rows silent truncate without .limit()" → always paginate bulk queries]
- External API: [rate limits? auth method? e.g., "Apify: Bearer header only, not query param"]
- Background jobs: [cron? queue? If cron → add concurrency row below]

| Condition | User Sees / System Does |
|-----------|------------------------|
| Not authenticated | [Redirect to /login? Toast message? Modal?] |
| Session expired | [Auto-refresh token? Redirect? Toast?] |
| API returns 500 | [Toast with message? Retry button? Fallback UI?] |
| API returns 404 | [Empty state? "Not found" message?] |
| Network offline | [Cached data? Offline banner?] |
| Required field missing | [Inline validation message. Specify exact text.] |
| Data is null/undefined | [Skeleton loader? Default value? Error boundary?] |
| [If background job] Concurrent runs | [Atomic DB lock? Idempotent? Queue? e.g., "UPDATE WHERE status IS NULL RETURNING id — second runner gets 0 rows"] |
| [If external API] Credentials | [Use Authorization: Bearer header — never pass token as query param (gets logged)] |
| [If bulk DB query] Row count > 1000 | [Paginate with .range() — PostgREST silent truncate at 1000 without explicit .limit()] |

## S2: Post-Completion Flow (MANDATORY)

<!-- What happens AFTER the main action succeeds? This is where "works in demo, fails in production" lives. -->

- **On success**: [Auto-save where? Show what? Navigate where? Toast what?]
- **User navigates away mid-flow**: [Auto-save draft? Warning dialog? Discard?]
- **User refreshes page**: [Restore from localStorage? From DB? Start over?]
- **Output constraints**: [Max length? File size? Rate limits?]

## S3: Cross-Feature Integration (MANDATORY)

<!-- How does this feature affect other features? AI builds features in isolation. This section forces integration thinking. -->

- **Triggers**: [Creating X here → refreshes list in Feature Y? Updates count in Feature Z?]
- **Shared state**: [Which Zustand store / context / global state is read or written?]
- **Empty state**: [User has no data yet → show what? Onboarding prompt? Sample data?]
- **Cleanup**: [Leaving this feature → reset which store? Clear which cache? Cancel which request?]

## S4: UX Copy Review (MANDATORY)

<!-- Every user-facing string matters. AI defaults to developer jargon. -->

- [ ] All text reviewed for natural, non-technical language
- [ ] No untranslated strings (if using i18n)
- [ ] Labels/buttons would make sense to a non-developer
- [ ] Feature name: say it out loud — does it sound natural?
- [ ] Error messages: helpful and specific, not "Something went wrong"

## S5: State & Persistence Matrix (MANDATORY)

<!-- Where does each piece of data live? Without this table, AI makes random persistence decisions. -->

| Data | Storage | Persist on refresh? | Cleanup when? |
|------|---------|:------------------:|---------------|
| [Form input] | [Zustand / useState / localStorage] | [Yes/No] | [Leave page / Submit / Never] |
| [Selected item] | [Zustand / URL param] | [Yes/No] | [Leave page / Deselect] |
| [API response] | [SWR cache / Zustand] | [Yes/No] | [Stale time / Leave page] |
| [User preference] | [Database / localStorage] | [Yes] | [Account deletion] |

## S6: Manual QA Scenarios (MANDATORY)

<!-- These are your test cases. Each scenario should have a clear expected outcome. -->

- [ ] Happy path: [Main flow works end to end]
- [ ] Click outside modal → [closes? stays open?]
- [ ] Double-click submit → [prevented? deduplicated?]
- [ ] API fails → user sees [specific message/UI]
- [ ] Loading state → result appears in < [X] seconds
- [ ] Mobile (375px width): [layout doesn't break]
- [ ] Refresh mid-flow: [data preserved? lost? restored?]
- [ ] Empty state: [no data yet → shows what?]
- [ ] Back button: [navigates where? state preserved?]

---

## Before You Return This Spec

<!-- Run through this before handing to an AI agent. Missing items = rework. -->

- [ ] Business Goal written — is it clear *why* this matters, not just *what* it does?
- [ ] S1: At least 5 error scenarios with specific user-visible outcomes (not "show error")
- [ ] S2: Post-completion navigation path defined — where does the user go after success?
- [ ] S3: At least 1 upstream trigger and 1 downstream effect listed
- [ ] S4: Every user-facing string reviewed — no developer jargon, no "Error 500"
- [ ] S5: Every piece of data has a storage location and cleanup condition
- [ ] S6: Includes happy path, at least 1 error path, mobile test, and refresh scenario
- [ ] All acceptance criteria are testable by a human who hasn't read the code

*S1 and S3 prevent 65% of review failures. If you're short on time, be thorough here and brief elsewhere.*

---

## Technical Notes (OPTIONAL)

<!--
⚠️  WARNING: Do NOT include implementation code in specs.
Specs define behavior. AI writes code.
If you paste code snippets into a spec, that code gets used verbatim —
including any bugs in it. This is how "spec-reviewed" code ships with P1 issues.

If you must reference a pattern, write it in prose: "use atomic DB lock, not check-then-act"
NOT: paste an entire TypeScript function body.

Only include if there's a non-obvious technical constraint. Otherwise let AI decide implementation.
-->

**API endpoints involved:**
- `[METHOD] /api/[path]` — [what it does]

**Database tables involved:**
- `[table_name]` — [what columns matter]

**Dependencies on other features:**
- Requires [Feature X] to be complete
- Shares [store/type/constant] with [Feature Y]

---

<!--
TEMPLATE VERSION: 1.0
WHY 6 SECTIONS: Each section targets a specific category of AI-generated bugs.
S1 → Error handling (25% of fixes)
S2 → Post-completion flow (15% of fixes)
S3 → Cross-module integration (40% of fixes)
S4 → Copy/i18n issues (10% of fixes)
S5 → State management (10% of fixes)
S6 → Regression prevention

SPEC QUALITY CHECKLIST:
- [ ] Every acceptance criterion is testable
- [ ] Every error state has a specific user-visible outcome
- [ ] State matrix covers ALL data, not just "important" data
- [ ] QA scenarios include at least: happy path, error path, mobile, refresh
-->
