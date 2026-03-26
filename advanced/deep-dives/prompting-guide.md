# Prompting Guide: What Actually Works

Analyzed from 14,000 user messages across 753 Claude Code conversation files over 24 days of production development.

---

## The 6 Patterns That Consistently Produce Better Output

### Pattern 1: Role Assignment

**What it is**: Telling the AI to adopt a specific expert persona before the task.

**What works:**
```
Act as a world-class product manager. Analyze this feature request
and identify the edge cases we're missing.
```

```
You are a senior security engineer. Review this authentication flow
for vulnerabilities.
```

**Why it works**: Role assignment activates domain-specific reasoning patterns. "World-class PM" produces different output than "helpful assistant" — more opinionated, more thorough, more willing to push back on bad ideas.

**Evidence**: Used 30+ times in our project. Consistently produced more thorough analysis than the same prompt without role assignment.

**When to use**: Research tasks, architecture decisions, reviews. NOT for implementation (specs are better for that).

---

### Pattern 2: Spec-as-Prompt (The Core Pattern)

**What it is**: Instead of describing what you want in natural language, hand the AI a structured spec document.

**What works:**
```
Read CLAUDE.md, then implement the spec at specs/user-authentication.md
```

**What doesn't work:**
```
Build a login page with email and password. Use our existing
auth system. Make it look nice.
```

**Why it works**: Specs are deterministic. Natural language is ambiguous. "Make it look nice" produces random results. S1-S6 sections eliminate ambiguity.

**Evidence**: Natural language prompts: ~50% first-try success. Spec-as-prompt: ~85% first-try success.

---

### Pattern 3: Cross-Agent Validation

**What it is**: Running the same question through multiple AI sessions and comparing answers.

**How we used it:**
```
Session A: "Analyze this UX problem. What are the root causes?"
Session B: "Analyze this UX problem. What are the root causes?"
→ Compare outputs. Where they agree = high confidence. Where they diverge = investigate deeper.
```

**Advanced version:**
```
Session B: "I got this analysis from another session. Do you agree?
Challenge every assumption. Where might this be wrong?"
```

**Why it works**: Individual AI sessions have blind spots. Cross-validation catches them. It's the same principle as code review — different perspectives catch different bugs.

**When to use**: Architecture decisions, UX strategy, any high-stakes choice where being wrong is expensive.

---

### Pattern 4: Paste-Output-as-Input

**What it is**: Copy the output from one AI session and paste it into another as context.

**How it works:**
```
Session A generates: [analysis of problem X]
Session B receives: "Given this analysis: [paste from A]. Now implement a solution."
```

**Why it works**: AI sessions are isolated. They can't share context. Manual copy-paste is the bridge. This is particularly valuable when Session A did research and Session B needs to implement.

**Evidence**: Used dozens of times for cross-pollinating insights between worktree sessions.

---

### Pattern 5: Autonomous Agent Prompts

**What it is**: Structured prompts that let AI run autonomously with clear boundaries.

**Template:**
```
## Context
[What the project is. What has been built. What matters.]

## Task
[Exactly what to do. Not vague — specific files, specific behaviors.]

## Steps
1. [First thing to do]
2. [Second thing to do]
3. [Verification step]

## Constraints
- Do not modify [files/directories]
- Follow patterns in CLAUDE.md
- Commit after each logical unit of work
```

**Evidence**: Used for 11 parallel agents. Agents with structured prompts (Steps + Constraints) completed with <10 messages. Agents with vague prompts required 50-150 messages.

**Key insight**: The more autonomy you give the AI, the MORE structure it needs, not less.

---

### Pattern 6: Depth Triggers

**What it is**: Single words or phrases that signal "I want exhaustive analysis, not a quick answer."

**What works:**
```
"Ultrathink. Analyze every edge case in this spec."
"Research this thoroughly. Leave nothing out."
"Be comprehensive. I'd rather have too much detail than too little."
```

**Evidence**: "Ultrathink" was used 259 times across our sessions. When used before complex tasks (spec writing, architecture analysis, code review), output was consistently longer and more thorough. When used for simple tasks, it added unnecessary verbosity.

**When to use**: Complex analysis, spec writing, architecture decisions.
**When NOT to use**: Simple fixes, formatting, routine implementation.

---

## Anti-Patterns: What Doesn't Work

### Anti-Pattern 1: "Fix it"

```
❌ "This doesn't work. Fix it."
✅ "The login form submits but returns a 401. The token is being sent
    in the body instead of the Authorization header. Fix the fetch
    call in lib/services/auth.ts."
```

**Why it fails**: "Fix it" gives the AI no information about what's broken, where, or why. It guesses, often incorrectly, and sometimes introduces new bugs while "fixing" the original.

### Anti-Pattern 2: "Make it better"

```
❌ "This code could be better. Refactor it."
✅ "Extract the validation logic from createUser() into a separate
    validateUserInput() function. Keep the same behavior."
```

**Why it fails**: "Better" is subjective. AI will add unnecessary abstractions, premature optimizations, or over-engineered patterns that make the code harder to maintain.

### Anti-Pattern 3: Multiple unrelated tasks in one prompt

```
❌ "Fix the login bug, add dark mode, and update the README."
✅ Three separate prompts, one per task.
```

**Why it fails**: AI loses focus on multi-task prompts. It does each task at 60% quality instead of one task at 95% quality.

### Anti-Pattern 4: Accepting output without reading

```
❌ [AI generates 200 lines] → "Looks good, commit."
✅ [AI generates 200 lines] → Read every line → "Line 47 logs the
    auth token to console. Remove that. Line 123 uses any type.
    Use proper typing."
```

**Why it fails**: AI-generated code has systematic blind spots (security, error handling, edge cases). Not reading the diff is gambling with your production environment.

---

## The Prompt Quality Ladder

Track where your prompts sit on this ladder. Move up over time.

| Level | Description | Fix:Feat Ratio | Example |
|:-----:|------------|:--------------:|---------|
| 1 | Vague natural language | 5:1+ | "Build a dashboard" |
| 2 | Specific natural language | 3-4:1 | "Build a dashboard showing user metrics with charts" |
| 3 | Structured with criteria | 2-3:1 | Acceptance criteria + API contracts |
| 4 | Full spec (S1-S6) | 1.5-2:1 | Complete behavioral contract |
| 5 | Spec + CLAUDE.md context | 1-1.5:1 | Full spec with system understanding |

Most teams start at Level 1-2 (vibe coding). This repo gets you to Level 4-5.
