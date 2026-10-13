---
title: "Calendar persistence: browser storage to database"
status: reconciled
scope: refactor
owner: "frontend-eng"
approver: "lead-eng"
created: 2026-06-10
approved_at: 2026-06-11
shipped_at: 2026-06-14
reconciled_at: 2026-06-15
---

# Calendar persistence: browser storage to database

> **Source**: Support log Q2-2026: 9 reports of calendar data lost after browser reset or device
> switch. No application bug — the storage choice is the root cause.

<!--
  Scope: refactor. Sections: Why · Verification · Invariants · Integration · QA · File changes ·
  Known issues. Acceptance and Failure modes are not written at refactor scope: the goal is that
  behaviour does not change, so Invariants carry what Failure modes would carry in other scopes.
-->

---

## Why

**Pain** — Calendar events live only in the browser. Clearing browser data or switching to a
different device wipes the calendar. Two devices logged in as the same account show two different
calendars.

**Need** — "I set up my whole posting schedule and it was gone the next day when I switched
computers."

**Proposed** — We will move event persistence from browser storage to a database API with
optimistic local updates, not rewrite the state layer from scratch, because the drag-drop
interaction depends on synchronous local mutation — keeping the local state as the immediate write
target and syncing in the background preserves that behaviour while adding durability.

**Non-goals** — Collaborative editing (multiple users, same calendar). Offline mode. Event
analytics or history.

---

## Verification

Run 2026-06-10 against `main` @ `8b2d3c1`.

1. Naming — browser storage key is `calendarEvents`. State store field is `calendarEvents`.
   Database column for dates is `event_date` (ISO 8601, one-indexed month). Frontend key format is
   `"year-month-day"` with zero-indexed month: 15 March 2026 → `"2026-2-15"`. The two formats
   diverge and must convert at the API boundary only.
2. Paths — state module at `store/calendar.ts`; calendar UI components under
   `components/calendar/`. No `components/shared/calendar.ts` — the draft used a wrong path.
3. Dependencies — HTTP client and state library already installed. No new packages.
4. Env — `API_BASE_URL` present. No new vars required.
5. Secrets in URLs — no hits in the calendar path.
6. Atomicity — add, move and delete each issue one API call after updating local state. No
   check-then-write. The database is the single authoritative writer.
7. Prior art — searched `calendarEvents`, `useCalendarStore`, `handleEventAdd`,
   `CALENDAR_KEY`, `calendarStore` — all references are in `store/calendar.ts` and
   `components/calendar/CalendarSection.ts`. No duplicate calendar persistence layer found.

---

## Invariants

- **Local state is the immediate source of truth; the database is the durable one.** Every user
  action writes to local state first. The API call is the background sync. Do not add a loading
  gate before the local state update — that removes the responsiveness this refactor is
  explicitly preserving.

- **The frontend key format does not change.** The frontend uses zero-indexed month keys
  (`"2026-2-15"`). Conversion to ISO format happens only at the API boundary. Do not normalise
  keys inside the state module or inside any calendar component. Every conversion point must have
  a comment naming the two formats so the next reader cannot miss it.

- **Every optimistic write carries the previous state.** An optimistic update without a rollback
  path leaves the UI in a state the database does not know about. Add, move and delete must each
  capture the pre-action state before modifying local state, so the rollback path can restore it.

- **One-time migration runs exactly once.** After migration completes, the browser storage key is
  cleared and a `calendar_migrated` flag is set. Do not read browser storage for calendar events
  on any subsequent load — the database is source of truth from that point.

- **Per-month fetch, not full-history fetch.** The API loads one month at a time. Do not replace
  per-month fetching with a bulk load: the calendar history has no defined upper bound.

---

## Integration

| Touches | Reads or writes | What breaks if this is wrong |
|---|---|---|
| `store/calendar.ts` | Reads and writes all calendar state | All calendar operations fail |
| `components/calendar/CalendarSection.ts` | Reads state; triggers add, move, delete | Drag-drop stops working; migration never runs |
| `components/calendar/CalendarToolbar.ts` | Reads month navigation state | Month changes no longer trigger fetches |
| `api/calendar/` routes (new) | GET by month, POST add, PUT move, DELETE remove | All persistence fails silently if routes are absent |
| Browser local storage | Read once on first load for migration; then cleared | Migration re-runs on every load if the flag is never set |

---

## QA

- [ ] Add event: drag a platform icon onto a calendar cell → event appears immediately (no
  visible delay); after a short wait, the same event is retrievable from the API.
- [ ] Move event: drag an event to a new cell → event moves immediately; API shows the new date.
- [ ] Delete event: click delete → event disappears immediately; API shows no matching row.
- [ ] Rollback add: stub the add API to return a server error → event disappears from the
  calendar after the failure; error toast shown.
- [ ] Rollback move: stub the move API to return a server error → event returns to its original
  cell; error toast shown.
- [ ] Rollback delete: stub the delete API to return a server error → event reappears in its
  original cell; error toast shown.
- [ ] Persistence: add an event, hard-reload the page → event is still present (loaded from the
  database, not from browser storage).
- [ ] Cross-device: add an event on device A, open the calendar on device B with the same
  account → event is visible.
- [ ] Date round-trip: event placed on 15 March → API stores `2026-03-15` → calendar shows
  event on the 15 March cell. Check for off-by-one in the month index conversion.
- [ ] Migration: browser storage has 3 events, database is empty → after first load all 3
  events appear in the calendar and in the database; browser storage key is cleared;
  `calendar_migrated` flag is set.
- [ ] Migration idempotency: hard-reload after migration → browser storage is not re-read;
  no duplicate events in the database.
- [ ] Past-date guard: drag an event onto a past date → drop is rejected; no API call is made.
- [ ] Month navigation: navigate to an unloaded month → API fetch fires; navigate back to an
  already-loaded month → no second fetch.

---

## File changes

```
MODIFIED:  store/calendar.ts — actions become async with rollback; add API calls for add, move,
           delete; add per-month fetch action; add one-time migration on first mount
MODIFIED:  store/types.ts — CalendarEvent gains optional dbId (server-assigned UUID), templateId,
           seasonalTag
MODIFIED:  components/calendar/CalendarSection.ts — trigger migration on first mount; trigger
           per-month fetch on month navigation; show loading state on initial fetch
ADDED:     api/calendar/route.ts — GET (list by month), POST (add), PUT (move), DELETE (remove)
ADDED:     db/migrations/018_calendar_events.sql — calendar_events table with event_date,
           platform, time_slot, status, user_id, and optional template_id and seasonal_tag
```

---

## Known issues

- The zero-indexed month key is a non-standard format. It is preserved to avoid a larger
  component-level refactor, but every API boundary must document both formats explicitly.
  Any contributor who does not read the conversion comment will introduce an off-by-one bug.
- Per-month fetch means the first navigation to any new month incurs a round-trip. On a slow
  connection this produces a visible loading flash. No skeleton state is planned for this release.
- `templateId` and `seasonalTag` are added to the event type but no UI path writes them yet.
  They exist to prevent a second migration when the template pipeline ships. Until then they
  are always null on new events.
