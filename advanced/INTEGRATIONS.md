# Integrations

spec-first works with any language, any AI tool, and any team configuration.
The methodology is the portable layer; the templates and hook are the setup cost.

---

## Four templates

| File | Purpose |
|---|---|
| `snippet.md` | Paste into your context file. Core methodology in one file. |
| `spec.md` | Spec template. Copy to `specs/<slug>.md` before each change. |
| `verify.md` | Seven pre-spec checks. Run first; paste output into `## Verification`. |
| `system.md` | Living system document template. Copy to `docs/system/<area>.md` after the change ships. |

---

## Enforcement gate — mechanical vs text

The approval gate rule is: no file edit without an approved spec that names the file.
Some tools can enforce this mechanically; most can only be told about it.

| Tool | Mechanical gate | Text-only gate |
|---|:---:|:---:|
| Claude Code | Yes — `hooks/pre-tool-use` | — |
| conductor.build | Yes (inherits Claude Code hook) | — |
| Kiro IDE | No | Yes |
| Cursor | No | Yes |
| Windsurf | No | Yes |
| Codex / Copilot Workspaces | No | Yes |
| GitHub Copilot Chat | No | Yes |
| Any AI chat | No | Yes |

**Mechanical** means the tool will refuse the edit at the tool-call level. **Text** means the context file tells the model the rule; the model can still proceed if it does not follow the instruction.

Claude Code is the only tool in this list that can enforce the gate mechanically today, via a pre-tool-use hook. conductor.build inherits this because it spawns Claude Code instances that read the project's `.claude/` directory.

---

## Opening a cold session

Each phase of the loop runs in a separate session with zero context from the previous one.
The handoff between phases is a file — the spec, the diff, the review findings — not a continuing conversation.

| Tool | How to open a cold session |
|---|---|
| Claude Code | New terminal or `claude` in a new tab. |
| Cursor | Close the chat panel. Open a new Composer: ⌘+I → New Conversation. |
| Windsurf | Click the new chat icon at the top-right of the Cascade panel. |
| Codex / Copilot | Start a new conversation. |
| Any AI chat | Open a new browser tab or conversation. |

Pass the spec to the build session. Pass the diff to the review session. Do not carry over chat history.

---

## Claude Code

All examples in this repo use Claude Code. It supports persistent context files, pre-tool-use hooks, and slash commands natively.

**New repository:**
```bash
cp spec-first/snippet.md CLAUDE.md
mkdir -p specs docs/system
```
Customize `CLAUDE.md` for your stack and conventions.

**Existing codebase (brownfield):**
```bash
mkdir -p docs/system
# Write docs/system/<area>.md from the code before writing any spec.
```
Start with the system document for the area you are about to change. It is what every spec reads.
Then spec the change against it.

**Enforcement hook:**

Copy `hooks/pre-tool-use` to `.claude/spec-first/pre-tool-use`. The hook rejects any file edit unless
all three conditions hold at once:

1. A spec exists in `specs/`
2. Its `status:` is `approved` or `implementing`
3. Its `## File changes` section names the file being edited (or a directory above it)

One file in `specs/` no longer unlocks the repository. All three must be true simultaneously.

Emergency override: `touch .spec-first-bypass`, fix, write the retroactive spec the same day.

**Slash command:**

Copy `advanced/skills/spec/SKILL.md` to `.claude/commands/spec.md` to get a `/spec` command
that generates specs from the template.

---

## Kiro IDE (AWS)

Kiro's native spec pipeline (requirements → design → tasks) uses EARS notation, which maps
directly to spec-first sections:

| spec-first section | Kiro equivalent |
|---|---|
| Failure modes | EARS `WHEN [invalid] THE SYSTEM SHALL [error behavior]` |
| Acceptance | EARS completion criteria |
| Integration | `design.md` dependencies section |
| State | `design.md` data model section |
| QA | `tasks.md` manual verification checkboxes |

