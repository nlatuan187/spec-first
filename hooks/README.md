# Hooks — Lifecycle Automation + Enforcement

Hooks for Claude Code users. Lifecycle hooks inject context at key session moments. The enforcement hook mechanically blocks code edits without a spec.

**Not using Claude Code?** These hooks are Claude Code-specific. For other tools, see [INTEGRATIONS.md](../advanced/INTEGRATIONS.md).

---

## Hook Reference

| Hook | Event | What it does |
|------|-------|-------------|
| `pre-tool-use` | Before Write/Edit | **Enforcement** — blocks source code edits when no spec exists in `specs/` |
| `session-start` | New session opens | Injects spec-first reminder + `KNOWLEDGE.md` + `session-state.md` |
| `pre-compact` | Context compaction | Reminds AI to save learnings to `KNOWLEDGE.md` before context is lost |
| `session-end` | Session closes | Prompts AI to update `KNOWLEDGE.md` + `session-state.md` + spec status |
| `run-hook.cmd` | *(wrapper)* | Polyglot bash/batch — makes hooks work on both Unix and Windows |

---

## Enforcement Hook (`pre-tool-use`)

The Code Rule says "never write code without a spec." This hook makes it mechanical.

**How it works:**
1. Claude Code calls this hook before every Write or Edit tool call
2. Hook checks: is the file a source code file? (`.ts`, `.py`, `.go`, `.rs`, etc.)
3. If yes: does `specs/` contain at least one active `.md` file?
4. No active spec → **edit blocked** — AI receives instructions to write a spec first
5. Spec exists → edit allowed

**What's never blocked:**
- Markdown, JSON, YAML, config files (any non-source-code extension)
- Test files (any path containing `test`, `__tests__`, `__mocks__`, `.test.`, `.spec.`)
- Spec files themselves (`specs/*.md`)
- Files outside the project directory

**Bypass mechanisms:**
```bash
# Temporary: create bypass file (remove it to re-enable)
touch .spec-first-bypass

# Per-session: environment variable
export SPEC_FIRST_ENFORCEMENT=off
```

**What happens when blocked:**

The AI receives a message explaining why the edit was blocked and what to do:
1. Say "build [feature]" to write a full spec
2. Run `/spec [slug]` to create one directly
3. For emergencies: create `specs/[slug]-bug.md` (S1 + S6), then implement

The enforcement teaches the correct workflow — the AI writes a spec, which satisfies the hook, then implements.

---

### Lifecycle Hooks

**`session-start`** — At every session start, injects:
1. A `<spec-first-active>` block reminding the AI to check for specs before writing code
2. The full contents of `KNOWLEDGE.md` (project learnings from previous sessions)
3. The contents of `.claude/session-state.md` (what the last session was working on)

**`pre-compact`** — When Claude Code compresses the conversation (context limit approaching), reminds the AI to save any discoveries to `KNOWLEDGE.md` before they're lost.

**`session-end`** — When you close a session, prompts the AI to:
- Append non-obvious patterns to `KNOWLEDGE.md` (if they recurred 2+ times)
- Update `.claude/session-state.md` with what was accomplished and what's next
- Update the spec's YAML frontmatter status field

**`run-hook.cmd`** — A polyglot file that works as both a bash script and a Windows batch file. On Unix, it directly executes the named hook script. On Windows, it finds `bash.exe` (Git for Windows, MSYS2, Cygwin, or WSL) and uses it to run the hook. If no bash is found, it exits silently.

---

## How to Verify Hooks Are Working

1. Open a new Claude Code session in your project
2. The first AI response should contain awareness of spec-first methodology
3. Try editing a `.ts` file without a spec — the edit should be blocked
4. Check `.claude/settings.json`:

```bash
# Quick check: are hooks registered?
cat .claude/settings.json | grep -A2 "spec-first"
```

---

## How to Disable

**Disable enforcement only:**
```bash
export SPEC_FIRST_ENFORCEMENT=off
```

**Disable all hooks** — remove entries from `.claude/settings.json`:
```json
{
  "hooks": {
    "SessionStart": [],
    "PreCompact": [],
    "PreToolUse": [],
    "Stop": []
  }
}
```

Or delete the `.claude/spec-first/` directory entirely. The core methodology (in your AI context file) still works without hooks — hooks are a convenience layer, enforcement is a discipline layer.

---

## How Hooks Are Installed

The installer (`install.sh` or `install.ps1`) copies hook scripts to `.claude/spec-first/` and registers them in `.claude/settings.json`. Registration is idempotent — running the installer twice won't create duplicate entries.

The enforcement hook registers under `PreToolUse` with `matcher: "Edit|Write"` — it only fires for file modification tools, not for Read, Glob, Grep, or Bash.
