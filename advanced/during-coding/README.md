# During-Coding Layer

The spec-first methodology has three moments where AI needs structure:

```
BEFORE coding   →  spec.md + verify.md              →  spec + seven checks
DURING coding   →  this folder                      →  /spec-check  (verify coverage)
AFTER coding    →  review.md                        →  /review (quality) + reconcile
```

This folder covers the **during-coding** layer.

---

## The Problem It Solves

You write a spec. You implement it. But:

1. **Session length**: Long sessions accumulate context. You forget what Integration said about the downstream effect. You implement the happy path and skip two error states.

2. **Context loss between sessions**: You restart and lose which decisions were made, what's done, what's in progress.

3. **Integration blind spots**: Integration is the hardest section to implement completely. It requires touching multiple files. Easy to miss in the middle of building a component.

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
### Failure modes — ⚠️ PARTIAL
  ❌ "API returns 500" — no toast shown, only console.error at auth/route.ts:47
  ✅ "Session expired" — redirect + toast implemented

### Integration — ❌ MISSING
  ❌ "Login → refresh user profile" — no refetch after auth at layout.tsx
```

Run it before marking a feature done. Run it when the spec's Integration section has downstream effects.

### `implementation-brief.md` — Decision Record

A 40-line compressed template. Fill it at the start of an implementation session. Automatic compaction handles most session continuity; what it does not preserve is the explicit record of why non-obvious choices were made and which files are deliberately out of scope.

**What it prevents**: Decisions being re-litigated. Implementation drift from the original spec caused by out-of-scope edits.

---

## Workflow

```
1. Run verify.md's seven checks; record output in spec's ## Verification
2. Write spec (spec.md) with Verification filled; a human approves it
3. Build: new session → "Read CLAUDE.md + approved spec + KNOWLEDGE.md, then implement"
4. Fill implementation-brief.md as you work; restart sessions via the brief when needed
5. Before PR: /spec-check specs/[feature].md → fix gaps → /review
6. Merge
7. Reconcile within one working day: re-read spec against merged diff, correct paths,
   fold durable parts (invariants, thresholds, known issues) into docs/system/<area>.md
```

---

## When to Use /spec-check

| Situation | Action |
|-----------|--------|
| After implementing main feature | Always run |
| Before opening a PR | Required |
| After a context-clearing session restart | Run if Integration section has downstream effects |
| When "I think I got everything" feeling | Run — you probably missed Failure modes |
| Bug report matches spec scenario | Check if spec-check would have caught it |
