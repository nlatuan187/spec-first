---
name: spec
preamble-tier: 2
version: 1.0.0
description: |
  Generate a complete feature spec with all 6 mandatory sections (S1-S6):
  Error States, Post-Completion Flow, Cross-Feature Integration, Copy Review,
  State Matrix, and Manual QA Scenarios. Use when asked to "write a spec for",
  "spec out a feature", "create requirements for", "document this feature", or
  "I want to build [feature]". Produces a ready-to-implement behavioral contract
  saved to the specs/ directory.
effort: medium
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
---

{{PREAMBLE}}

# /spec: Generate Feature Spec

You are generating a behavioral contract — the primary engineering artifact that drives AI implementation. This is not documentation written after the fact. It is the specification that comes before the implementation.

A good spec prevents 65% of review failures. A bad spec produces bad code at machine speed.

---

## Step 1: Get the Feature Name

If arguments were provided (e.g., `/spec User Authentication`), use them as the feature name and description.

If no arguments: ask once — "What feature do you want to spec? (one sentence)"

---

## Step 2: Read Project Context

Look for a system context file in this order:
1. `CLAUDE.md` (Claude Code)
2. `AGENTS.md` (Codex / GitHub Copilot Workspaces)
3. `.cursorrules` (Cursor)
4. `.windsurfrules` (Windsurf)
5. `.github/copilot-instructions.md` (GitHub Copilot Chat)

If found, read it. Extract: tech stack, API patterns, state management approach, directory structure, conventions.

If not found, proceed without project-specific context and note it in the spec header.

---

## Step 3: Clarify (Only If Needed)

If the feature description is ambiguous about *what the user does or sees*, ask ONE focused question:

"What's the user's goal? (e.g., 'upload a profile photo and see it reflected immediately')"

Do NOT ask about implementation. Do NOT ask multiple questions. One answer is enough.

If the feature name is self-explanatory, skip this step entirely and proceed to Step 4.

---

## Step 4: Generate the Spec

Generate a complete spec using the structure below. Fill every section — do not leave placeholder text.

The most commonly skipped and most expensive sections are S1 (Error States) and S3 (Integration). Be thorough here.

---

```markdown
# [Feature Name]

> **Status**: Draft
> **Stack**: [from CLAUDE.md, or "Not specified"]

## Overview

**Goal**: [What the user accomplishes — one sentence]
**Trigger**: [What causes this feature to activate — user action, system event, etc.]
**Users affected**: [Who uses this feature]

---

## Acceptance Criteria

- [ ] [Primary success: what the user can do when this feature is complete]
- [ ] [Secondary condition]
- [ ] [Edge case that must work]

---

## S1: Error States & Validation

| Scenario | Expected Behavior |
|----------|------------------|
| Unauthenticated / session expired | [redirect to login / show message / silent refresh] |
| Required field missing | [highlight field + show message: "X is required"] |
| Invalid input format | [inline validation message] |
| API / service failure | [toast error + retry option / fallback UI] |
| Resource not found | [empty state / 404 message] |
| Rate limit / quota exceeded | [block with explanation + upgrade path if applicable] |
| Concurrent modification conflict | [optimistic lock failure message / refresh prompt] |

---

## S2: Post-Completion Flow

| Event | Result |
|-------|--------|
| Feature completes successfully | [where user goes / what they see / what auto-saves] |
| User navigates away mid-flow | [auto-save? / "unsaved changes" dialog? / discard silently?] |
| User refreshes the page mid-flow | [what persists / what resets] |
| Session expires mid-flow | [save draft? / redirect to login? / lose work?] |
| Output constraints | [max length / file size limit / platform-specific limits] |

---

## S3: Cross-Feature Integration

| When This Happens | This Feature | Triggers / Updates |
|-------------------|-------------|-------------------|
| [upstream event] | → | [downstream effect in this feature] |
| [this feature action] | → | [downstream effect in another feature] |

**Shared state**: [What state is shared with other features? What store/event/prop?]
**Empty state**: [What does the user see if prerequisite data doesn't exist yet?]
**Cleanup**: [What resets when the user leaves this feature? What state/cache clears?]

---

## S4: Copy Review

- [ ] All user-facing text reviewed — no developer jargon
- [ ] Error messages use plain language ("Connection failed. Try again." not "500 Internal Server Error")
- [ ] Labels and buttons are self-explanatory to non-technical users
- [ ] Confirmation messages are specific ("Document saved" not "Success")
- [ ] Loading states have descriptive text ("Uploading photo..." not "Loading...")
- [ ] Empty states have a clear next action ("No items yet. Create your first →")

---

## S5: State & Persistence Matrix

| Data | Stored Where | Persists After Refresh? | Cleared When |
|------|-------------|------------------------|--------------|
| [field name] | [memory / localStorage / sessionStorage / DB / cache] | Yes / No | [navigation / logout / timeout / manual] |

---

## S6: Manual QA Scenarios

- [ ] **Happy path**: [step-by-step → expected result]
- [ ] **Error — API fails**: trigger API failure → user sees [specific message], can retry
- [ ] **Error — invalid input**: submit with [specific bad input] → user sees [specific message]
- [ ] **Empty state**: no existing data → user sees [specific UI], can [create first item]
- [ ] **Loading**: click [action] → result appears within [X seconds]; loading indicator visible
- [ ] **Mobile**: test at 375px width — all elements accessible, no horizontal scroll
- [ ] **Refresh mid-flow**: refresh at [specific step] → [data preserved / user returned to start]
- [ ] **Concurrent use**: [if relevant] open in two tabs → [expected behavior]
```

