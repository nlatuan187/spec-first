# spec-first — Agent Guidelines

> This repo contains the spec-first methodology for AI-assisted development. No application code — only markdown and one bash script.

## Structure

```
spec-first/
├── snippet.md           ← THE product — paste into CLAUDE.md, .cursorrules, AGENTS.md, etc.
├── spec.md              ← Feature spec template (S1-S6, EARS acceptance criteria)
├── review.md            ← Two-pass code review checklist
├── install.sh           ← curl-friendly installer
├── README.md            ← Entry point
└── advanced/
    ├── prp.md               ← Full implementation blueprint (optional, for complex features)
    ├── ETHOS.md
    ├── INTEGRATIONS.md
    ├── skills/
    │   ├── spec/SKILL.md        ← /spec slash command for Claude Code
    │   ├── spec-review/SKILL.md ← /spec-review slash command
    │   ├── spec-check/SKILL.md  ← /spec-check slash command
    │   └── spec-stats/SKILL.md  ← /spec-stats slash command
    ├── deep-dives/              ← ai-limitations.md, worktree-workflow.md, etc.
    ├── during-coding/           ← implementation-brief.md
    ├── templates/               ← full feature-spec.md, review-checklist.md, CLAUDE.md template
    └── examples/
```

## Rules

1. **No application code** — methodology + templates only. No TypeScript or Python except install.sh.
2. **Markdown quality** — every file must be directly usable. No placeholder text.
3. **Evidence-based** — claims in README.md and ETHOS.md reference real data. Do not invent metrics.
4. **Tool-agnostic** — snippet.md works on Cursor, Windsurf, Copilot, Claude Code. Do not make it Claude Code-specific.
5. **snippet.md is the core** — any methodology change goes there first, then propagates to advanced/ files.

## Consistent numbers (use these everywhere)

- Week 1 fix:feat: **5:1**
- Week 4 fix:feat: **1.5:1**
- Productivity multiplier: **10–15x** (never "100x")
- Team: **2 people, 24 days**
- S1 + S3 prevent: **65% of review failures**

## When to edit what

| Goal | File |
|------|------|
| Change the Fundamental Law or derived rules | `snippet.md` |
| Change the spec template | `spec.md` (root) and `advanced/templates/feature-spec.md` |
| Change the full implementation blueprint | `advanced/prp.md` |
| Change the review checklist | `review.md` (root) and `advanced/templates/review-checklist.md` |
| Change /spec slash command | `advanced/skills/spec/SKILL.md` |
| Change /spec-check | `advanced/skills/spec-check/SKILL.md` |
| Change /spec-stats | `advanced/skills/spec-stats/SKILL.md` |
| Change install behavior | `install.sh` |
| Add tool integration | `advanced/INTEGRATIONS.md` |
| Change core principles | `advanced/ETHOS.md` |
