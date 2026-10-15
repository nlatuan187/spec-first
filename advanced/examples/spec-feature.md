---
title: "Content generation from templates"
status: reconciled
scope: feature
owner: "product-eng"
approver: "lead-eng"
created: 2026-04-01
approved_at: 2026-04-03
shipped_at: 2026-04-10
reconciled_at: 2026-04-11
---

# Content generation from templates

> **Source**: User interviews Q1-2026 (14 active users); product review 2026-03-28. Interview
> notes in `docs/research/q1-2026-content-workflow.md`.

<!--
  Scope: feature. All mandatory sections required. Optional Copy and State sections included
  here because this feature introduces new user-facing strings and non-trivial client-side state.
  Mental model and Pre-reading are omitted: state is split across two stores only, which does
  not meet the threshold for Mental model.
-->

---

## Why

**Pain** — Users produce content for the same inventory item on multiple platforms by writing
each post from scratch. Among the 14 interviewed, 11 manage 3 or more platforms and publish at
least 4 times per week. There is no shared starting point: each platform gets a blank editor.

**Need** — "I waste time rewriting the same facts for every platform. I just want something to
edit, not a blank page."

**Proposed** — We will let users select a pre-written template, attach it to an item from their
inventory, and generate a platform-adapted draft in one action, not build a free-form AI prompt
interface, because free-form requires the user to already know what to ask — a template makes the
decision surface concrete and the output predictable.

**Non-goals** — Auto-publishing. Template authoring by end users. Bulk generation across all
inventory items at once.

---

## Guards

- Approver ruled on 2026-04-03: generation is reachable from the item detail page only. No
  entry point in the list toolbar, no bulk action — those were asked for and refused.
- The provider key is read server-side only. It must not reach the client bundle, a client
  error payload, or a log line, including on the failure paths below.
- Do not merge before the rate-limit table exists in staging. The generation route reads it
  on every request and fails closed if it is missing.

---

## Verification

Run 2026-04-01 against `main` @ `f1c9a48`.

1. Naming — credit balance is in `usage` table, column `credits_remaining`. Transaction log is
   `credit_transactions`, keyed by `user_id`. Client-facing API field is `creditsRemaining`
   (camelCase). Consistent across the three checked locations.
2. Paths — `api/templates/` exists (list endpoint only; a per-template metadata endpoint does
   not exist and must be added). `api/generate/` does not exist and must be created.
   `components/editor/PostEditor.ts` exists and accepts a `content` prop.
3. Dependencies — AI client installed; state library installed. No new packages needed.
4. Env — `AI_API_KEY` and `API_BASE_URL` present. No new env vars required.
5. Secrets in URLs — no hits for `?key=`, `?token=`, `?api_key=` in the generation path.
   Credit balance is checked via POST body, not a query string.
6. Atomicity — credit deduction is a separate call from the AI call (check → AI → deduct). A
   concurrent-deduction race exists in the current deduct path; a separate bug spec covers it.
   This feature inherits that risk and documents it under Known issues.
7. Prior art — searched `useContentStore`, `generatedContent`, `templateId`, `content_store`,
   `CONTENT_STORE` — `useContentStore` (or equivalent) exists in `store/content.ts`;
   `generatedContent` and `templateId` fields do not exist. Confirmed: extend the existing
   store; do not create a second one.
8. Reachability — `store/content.ts` is imported by the generate page and the history
   panel → live. `components/templates/TemplatePickerV1.tsx` has no importer → dead; the
   new picker is built from the live `TemplatePicker`, not from it.

---

## Acceptance

- WHEN a user selects a template THEN the system SHALL display the template's description and an
  example output before they proceed to generation.
- WHEN a user reaches the generation screen THEN only inventory items belonging to their own
  account SHALL be selectable.
- WHEN the user submits a generation request THEN the system SHALL produce a draft within 10
  seconds or surface a recoverable error.
- IF the user has no inventory items THEN the Generate button SHALL be disabled and the screen
  SHALL show a prompt to create one.
- IF the user has insufficient credits THEN the system SHALL surface the shortfall before the
  AI call is made.
- WHEN generation succeeds THEN the draft SHALL be saved automatically and credits SHALL be
  deducted exactly once.
- WHEN the user navigates away during an active generation THEN the draft SHALL be saved on
  completion and available in the drafts list.
- WHILE generation is running THEN the user SHALL see a loading indicator and SHALL NOT be able
  to submit a second request.

---

## Failure modes

**Deployment constraints**
- Timeout: serverless, 10 s hard limit. The AI call must complete in under 8 s to leave margin
  for credit deduction and draft save.
- Data limits: platform character limits are enforced server-side; the client display is advisory.
  Drafts stored indefinitely until explicit delete or 30-day expiry.
- Auth: AI API key is server-side only. Credit balance may appear in error responses but only
  the amount the user already knows (their own balance and the required amount).
- Concurrency: credit check and deduction are two separate calls (see Known issues). The Generate
  button is disabled during an in-flight request; this is the only UI-layer concurrency guard.

| Condition | System does | User sees | Recovery |
|---|---|---|---|
| Not authenticated | Redirects to login with the return URL preserved | Login screen | Log in and return |
| No item selected | Blocks submission | Generate button disabled; tooltip "Select an item first" | Select an item |
| Insufficient credits | Returns shortfall before the AI call is made | Modal showing required and current balance plus an upgrade path | Add credits, or choose a lower-cost action |
| AI API returns 5xx | Returns error; no credit deducted; no draft saved | Toast "Generation failed. Try again." with a Retry button | Retry |
| AI API returns 429 | Returns rate-limit error; no credit deducted | Toast "Too many requests. Wait 30 seconds." | Wait and retry |
| Template not found (deleted after selection) | Returns 404 | Redirect to template library; toast "Template no longer available" | Choose a different template |
| Item data incomplete | Generates with missing fields; returns warning | Warning banner naming the missing field; generation proceeds | User adds the missing data and regenerates |
| Draft save fails after generation | Content shown in editor; background retry queued | No visible error on first failure; error toast if retries exhausted | User can copy content from the editor manually |
| Generate submitted twice | Second submission blocked at UI; first request completes | Nothing on second click — by design | — |

