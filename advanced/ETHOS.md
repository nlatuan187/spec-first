# Ethos

> "We did not write code. We wrote intent. The machine wrote code."

---

## Who This Is For

**Solo developers and 2–3 person teams shipping an existing product, 3–5 features per week.**

Not for planning committees. Not for enterprise governance workflows. Not for teams that need to coordinate 10 engineers across parallel tracks.

For those users, there are better tools: Spec-Kit for constitution-first governance, BMAD for multi-agent role orchestration, GSD-2 for wave-parallel execution. They are not competitors — they're tools for different users at different scales. See [INTEGRATIONS.md](INTEGRATIONS.md).

For the solo dev or small team that needs a spec written in 10 minutes and code shipped today, spec-first is purpose-built.

---

## Why spec-first works differently

Every other tool in this space adds a **layer on top of your workflow** — a CLI, a framework, an agent to invoke.

spec-first works differently: it modifies **the AI itself** by embedding methodology in the context file the AI already reads. No CLI to install. No agents to invoke. No commands to remember. You paste one file, open a new session, and the AI enforces the discipline on itself.

This has a concrete consequence: **zero orchestration overhead.** GSD-2 has 4:1 token overhead for context management. BMAD uses 50–100K tokens for Party Mode. spec-first uses 0. The methodology is already in context.

The tradeoff is scope: spec-first doesn't manage execution, parallelism, or multi-agent coordination. It does one thing — makes specs complete enough that implementation sessions succeed on the first pass.

---

## Scale-independent methodology

The Fundamental Law applies at every team size. Happy-path bias exists whether you have 1 developer or 100. Isolation blindness is actually worse at larger teams — more features to integrate, more surface area to miss. Session isolation, S1 completeness, S3 enumeration: these rules don't have a scale limit.

What scales is **coordination**, not the methodology:

