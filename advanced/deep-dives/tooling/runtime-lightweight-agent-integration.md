# Spec: TOOL-RUNTIME — Lightweight Native Integration for Codex-LB, Claude Proxy, OMX, and OMC

Author: Codex + local production learnings  
Updated: 2026-04-06  
Status: Proposed / spec-first runtime direction

---

## Scope Routing

Error states: 8 → REVIEW REQUIRED  
Integration points: 6 → REVIEW REQUIRED  
High-risk: YES (developer runtime, shell wrappers, tmux/session lifecycle, local auth, MCP backend)  
→ Decision: **REVIEW REQUIRED**

---

## Why This Spec Exists

The current developer environment combines four powerful but overlapping layers:

1. `codex-lb` via native Codex CLI
2. Claude native CLI
3. `oh-my-codex` (OMX)
4. `oh-my-claude-sisyphus` (OMC)

Over time, the environment accumulated two contradictory goals:

- keep the orchestration intelligence, memory, tracing, and helper tooling
- keep the daily UI path lightweight, copy-friendly, and free of tmux/HUD overhead

In practice, the launch UI layers of OMX/OMC became the main source of pain:

- runaway detached tmux sessions
- high tmux CPU usage
- many green panes / pane storms
- resume paths that feel opaque or broken
- launch-time behavior that is heavier than the value it provides for daily work

This spec captures the learning:

> The correct long-term architecture is **native UI by default, orchestration intelligence behind it, tmux only as an explicit opt-in surface**.

---

## Product Goal

### Daily experience

The user should mostly live in exactly three commands:

- `codex`
- `claude`
- `prox`

These commands should be:

- native
- lightweight
- no tmux HUD
- no detached session storms
- safe to use for normal launch and resume

### Power path

Advanced users should still have access to:

- `omx explore`
- `omx sparkshell`
- `omx session`
- `omx team`
- `omc` explicit bridge/orchestration commands

### Architectural principle

The user should be able to say:

> “I keep the intelligence, but I do not pay for the launch UI.”

---

## System Layers

### Layer A — Native terminal UI

These are the user-facing shells that should remain default:

- native Codex binary
- native Claude binary
- native Claude binary with proxy env

This layer optimizes for:

- low CPU
- predictable copy/select behavior
- fewer moving parts
- direct and transparent runtime behavior

### Layer B — Orchestration intelligence

This is the real moat and should be preserved:

#### OMX backend intelligence

- MCP state
- MCP memory
- MCP code intelligence
- MCP trace
- optional team runtime
- runtime overlay generation
- `explore`, `sparkshell`, `session`, `agents`, `team`

#### OMC backend intelligence

- session-start hook
- persistent mode restore
- keyword detector / skill activation
- pre-tool-use / post-tool-use lifecycle
- `.omc/state` orchestration
- bridge-level runtime semantics

### Layer C — Launcher UI / orchestration surface

This includes:

- tmux HUD
- detached tmux launch path
- pane splitting
- session bootstrap visuals
- launch-time takeover behavior

This is where the current pain lives.

---

## Current Reality

## Codex + OMX

### What is already true

OMX intelligence is already more separable from its UI than OMC:

- Codex reads `.codex/config.toml`
- OMX MCP servers can remain active regardless of tmux HUD
- the most valuable features are not the launch UI itself

### What failed historically

The default OMX launch path could choose detached tmux behavior when not already in tmux:

- `resolveCodexLaunchPolicy()` → `detached-tmux`
- detached `omx-<user>-detached-*` sessions spawned
- many sessions stayed alive
- tmux CPU grew

### What we learned

The best practical setup for daily Codex usage is:

- native or headless-direct launch
- full backend intelligence
- detached tmux only when explicitly requested

## Claude + OMC

### What is different

OMC intelligence is more tightly coupled to its managed launch/runtime path.

The most valuable parts of OMC are not only “configuration”, but also runtime hooks:

- session-start restore
- persistent-mode state transitions
- tool interception
- skill lifecycle

### What we learned

Native Claude is better for lightweight UX, but native Claude alone does not automatically guarantee full OMC intelligence.

Therefore:

- the default path should still be native
- but OMC headless mode needs separate design work

---

## Key Distinction: Intelligence vs UI

We must stop treating these as the same thing.

### Launcher/UI intelligence

Examples:

- HUD bootstrap
- tmux pane creation
- detached session naming
- mouse scrolling / pane resize hooks

This is not the real value for everyday work.

### Backend/runtime intelligence

Examples:

- memory/state MCPs
- code-intel MCP
- session overlays
- prompt routing
- hook-based state restore
- trace and orchestration context

This is the real value worth preserving.

---

## Target Architecture

## Default commands

### Codex

Preferred default:

```sh
codex "$@"
codex resume <id>
```

