# State Management Comparison

## Score: ElandHub 7/10 vs Midday 8/10, Dub 8/10

---

## 1. Store Size Problem

### ElandHub — 8 Stores Over 500 Lines
```
store/shared/calendar.ts         — 627 lines
store/create/publish.ts          — 557 lines
store/create/contentTemplate.ts  — 541 lines
store/create/posts.ts            — 526 lines
store/shared/statusCheck.ts      — 522 lines
store/properties/propertyDetailStore.ts — 474 lines
store/create/chat.ts             — 466 lines
```

**Problem**: A 627-line store is a monolith. Hard to test, hard to read, hard to maintain.

### Midday — Per-Domain, Focused Stores
```
store/transactions.ts    — ~65 lines
store/customers.ts       — ~60 lines
store/search.ts          — ~40 lines
store/invoice.ts         — ~55 lines
store/metrics-filter.ts  — ~200 lines (most complex)
```

Midday có nhiều stores nhỏ với 1 trách nhiệm rõ ràng mỗi store.

---

## 2. Calendar Store — Architecture Issue

### Current ElandHub `store/shared/calendar.ts:627 lines`
```typescript
// Mixes: UI state + API calls + localStorage sync + DB sync + status mapping + date utils
export const useCalendarStore = create<CalendarState>((set, get) => ({
  // Platform mapping
  PLATFORM_DISPLAY: { facebook: 'Facebook', ... },
  platformToDisplay,
  platformToDB,

  // Date utilities
  toISODate,
  isoDateToKey,
  dbEventToFE,

  // UI state
  events: loadFromLocalStorage(...),
  selectedDate: null,

  // API operations
  loadMonthEvents: async () => { ... },    // DB fetch
  createEvent: async () => { ... },         // DB write
  updateEvent: async () => { ... },         // DB write

  // Status sync
  syncPostStatus: async () => { ... },      // Cross-store dependency
}));
```

**Problem**: Store làm quá nhiều việc — utility functions, UI state, API calls, cross-store sync đều trong 1 file.

### Recommended Split
```
store/shared/
  calendar.ts              — UI state only (events[], selectedDate, view)
  calendarApi.ts           — async operations (loadMonthEvents, createEvent)
  calendarUtils.ts         — pure functions (platformToDisplay, isoDateToKey, dbEventToFE)
```

Hoặc tốt hơn: extract utilities ra `lib/utils/calendarHelpers.ts` (pure functions không cần store).

---

## 3. localStorage Race Condition

### ElandHub — Dual Persistence Problem

```typescript
// store/create/posts.ts:76-78
openPosts: loadFromLocalStorage<Post[]>('openPosts', []),
selectedPostId: loadFromLocalStorage<number>('selectedPostId', 0),
postContents: loadFromLocalStorage<Record<number, string>>('postContents', {}),
```

**Scenario bug**:
1. User tạo post → lưu vào localStorage
2. User clear browser cache → localStorage mất
3. Posts gone, DB không có backup

**Midday's fix** — explicit cache invalidation với SSR guard:
```typescript
// Midday store/metrics-filter.ts
const getStoredPreferences = (teamId: string) => {
  if (typeof window === "undefined") return null;  // SSR guard
  try {
    const stored = localStorage.getItem(`metrics-filter-${teamId}`);
    if (!stored) return null;
    const parsed = JSON.parse(stored);
    return isPeriodOption(parsed.period) ? parsed : null;  // Validate before use
  } catch {
    localStorage.removeItem(`metrics-filter-${teamId}`);  // Clear corrupt data
    return null;
  }
};
```

**ElandHub's `loadFromLocalStorage`** — check if it handles:
- SSR guard (`typeof window !== "undefined"`)
- Corrupt JSON (`try/catch` around `JSON.parse`)
- Stale/invalid data (type validation after parse)

---

## 4. Missing SSR Guard in Store Init

### Problem
```typescript
// store/create/posts.ts:76 — RUNS AT MODULE LOAD TIME
openPosts: loadFromLocalStorage<Post[]>('openPosts', []),
```

If `loadFromLocalStorage` calls `localStorage` without SSR guard → crashes on server-side rendering.

