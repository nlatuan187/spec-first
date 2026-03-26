# Feature: Content Generation from Templates

<!--
This is a REAL production spec (anonymized). It was fed to Claude Code
and generated a working feature across 8 files in one session.
Fix:feat ratio for this spec: 1.5:1 (3 fix commits after initial implementation).
-->

## Overview

User selects a content template from the library, chooses a target entity and platform, then generates AI-powered content. The system uses the template's structure, the entity's data, and platform-specific constraints to produce ready-to-publish content.

## Acceptance Criteria

- [ ] User opens content library and sees templates organized by category
- [ ] User selects a template → sees preview with description and example output
- [ ] User picks a target entity from their inventory
- [ ] User selects target platform (affects character limits, format, tone)
- [ ] "Generate" button produces content within 10 seconds
- [ ] Generated content appears in the editor with platform-appropriate formatting
- [ ] User can regenerate with different parameters without losing current result
- [ ] Credit is deducted only on successful generation
- [ ] Empty state: user with no entities → shows prompt to create one first

---

## S1: Error States & Validation

| Condition | User Sees |
|-----------|----------|
| Not authenticated | Redirect to /login with return URL |
| No entity selected | "Generate" button disabled + tooltip "Select an item first" |
| Insufficient credits | Modal: "You need X credits. Current balance: Y." + upgrade button |
| API returns 500 | Toast: "Generation failed. Try again." + "Retry" button |
| API returns 429 (rate limit) | Toast: "Too many requests. Wait 30 seconds." |
| Template not found (deleted) | Redirect to library home + toast "Template no longer available" |
| Entity data incomplete | Warning banner: "Missing [field]. Content quality may be affected." |

## S2: Post-Completion Flow

- **On success**: Content appears in editor. Auto-saved as draft (database). Toast: "Content generated successfully."
- **User navigates away mid-generation**: Generation continues in background. Draft saved on completion. User sees draft in "Drafts" tab.
- **User refreshes during generation**: Draft restored from database if generation completed. If still generating, shows loading state.
- **Output constraints**: Platform character limits enforced (Facebook: 63,206 chars, Twitter: 280 chars, TikTok: 2,200 chars).

## S3: Cross-Feature Integration

- **Template library → Generation → Editor**: Template ID + entity ID passed via Zustand store `useContentStore`. Editor reads `generatedContent` from store.
- **Credit system**: `POST /api/usage/check` before generation. `POST /api/usage/deduct` after successful generation. If deduction fails, content still shown (fire-and-forget deduction with retry).
- **Empty state**: No entities → "Create your first item" CTA linking to entity creation page.
- **Cleanup**: Leaving the generation flow → reset `useContentStore.generatedContent`. Keep `selectedTemplate` and `selectedEntity` for 5 minutes (user might return).

## S4: UX Copy Review

- [ ] "Generate" not "Submit" or "Create" (matches user mental model)
- [ ] Template descriptions use non-technical language (no "AI-powered" or "algorithm")
- [ ] Platform names match common usage (not internal codes)
- [ ] Error messages are specific and actionable (not "Something went wrong")
- [ ] Credit-related text: "credits" not "tokens" or "units"

## S5: State & Persistence Matrix

| Data | Storage | Persist on refresh? | Cleanup when? |
|------|---------|:------------------:|---------------|
| Selected template | Zustand | No | Leave content library |
| Selected entity | Zustand | No | Leave generation flow |
| Generated content | Zustand + Database (draft) | Yes (from DB) | Explicit delete or 30-day expiry |
| Generation loading state | Zustand | No | Generation completes or fails |
| Platform selection | Zustand | No | Leave generation flow |
| Credit balance | SWR cache | Yes (stale-while-revalidate) | Re-fetched on page load |

## S6: Manual QA Scenarios

- [ ] Happy path: Select template → select entity → select platform → generate → content appears in editor
- [ ] Click outside template modal → modal closes, no state change
- [ ] Double-click "Generate" → only one request sent (button disabled during loading)
- [ ] API fails → user sees error toast → retry button works → content appears on retry
- [ ] Loading state → spinner with "Generating..." text → result in < 10 seconds
- [ ] Mobile (375px): Template cards stack vertically, modal fullscreen
- [ ] Refresh mid-generation: If complete → draft visible in Drafts. If still running → loading state shown.
- [ ] Back button from editor → returns to library (not re-generates)
- [ ] No entities: "Create your first item" CTA visible, "Generate" disabled
- [ ] Insufficient credits: Modal appears BEFORE generation starts, not after

---

## Technical Notes

**API endpoints:**
- `GET /api/templates?category={cat}` — List templates
- `POST /api/ai/generate` — Generate content (body: `{ templateId, entityId, platform }`)
- `POST /api/usage/deduct` — Deduct credits after success

**Existing patterns to reuse:**
- `useContentStore` (Zustand) — already exists, extend with `generatedContent`
- `lib/services/ai/templateGenerationService.ts` — existing service, add template support
- `components/features/create/editor/PostEditor.tsx` — existing editor, receives generated content
