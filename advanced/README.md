# advanced/

Everything here is optional. The six files at the repo root are the method:
[snippet.md](../snippet.md) · [spec.md](../spec.md) · [verify.md](../verify.md) ·
[system.md](../system.md) · [review.md](../review.md) · [heads.md](../heads.md).

This index is generated from what is on disk. If a row here has no file, that is a bug —
`scripts/check.sh` fails on it. Never add a row for something not yet written.

## Slash commands

Installed into `.claude/commands/` by the installer. Other tools: copy each file into
whatever directory they read commands from.

| Command | File | What it does |
|---|---|---|
| `/spec` | [skills/spec/SKILL.md](skills/spec/SKILL.md) | Routes by scope, runs the seven checks, writes `specs/<slug>.md` as `status: draft` |
| `/spec-review` | [skills/spec-review/SKILL.md](skills/spec-review/SKILL.md) | Reads a spec, returns a verdict with evidence. Blocks on an empty Verification or Known issues section |
| `/spec-check` | [skills/spec-check/SKILL.md](skills/spec-check/SKILL.md) | Compares shipped code against its spec. Reads handlers rather than grepping for filenames |
| `/spec-reconcile` | [skills/spec-reconcile/SKILL.md](skills/spec-reconcile/SKILL.md) | The post-merge step. Corrects the spec against the diff, folds the durable half into `docs/system/` |
| `/spec-stats` | [skills/spec-stats/SKILL.md](skills/spec-stats/SKILL.md) | Weekly health score. Headline metric is reconciliation rate |

No command sets `status: approved`. That is a human act, and the `pre-tool-use` hook is
what makes it mean something.

## Working documents

| File | Read it when |
|---|---|
| [ETHOS.md](ETHOS.md) | You want to know why the method is shaped this way before adopting it |
| [knowledge.md](knowledge.md) | `KNOWLEDGE.md` has started collecting entries and you need to keep it readable |
| [team-workflow.md](team-workflow.md) | More than one person writes specs — ownership, the approval gate, the PR template |
| [calibration.md](calibration.md) | The defaults do not fit your codebase and you want to measure your own |
| [feedback-triage.md](feedback-triage.md) | You have a pile of raw user feedback and need issues out of it |
| [INTEGRATIONS.md](INTEGRATIONS.md) | Setting this up on a tool other than Claude Code, or deciding whether another toolchain fits you better |
| [prp.md](prp.md) | A feature is complex enough to need an implementation blueprint beyond the spec |
| [during-coding/README.md](during-coding/README.md) · [during-coding/implementation-brief.md](during-coding/implementation-brief.md) | One build session is running long and you need to hand off to a fresh one |

## Templates

| File | Used for |
|---|---|
| [templates/CLAUDE.md](templates/CLAUDE.md) | The project constitution a new user fills in first |
| `templates/.coderabbit.yaml` | Drop-in config if you use CodeRabbit for the automated review layer |

## Examples

Four anonymised specs, deliberately different sizes, demonstrating the scope ladder.
Each one obeys the current template — an example that does not is worse than no example,
because it is the thing people copy.

[spec-bugfix.md](examples/spec-bugfix.md) · [spec-delta.md](examples/spec-delta.md) ·
[spec-refactor.md](examples/spec-refactor.md) · [spec-feature.md](examples/spec-feature.md)

## Deep dives

Background, not instructions. [deep-dives/README.md](deep-dives/README.md) indexes them.