### Formbricks Fix Pattern
```typescript
// Formbricks — gate the fetch until browser confirms hydration
const [isFilterInitialized, setIsFilterInitialized] = useState(false);

useEffect(() => {
  const savedFilters = localStorage.getItem("filterPreferences");
  if (savedFilters) { /* restore */ }
  setIsFilterInitialized(true);
}, []);

useEffect(() => {
  if (!isFilterInitialized) return;  // Wait for localStorage read
  fetchSurveys(filters);
}, [filters, isFilterInitialized]);
```

---

## 5. Advanced Patterns ElandHub Could Use

### 5a. Per-Tab State Map (Midday)
```typescript
// Midday store/transactions.ts — tracking selection per tab
rowSelectionByTab: {
  all: {},
  income: {},
  expense: {},
} as RowSelectionByTab,

setRowSelection: (tab, updater) =>
  set((state) => ({
    rowSelectionByTab: {
      ...state.rowSelectionByTab,
      [tab]: typeof updater === "function"
        ? updater(state.rowSelectionByTab[tab])
        : updater,
    },
  })),
```

**ElandHub opportunity**: `store/create/posts.ts` có nhiều operations "per post" — tracking state by `postId` as a map key là pattern tương tự.

### 5b. URL Sync Pattern (Midday)
```typescript
// Midday store/metrics-filter.ts — bi-directional URL ↔ Store sync
syncFromUrl: (period?, revenueType?, currency?, from?, to?) => {
  set({
    period: isPeriodOption(period) ? period : DEFAULT_PERIOD,
    revenueType: isRevenueType(revenueType) ? revenueType : DEFAULT_REVENUE_TYPE,
  });
},
```

**ElandHub opportunity**: Content library filters, property search filters — hiện tại không sync với URL, user không thể share filtered state.

### 5c. Template Literal Key Types (Inbox Zero)
```typescript
// Inbox Zero — type-safe queue key format
activeThreads: Record<`${ActionType}-${string}`, QueueItem>
// Key MUST match "archive-<id>", "delete-<id>", "markRead-<id>"
```

**ElandHub opportunity**: `store/create/contentTemplate.ts` tracks stream progress per template:
```typescript
// ✅ BETTER
type StreamPhase = "generating" | "done" | "error";
streamProgress: Record<`${StreamPhase}-${string}`, StreamProgress>
```

### 5d. Retry Logic in Async Actions (Inbox Zero)
```typescript
// Inbox Zero — pRetry for Gmail API calls
await pRetry(
  async () => { await archiveThread(threadId); },
  {
    retries: 3,
    onFailedAttempt: (error) => {
      if (error.message.includes("rate limit")) await exponentialBackoff(error.attemptNumber);
    },
  }
);
```

**ElandHub opportunity**: Gemini API calls in `lib/ai/providers/gemini.ts` — một `503 Service Unavailable` kills the generation. `pRetry` với 3 retries + exponential backoff would prevent this.

---

## 6. What ElandHub Does Well

### Type-Safe Store Interface
```typescript
// store/create/posts.ts:20-44
interface CreatePostsState {
  openPosts: Post[];
  selectedPostId: number;
  postContents: Record<number, string>;
  postToEventMap: Record<number, { eventId: string; dateKey: string }>;
  // All actions typed with parameters and return types
  handlePostSelect: (id: number) => void;
  handlePostCreate: (type: string, metadata?: PostMetadata) => number;
  // ...
}
```

Fully typed store interface là đúng hướng. Midday và Dub cũng làm tương tự.

### Cross-Store Dependencies via Getters
```typescript
// posts.ts uses calendarStore via get() pattern — not prop drilling
const calendarStore = useCalendarStore.getState();
```

Pattern đúng — không import store instance, dùng `getState()` directly.

### Store Cleanup Functions
```typescript
clearPosts: () => set({ openPosts: [], selectedPostId: 0, postContents: {} })
```

Có cleanup functions — important for memory leaks and state reset on navigation.

---

## 7. Recommendations Priority

| Issue | File | Fix | Effort |
|-------|------|-----|--------|
| SSR guard in localStorage | `store/create/posts.ts:76` | Check `loadFromLocalStorage` impl | 30 min |
| Split calendar store | `store/shared/calendar.ts:627` | Extract utils to `lib/utils/` | 2 hours |
| Add pRetry to Gemini | `lib/ai/providers/gemini.ts` | `npm i p-retry` + wrap AI calls | 1 hour |
| Template literal keys | `store/create/contentTemplate.ts` | Refactor StreamProgress keys | 1 hour |
| URL sync for filters | ContentLibrary filters | Midday-style `syncFromUrl` | 1 day |
