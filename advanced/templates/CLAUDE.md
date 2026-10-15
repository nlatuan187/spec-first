# Project: [YOUR PROJECT NAME]

> [One-line description. What does this product do? Who is it for?]

## Tech Stack

[Framework] · [Language] · [Database] · [ORM/Client]
[State management] · [UI library] · [CSS] · [Auth provider]

<!-- Example:
Next.js 14 (App Router) · TypeScript strict · Supabase PostgreSQL
Zustand 5 · Shadcn UI · TailwindCSS · Supabase Auth
-->

## Methodology

This project follows the spec-first methodology (see `snippet.md`).

**Three artifacts:**
- `specs/<slug>.md` — written BEFORE code; a prediction.
- `docs/system/<area>.md` — written AFTER code; an observation.
- `KNOWLEDGE.md` — accumulates discoveries across specs.

**Before writing a spec, run the eight checks in `verify.md`** and record the output in
the spec's `## Verification` section. The checks catch invented paths, wrong column names,
missing dependencies, and similar errors that produce review gaps.

**7-step loop:** Clarify → Verify → Spec → Approve (human only) → Build → Review →
Reconcile. Reconcile within one working day of merge: re-read the spec against the diff,
correct what changed, and fold durable findings into `docs/system/<area>.md`.

**Brownfield:** Do not start with a spec. Write `docs/system/<area>.md` from the existing
code first, then spec the change against it.

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
     Only include directories that matter to the AI's work. -->

```
[replace with your actual structure]
```

<!--
LANGUAGE-SPECIFIC EXAMPLE (Next.js / TypeScript — delete if not applicable):

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
-->

## API / Data Contract

<!-- Define the response or data shape so producers and consumers never disagree.
     This is the #1 source of cross-boundary bugs. Use the language/format that fits
     your stack (TypeScript, Python dataclass, protobuf, OpenAPI snippet, etc.). -->

```
[replace with your actual contract]
```

<!--
LANGUAGE-SPECIFIC EXAMPLE (TypeScript REST API — delete if not applicable):

// Backend ALWAYS returns:
{ success: true, data: { /* actual payload */ } }
{ success: false, error: "message" }

// Frontend MUST parse:
const json = await res.json();
const result = json.data;
-->

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

Version: 2.0
Last updated: [DATE]
-->