| Scale | spec-first handles | Add separately for |
|---|---|---|
| 1–3 devs | Everything | — |
| 3–10 devs | Spec quality | Approval gate, PR template (in team-workflow.md) |
| 10+ devs | Spec quality | Multi-agent orchestration ([BMAD](https://github.com/bmad-method/BMAD-METHOD)) |

BMAD solves who-does-what in what order. spec-first solves spec quality. Different axes — they add, not replace.

Spec-Kit is a different spec *philosophy* (constitution-first vs law-first). Neither is subordinate to the other — you pick one based on whether you want to start from project values (Spec-Kit) or from AI failure modes (spec-first).

---

## The Core Bet

AI can generate implementation faster than any human. But AI has no judgment about *what* to build, no adversarial thinking about *what could break*, and no product intuition about *what users need*.

Spec-first is a division of labor based on that asymmetry:

- **You**: define intent, set constraints, verify outcomes, make judgment calls
- **AI**: translate intent into implementation, across as many files as needed, in minutes

The spec is not documentation. The spec is the primary act of engineering. Writing a good spec is harder than writing good code — and more leveraged.

---

## Six Principles

### 1. Specs Compound

A bad spec produces bad output. You fix it. The fix ratio is 5:1 — five fix commits per feature.

A good spec produces good output. Fix ratio drops to 1.5:1.

The 3.5x improvement in fix ratio compounds. Every week you write better specs, you produce more usable output per day. The system gets faster as it gets more precise.

**Measure this**: Track your fix:feat ratio weekly. It is the single metric that tells you whether your specs are improving.

**Anti-pattern**: "We'll write better specs when we have time." You never have time. The fix ratio is the cost of not having time now.

---

### 2. The Tax Is Real

AI-generated output has a systematic fix tax. Ours was **2.93:1** for the first month. It improved to 1.5:1 as specs matured.

Nobody talks about this honestly. "AI writes production code" claims skip the part where a significant portion of your commits are fixing what AI got wrong.

The tax is not a failure. It is the price of generating 82,000 lines in 24 days. The equation:

```
Without AI: 1 feature / day, 0 fix overhead
With AI (bad specs): 3 features / day, 2.93:1 fix overhead → 1 net feature / day
With AI (good specs): 10 features / day, 1.5:1 fix overhead → 6.7 net features / day
```

**The goal is not to eliminate the tax. The goal is to reduce it while increasing the base rate.**

The S1-S6 spec sections exist specifically to reduce the tax by targeting the categories where AI fails most systematically.

---

### 3. Context Is the Constraint

AI's output quality is bounded by the context it receives. Not by its capabilities — by yours.

Three context levers:

**Your system context file** (project context): What stack. What patterns. What conventions. What's off-limits. Without it, every session starts from zero and the AI invents patterns that conflict with your codebase.

This file goes by different names in different tools:
- `CLAUDE.md` — Claude Code
- `AGENTS.md` — Codex, GitHub Copilot Workspaces
- `.cursorrules` — Cursor
- `.windsurfrules` — Windsurf
- `.github/copilot-instructions.md` — GitHub Copilot Chat

The name doesn't matter. The content does. See `templates/CLAUDE.md` for what to put in it.

**The spec** (task context): What the user sees. What happens on error. How state persists. Without it, the AI builds the happy path and ignores everything else.

**Prior output as input** (session context): Copy the output from one session into the next. AI sessions are isolated — paste-bridging is how you build continuity across sessions.

**Anti-pattern**: One giant context window trying to do everything. Context exhaustion costs ~15 minutes per recovery. Keep sessions focused. Use your system context file for persistence.

---

### 4. Reading Is the New Coding

The old workflow: 70% writing, 30% reading.
The new workflow: 30% writing (specs), 70% reading (AI output).

This inversion is uncomfortable for engineers who derive identity from writing code. It requires a different skill: reading AI-generated output critically, spotting the systematic blind spots, and knowing when to accept vs. when to prompt for correction.

**What to look for when reading AI output:**
- Happy-path-only code (missing S1: Error States)
- Isolated features that don't connect to the system (missing S3: Integration)
- State that doesn't persist or clean up (missing S5: State Matrix)
- Hardcoded strings, developer jargon in user-facing text (missing S4: Copy)

Automated review tools are not a substitute for reading. They catch different issues than human review. Use both.

---

### 5. Session Boundaries Are Knowledge Boundaries

One of the most counterintuitive practices in spec-first development: using MORE AI sessions, not fewer.

The instinct is to keep context alive — "I don't want to re-explain everything." But accumulated context is also accumulated bias. A session that implemented a feature will rationalize that implementation when asked to review it. A session that's 60 messages long weights early constraints less than recent ones.

**Session boundary = knowledge boundary.** What happens in Session A stays in Session A. The handoff between sessions is a file — spec, diff, review findings — not a continuing conversation.

This has three practical consequences:

**One: each phase is a separate session.**
Spec session writes the spec and ends. Implementation session reads the spec cold and implements. Review session reads the diff cold and reviews. No shared context between phases.

**Two: the review session must be cold.**
An AI that just implemented a feature knows why every decision was made. When asked to review its own work, it applies motivated reasoning. A cold review session — no prior context — catches what the implementation session rationalized away. Every AI tool has a way to open a fresh session. Use it.

**Three: the brief bridges long sessions.**
When a single implementation session runs long, compress current state to 40 lines using the implementation brief (`during-coding/implementation-brief.md`). Start a new session. Paste the brief. Continue. 5 minutes of compression saves 20 minutes of context rebuilding.

→ [Why each failure mode occurs and the mechanism behind each fix](deep-dives/ai-limitations.md)

---

### 6. Completeness Is Cheap

The marginal cost of completeness is near-zero when AI generates implementation.

The question used to be "is this worth the engineering time?" With AI-assisted development, the calculus changes:

```
Human team: 100% solution takes 2x the time of 80% solution
AI-assisted: 100% solution takes 1.1x the time of 80% solution
```

When writing specs, default to completeness. Specify all error states — not just the main one. Cover all edge cases. Write all QA scenarios. The spec takes 20 minutes more. The AI generates the complete implementation. You avoid 2 hours of debugging the 20% you skipped.

**"Boil the lake"**: A "lake" is achievable — complete error handling, all state cases, full QA coverage. An "ocean" is not — rewriting the entire architecture. Boil lakes. Flag oceans.

The 6-section spec template (S1-S6) exists to force lake-boiling. Each section targets the most common incomplete implementations.

---

## What Changes

**Typing speed is irrelevant.** A developer who types 120 WPM has zero advantage over one who types 40. The bottleneck is judgment, not keystrokes.

**Breadth beats depth** (for now). Understanding a little about databases, frontend, infrastructure, and security is more valuable than deep expertise in one framework. You need to evaluate AI output across the full stack.

**Architecture happens before implementation.** In traditional development, architecture and implementation are interleaved — you discover constraints as you build. Spec-first forces architecture up front. The spec IS the architecture. The implementation is execution.

**Product judgment is the irreducible skill.** We reverted 3 features that AI built perfectly — they were the wrong features. No spec template, no AI tool, no framework prevents you from building the wrong thing. Product judgment is what remains after AI handles implementation.

---

## What Doesn't Change

**Security is adversarial thinking.** AI doesn't think like an attacker. Every auth flow, every data exposure surface, every input validation path requires a human to ask "how would someone misuse this?" Automate the pattern-matching (CodeRabbit, `claude review`, or equivalent). Keep the adversarial thinking human.

**Systems architecture is holistic thinking.** AI builds components. Humans build systems. Understanding how modules connect, where state flows, where failures cascade — this requires seeing the whole. AI sees the file. You see the system.

**User empathy is irreplaceable.** "Does this solve the user's actual problem?" cannot be delegated to AI. Your specs encode the answer. The AI builds whatever you specify. If you specify wrong, you get the wrong thing built correctly.

---

## The Number

We measured 10–15x productivity improvement over traditional development.

Not 100x. Here is why:

| Activity | Compresses? | Why |
|----------|:-----------:|-----|
| Code generation | **Yes (50-100x)** | AI types fast |
| Spec writing | No (0x) | Requires human judgment |
| Review | No (0x) | Humans verify behavior |
| Architecture | No (0x) | Holistic thinking required |
| Bug fixing | Partial (~3x) | AI helps but context rebuilding is slow |

The overall system produces **10–15x** because only some activities compress. The activities that don't compress (spec, review, architecture) are the ones that require judgment. They're also the ones you want humans doing.

**100x is the wrong goal.** 10–15x with the same quality bar is transformative. Two people now ship what five previously needed.

---

## The Architecture Travels

spec-first is not tied to a language, framework, or AI tool.

The methodology works with any AI coding agent — Claude Code, Cursor, Windsurf, Codex, Copilot Workspaces. The system context file travels under different names. The spec template is plain markdown. The review checklist is a list of questions, not a tool.

**Optimized for Claude Code**: All examples use Claude Code. The templates are tuned for how Claude Code reads context, handles sessions, and generates code.

**Compatible with everything else**: The underlying architecture — write specs before code, give AI project context, review with adversarial eyes, ship incrementally — works regardless of which tool generates the implementation.

**Execution pair**: [GSD-2](https://github.com/gsd-build/gsd-2) solves context management at execution time (fresh 200K token window per task, auto/step modes). Different problem, different scope — they stack without conflict.

**When to use something else instead**: For multi-agent orchestration (10+ devs, named roles), use BMAD. For formal governance with constitution-first workflows, use Spec-Kit. These are different methodologies for different scales — not tools that combine with spec-first.

→ [Ecosystem integrations — Claude Code, Cursor, Windsurf, GSD-2](INTEGRATIONS.md)

---

## Starting Point

If you remember one thing: **write specs, not prompts.**

A prompt is a sentence. A spec is a contract. Contracts produce predictable outcomes. Sentences produce surprises.

Three practices make the biggest difference, in order of impact:

1. **Spec before code** — S1 and S3 written before a single line of implementation
2. **Session boundaries** — spec session, implement session, review session all run cold
3. **Rules with mechanisms** — every constraint in CLAUDE.md has a "why" you understand, so you maintain it under pressure

The templates in this repo enforce all three. Copy them. Fill them in. The loop — spec → generate → measure → better spec — compounds over weeks.

→ [Why each rule works: mechanism analysis](deep-dives/ai-limitations.md)
→ [Complete workflow from issue to merge](deep-dives/worktree-workflow.md)
