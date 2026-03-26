# Actionable Fixes — Copy-Paste Ready

**Mỗi fix có: file cần sửa, code trước/sau, effort estimate**

---

## CRITICAL (Sửa trước tiên)

### FIX-1: Generic `success<T>()` in response.ts

**File**: `lib/response.ts`
**Effort**: 2 phút

```typescript
// BEFORE
export function success(data: any, status = 200) {
  return NextResponse.json({ success: true, data }, { status });
}

// AFTER
export function success<T>(data: T, status = 200) {
  return NextResponse.json({ success: true, data }, { status });
}
```

**Impact**: All 119 routes now have type-safe responses. FE parsing bugs caught at compile time.

---

### FIX-2: Remove `[key: string]: any` from Interfaces

**Files**: `lib/services/db/users.ts:22,48,62`
**Effort**: 10 phút

```typescript
// BEFORE
export interface UserProfile {
  id: string;
  plan: string;
  subscription_status: string | null;
  credits_balance: number | null;
  [key: string]: any;  // ← REMOVE THIS
}

// AFTER
export interface UserProfile {
  id: string;
  email?: string | null;
  name?: string | null;
  avatar_url?: string | null;
  plan: string;
  subscription_status: string | null;
  credits_balance: number | null;
  // No index signature — add explicit fields as needed
}
```

Same change for `UsageRecord` and `MonthlyUsage` interfaces.

---

### FIX-3: Add `import "server-only"` to DB Services

**Files**: All 21 files in `lib/services/db/*.ts`
**Effort**: 5 phút (sed command)

```bash
# Run from project root:
for f in lib/services/db/*.ts; do
  if ! grep -q "server-only" "$f"; then
    sed -i '' '1s/^/import "server-only";\n/' "$f"
  fi
done
```

Or manually add to top of each file:
```typescript
import "server-only";  // ← ADD AS FIRST LINE
import { supabase } from "@/lib/supabase";
// ...
```

**Impact**: Build fails if any Client Component accidentally imports DB service. Prevents SUPABASE_SERVICE_ROLE_KEY from leaking into client bundle.

---

## HIGH (Sửa trong sprint này)

### FIX-4: `withAuth` HOF for API Routes

**New file**: `lib/middleware/withAuth.ts`
**Effort**: 30 phút (new file + migrate 5 key routes)

```typescript
// lib/middleware/withAuth.ts — NEW FILE
import { requireAuth } from "@/lib/auth";
import { fail } from "@/lib/response";
import { NextRequest, NextResponse } from "next/server";

type AuthedUser = { id: string };
type AuthedHandler<T = NextResponse> = (
  req: NextRequest,
  user: AuthedUser
) => Promise<T>;

export function withAuth(
  moduleName: string,
  handler: AuthedHandler
) {
  return async (req: NextRequest): Promise<NextResponse> => {
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

**Usage — calendar-events example**:
```typescript
// app/api/calendar-events/route.ts — AFTER REFACTOR
import { withAuth } from "@/lib/middleware/withAuth";
import { success, fail } from "@/lib/response";
import { getCalendarEvents, createCalendarEvent } from "@/lib/services/db/calendarEvents";
import { calendarEventCreateSchema } from "@/lib/validators/calendarEvent";

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

export const POST = withAuth("api/calendar-events/POST", async (req, user) => {
  const rawBody = await req.json().catch(() => null);
  if (!rawBody) return fail("Invalid request body", 400);

  const parseResult = calendarEventCreateSchema.safeParse(rawBody);
  if (!parseResult.success) {
    return fail(parseResult.error.issues[0].message, 400);
  }

  const event = await createCalendarEvent(user.id, parseResult.data);
  if (!event) return fail("Failed to create calendar event", 500);

  return success(event, 201);
});
```

---

### FIX-5: Zod Validation for AI Output

**New folder**: `lib/ai/schemas/`
**Effort**: 2 giờ

```typescript
// lib/ai/schemas/content-generation.ts — NEW FILE
import { z } from "zod";

// Schema for structured post generation response
export const generatedPostSchema = z.object({
  platform: z.string(),
  content: z.string().max(5000),
  hashtags: z.array(z.string()).optional().default([]),
  emoji_count: z.number().optional(),
});

export const contentGenerationResponseSchema = z.object({
  posts: z.array(generatedPostSchema),
  total_generated: z.number().optional(),
});

export type GeneratedPostOutput = z.infer<typeof generatedPostSchema>;
export type ContentGenerationOutput = z.infer<typeof contentGenerationResponseSchema>;
```

**Usage in `lib/ai/providers/gemini.ts`**:
```typescript
import { contentGenerationResponseSchema } from "@/lib/ai/schemas/content-generation";

// After receiving Gemini response:
const rawText = response.text();
let parsed: unknown;
try {
  parsed = JSON.parse(rawText);
} catch {
  console.error("[gemini/generateContent] Invalid JSON from AI:", rawText.slice(0, 200));
  throw new Error("AI returned malformed response");
}

const result = contentGenerationResponseSchema.safeParse(parsed);
if (!result.success) {
  console.error("[gemini/generateContent] Schema validation failed:", result.error.issues);
  throw new Error("AI response did not match expected schema");
}

return result.data;  // Fully typed ContentGenerationOutput
```

---

### FIX-6: Safe JSON Parse Utility

**File**: Add to `lib/utils/storage.ts` (or create `lib/utils/json.ts`)
**Effort**: 15 phút

```typescript
// lib/utils/json.ts — NEW FILE
/**
 * Safely parse JSON — returns null on any error instead of throwing.
 * Use this anywhere you parse untrusted JSON (localStorage, user input, AI response).
 */
