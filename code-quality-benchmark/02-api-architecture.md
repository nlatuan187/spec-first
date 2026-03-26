# API Architecture Comparison

## Score: ElandHub 8/10 vs Industry Leaders 9-10/10

---

## 1. Auth Pattern: Function Call vs HOF Wrapper

### ElandHub — Per-Route Function Call
```typescript
// app/api/calendar-events/route.ts — REPEATED in 30+ routes
export async function GET(req: NextRequest) {
  const user = await requireAuth(req);
  if (!user) return fail("Unauthorized", 401);

  try {
    // ... business logic
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : "Server error";
    console.error("[api/calendar-events/GET] error:", err);
    return fail(message, 500);
  }
}
```

**Total boilerplate per route**: ~6 lines (auth check + try/catch shell) × 30 routes = ~180 lines of identical code.

### Dub — `withWorkspace` Higher-Order Function
```typescript
// apps/web/app/api/links/route.ts — ZERO boilerplate in handler
export const GET = withWorkspace(
  async ({ searchParams, workspace, session }) => {
    const filters = getLinksQuerySchemaExtended.parse(searchParams);
    const response = await getLinksForWorkspace({ ...filters, workspaceId: workspace.id });
    return NextResponse.json(response);
  },
  { requiredPermissions: ["links.read"] },
);
```

The HOF handles: session auth, API key auth, token caching, rate limiting, RBAC, Axiom logging, response headers, error wrapping.

### Inbox Zero — `withError` HOF
```typescript
// apps/web/app/api/user/categorize/senders/batch/route.ts — 9 LINES TOTAL
export const POST = withError(
  "user/categorize/senders/batch",
  withQstashOrInternal(handleBatchRequest),
);
```

Error module `"user/categorize/senders/batch"` is passed as a string → used for structured logging automatically.

---

## 2. Recommended Fix: `withAuth` HOF for ElandHub

```typescript
// lib/middleware/withAuth.ts — NEW FILE
import { requireAuth } from "@/lib/auth";
import { fail } from "@/lib/response";
import { NextRequest, NextResponse } from "next/server";

type AuthedHandler = (req: NextRequest, user: { id: string }) => Promise<NextResponse>;

export function withAuth(moduleName: string, handler: AuthedHandler) {
  return async (req: NextRequest) => {
    const user = await requireAuth(req);
    if (!user) return fail("Unauthorized", 401);

    try {
      return await handler(req, user);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : "Server error";
      console.error(`[${moduleName}] error:`, err);
      return fail(message, 500);
    }
  };
}
```

**Usage** — calendar-events route becomes:
```typescript
// app/api/calendar-events/route.ts — BEFORE: 52 lines → AFTER: 18 lines
import { withAuth } from "@/lib/middleware/withAuth";

export const GET = withAuth("api/calendar-events/GET", async (req, user) => {
  const url = new URL(req.url);
  const year = parseInt(url.searchParams.get("year") || "", 10);
  const month = parseInt(url.searchParams.get("month") || "", 10);

  if (!year || !month || month < 1 || month > 12) {
    return fail("Valid year and month (1-12) are required", 400);
  }

  const events = await getCalendarEvents(user.id, year, month);
  return success({ events, total: events.length });
});
```

**Impact**: Eliminates ~180 lines of boilerplate across 30 routes.

---

## 3. Input Validation: Manual vs Zod

### ElandHub — Manual Validation
```typescript
// app/api/calendar-events/route.ts:62-76
const { event_date, platform } = body;
if (!event_date) return fail("event_date is required", 400);
if (!platform) return fail("platform is required", 400);
if (body.status && (typeof body.status !== "string" || !VALID_EVENT_STATUSES.has(body.status))) {
  return fail("status is invalid", 400);
}
```

This is manual, verbose, inconsistent across routes.

### Dub — Zod at Route Level
```typescript
// All validation in Zod schema, handler is clean:
const body = await createLinkBodySchemaAsync.parseAsync(await parseRequestBody(req));
// If validation fails → DubApiError thrown → withWorkspace catches → HTTP 422 returned
// Handler body has ZERO validation code
```

