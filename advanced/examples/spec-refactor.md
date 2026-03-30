# Refactor: Calendar Persistence — localStorage to Database Sync

<!--
This is a REAL production refactor spec (anonymized). The calendar feature
worked entirely from localStorage. This spec upgrades it to database-backed
persistence with optimistic updates, preserving all existing behavior.
Zero bugs introduced — the key format decision prevented the most common refactor failure.
-->

## What's Being Restructured

The calendar feature stores all events in `localStorage`. This works for single-device usage but breaks when:
- User switches devices (laptop → phone)
- User clears browser data (all calendar events lost)
- Multiple browser tabs create conflicting states

This refactor moves persistence from localStorage to a database API while keeping the exact same frontend behavior. Users should notice nothing except that their calendar now syncs across devices.

## Behavior That MUST NOT Change

1. **Drag-drop to add events** — drag a platform icon onto a calendar cell → event appears immediately
2. **Drag-drop to move events** — drag existing event to new cell → event moves immediately
3. **Delete events** — click delete → event disappears immediately
4. **Past-date guard** — cannot drop events on dates before today
5. **View toggle** — monthly/weekly view switching
6. **Status display** — events show "Planned", "Scheduled 09:00", "Published 10:00", "Failed"
7. **Calendar key format** — `"year-month-day"` with zero-indexed month stays unchanged internally

## What References It (scan, don't rely on memory)

```
grep -r "calendarEvents\|useCalendarStore\|handleEventAdd" src/ components/ store/ --include="*.ts" --include="*.tsx" | head -20
```

## S3: Every File That Needs Migration

| File | How it references the calendar | Migration needed |
|------|-------------------------------|-----------------|
| `store/shared/calendar.ts` | Defines all state + actions | Core change: async actions, API calls, optimistic updates |
| `store/shared/types.ts` | `CalendarEvent` interface | Add `dbId`, `templateId`, `seasonalTag` fields |
| `components/.../CalendarSection.tsx` | Reads state, handles drag-drop | Add auto-fetch per month, one-time migration trigger, loading state |
| `components/.../CalendarToolbar.tsx` | Month navigation | No change (but now triggers data fetch indirectly) |
| `localStorage('calendarEvents')` | Current persistence | One-time migration to DB, then cleared |

---

## Implementation

### Strategy: Optimistic Updates

All user actions update local state **immediately** (same as current behavior). Database sync happens in background. On API failure: rollback local state + show error toast.

This means the user experience is identical — no loading spinners on every click.

### Key Format Decision

**Current**: Frontend uses `"year-month-day"` keys with **zero-indexed months** (March = 2, so March 15 = `"2026-2-15"`).

**Database**: Uses ISO dates (`"2026-03-15"` with 1-indexed months).

**Decision**: Keep the frontend key format unchanged. Convert only at the API boundary.

```
Frontend key: "2026-2-15" → API sends: event_date "2026-03-15"
API returns: event_date "2026-03-15" → Frontend key: "2026-2-15"
```

**Why**: Changing the key format would require refactoring every calendar grid component, every drag-drop handler, and every date calculation. The risk of introducing bugs far exceeds the benefit of "cleaner" keys. Convert at the boundary; leave internals alone.

### Action Migration

| Action | Before (sync) | After (async) |
|--------|---------------|---------------|
| Add event | Create in state → save to localStorage | Create in state → POST to API → on failure: rollback |
| Move event | Move in state → save to localStorage | Move in state → PUT to API → on failure: rollback |
| Delete event | Remove from state → save to localStorage | Remove from state → DELETE to API → on failure: rollback |
| Load events | Read from localStorage on mount | Fetch from API per month on navigation |

### One-Time Migration

On first mount after deployment:
1. Check: does localStorage have calendar data?
2. Check: does the database already have events for this user?
3. If localStorage has data AND database is empty → migrate each event via API
4. Clear localStorage after successful migration
5. Set `localStorage('calendar_migrated')` flag to prevent repeat

If database already has events: skip migration, just clear localStorage (database is source of truth).

### Data Shape Changes

```typescript
// EXISTING fields (unchanged)
interface CalendarEvent {
  id: string;
  platform: string;      // "Facebook", "TikTok"
  time: string;          // "09:00" or ""
  status: string;        // "Planned", "Scheduled 09:00", "Published 10:00"
  noteType: string;      // 'yellow' | 'green' | 'blue' | 'red'
  content?: string;
  isPublished?: boolean;
  isFailed?: boolean;

  // NEW fields
  dbId?: string;         // Server-side UUID (differs from local `id` during optimistic update)
  templateId?: string;   // FK to content template
  seasonalTag?: string;  // "lunar_new_year" | "ghost_month" | etc.
}
```

---

## S6: Regression — Verify Behavior Is Preserved

### Core Operations
- [ ] Drag-drop add event → event appears immediately (no visible delay)
- [ ] Drag-drop move event → event moves immediately
- [ ] Delete event → event disappears immediately
- [ ] API failure on add → event is removed (rollback) + error toast shown
- [ ] API failure on move → event returns to original position + error toast
- [ ] API failure on delete → event reappears + error toast

### Data Integrity
- [ ] Event data round-trips correctly:
  - Platform: "Facebook" → API lowercase "facebook" → display "Facebook"
  - Time: "09:00" → API time_slot → "09:00"
  - Month key: "2026-2-15" → API event_date "2026-03-15" → "2026-2-15"
- [ ] Events persist across page refresh (loaded from database)
- [ ] Events visible on different device (same account)

### Migration
- [ ] localStorage events migrate to database on first load
- [ ] After migration: localStorage cleared
- [ ] Migration skipped if database already has events
- [ ] `calendar_migrated` flag prevents repeat migration
- [ ] Migration handles events with missing optional fields gracefully

### Existing Features
- [ ] Monthly/weekly view toggle still works
- [ ] Past-date guard still blocks drops on old dates
- [ ] Navigating to new month fetches that month's events
- [ ] Already-fetched months don't re-fetch (cached in state)
- [ ] Status polling (3-second interval) still updates event statuses

---

## Design Decisions

1. **Key format unchanged** — converting would touch every calendar component. Convert at API boundary only.
2. **Optimistic updates** — user sees no delay. Only rollback on failure.
3. **One-time migration** — check flag, check DB, migrate if needed, clear localStorage.
4. **Per-month fetch** — don't load entire calendar history. Fetch when user navigates to a month.
5. **Error handling** — rollback + toast. No error modals. Calendar must always feel responsive.