export function safeJsonParse<T>(value: string | null, fallback: T): T {
  if (!value) return fallback;
  try {
    return JSON.parse(value) as T;
  } catch {
    return fallback;
  }
}
```

**Replace all `JSON.parse()` calls in store initialization**:
```typescript
// store/create/posts.ts — BEFORE
openPosts: loadFromLocalStorage<Post[]>('openPosts', []),

// After updating loadFromLocalStorage to use safeJsonParse internally:
// In lib/utils/storage.ts:
export function loadFromLocalStorage<T>(key: string, fallback: T): T {
  if (typeof window === "undefined") return fallback;  // SSR guard
  return safeJsonParse(localStorage.getItem(key), fallback);
}
```

---

### FIX-7: `pRetry` for Gemini API Calls

**File**: `lib/ai/providers/gemini.ts`
**Effort**: 1 giờ

```bash
# Install
npm install p-retry
```

```typescript
// lib/ai/providers/gemini.ts
import pRetry from "p-retry";

// Wrap Gemini calls with retry:
const response = await pRetry(
  async () => {
    const result = await model.generateContent(prompt);
    if (!result.response) throw new Error("Empty response from Gemini");
    return result;
  },
  {
    retries: 3,
    onFailedAttempt: (error) => {
      console.warn(
        `[gemini] Attempt ${error.attemptNumber} failed:`,
        error.message,
        `— Retrying...`
      );
    },
    shouldRetry: (error) => {
      // Retry on rate limit and service unavailable, not on auth errors
      const retryableCodes = [429, 503, 500];
      return retryableCodes.some(code => error.message.includes(String(code)));
    },
  }
);
```

---

## MEDIUM (Backlog — khi có thời gian)

### FIX-8: Split ContentLibraryModal

**File**: `components/features/create/content-library/ContentLibraryModal.tsx` (1000+ lines)
**Effort**: 4 giờ

Extract into:
```
ContentLibraryModal.tsx        — Root wrapper, tab state (~100 lines)
  ContentLibraryBrowse.tsx     — Template browsing, search, filter (~300 lines)
  ContentLibraryPreview.tsx    — Template preview, audience select (~250 lines)
  InspirationTab.tsx           — Inspiration flow (~200 lines)
  ContentLibraryGenerating.tsx — Generation progress UI (~150 lines)
```

### FIX-9: Cron Route Protection

**Files**: All `app/api/cron/*.ts`
**Effort**: 30 phút

```typescript
// Add to ALL cron routes as first check:
export async function GET(req: NextRequest) {
  const authHeader = req.headers.get("authorization");
  const cronSecret = process.env.CRON_SECRET;

  if (!cronSecret || authHeader !== `Bearer ${cronSecret}`) {
    return fail("Unauthorized", 401);
  }
  // ... rest of cron logic
}
```

And set in `vercel.json`:
```json
{
  "crons": [{
    "path": "/api/cron/process-scheduled-posts",
    "schedule": "0 * * * *"
  }]
}
```

Vercel automatically sends the `CRON_SECRET` bearer token for configured cron jobs.

### FIX-10: Type Predicates for Platform/Status Validation

**File**: `lib/utils/typeGuards.ts` — NEW FILE

```typescript
// lib/utils/typeGuards.ts
const VALID_PLATFORMS = ["facebook", "instagram", "tiktok", "zalo", "youtube", "twitter", "linkedin", "threads", "bluesky", "pinterest"] as const;
export type Platform = (typeof VALID_PLATFORMS)[number];

export function isPlatform(value: unknown): value is Platform {
  return typeof value === "string" && VALID_PLATFORMS.includes(value as Platform);
}

const VALID_EVENT_STATUSES = ["planned", "draft_ready", "scheduled", "posted", "failed"] as const;
export type EventStatus = (typeof VALID_EVENT_STATUSES)[number];

export function isEventStatus(value: unknown): value is EventStatus {
  return typeof value === "string" && (VALID_EVENT_STATUSES as readonly string[]).includes(value);
}
```

Replace `VALID_EVENT_STATUSES.has(body.status)` Set pattern with type predicate — adds type narrowing.

---

## Impact Summary

| Fix | Effort | Impact | Priority |
|-----|--------|--------|----------|
| FIX-1: Generic success() | 2 min | Critical — type safety on all routes | P0 |
| FIX-2: Remove [key: string]: any | 10 min | High — 3 interfaces safer | P0 |
| FIX-3: server-only imports | 5 min | Critical — security boundary | P0 |
| FIX-4: withAuth HOF | 2 hours | High — 180 lines boilerplate removed | P1 |
| FIX-5: Zod for AI output | 2 hours | High — prevent AI hallucination crashes | P1 |
| FIX-6: Safe JSON parse | 15 min | Medium — localStorage crash prevention | P1 |
| FIX-7: pRetry for Gemini | 1 hour | Medium — reliability for AI calls | P1 |
| FIX-8: Split ContentLibraryModal | 4 hours | Medium — maintainability | P2 |
| FIX-9: Cron route protection | 30 min | High — security | P1 |
| FIX-10: Type predicates | 1 hour | Low — nice-to-have type safety | P2 |

**Total P0**: ~15 minutes
**Total P1**: ~7 hours
**Total P2**: ~5 hours