---

## Invariants

- **Credits are deducted only on successful generation.** The deduction call is issued after the
  AI response is received and validated. Do not move deduction to the start of the request as a
  pre-reservation without a release path for failures.

- **The Generate button is disabled while a request is in flight.** This is the UI-layer
  concurrency guard. Do not remove the disabled state to make the interface feel more responsive —
  that re-enables double-submission. The server-side race risk (separate bug) is independent.

- **Generated drafts are scoped to the requesting user.** Item data, template content and drafts
  must not be readable by another account. Any new query that touches these tables must carry the
  user identifier as a filter, not rely on the caller passing the correct ID.

- **Draft state is not persisted until the AI call succeeds.** An in-progress placeholder stored
  before the response can surface as a "draft restored" entry with empty content. Persist only a
  complete, non-empty response.

---

## Integration

| Touches | Reads or writes | What breaks if this is wrong |
|---|---|---|
| `api/templates/` | Reads list and per-template metadata | Template library shows nothing; preview unavailable |
| `api/generate/` (new) | Triggers AI call; records draft | Core feature does not exist |
| `api/usage/` | Reads credit balance; writes deduction | Credit gate bypassed or double-charged |
| `store/content.ts` | Reads selected template and item; writes generated draft | State not shared between selection and generation steps |
| `components/editor/PostEditor.ts` | Reads generated content from the store | Editor receives no content |
| Credit deduction race (existing bug) | Two concurrent requests can both pass the balance check | Double charge on concurrent submit; see Known issues |

---

## QA

- [ ] Happy path: select template → select item → select platform → click Generate → draft
  appears in editor within 10 s; credits deducted once; draft visible in Drafts list.
- [ ] No items: inventory is empty → Generate is disabled; prompt to create an item is visible;
  no API call is made.
- [ ] Insufficient credits: user balance below required amount → modal appears before any AI
  call; balance unchanged after dismissing the modal.
- [ ] AI 5xx: stub the AI endpoint to return 500 → error toast with Retry button; clicking
  Retry re-submits and succeeds on the next call.
- [ ] Double-click Generate: two rapid clicks → one request sent; button is disabled after the
  first click.
- [ ] Navigate away: start generation, navigate elsewhere, return → draft is in the Drafts list.
- [ ] Refresh mid-generation: if complete → draft in Drafts list; if still running → loading
  state shown.
- [ ] Template deleted: arrive at generation with a template that was deleted between selection
  and submission → redirect to template library; toast shown.
- [ ] Narrow screen (375 px): template cards readable; generation modal usable; all actions
  reachable without horizontal scroll.
- [ ] Platform character limit: generate for a platform with a 280-character limit → output does
  not exceed the limit; if truncation is needed, it occurs at the server.
- [ ] Empty state copy: user with no items sees the correct CTA text (see Copy section).

---

## File changes

```
ADDED:     api/generate/route.ts — POST: validate session, check credits, call AI, save draft,
           deduct credits; returns draft ID and generated content
MODIFIED:  api/templates/route.ts — add per-template metadata endpoint (description, example
           output, supported platforms, credit cost)
MODIFIED:  store/content.ts — add generatedContent, templateId, selectedPlatform fields; add
           cleanup action that clears generatedContent on navigation; keep selectedTemplate and
           selectedItem for 5 minutes after leaving the flow
MODIFIED:  components/editor/PostEditor.ts — accept pre-populated content on mount; do not
           overwrite user edits if content is already present
ADDED:     components/generate/ — template picker, item picker, platform selector, Generate
           button with loading and disabled states, error toast handling
```

---

## Known issues

- Credit deduction uses a check-then-deduct sequence, not an atomic operation. A concurrent
  submission that bypasses the disabled-button guard (two browser tabs, for example) can result
  in a double charge. This is tracked as a separate bug. The button-disabled guard reduces but
  does not eliminate the risk.
- The 10-second generation target is a product requirement, not a platform guarantee. Under load
  or with a large item data set, the AI call may exceed it. The timeout error path handles this,
  but the user experience degrades to a retry loop.
- `selectedTemplate` and `selectedItem` are retained in client state for 5 minutes after the
  user leaves the generation flow. There is no visible indication to the user that these are
  still held.

---

## Copy

| System term | What the user calls it |
|---|---|
| Template | Template |
| Inventory item / entity | Item |
| Generate | Generate (not "Submit" or "Create") |
| Credits | Credits (not "tokens" or "units") |
| Draft | Draft |
| No items CTA | "Create your first item" |

---

## State

| Data | Lives where | Survives restart? | Cleared when |
|---|---|:---:|---|
| Selected template | Client state | No | User leaves the generation flow (5-minute grace period) |
| Selected item | Client state | No | User leaves the generation flow (5-minute grace period) |
| Selected platform | Client state | No | User leaves the generation flow |
| Generated content | Client state + database (draft row) | Yes (from database) | User explicitly deletes the draft; 30-day expiry |
| Generation loading state | Client state | No | Generation completes or fails |
| Credit balance | API response cache | Yes (stale-while-revalidate) | Re-fetched after each mutation |