### Recommended for ElandHub
```typescript
// lib/validators/calendarEvent.ts — NEW FILE
import { z } from "zod";

export const calendarEventCreateSchema = z.object({
  event_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "YYYY-MM-DD required"),
  platform: z.string().min(1),
  status: z.enum(["planned", "draft_ready", "scheduled", "posted", "failed"]).optional(),
  note_type: z.enum(["green", "yellow", "red", "blue"]).optional(),
  time_slot: z.string().optional(),
  title: z.string().optional(),
  content: z.string().optional(),
});

export type CalendarEventCreateInput = z.infer<typeof calendarEventCreateSchema>;
```

Then in route:
```typescript
const parseResult = calendarEventCreateSchema.safeParse(body);
if (!parseResult.success) return fail(parseResult.error.issues[0].message, 400);
const input = parseResult.data; // fully typed CalendarEventCreateInput
```

---

## 4. Background Work: Missing `waitUntil`

### ElandHub — Synchronous Side Effects
```typescript
// Current: webhook/audit calls happen in the main request → slow response
await sendAuditLog(user.id, "publish", postId);  // blocks response
await updateCampaignStats(campaignId);             // blocks response
```

### Dub — `waitUntil` from Vercel
```typescript
// Response sent immediately, side effects run after
return NextResponse.json(response, { headers });
waitUntil(sendWorkspaceWebhook({ trigger: "link.created", workspace, data }));
// Client gets 201 in < 50ms, webhook fires async
```

**ElandHub Impact**: Any route that calls audit logging, webhook notification, or cache invalidation after the main operation should use `waitUntil`. Install: `@vercel/functions` (already on Vercel).

---

## 5. Error Class: String vs Typed

### ElandHub — String Error Messages
```typescript
return fail("Unauthorized", 401);
return fail("event_date is required", 400);
return fail("Failed to create calendar event", 500);
// Error codes are implicit in HTTP status only
```

### Dub — Typed Error Class
```typescript
throw new DubApiError({ code: "rate_limit_exceeded", message: "..." });
throw new DubApiError({ code: "conflict", message: `Slug "${slug}" already in use.` });
// code is an enum: "not_found" | "unauthorized" | "conflict" | "rate_limit_exceeded" | ...
```

**Benefit**: Frontend can `switch (error.code)` for specific UI handling. With ElandHub's current approach, FE must parse error strings.

**Recommended**: ElandHub doesn't need this yet (single company, not public API) but should be planned for multi-tenant expansion.

---

## 6. API Route Quality: What ElandHub Does BETTER

### SSE Streaming — Excellent
`app/api/chat/stream/route.ts` is a clean, well-structured SSE implementation:
```typescript
const emit = async (event: string, data: object) => {
  try {
    await writer.write(encoder.encode(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`));
  } catch { /* Client disconnected — ignore */ }
};
```

Proper `maxDuration = 60`, backpressure handling, abort signal check — this is better than most open source SSE implementations.

### Input Whitelisting — Correct Security Pattern
```typescript
// app/api/calendar-events/route.ts:17-30
const VALID_EVENT_STATUSES = new Set(["planned", "draft_ready", "scheduled", "posted", "failed"]);
const VALID_NOTE_TYPES = new Set(["green", "yellow", "red", "blue"]);
// Then: !VALID_EVENT_STATUSES.has(body.status) → fail
```

This prevents SQL injection via status values better than some top repos.

### Consistent Response Contract
`success(data) / fail(msg, status)` on 100% of routes — most repos have inconsistency here.

---

## 7. Summary: Gap vs Top Repos

| Pattern | ElandHub | Dub | Inbox Zero | Fix Effort |
|---------|----------|-----|-----------|-----------|
| Auth HOF | ❌ Per-route | ✅ `withWorkspace` | ✅ `withError` | 2 hours (new file + refactor 5 key routes) |
| Zod input validation | ❌ Manual | ✅ Schema-first | ✅ Schema-first | 1 day (create validators/) |
| Background work | ❌ Synchronous | ✅ `waitUntil` | ✅ Background queues | 30 min (install + wrap) |
| Typed error class | ❌ Strings | ✅ `DubApiError` | ❌ Strings | Low priority |
| RBAC declarative | ❌ Manual check | ✅ `requiredPermissions` | N/A | Future (multi-tenant) |
