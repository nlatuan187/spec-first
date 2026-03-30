# Integrations

spec-first is designed to be **atomic** — effective standalone or embedded in any AI development ecosystem.

The four-phase cycle (Spec → Generate → Review → Ship), the S1-S6 spec template, and the system context file pattern all work with any language, any AI tool, and any team configuration. The methodology is the portable layer.

---

## At a Glance

| Tool / Method | What It Does | spec-first Integration |
|---------------|-------------|------------------------|
| Claude Code | AI coding agent | Native — CLAUDE.md + /commands |
| gstack | Runtime slash commands (review, ship, QA) | Plugin — copy `advanced/skills/spec/SKILL.md` |
| Kiro IDE (AWS) | Spec-driven agentic IDE | `.kiro/steering/spec-conventions.md` |
| Cursor | AI code editor | `.cursorrules` or `.cursor/rules/*.mdc` |
| Windsurf | AI code editor | `.windsurfrules` + `workflows/spec.md` |
| Codex / Copilot Workspaces | AI coding agents | `AGENTS.md` replaces CLAUDE.md |
| conductor.build | Parallel agent orchestration (Mac app) | Zero config — inherits Claude Code skills |
| CodeRabbit | Automated PR scanning | Drop-in config (`templates/.coderabbit.yaml`) |
| Any AI chat session | Second-pass reviewer | No setup — paste diff + checklist |

---

## Claude Code (Primary, Optimized)

All examples in this repo use Claude Code. It is the primary target because it natively supports persistent context files (`CLAUDE.md`), session management, and multi-file implementation.

**Setup:**
1. `cp spec-first/advanced/templates/CLAUDE.md ./CLAUDE.md` — customize with your stack
2. `cp spec-first/advanced/templates/feature-spec.md ./specs/` — write specs here
3. Feed specs: `Read CLAUDE.md, then implement specs/feature.md`

**Slash command**: Copy `advanced/skills/spec/SKILL.md` to `.claude/commands/spec.md` to get a `/spec` command that generates S1-S6 specs automatically.

---

## gstack (Complementary, Not Competing)

