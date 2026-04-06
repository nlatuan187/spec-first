# Spec Note: TOOL-OMC — Headless Mode Analysis (Deferred)

Author: Codex + production learnings  
Updated: 2026-04-06  
Status: Deferred / research-backed

---

## Summary

OMC is **not** equivalent to OMX in how easily it can be made headless.

The developer desire is clear:

- keep the intelligence
- remove tmux/HUD launcher UI
- make `claude` and `prox` feel lightweight

This is achievable only partially with shell wrappers today. A full solution requires dedicated OMC headless work.

---

## Why OMC Is Harder Than OMX

OMC’s value is more tightly coupled to runtime hooks and session bootstrap:

- session-start hook
- persistent mode restore
- keyword detector / skill routing
- pre-tool-use and post-tool-use interception
- notepad/context injection
- stateful orchestration in `.omc/state`

Unlike OMX, much of this intelligence appears to depend on entering the managed runtime path rather than merely having a config file loaded by the host CLI.

---

## Current Best Practical Setup

### Default path

Use native Claude for:

- `claude`
- `claude --resume <id>`
- `prox`
- `prox --resume <id>`

### Explicit OMC path

Keep only as advanced route:

- `claude-omc`
- `prox-omc`
- `claude-tmux`
- `prox-tmux`

This gives:

- lightweight default UX
- minimal CPU overhead
- explicit access to OMC orchestration when truly needed

---

## What Is Lost In Native Claude Path

Potentially lost or reduced:

- full session-start restore semantics
- some persistent-mode lifecycle behavior
- hook-based skill orchestration
- OMC-specific HUD/background runtime context

This is the core reason OMC cannot yet be considered “fully merged” into native Claude in the same way OMX is largely merged into native Codex.

---

## What A Future Headless OMC Would Need

To be worth doing, a true headless OMC mode should:

1. Run native Claude binary directly
2. Still execute:
   - session-start logic
   - persistent mode restore
   - skill/keyword routing
   - state/notepad context injection
3. Skip:
   - tmux HUD
   - detached panes
   - launch-time UI takeover

---

## Recommendation

### Do now

- keep native `claude` / `prox` as default
- keep explicit `claude-omc` / `prox-omc` as advanced route

### Do later

- design and implement a first-class OMC headless runtime

### Do not do now

- do not restore `omc launch` as the default surface
- do not reintroduce tmux/HUD behavior into ordinary `claude` / `prox`

---

## Definition of Success for Future Work

Future OMC headless mode is successful only if:

- native Claude remains the visible UI
- OMC runtime intelligence still applies
- no detached tmux sessions appear during normal launch/resume
- proxy mode remains compatible

