# Hooks — Session Lifecycle Automation

Optional automation for Claude Code users. These hooks fire at key points in a session to maintain cross-session memory and methodology adherence.

**Not using Claude Code?** These hooks are Claude Code-specific. For other tools, see [INTEGRATIONS.md](../advanced/INTEGRATIONS.md).

## Hook Reference

| Hook | Fires when | What it does |
|------|-----------|--------------|
| `session-start` | New session opens | Injects KNOWLEDGE.md + session-state.md + spec-first methodology reminder |
| `session-end` | Session closes (Stop) | Prompts to update KNOWLEDGE.md and session-state.md |
| `pre-compact` | Context compression | Reminds to capture learnings before old context is lost |
| `run-hook.cmd` | (wrapper) | Polyglot bash/batch script for cross-platform compatibility |

## How hooks are installed

`install.sh` / `install.ps1` copies hooks to `.claude/spec-first/` and registers them in `.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [{ "hooks": [{ "type": "command", "command": ".claude/spec-first/run-hook.cmd session-start" }] }],
    "PreCompact":   [{ "hooks": [{ "type": "command", "command": ".claude/spec-first/run-hook.cmd pre-compact" }] }],
    "Stop":         [{ "hooks": [{ "type": "command", "command": ".claude/spec-first/run-hook.cmd session-end" }] }]
  }
}
```

## How to verify hooks work

1. Start a new Claude Code session in your project
2. Check for the spec-first reminder in the session context
3. If missing, verify `.claude/settings.json` has the hook entries above

## How to disable

Remove the spec-first entries from `.claude/settings.json`, or delete the `.claude/spec-first/` directory.

## How `run-hook.cmd` works

It's a polyglot file — valid as both a bash script and a Windows batch file. On Unix, bash executes it directly. On Windows, `cmd.exe` runs the batch portion. Both call the appropriate hook script with the correct arguments.
