# Hooks — Lifecycle Automation and Enforcement

Five hooks for Claude Code. Three inject context at key session moments. One enforces
the gate before every file edit. One wraps the others for Windows.

**Not using Claude Code?** These hooks are Claude Code-specific. For other tools,
see [INTEGRATIONS.md](../advanced/INTEGRATIONS.md).

---

## Hook Reference

| Hook | Event | Purpose |
|------|-------|---------|
| `pre-tool-use` | Before Write or Edit | **Enforcement** — blocks source edits when no approved spec claims the file |
| `session-start` | New session opens | Injects v2 reminder, active spec stage, KNOWLEDGE.md, session state, unreconciled spec warning |
| `pre-compact` | Context compaction | Reminds AI to save learnings and spec state before context is lost |
| `session-end` | Session closes | Prompts learnings capture, session state update, and reconciliation of any shipped spec |
| `run-hook.cmd` | *(wrapper)* | Polyglot bash/batch — makes hooks work on Unix and Windows |

---

## Enforcement Hook (`pre-tool-use`)

The gate rule: no source edit without an approved spec that names the file. This hook
enforces that mechanically, before every Write or Edit tool call.

**Three conditions must all hold for an edit to pass:**

1. A spec exists in `specs/`
2. Its front-matter `status` is `approved` or `implementing`
   — set by the approver, never by the author, never by an agent
3. Its `## File changes` section names the file being edited (or a directory above it)

Condition 2 is what separates a reviewed decision from a draft. An unreviewed spec is a
prompt with extra steps; a gate that accepts one is not a gate.

Condition 3 is what stops one spec from unlocking the whole repository permanently.
The old behaviour — any `.md` in `specs/` unlocked every file — is the bug this
condition fixes. A spec that names `docs/system/` does not open `src/`.

**Files that are never blocked:**

- Markdown, JSON, YAML, config files — anything without a recognised source extension
- Test files — any path containing `/test/`, `/tests/`, `/__tests__/`, `/__mocks__/`,
  or `/spec/`, and any file matching `*.test.*`, `*.spec.*`, `*_test.*`, `test_*.py`
- The spec files themselves (`specs/*.md`)
- Files outside the project directory

**Bypass mechanisms:**

```bash
# Emergency: create bypass file, remove it to re-enable enforcement
touch .spec-first-bypass

# Per-session: environment variable
export SPEC_FIRST_ENFORCEMENT=off
```

After using the bypass, write the retroactive spec the same day and remove the file
before the next session. The emergency bypass is `touch .spec-first-bypass, fix, spec`;
not `touch .spec-first-bypass, ship, forget`.

**What happens when blocked:**

The AI receives a message identifying which condition failed and listing the steps to
satisfy it: write a spec, have it approved, make sure it names the file.

---

## Lifecycle Hooks

### `session-start`

At every session start, injects a `<spec-first-active>` block containing:

1. **v2 model** — three artifacts (specs/ prediction, docs/system/ observation,
   KNOWLEDGE.md permanent), the loop (Clarify → Verify → Spec → Approve → Build →
   Review → Reconcile), the brownfield rule (write the system doc before the spec),
   and the gate rule
2. **Active specs** — scanned from `specs/` front-matter `status` fields; shows which
   work is in progress and at what stage (draft, in-review, approved, implementing)
3. **Unreconciled warning** — names every spec whose `shipped_at` is set but
   `reconciled_at` is empty; this is work the user has forgotten and must not leave
4. **KNOWLEDGE.md** — full contents, if the file exists and is non-empty
5. **Session state** — contents of `.claude/session-state.md`, if it exists

### `pre-compact`

When Claude Code compresses the conversation (context limit approaching), reminds the
AI to:

- Append non-obvious discoveries to `KNOWLEDGE.md` before they are lost (only if they
  recurred 2+ times or are critical)
- Update the active spec's status and open questions
- Record what changed in `## Known issues` if a spec shipped and reconciliation is not done

### `session-end`

When you close a session, prompts the AI to:

- Append non-obvious patterns to `KNOWLEDGE.md` (if they recurred 2+ times)
- Update `.claude/session-state.md` with what was accomplished and what comes next
- Update the spec's YAML front-matter `status` field
- Reconcile any spec that shipped in this session — re-read against the merged diff,
  correct paths and symbols, append to `## Known issues`, fold durable parts into
  `docs/system/<area>.md`, set `reconciled_at`

Also scans `specs/` and appends a named list of any shipped-but-unreconciled specs,
so the reminder is concrete rather than generic.

### `run-hook.cmd`

A polyglot file that works as both a bash script and a Windows batch file. On Unix it
executes the named hook script directly. On Windows it locates `bash.exe` (Git for
Windows, MSYS2, Cygwin, or WSL) and uses it to run the hook. If no bash is found, it
exits silently.

---

## How to Verify Hooks Are Working

1. Open a new Claude Code session in your project
2. The first AI response should mention spec-first v2, the three artifacts, and any
   active or unreconciled specs
3. Try editing a source file without an approved spec — the edit should be blocked
4. Check that hooks are registered:

```bash
grep -A2 "spec-first" .claude/settings.json
```

---

## How to Disable

**Enforcement only:**

```bash
export SPEC_FIRST_ENFORCEMENT=off
# or
touch .spec-first-bypass
```

**All hooks** — remove entries from `.claude/settings.json`:

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

Or delete `.claude/spec-first/` entirely. The methodology in the context file works
without hooks — the lifecycle hooks are a convenience layer, the enforcement hook is a
discipline layer.

---

## Installation

The installer (`install.sh` or `install.ps1`) copies hook scripts to
`.claude/spec-first/` and registers them in `.claude/settings.json`. Registration
is idempotent — running the installer twice does not create duplicate entries.

The enforcement hook registers under `PreToolUse` with `matcher: "Edit|Write"` so it
fires only for file-modification tools, not for Read, Glob, Grep, or Bash.
