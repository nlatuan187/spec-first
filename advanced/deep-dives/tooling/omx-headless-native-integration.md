# Spec: TOOL-OMX — Headless Native Integration for Codex

Author: Codex + production learnings  
Updated: 2026-04-06  
Status: Proposed / implementation-aligned

---

## Scope Routing

Error states: 6 → RECOMMEND REVIEW  
Integration points: 4 → REVIEW REQUIRED  
High-risk: YES (developer tooling, runtime shell wrappers, session lifecycle, local state)  
→ Decision: **REVIEW REQUIRED**

---

## Context

The current developer setup uses three overlapping layers:

1. Native Codex CLI (`codex`)
2. OMX launch/orchestration surface (`omx launch`, `omx resume`)
3. OMX backend intelligence:
   - state
   - memory
   - code intelligence
   - trace
   - optional tmux team runtime

Historically, the launch surface defaulted to tmux/HUD-oriented behavior when not already inside tmux. In practice, this produced:

- detached tmux session storms
- copy/select pain
- high CPU usage from many idle tmux sessions
- confusing `resume` behavior

The goal of this spec is to **preserve OMX intelligence while removing the default dependency on tmux UI**.

---

## Problem Statement

The problem is **not** OMX intelligence itself. The problem is that launch-time UI/runtime behavior is coupled too tightly to the default invocation path.

Observed failure mode:

- `codex resume <id>` or `omx launch ...`
- launcher resolves detached tmux path
- repeated detached sessions like `omx-<user>-detached-*` are created
- tmux CPU rises because many sessions remain alive
- user sees “green bars” / pane clutter and assumes Codex itself is broken

The production insight is:

> For daily use, most value comes from OMX backend intelligence, not from the tmux/HUD launch layer.

---

## Product Goal

The default developer experience should be:

- lightweight
- native terminal UI
- no detached tmux session creation
- still backed by OMX intelligence wherever possible

Desired daily commands:

- `codex`
- `codex resume <id>`

Optional advanced surfaces:

- `omx explore`
- `omx sparkshell`
- `omx session`
- `omx ask`
- `omx team` (explicit only)

---

## Current Architecture

### Native CLI path

`codex` binary:
- stable
- copy-friendly
- no tmux UI

### OMX launch path

`omx launch` and `omx resume` currently go through:

- `resolveCodexLaunchPolicy()`
- `preLaunch()`
- `runCodex()`
- optional HUD/tmux bootstrap

This path owns:
- overlay generation
- session lifecycle
- orphan cleanup
- notify fallback watcher bootstrap

### OMX backend intelligence

The most valuable intelligence lives outside the tmux UI layer:

- MCP state server
- MCP memory server
- MCP code intelligence server
- MCP trace server
- optional team runtime server
- AGENTS/runtime overlay design
- `explore` / `sparkshell` / `session` command family

---

## What We Learned

### L1 — Codex can keep most OMX intelligence without `omx launch`

Codex still benefits from local `.codex` configuration and MCP servers even when launched natively.

Therefore:

- native Codex keeps most useful OMX power
- tmux/HUD is not required for the majority of developer workflows

### L2 — Detached tmux should be opt-in, never default

Detached tmux should be reserved for:

- explicit team mode
- explicit tmux mode
- long-running pane orchestration

It should not be the silent default for launch/resume.

### L3 — Team MCP is optional overhead for non-team users

If the developer is not actively using tmux workers or team orchestration, `omx_team_run` is mostly overhead.

Therefore:

- state/memory/code-intel/trace should remain enabled
- team runtime should be disabled by default unless explicitly needed

### L4 — “Launcher intelligence” and “backend intelligence” are different

We should distinguish:

1. Launcher intelligence:
   - overlay bootstrap
   - HUD
   - tmux attachment
   - prompt injection workarounds

2. Backend intelligence:
   - memory/state/code-intel/trace
   - explore/sparkshell/session
   - toolchain context and orchestration assets

The first can be reduced. The second is the real moat.

---

## Proposed Architecture

### Default path

Use native Codex CLI as the default command surface.

```sh
codex "$@"
codex resume <id>
```

### Explicit OMX path

Keep OMX as an explicit advanced tool.

```sh
codex-omx ...
codex-tmux ...
omx explore ...
omx sparkshell ...
omx team ...
```

### Shell wrapper rule

If `omx` itself is called with launch-like commands:

- `launch`
- `resume`
- or empty command

force:

- `TMUX=""`
- `OMX_LAUNCH_POLICY="direct"`

This preserves OMX behavior while preventing accidental tmux UI spawning.

### Local config rule

Keep enabled:

- `omx_state`
- `omx_memory`
- `omx_code_intel`
- `omx_trace`

Disable by default unless needed:

- `omx_team_run`

---

## UX Principles

### P1 — Default should be invisible

Most users should never think about HUD panes, tmux sessions, or helper bootstrap.

### P2 — Power should remain accessible

Advanced users can still opt into:

- explore
- sparkshell
- team
- session search

### P3 — Failure modes must be local and obvious

If tmux orchestration is intentionally invoked and fails:

- it should fail inside the explicit tmux route
- not infect ordinary `codex` usage

---

## Implementation Guidance

### Local shell layer

Preferred command structure:

```sh
codex() { /opt/homebrew/bin/codex "$@"; }
codex-omx() { TMUX="" CMUX_SURFACE_ID="omx-copy" OMX_LAUNCH_POLICY="direct" omx launch "$@"; }
codex-tmux() { omx launch "$@"; }
```

### OMX wrapper itself

`omx()` should force `direct` for launch-like commands:

```sh
case "$1" in
  launch|resume|"")
    TMUX="" OMX_LAUNCH_POLICY="direct" node .../omx.js "$@"
    ;;
  *)
    node .../omx.js "$@"
    ;;
esac
```

### MCP config

Disable `omx_team_run` by default unless an explicit team workflow is being used.

---

## Definition of Done

The setup is considered complete when:

- `codex` launches native CLI directly
- `codex resume <id>` does not create detached tmux sessions
- `omx launch` also defaults to direct/no-tmux path
- no runaway `omx-*-detached-*` sessions are created during normal usage
- state/memory/code-intel/trace remain available
- team runtime is opt-in

---

## Follow-up Questions

1. Should OMX upstream expose a first-class `--headless` launch mode?
2. Should direct native launch still run overlay/session bootstrap in a lighter mode?
3. Should `omx_team_run` be lazily started only on first explicit `team` usage?

