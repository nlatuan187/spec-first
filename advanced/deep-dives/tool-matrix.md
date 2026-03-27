# Tool Matrix: Which AI Tool for Which Task

Not all AI tools are interchangeable. Each has a specific role in the spec-first pipeline. Using the wrong tool for a task wastes time and produces worse output.

---

## The Decision Matrix

| Task | Best Tool | Why | Alternative |
|------|----------|-----|------------|
| **Architecture planning** | Claude Code (Opus) | Deep reasoning, considers trade-offs, long context | — |
| **Feature implementation** | Claude Code (Sonnet) | Best cost/performance for multi-file code generation | Cursor (if IDE-integrated) |
| **Quick single-file fix** | Claude Code (Haiku) | Fast, cheap, sufficient for simple edits | Copilot inline |
| **PR review** | CodeRabbit | Purpose-built, severity ratings, cross-file analysis | Claude Code `/review` |
| **Inline completion** | GitHub Copilot | Low-latency, stays in editor flow | Cursor Tab |
| **Spec writing** | Claude Code (Opus/Sonnet) | Understands product context, generates S1-S6 sections | — |
| **Debugging** | Claude Code (Sonnet) | Can read error + codebase + suggest fix | — |
| **Refactoring** | Claude Code (Sonnet) | Multi-file awareness, pattern consistency | Cursor |
| **Test generation** | Claude Code (Sonnet) | Reads implementation + spec → generates tests | — |

---

## Model Selection Guide

### Claude Code Models

| Model | Best For | Cost | Speed |
|-------|---------|------|-------|
| **Opus** | Architecture, complex planning, spec writing, deep analysis | Highest | Slowest |
| **Sonnet** | Day-to-day implementation, debugging, refactoring, tests | Medium | Fast |
| **Haiku** | Quick fixes, formatting, simple edits, boilerplate | Lowest | Fastest |

**Rule of thumb**: Start with Sonnet. Use Opus when you need the AI to "think harder" (architecture decisions, complex refactoring, spec writing). Use Haiku for routine tasks where speed matters more than depth.

### When to Switch Models

```
Task taking too long with Haiku?      → Switch to Sonnet
Sonnet output not thorough enough?    → Switch to Opus
Opus spending 5 minutes on a typo fix? → Switch to Haiku
```

---

## Tool Roles in the Pipeline

### Phase 1: Spec (Human + Claude Opus)

```
Human writes spec → Claude Opus reviews for completeness
"Review this spec. What edge cases am I missing? What will break?"
```

Opus is worth the cost here because spec quality determines everything downstream.

### Phase 2: Generate (Claude Sonnet)

```
"Read CLAUDE.md, then implement specs/feature-name.md"
```

Sonnet handles 90% of implementation tasks. Multi-file changes, API routes, components, services, types — all generated from the spec.

### Phase 3: Review (CodeRabbit + Human)

```
Push PR → CodeRabbit auto-reviews → Human reviews behavior
```

**Why CodeRabbit over Claude for review:**
- Purpose-built for PR review (severity ratings, cross-file analysis)
- Catches security issues Claude generated (AI reviewing its own code misses systematic blind spots)
- Runs automatically on every PR (no human action needed)
- Free tier available

### Phase 4: Ship (Human)

Merge. Deploy. No AI needed.

---

## Tool Comparison for Common Tasks

### Code Generation

| Tool | Strengths | Weaknesses |
|------|-----------|-----------|
| **Claude Code** | Multi-file, spec-driven, understands full codebase | Terminal-based (no visual IDE) |
| **Cursor** | IDE-integrated, visual diff, tab completion | Single-file focus, less autonomous |
| **GitHub Copilot** | Fast inline completion, low latency | Can't do multi-file changes, no spec awareness |
| **Windsurf** | IDE-integrated, Cascade for multi-step | Newer, less tested at scale |

**Our choice**: Claude Code for all generation. The terminal-based workflow matches spec-first development — you write a spec, feed it in, review the output. IDE integration is less important when you're not writing code manually.

### Code Review

| Tool | Strengths | Weaknesses |
|------|-----------|-----------|
| **CodeRabbit** | Severity ratings, security focus, cross-file analysis | Paid for advanced features |
| **GitHub Copilot Review** | Free with Copilot, catches style issues | Single-file, no severity ratings |
| **Claude Code `/review`** | Deep analysis, understands intent | Manual trigger, no PR integration |

**Our choice**: CodeRabbit as primary (automated, severity-rated). Copilot as bonus (catches small things CodeRabbit misses).

---

## Cost Optimization

### Monthly Cost by Configuration

| Configuration | Tools | Monthly Cost |
|--------------|-------|:------------:|
| **Solo Minimal** | Claude Code Pro + CodeRabbit Free | ~$100 |
| **Solo Full** | Claude Code Pro + CodeRabbit Pro | ~$115 |
| **Duo** | 2x Claude Code Pro + CodeRabbit Pro | ~$215 |
| **Team (5)** | 5x Claude Code Pro + CodeRabbit Team | ~$550 |

### Cost Per Feature

From our data: ~$360 infrastructure for 106 merged PRs = **~$3.40 per shipped feature**.

Traditional: $300K / 106 features = **~$2,830 per shipped feature**.

Even at emerging market rates: $60K / 106 = **~$566 per feature**.

AI infrastructure cost is negligible compared to human cost. Optimize for human time, not AI cost.

---

## Anti-Recommendations

Tools we evaluated and chose NOT to use:

| Tool | Why Not |
|------|---------|
| ChatGPT / GPT-4 web interface | No codebase awareness. Copy-pasting code is friction. |
| Aider | Good for small projects, but less autonomous than Claude Code for spec-driven workflow. |
| v0 / Bolt / Lovable | Good for prototyping, not for production codebases with existing patterns. |
| Multiple AI providers | Vendor consistency matters. Switching between Claude and GPT creates style conflicts in your codebase. Pick one and commit. |

---

## Setup Checklist

### Minimum Viable Stack (5 minutes)

```bash
# 1. Install Claude Code
npm install -g @anthropic-ai/claude-code

# 2. Add system context
cp spec-first/advanced/templates/CLAUDE.md ./CLAUDE.md
# → Customize for your project

# 3. Add review config
cp spec-first/advanced/templates/.coderabbit.yaml ./.coderabbit.yaml

# 4. Write first spec
cp spec-first/advanced/templates/feature-spec.md ./specs/my-feature.md
# → Fill in all 6 sections

# 5. Generate
claude "Read CLAUDE.md, then implement specs/my-feature.md"

# 6. Review + merge
git push → CodeRabbit reviews → you review behavior → merge
```

You're now doing spec-first development.