The old S1-S6 names are retired but still resolve: S1 → Failure modes, S3 → Integration, S6 → QA.

**Setup:**
```bash
mkdir -p .kiro/steering
cp spec-first/snippet.md .kiro/steering/spec-conventions.md
```
Kiro loads all files in `.kiro/steering/` as always-on context. No mechanical enforcement is available.

---

## Cursor

**Setup:**
```bash
# Legacy — works everywhere:
cp spec-first/snippet.md .cursorrules

# New format — loads only when editing spec files:
mkdir -p .cursor/rules
```

`.cursor/rules/spec-first.mdc`:
```markdown
---
description: spec-first conventions when writing or reviewing specs
globs: ["specs/**/*.md"]
alwaysApply: false
---

[paste snippet.md here]
```

`alwaysApply: true` loads the rules in every session. `alwaysApply: false` with a glob
loads them only when editing files that match. No mechanical enforcement is available.

---

## Windsurf

**Setup:**
```bash
cp spec-first/snippet.md .windsurfrules
mkdir -p .windsurf/workflows
```

`.windsurf/workflows/spec.md` — invoked with `/spec`:
```markdown
# Write feature spec

## Step 1 — Read context
Read .windsurfrules.

## Step 2 — Run verify.md checks
Run the eight checks. Paste output into ## Verification.

## Step 3 — Write spec
Create specs/<slug>.md from spec.md. Fill every mandatory section.

## Step 4 — Save
Write to specs/<slug>.md.
```

No mechanical enforcement is available.

---

## Codex / GitHub Copilot

```bash
# Codex and Copilot Workspaces:
cp spec-first/snippet.md AGENTS.md

# GitHub Copilot Chat:
mkdir -p .github
cp spec-first/snippet.md .github/copilot-instructions.md
```

No mechanical enforcement is available.

---

## conductor.build

conductor.build spawns Claude Code instances in isolated git worktrees. Each instance inherits
the project's `.claude/` directory and `CLAUDE.md`. If the enforcement hook is in place for
Claude Code, every conductor.build agent runs under the same gate. No additional setup.

---

## gstack

[gstack](https://github.com/garrytan/gstack) provides runtime slash commands (`/review`, `/ship`,
`/qa`). It handles execution; spec-first handles spec completeness. They do not overlap.

```bash
mkdir -p ~/.claude/skills/spec
cp spec-first/advanced/skills/spec/SKILL.md ~/.claude/skills/spec/SKILL.md
```

Once installed, `/spec` is available in any Claude Code session and generates specs from the template.

---

## Review without an automated scanner

When no automated PR scanner is available, run review in a separate cold session.

```
Read CLAUDE.md, then:
git diff origin/main

Apply the review checklist at review.md.
Output Pass 1 (Critical) first. Then Pass 2 (Informational).
Format: [file:line] Problem → recommended fix
```

A cold review session catches what the build session rationalised away. A session that wrote the
code knows why every decision was made; a session that starts cold reads the diff as a stranger would.

---

## Alternatives — when to use something else

spec-first covers one problem: writing specs complete enough that the build succeeds on the first
pass. It does not manage execution pipelines, parallelism, or role-based handoffs. If those are
your bottleneck, use one of these instead.

| Tool | What it does better | When to reach for it |
|---|---|---|
| BMAD Method | Role-based agent orchestration (PM, Architect, Dev, QA) with structured handoff between named roles | Multi-agent teams where who-does-what in what order is the primary bottleneck |
| Spec-Kit | Constitution-first governance; starts from project values, then derives specs | Teams that want to ratify a shared set of principles before writing any individual spec |
| OpenSpec | Broader specify → plan → tasks → implement pipeline with opinionated task management | Projects where task breakdown and assignment, not spec quality, is the primary need |

A team that adopts BMAD's role model does not need spec-first's spec loop layered on top of it.
These are listed so a reader who needs what they provide goes and uses them rather than trying
to adapt spec-first to a problem it was not built for.