---

## Step 5: Save the Spec

1. Convert the feature name to a kebab-case filename:
   - "User Authentication" → `user-authentication.md`
   - "Bulk Photo Upload" → `bulk-photo-upload.md`

2. Check if `specs/` directory exists:
   ```bash
   ls specs/ 2>/dev/null || mkdir -p specs
   ```

3. Write the spec to `specs/[slug].md`

4. Report to the user:
   ```
   ✓ Spec written: specs/[slug].md

   ─── STOP HERE ────────────────────────────────────────────────────
   This session's job is done. END THIS SESSION before implementing.

   Why: Implementation in the same session as spec-writing produces
   biased output — the AI "knows" the spec and skips error states it
   just defined. A fresh session reads the spec cold.

   Next steps (each in a NEW session):

   1. [Optional] Review spec:
      New session → "Read CLAUDE.md, review specs/[slug].md for
      completeness — S1 error states, S3 integration, S6 QA"

   2. Implement:
      New session → "Read CLAUDE.md, then implement specs/[slug].md"

   3. Verify coverage:
      /spec-check specs/[slug].md

   4. Review code:
      New cold session → "git diff origin/main, apply review-checklist"
   ──────────────────────────────────────────────────────────────────
   ```

---

## Notes

- **Do not specify implementation.** Specs define behavior, not code. "Store the user ID" is behavior. "Use a UUID primary key" is implementation. Put behavior in specs, let AI decide implementation.
- **S1 and S3 are the highest-value sections.** They prevent 65% of review failures. If you're short on time, be thorough here and brief everywhere else.
- **S6 scenarios must be testable by a human** who hasn't read the code. "Works correctly" is not a scenario. "Click Save with empty title field → red border on field, 'Title is required' shown below" is a scenario.
- **The Copy Review (S4)** is frequently skipped and frequently causes rework. Hardcoded strings and developer jargon in user-facing text account for ~10% of fixes on AI-generated code.

---

## Install as a Claude Code command

To use `/spec` directly in Claude Code:

```bash
mkdir -p .claude/commands

# If you cloned spec-first locally:
cp path/to/spec-first/advanced/skills/spec/SKILL.md .claude/commands/spec.md

# Or fetch directly:
curl -fsSL https://raw.githubusercontent.com/nlatuan187/spec-first/master/advanced/skills/spec/SKILL.md \
  -o .claude/commands/spec.md
```

Claude Code will expose it as `/spec` in any session within this project.
