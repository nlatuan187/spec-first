# Project: [YOUR PROJECT NAME]

> [One-line description. What does this product do? Who is it for?]

## Tech Stack

[Framework] · [Language] · [Database] · [ORM/Client]
[State management] · [UI library] · [CSS] · [Auth provider]

<!-- Example:
Next.js 14 (App Router) · TypeScript strict · Supabase PostgreSQL
Zustand 5 · Shadcn UI · TailwindCSS · Supabase Auth
-->

## Critical Rules

<!-- These are NON-NEGOTIABLE. AI agents read this file on every session.
     Keep each rule to 1 line. Max 10 rules. -->

1. **AI Provider**: [e.g., "Claude API ONLY" or "OpenAI ONLY" — prevent vendor drift]
2. **Security**: [e.g., "RLS on all tables. Never expose internal IDs in API responses"]
3. **DB Pattern**: [e.g., "All DB access through `lib/services/db/*.ts`. No direct Supabase calls in components"]
4. **API Pattern**: [e.g., "`requireAuth(req)` → try/catch → `success(data)` / `fail(msg, status)`"]
5. **Frontend**: [e.g., "Zustand stores for state. Components in `components/features/[domain]/`"]
6. **i18n**: [e.g., "`useTranslations()` from next-intl. No hardcoded user-facing strings"]
7. **No secrets in code**: [e.g., "Use env vars. Never commit `.env`, API keys, or PII"]

## Directory Structure

<!-- Map the codebase so the AI knows where things live.
     Only include directories that matter. Skip node_modules, .next, etc. -->

```
app/
├── api/           — API routes (REST)
├── [locale]/      — Pages (i18n)
components/
├── features/      — Domain-specific UI (organized by feature)
├── ui/            — Design system primitives (DO NOT modify)
├── shared/        — Cross-feature components
lib/
├── services/db/   — Database CRUD services
├── services/ai/   — AI integration services
├── types/         — TypeScript interfaces (source of truth)
├── constants/     — Enums and config values
├── utils/         — Pure utility functions
├── middleware/     — Auth, rate limiting, API protection
store/             — Zustand state management
db/migrations/     — SQL migration files
messages/          — i18n translation files
```

## API Response Contract

<!-- Define the response wrapper so FE/BE never disagree on shape.
     This is the #1 source of cross-boundary bugs. -->

```typescript
// Backend ALWAYS returns:
{ success: true, data: { /* actual payload */ } }
{ success: false, error: "message" }

// Frontend MUST parse:
const json = await res.json();
const result = json.data;  // ✅ Correct
// NOT: json.result or json.payload (wrong wrapper)
```

## Ownership Zones

<!-- Who owns what. Prevents AI from modifying files outside scope.
     Remove this section for solo developers. -->

| Owner | Directories | Can Modify |
|-------|------------|-----------|
| [Backend dev] | `db/`, `lib/services/`, `app/api/` | Migrations, API routes, services |
| [Frontend dev] | `components/`, `store/`, `app/[locale]/` | UI, state, pages |
| [Shared / PM] | `lib/types/`, `lib/constants/` | Type contracts (requires review) |
| [NOBODY touches] | `components/ui/` (design system), `.env` | Read-only |

## Conventions

- **Files**: kebab-case (`user-profile.ts`)
- **Components**: PascalCase (`UserProfile.tsx`)
- **Functions**: camelCase (`getUserProfile()`)
- **DB columns**: snake_case (`created_at`)
- **Constants**: UPPER_SNAKE_CASE (`MAX_RETRIES`)
- **Errors**: `console.error("[module/function] message:", error)`
- **No `any`**: Use `Record<string, unknown>` or proper types
- **Imports**: Use `@/` alias for root-relative imports

## Git

- **Branch**: `feature/[task-id]-[description]`
- **Commit**: `[task-id]: description` or conventional commits (`feat:`, `fix:`)
- **No force push**
- **No direct push to main** — always PR

<!--
GUIDELINES FOR CUSTOMIZING THIS FILE:
1. Keep it under 150 lines. AI context is expensive.
2. Every line should prevent a specific mistake you've seen AI make.
3. Update this file when you discover new recurring issues.
4. Delete rules that no longer apply.
5. This file evolves — week 1 version will differ from month 3 version.

Version: 1.0
Last updated: [DATE]
-->
