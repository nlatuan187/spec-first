# Top 20 Repos Ranked — Comparison Reference

**Stack**: Next.js 14 App Router + TypeScript + Supabase/PostgreSQL + AI features
**ElandHub Stats**: ~96,400 LOC, 509 TS/TSX files, 119 API routes, 26+ Zustand stores

---

## TOP 5 (Deep Code Read)

### Rank 1 — Midday ⭐ 14,100 stars
**URL**: https://github.com/midday-ai/midday
**Stack match**: 10/10 — Next.js + TypeScript + **Supabase** + **Shadcn UI** + **Gemini AI** + Turborepo
**Description**: All-in-one business management (invoicing, time tracking, AI assistant)

**Key learnings from code read**:
- `authActionClient` middleware chain — auth + analytics in one `next-safe-action` wrapper
- Two-layer DB pattern: `packages/supabase/src/queries/index.ts` (raw) + `cached-queries.ts` (React cache)
- `metrics-filter.ts` Zustand store: type predicates (`isPeriodOption`), localStorage SSR guard, `satisfies` keyword
- Per-tab state maps `rowSelectionByTab` — elegant solution vs multiple stores
- `WEAKNESS`: Inconsistent error handling — some queries use `throwOnError()`, others don't

**When to reference**: Architecture decisions for Supabase query layer, Zustand store patterns, AI integration

---

### Rank 2 — Dub ⭐ 23,200 stars
**URL**: https://github.com/dubinc/dub
**Stack match**: 9/10 — Next.js 14 App Router + TypeScript (99.9%) + Zustand + Shadcn/Radix
**Description**: Link attribution platform, 100M+ monthly clicks, gold standard code quality

**Key learnings from code read**:
- `withWorkspace` HOF — handles auth, RBAC, rate limiting, logging, error wrapping in one place
- `waitUntil()` from `@vercel/functions` — send response immediately, fire side effects after
- Zod v4 with `.meta()` for OpenAPI documentation
- `.parseAsync()` vs `.parse()` — async for body validation, sync for URL params
- Prisma `P2002` error interception — unique constraint → semantic `DubApiError`
- `const-array type inference`: `(typeof ARRAY)[number]` for union types
- Type predicates: `isFulfilled<T>`, `isRejected<T>` for `Promise.allSettled`

**When to reference**: API route architecture, TypeScript advanced patterns, HOF patterns

---

### Rank 3 — Inbox Zero ⭐ 10,300 stars
**URL**: https://github.com/elie222/inbox-zero
**Stack match**: 8/10 — Next.js + TypeScript (98.1%) + Shadcn/ui + PostgreSQL/Prisma
**Description**: AI personal email assistant, most similar in AI feature depth

**Key learnings from code read**:
- Thin route pattern: 9-line route file, all logic in `handle-batch.ts`
- `withError` HOF wraps every route — module name as parameter for structured logs
- Zod schema for AI output + post-process hallucination guard (`matchSendersWithFullEmail`)
- `pRetry` + exponential backoff for Gmail API calls — 3 retries
- Template literal key types: `Record<\`${ActionType}-${string}\`, QueueItem>`
- `Promise.all([props.params, props.searchParams])` for parallel async params (Next.js 15)
- `WEAKNESS`: Hardcodes English strings in JSX, no i18n discipline

**When to reference**: AI content generation patterns, error wrapper HOF, retry logic, Zustand queue patterns

---

### Rank 4 — Formbricks ⭐ 12,000 stars
**URL**: https://github.com/formbricks/formbricks
**Stack match**: 8/10 — Next.js + TypeScript + PostgreSQL/Prisma + Vitest + Auth.js
**Description**: Open-source Qualtrics, multi-feature SaaS, very clean architecture

**Key learnings from code read**:
- `import "server-only"` — compile-time security for server-only modules
- `satisfies Prisma.SurveySelect` — preserves literal types for query inference
- Typed error class hierarchy: `DatabaseError`, `InvalidInputError`, `ResourceNotFoundError`
- `withV1ApiWrapper({ handler, action, targetType })` — audit logging as wrapper concern
- Structured logging: `logger.error({ error, url: req.url }, "Error parsing JSON")` (Pino-style)
- `isFilterInitialized` gate — reads localStorage before firing first fetch (prevents data flash)
- `wrapThrows(() => JSON.parse(...))()` — functional JSON safety, handles corrupt localStorage
- `useAutoAnimate` — list animations with zero code
- `WEAKNESS`: Missing `finally` clause in survey list component (loading state stuck on error)

**When to reference**: Vitest patterns, service layer typed errors, structured logging, filter init patterns

---

