# During-Coding Layer

The spec-first methodology has three moments where AI needs structure:

```
BEFORE coding   →  advanced/skills/spec/SKILL.md    →  /spec        (generate S1-S6 spec)
DURING coding   →  this folder            →  /spec-check  (verify coverage)
AFTER coding    →  templates/review-*     →  /review      (security + quality)
```

This folder covers the **during-coding** layer.

---

## The Problem It Solves

You write a spec. You implement it. But:

1. **Session length**: Long sessions accumulate context. You forget what S3 said about the downstream effect. You implement the happy path and skip two error states.

2. **Context loss between sessions**: You restart and lose which decisions were made, what's done, what's in progress.

3. **Integration blind spots**: S3 is the hardest section to implement completely. It requires touching multiple files. Easy to miss in the middle of building a component.

`/spec-check` catches gaps before you ship. The Implementation Brief prevents context loss between sessions.

---

## Tools in This Folder

### `/spec-check` — Coverage Auditor

```bash
# Install as Claude Code slash command
cp spec-first/advanced/skills/spec-check/SKILL.md .claude/commands/spec-check.md

# Use during or after implementation
/spec-check specs/user-authentication.md
```

Output:
```
### S1 Error States — ⚠️ PARTIAL
  ❌ "API returns 500" — no toast shown, only console.error at auth/route.ts:47
  ✅ "Session expired" — redirect + toast implemented

### S3 Integration — ❌ MISSING
  ❌ "Login → refresh user profile" — no refetch after auth at layout.tsx
```

Run it before marking a feature done. Run it when the spec says S3 has downstream effects.

### `implementation-brief.md` — Session Bridge

A 40-line compressed template. Fill it at the start of an implementation session. When context runs long and you need a new session, paste this brief instead of re-reading the full spec.

**What it prevents**: 15+ minutes of context rebuilding per session restart. Decisions being re-litigated. Implementation drift from the original spec.

---

## Workflow

```
1. Write spec (feature-spec.md)
2. Start new session: "Read CLAUDE.md, then implement specs/[feature].md"
3. Fill implementation-brief.md as you work
4. When context gets long: new session → paste brief → continue
5. Before PR: /spec-check specs/[feature].md
6. Fix gaps, then: /review (review checklist)
7. Merge
```

---

## When to Use /spec-check

| Situation | Action |
|-----------|--------|
| After implementing main feature | Always run |
| Before opening a PR | Required |
| After a context-clearing session restart | Run if S3 involved |
| When "I think I got everything" feeling | Run — you probably missed S1 |
| Bug report matches spec scenario | Check if spec-check would have caught it |
