# Changelog

All notable changes to spec-first are documented here. When `snippet.md` changes, re-paste it into your AI context file to get the latest rules.

Format follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- Delta and Refactor example specs in `advanced/examples/` (real production specs, anonymized)
- `hooks/README.md` — documents what each hook does, how to verify, how to disable
- `CONTRIBUTING.md` — guide for community contributions
- `CHANGELOG.md` (this file)
- GitHub issue templates (bug report + feature request)

### Changed
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