[gstack](https://github.com/garrytan/gstack) provides runtime slash commands: `/review`, `/ship`, `/qa`, `/browse`, and more. It excels at *execution* — landing code, running QA, verifying deployments.

spec-first provides the *methodology* — how to define what to build, how to reduce the fix tax, how to write complete specs.

**Together, they cover the full cycle:**

```
spec-first: SPEC (1-2h) → GENERATE (3-10 min)
gstack:                                       → REVIEW → SHIP (30-60 min total)
```

### Installing /spec as a gstack skill

```bash
# After installing gstack
mkdir -p ~/.claude/skills/spec
cp spec-first/advanced/skills/spec/SKILL.md ~/.claude/skills/spec/SKILL.md

# Available in any Claude Code session
/spec User Authentication Flow
```

`advanced/skills/spec/SKILL.md` follows the [Anthropic Agent Skills](https://agentskills.io) open standard — YAML frontmatter + `{{PREAMBLE}}` placeholder + markdown instructions. It works as-is inside gstack's skill loader.

---

## Kiro IDE (AWS) — Natural Fit

[Kiro](https://kiro.dev) is Amazon's spec-driven agentic IDE with a native spec pipeline (requirements → design → tasks). It has the most natural alignment with spec-first of any tool — it was built around specifications.

Kiro uses EARS (Easy Approach to Requirements Syntax) notation in `requirements.md`:
```
WHEN [condition/event] THE SYSTEM SHALL [expected behavior]
WHEN [invalid input] THE SYSTEM SHALL [error behavior]
```

This maps to S1-S6 directly:

| spec-first Section | Kiro Equivalent |
|--------------------|-----------------|
| S1: Error States | EARS `WHEN [invalid] THE SYSTEM SHALL` criteria |
| S2: Post-Completion | EARS completion criteria |
| S3: Integration | `design.md` dependencies section |
| S4: Copy Review | `design.md` UI notes |
| S5: State Matrix | `design.md` data model section |
| S6: QA Scenarios | `tasks.md` manual verification checkboxes |

**Integration via `.kiro/steering/`** (Kiro's equivalent of CLAUDE.md — always-loaded context):

```bash
mkdir -p .kiro/steering
cat > .kiro/steering/spec-conventions.md << 'EOF'
When writing requirements.md for any feature, include error scenarios using
EARS notation: WHEN [invalid condition] THE SYSTEM SHALL [error behavior]

Cover these categories in every requirements.md:
- Unauthenticated/expired session behavior
- Required field validation messages
- API failure fallback
- Post-completion navigation
- Cross-feature state effects
EOF
```

---

## Cursor

Cursor supports two context formats:

**Legacy (works everywhere):**
```bash
cp spec-first/advanced/templates/CLAUDE.md .cursorrules
```

**New format (`.cursor/rules/*.mdc`) — scoped and conditionally loaded:**
```markdown
# .cursor/rules/spec-format.mdc
---
description: Enforce S1-S6 format when writing feature specs
globs: ["specs/**/*.md"]
alwaysApply: false
---

When writing or reviewing any spec file, ALWAYS include these 6 sections:
S1: Error States & Validation
S2: Post-Completion Flow
S3: Cross-Feature Integration
S4: Copy Review
S5: State & Persistence Matrix
S6: Manual QA Scenarios

[paste S1-S6 template here]
```

The `.mdc` format supports: `alwaysApply: true` (all sessions), `alwaysApply: false` with glob-scoped activation (only when editing spec files), or manual `@rule-name` invocation.

**"New session" in Cursor** = close the chat panel, open a new Composer (⌘+I → New Conversation). Each Composer starts with zero context from the previous one.

---

## Windsurf

Windsurf supports context rules (always-on) and workflows (step-by-step slash commands):

**Context (`.windsurfrules`):**
```bash
cp spec-first/advanced/templates/CLAUDE.md .windsurfrules
```

**Workflow (`.windsurf/workflows/spec.md`)** — invoke with `/spec`:
```markdown
# Write Feature Spec

Generate a complete S1-S6 spec for the described feature.

## Step 1: Read project context
Read .windsurfrules to understand the tech stack and conventions.

## Step 2: Write S1 — Error States & Validation
List all scenarios where the feature can fail...

## Step 3: Write S2 — Post-Completion Flow
...

[Continue for S3-S6]

## Step 7: Save
Write to specs/[feature-slug].md
```

**"New session" in Windsurf** = click the new chat icon (top-right of Cascade panel). Each Cascade chat starts cold.

---

## Codex / GitHub Copilot

These tools read `AGENTS.md` for project context:
```bash
cp spec-first/advanced/templates/CLAUDE.md AGENTS.md
```

**GitHub Copilot Chat** reads `.github/copilot-instructions.md`:
```bash
mkdir -p .github
cp spec-first/advanced/templates/CLAUDE.md .github/copilot-instructions.md
```

Feature specs work as-is — pass `specs/feature.md` as context in prompts.

---

## conductor.build

[conductor.build](https://conductor.build) is a Mac app for orchestrating parallel coding agents across isolated git worktrees. It's a parallelization layer, not a spec format.

**Integration**: Zero config. conductor.build spawns Claude Code instances that inherit the project's `.claude/skills/` and `CLAUDE.md`. If spec-first is set up for Claude Code, every conductor.build agent automatically has access to `/spec` and the review checklist.

---

## Review: Without CodeRabbit

If CodeRabbit is unavailable, run review via a second AI session.

**Why a second session, not your current one?** Your primary session has implementation context — it knows *why* the code does what it does. A second session reads the code as a stranger would, catching blind spots the primary session rationalizes away.

### Setup

Open a new Claude Code session (separate terminal or tab). Do not carry over any context from your implementation session.

```
Read CLAUDE.md, then:
git diff origin/main

Apply the review checklist at advanced/templates/review-checklist.md.
Output Pass 1 (Critical) first. Then Pass 2 (Informational).
Format: [file:line] Problem → recommended fix
```

A cold second session catches ~70% of what CodeRabbit provides. What it misses: automated PR-creation scanning, multi-commit pattern analysis, historical false-positive suppression.

### `/review` from gstack

If you have gstack installed, `/review` runs the full checklist automatically — no second session needed.

---

## Compatibility Matrix

| Tool | Has Native Spec Format? | S1-S6 Integration | Config File | Effort |
|------|:---:|-------------------|-------------|:------:|
| **Claude Code** | Partial (CLAUDE.md) | Native — SKILL.md + /commands | `.claude/skills/spec/SKILL.md` | Low |
| **gstack** | Skill-based | Install `advanced/skills/spec/SKILL.md` | `~/.claude/skills/spec/` | Low |
| **Kiro IDE** | Yes (EARS notation) | `.kiro/steering/spec-conventions.md` | `.kiro/steering/` | Low |
| **Cursor** | Rules (.mdc) | `.cursor/rules/spec-first.mdc` | `.cursor/rules/` | Very Low |
| **Windsurf** | Workflows (.md) | `.windsurf/workflows/spec.md` | `.windsurf/workflows/` | Low |
| **Codex / Copilot** | Partial (AGENTS.md) | `AGENTS.md` + issue templates | `AGENTS.md` | Low |
| **conductor.build** | None (parallelizer) | Inherits Claude Code skills | (none needed) | Zero |

---

## Combining Everything

The highest-leverage configuration:

```
spec-first  → behavioral contracts (S1-S6 completeness, fix tax reduction)
Claude Code → generates implementation from specs
gstack      → /review (pre-landing) + /ship (PR + merge)
CodeRabbit  → automated PR scanning on every push

Cycle: SPEC (1-2h) → GENERATE (3-10m) → REVIEW (30-60m) → SHIP (5m)
```

All four are independently optional. The methodology works with zero tooling. Tools reduce friction — they don't change the cycle.

---

## Roll Your Own

This repo is MIT licensed. The methodology works without any specific tool:

1. **Any AI agent** reads a spec and generates implementation
2. **Any context file** carries project conventions to every session
3. **Any reviewer** — human, second AI session, or automated — verifies behavior
4. **Any version control** lets you track fix:feat ratio

The tools are interchangeable. The methodology compounds regardless.
