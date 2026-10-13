# Changelog

All notable changes to spec-first are documented here. When `snippet.md` changes, re-paste it into your AI context file to get the latest rules.

Format follows [Keep a Changelog](https://keepachangelog.com/).

## [2.0.0] — 2026-10-13

Merged in the parts of a production methodology that matured after this repo was
extracted, and the mechanisms competing toolchains added since. Removed the parts that
existed to compensate for weaker models.

### Added
- `verify.md` — seven mandatory pre-spec checks, recorded into the spec. A spec whose
  `## Verification` section is empty is a draft. Origin: 11 review gaps in two specs
  written from memory in a single day.
- `system.md` — living system-document template. Shipped specs are folded into it rather
  than filed in `specs/done/` to go stale.
- Reconciliation step — within a working day of merge, the spec is re-read against the
  merged diff and its durable parts move into the system document. Measured basis:
  documents written after their code kept 70/70 path references accurate over five
  months; the one written ahead of its code held 2 of the 3 dead references in the set.
- Spec sections `Why` (Pain · Need · Proposed · Non-goals), `Invariants`, `Thresholds`,
  `Known issues`, `Mental model`, `Pre-reading`.
- `Discovery` scope — when the solution is unknown, write the questions, not a guess.
- Front matter `owner`, `approver`, `approved_at`, `shipped_at`, `reconciled_at`.

### Changed — enforcement is now real
The `pre-tool-use` hook previously allowed any edit as soon as a single `.md` file
existed in `specs/`. One file unlocked the repository permanently. It now requires all
three of: a spec exists, its status is `approved` or `implementing`, and its
`## File changes` names the file being edited. Approval is a human act; an agent setting
`approved_at` is the thing this gate exists to prevent.

Also fixed: test-path matching was substring-based, so `src/contest/page.tsx` and
`lib/latest.ts` were silently treated as test files and never gated.

### Changed — written for a capable model
Removed context-window and attention-weighting workarounds, the cap on clarifying
questions, the instruction to re-read sections in a particular order, and most of the
per-rule derivations. `snippet.md` went from 428 lines to under 200 — it is pasted into
the user's context file, and the file itself says to keep that under ~200 lines.

### Removed
- `advanced/deep-dives/{team-scaling,the-system,tool-matrix,prompting-guide}.md` — four
  orphans nothing linked to; two duplicated files that are still present, one carried
  vendor and model guidance from March 2026.
- `advanced/templates/{feature-spec,review-checklist}.md` — divergent second copies of
  `spec.md` and `review.md`. The old guidance was to edit both, which is why they diverged.

### Fixed
- `evidence.md` claimed a 2.93:1 fix:feat ratio meant "75% of commits were fixing AI
  output". `fix:` was 47% of all commits (293 of 626); 75% is the share among commits
  that were either a feature or a fix.
- Dead prose paths to `spec-first/during-coding/` and to the removed templates.
- The installer no longer overwrites a `spec.md` or `review.md` the project has edited.

## [Unreleased]

### Added
- **Enforcement hook** (`pre-tool-use`) — mechanically blocks Write/Edit on source code when no spec exists in `specs/`. The Code Rule is no longer advisory-only for Claude Code users.
- Delta and Refactor example specs in `advanced/examples/` (real production specs, anonymized)
- `hooks/README.md` — documents what each hook does, how to verify, how to disable
- `CONTRIBUTING.md` — guide for community contributions
- `CHANGELOG.md` (this file)
- GitHub issue templates (bug report + feature request)

### Changed
- `snippet.md` — Autonomous route: "re-read S1 last" (recency bias — the section read most recently gets the most weight in implementation)
- `snippet.md` — S1-S6 table: added multi-resolution framing (each section = a different abstraction level)
- `snippet.md` — Code Rule section now documents mechanical enforcement
- `README.md` — Fundamental Law: added "planning architecture > model power" evidence note
- `install.sh` / `install.ps1` — register `PreToolUse` enforcement hook with `matcher: "Edit|Write"`
- `tool-matrix.md` — added stack disclaimer (methodology is stack-agnostic, tool recommendations are JS/TS-specific)

## [2026-03-30]

### Added
- `/spec-stats` skill — methodology health dashboard (fix:feat ratio, spec coverage, S1/S3 quality, health score /10)
- BMAD integration restored in `INTEGRATIONS.md` (complementary orchestration, not competing)
- `install.ps1` now downloads and registers all 3 hooks (SessionStart, PreCompact, Stop)
- `install.ps1` now scaffolds `KNOWLEDGE.md`

### Fixed
- `install.sh` dead reference to `hooks/README` (line 197) replaced with URL
- `install.sh` now scaffolds `KNOWLEDGE.md` on install
- Star counts removed from `INTEGRATIONS.md` (were outdated)
- MIT License added
- `during-coding/` added to README Advanced section (was undiscoverable)
- "Skill Dial" → "Skill dial" capitalization consistency
- Calibration threshold clarified as "20 commits OR 4 weeks, whichever first"

## [2026-03-28]

### Added
- Session lifecycle hooks: `session-start`, `pre-compact`, `session-end`
- `session-state.md` — continuity across sessions (auto-injected by SessionStart hook)
- YAML frontmatter for specs (machine-readable metadata: status, scope, s1_count, s3_count)
- Code Rule — explicit gate: no code without a spec
- Pair workflow guides (human reads spec for high-risk, /spec-review for standard)
- `/spec-check` Step 0 — verify spec file exists before checking coverage
- Multi-stack deployment constraints (mobile, backend, infra alongside web)
- Refactor Format — structured template for structural changes
- Delta Format — for modifying existing behavior
- Intent Router merged into Formality Dial (1 table, zero conflict)
- Test-first step in Autonomous route (zero overhead TDD)
- Retention use cases: emergency hotfix, spec hygiene, constitution maintenance

### Fixed
- Terraform/K8s added to high-risk override in Scope Routing
- "Four cold sessions" claim corrected (contradicted by Scope Routing)

## [2026-03-27]

### Added
- Scope Routing — evidence-based autonomous/review/required mode selection
- `/spec-review` skill — gate between Spec and Build sessions
- `feedback-triage.md` — 5-phase workflow for processing user feedback into specs
- Calibration protocol with stack adaptation guide
- `install.ps1` — Windows PowerShell installer
- `advanced/examples/` — real production spec examples (feature + bugfix)
- `SessionStart` hook + `KNOWLEDGE.md` cross-session memory

### Changed
- README repositioned: outcomes before mechanism, brownfield entry points elevated
- Non-coder section reframed from "come back later" to "you need this"

### Fixed
- All `/main/` → `/master/` URL paths corrected
- 14 issues from full repo audit (stale paths, logic errors, naming)
- Precise fix:feat metric (1.5:1) replaces vague "3x"

## [2026-03-26]

### Added
- Initial release: spec-first methodology
- `snippet.md` — the core product (paste into any AI context file)
- `spec.md` — spec template with S1-S6 sections
- `review.md` — two-pass code review checklist
- `install.sh` — auto-detect + append installer
- `advanced/` — deep-dives, team workflow, calibration, ETHOS, skills
