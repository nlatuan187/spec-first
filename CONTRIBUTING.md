# Contributing to spec-first

spec-first is a methodology repo — markdown and one bash script. No application code.

## What We Accept

| Type | Directory | Notes |
|------|-----------|-------|
| New example spec | `advanced/examples/` | Must be anonymized, from real production, complete for its format |
| New deep-dive | `advanced/deep-dives/` | Evidence-based, ~200 lines, references real data |
| Tool integration | `advanced/INTEGRATIONS.md` | Add section with setup steps + workflow example |
| Calibration data | GitHub Discussion | Follow the format in `advanced/calibration.md` — stack, team size, commits, ratios |
| Bug fix / typo | Any file | Direct PR |
| Translation | `i18n/{lang}/` | Mirror structure of root files (see below) |

## Rules

These come from [CLAUDE.md](CLAUDE.md) and apply to all contributions:

1. **No application code** — methodology + templates only. No TypeScript/Python except `install.sh`.
2. **Markdown quality** — every file must be directly usable. No placeholder text ("TBD", "TODO", "fill this in").
3. **Evidence-based** — claims must reference real data. Do not invent metrics or star ratings.
4. **Tool-agnostic** — `snippet.md` works with any AI tool. Don't make contributions Claude Code-specific unless they're in `advanced/skills/`.
5. **`snippet.md` is the core** — methodology changes go there first, then propagate to `advanced/` files.

## Commit Messages

```
type(scope): description

feat: add Django calibration example
docs: add hooks/README.md
fix: correct dead link in INTEGRATIONS.md
```

Types: `feat`, `fix`, `docs`, `refactor`, `chore`, `remove`

## PR Checklist

- [ ] Files follow existing format (compare with neighboring files in the same directory)
- [ ] No placeholder text
- [ ] Cross-links updated if adding new files (README.md Advanced section, CLAUDE.md tree)
- [ ] `snippet.md` updated if methodology changed
- [ ] CHANGELOG.md updated with your changes under `[Unreleased]`

## Translations

Mirror the root files. Technical terms stay in English where standard (commit, branch, deploy, token). Methodology terms get translated with English original in parentheses on first use.

```
i18n/
└── vi/
    ├── README.md      ← translated entry point
    ├── snippet.md     ← translated methodology (users paste this)
    └── spec.md        ← translated spec template
```

## Questions?

Open a [GitHub Discussion](https://github.com/nlatuan187/spec-first/discussions) — not an issue. Issues are for bugs and feature requests.
