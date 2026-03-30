# Hooks — Session Lifecycle Automation

Optional automation for Claude Code users. These hooks inject context at key moments in the AI session lifecycle so the methodology stays active without manual reminders.

**Not using Claude Code?** These hooks are Claude Code-specific. For other tools, see [INTEGRATIONS.md](../advanced/INTEGRATIONS.md).

---

## Hook Reference

| Hook | Fires when | What it injects |
|------|-----------|-----------------|
| `session-start` | New session opens | Spec-first reminder + `KNOWLEDGE.md` contents + `session-state.md` (if exists) |
| `pre-compact` | Context is about to be compressed | Reminder to save learnings to `KNOWLEDGE.md` before old context is lost |
| `session-end` | Session closes (Stop) | Prompt to update `KNOWLEDGE.md` + `session-state.md` with session results |
| `run-hook.cmd` | *(wrapper)* | Polyglot bash/batch script — makes hooks work on both Unix and Windows |

### What each hook does

**`session-start`** — The most important hook. At every session start, it injects:
1. A `<spec-first-active>` block reminding the AI to check for specs before writing code
2. The full contents of `KNOWLEDGE.md` (project learnings from previous sessions)
3. The contents of `.claude/session-state.md` (what the last session was working on)

This ensures every session starts with methodology context + project memory — no manual copy-paste needed.

**`pre-compact`** — When Claude Code compresses the conversation (context limit approaching), this hook reminds the AI to save any discoveries to `KNOWLEDGE.md` before they're lost. Without this, learnings from the first half of a long session disappear during compaction.

**`session-end`** — When you close a session, this hook prompts the AI to:
- Append non-obvious patterns to `KNOWLEDGE.md` (if they recurred 2+ times)
- Update `.claude/session-state.md` with what was accomplished and what's next
- Update the spec's YAML frontmatter status field

**`run-hook.cmd`** — A polyglot file that works as both a bash script and a Windows batch file. On Unix, it directly executes the named hook script. On Windows, it finds `bash.exe` (Git for Windows, MSYS2, Cygwin, or WSL) and uses it to run the hook. If no bash is found, it exits silently — the tool still works, just without hook injection.

---

## How to Verify Hooks Are Working

1. Open a new Claude Code session in your project
2. The first AI response should contain awareness of spec-first methodology
3. Check `.claude/settings.json` — you should see entries under `hooks.SessionStart`, `hooks.PreCompact`, and `hooks.Stop`

```bash
# Quick check: are hooks registered?
cat .claude/settings.json | grep -A2 "spec-first"
```

---

## How to Disable

Remove the hook entries from `.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [],
    "PreCompact": [],
    "Stop": []
  }
}
```

Or delete the `.claude/spec-first/` directory entirely. The core methodology (in your AI context file) still works without hooks — hooks are a convenience layer, not a requirement.

---

## How Hooks Are Installed

The installer (`install.sh` or `install.ps1`) copies hook scripts to `.claude/spec-first/` and registers them in `.claude/settings.json`. Registration is idempotent — running the installer twice won't create duplicate entries.