Internally, this should still be allowed to use OMX backend intelligence, but must not go through tmux HUD by default.

### Claude

Preferred default:

```sh
claude "$@"
claude --resume <id>
prox "$@"
prox --resume <id>
```

These must remain native UI commands.

## Explicit advanced commands

### OMX explicit

```sh
omx explore ...
omx sparkshell ...
omx session ...
omx team ...
```

### OMC explicit

```sh
omc ...
claude-omc ...
prox-omc ...
```

These are power-user surfaces, not defaults.

---

## Runtime Rules

### Rule 1 — No detached tmux by default

Launch/resume must never silently choose detached tmux for ordinary use.

### Rule 2 — Headless/direct should be the default for launch-like commands

For launch-like invocations:

- `launch`
- `resume`
- or empty launch surface

the runtime should force:

- no inherited tmux attachment
- no HUD bootstrap
- no detached session path

### Rule 3 — Team/tmux is explicit only

Team runtime should be:

- off by default
- enabled only when explicit team behavior is requested

### Rule 4 — Proxy path must remain native

Proxy-backed Claude should stay direct:

- native UI
- proxy env
- no launcher UI

### Rule 5 — Intelligence should be composable

The user should be able to combine:

- native binary
- backend MCP
- headless launch lifecycle

without being forced into tmux UI.

---

## Practical Local Configuration

### Good current local shape for Codex

Keep enabled:

- `omx_state`
- `omx_memory`
- `omx_code_intel`
- `omx_trace`

Disable unless explicitly needed:

- `omx_team_run`

### Good current local shell wrappers

#### Native-first

```sh
claude() { /path/to/claude "$@"; }
prox() { ANTHROPIC_BASE_URL=... ANTHROPIC_AUTH_TOKEN=... /path/to/claude "$@"; }
```

#### Codex with headless OMX direct path

Two valid strategies exist:

#### Strategy A — fully native Codex default

```sh
codex() { /path/to/codex "$@"; }
```

Use when:

- you want maximum simplicity
- you are okay losing launch-time OMX overlay/lifecycle extras

#### Strategy B — OMX direct/headless default

```sh
codex() {
  case "$1" in
    resume|--resume)
      shift
      TMUX="" CMUX_SURFACE_ID="omx-copy" OMX_LAUNCH_POLICY="direct" omx resume "$@"
      ;;
    *)
      TMUX="" CMUX_SURFACE_ID="omx-copy" OMX_LAUNCH_POLICY="direct" omx launch "$@"
      ;;
  esac
}
```

Use when:

- you want more OMX launch-time intelligence
- you still want zero tmux UI

This is currently the best “smart but lightweight” shape for Codex.

---

## Why Codex Can Take More OMX Intelligence Than Claude Can Take OMC Intelligence

### Codex + OMX

Codex gains a lot from:

- `.codex/config.toml`
- active MCP servers
- OMX runtime overlay

These are more separable from tmux UI.

### Claude + OMC

Claude/OMC depends more heavily on:

- session-start hook execution
- persistent mode bootstrap
- lifecycle interception

These are less separable from the OMC runtime today.

Therefore:

- Codex can already absorb most OMX value with low UX cost
- Claude cannot yet absorb full OMC value without more explicit headless design

---

## Open Design Questions

### Q1 — Should OMX expose a first-class `--headless` or `--no-hud` mode?

Current shell forcing works, but upstream support would be cleaner and safer.

### Q2 — Should native Codex receive a minimal overlay bootstrap automatically?

This would preserve more OMX intelligence even when not using `omx launch`.

### Q3 — Should `omx_team_run` become lazy-init only?

This would reduce background overhead while preserving the team path.

### Q4 — Should OMC support headless runtime hooks without `omc launch`?

This is the key design problem for future work.

---

## Recommended Roadmap

### Phase 1 — Stabilize local default behavior

- native UI by default
- direct/headless launch policy
- team runtime disabled by default
- detached session cleanup

### Phase 2 — Formalize headless OMX

- spec-first `--headless` semantics
- direct lifecycle path without tmux UI
- better docs and shell examples

### Phase 3 — Research and prototype headless OMC

- separate runtime hooks from launch UI
- prove what intelligence is preserved
- only then consider wider rollout

---

## Definition of Done

This tooling direction is complete when:

- `codex`, `claude`, and `prox` are the only daily commands most users need
- no detached tmux sessions are created by default usage
- Codex still benefits from OMX backend intelligence
- Claude/proxy remain lightweight without reintroducing OMC launch UI
- explicit tmux/advanced orchestration remains available as opt-in

---

## Non-Goals

- turning tmux into the default UX again
- hiding failures behind more launcher complexity
- binding all intelligence to a single opaque wrapper
- forcing users to choose between “smart” and “usable”