### Rank 5 — MakerKit Next.js Supabase Lite ⭐ 407 stars
**URL**: https://github.com/makerkit/nextjs-saas-starter-kit-lite
**Stack match**: 10/10 — Next.js 15 + **Supabase** + **Shadcn UI** + i18next + TypeScript + Zod
**Description**: Exact stack match, intentionally minimal for architectural clarity

**Why relevant despite low stars**: Every architectural decision maps directly to ElandHub's choices:
- Supabase RLS migration patterns
- `@supabase/ssr` auth middleware conventions
- i18n setup (vi/en equivalent)
- Feature-based folder structure

**When to reference**: Supabase-specific patterns, auth middleware, i18n setup

---

## FULL TOP 20

| # | Repo | Stars | Stack Match | Primary Value |
|---|------|-------|-------------|---------------|
| 1 | [midday-ai/midday](https://github.com/midday-ai/midday) | 14.1K | 10/10 | Exact stack, production SaaS |
| 2 | [dubinc/dub](https://github.com/dubinc/dub) | 23.2K | 9/10 | Highest code quality, HOF patterns |
| 3 | [calcom/cal.com](https://github.com/calcom/cal.com) | 40.7K | 7/10 | Largest scale, auth/i18n/billing depth |
| 4 | [formbricks/formbricks](https://github.com/formbricks/formbricks) | 12K | 8/10 | Vitest, clean architecture |
| 5 | [elie222/inbox-zero](https://github.com/elie222/inbox-zero) | 10.3K | 8/10 | AI generation patterns |
| 6 | [mfts/papermark](https://github.com/mfts/papermark) | 8.1K | 7/10 | Full Shadcn+Prisma+analytics |
| 7 | [documenso/documenso](https://github.com/documenso/documenso) | 12.5K | 7/10 | tRPC+Prisma+Shadcn |
| 8 | [payloadcms/payload](https://github.com/payloadcms/payload) | 41.5K | 6/10 | Next.js-native, content management |
| 9 | [makeplane/plane](https://github.com/makeplane/plane) | 35.2K | 6/10 | Complex SaaS, large-scale state |
| 10 | [nextjs/saas-starter](https://github.com/nextjs/saas-starter) | 15.5K | 7/10 | Official Vercel architecture reference |
| 11 | [ixartz/SaaS-Boilerplate](https://github.com/ixartz/SaaS-Boilerplate) | 6.9K | 8/10 | i18n + Vitest + Shadcn |
| 12 | [boxyhq/saas-starter-kit](https://github.com/boxyhq/saas-starter-kit) | 4.8K | 7/10 | Enterprise RBAC, SSO, audit logs |
| 13 | [makerkit/nextjs-saas-starter-kit-lite](https://github.com/makerkit/nextjs-saas-starter-kit-lite) | 407 | 10/10 | Supabase+Next.js+Shadcn+i18n |
| 14 | [chroxify/feedbase](https://github.com/chroxify/feedbase) | 659 | 9/10 | Exact stack (Supabase+Shadcn) |
| 15 | [mickasmt/next-saas-stripe-starter](https://github.com/mickasmt/next-saas-stripe-starter) | 3K | 7/10 | RBAC + admin panel |
| 16 | [KolbySisk/next-supabase-stripe-starter](https://github.com/KolbySisk/next-supabase-stripe-starter) | 757 | 9/10 | Feature-based folder structure |
| 17 | [langgenius/dify](https://github.com/langgenius/dify) | 135K | 7/10 | AI workflow architecture |
| 18 | [supabase/supabase](https://github.com/supabase/supabase) | 82K | 8/10 | Supabase Studio on Next.js+Zustand |
| 19 | [unkeyed/unkey](https://github.com/unkeyed/unkey) | 5.2K | 7/10 | API route design, audit logging |
| 20 | [imbhargav5/nextbase-nextjs-supabase-starter](https://github.com/imbhargav5/nextbase-nextjs-supabase-starter) | 771 | 9/10 | Supabase RLS + PLpgSQL migrations |

---

## ElandHub Position

At ~96,400 LOC with 119 API routes and 26 Zustand stores, ElandHub is **larger and more feature-complete** than all starters (Rank 10-20) and comparable in scale to Inbox Zero, Papermark, and Formbricks.

ElandHub lacks the architectural refinement of Midday and Dub (which have full-time engineering teams) but exceeds most open-source projects in:
- Domain depth (Vietnamese BDS, PostGIS, OCR)
- i18n discipline
- DB layer consistency
- Security (RLS, PII handling)

The gap to close is primarily **3 architectural patterns**: HOF wrapper, Zod AI validation, `server-only` imports.
