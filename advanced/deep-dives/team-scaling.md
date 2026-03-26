# Team Scaling: Solo → Duo → Team

Three tested configurations for spec-first development. Start with what matches your current team, scale when ready.

---

## Solo

**You are**: PM + Architect + QA. AI is your entire dev team.

```
You (Architect)
  ├── Claude Code Session 1 (Feature A)
  ├── Claude Code Session 2 (Feature B)    ← parallel if independent
  └── Automated Review (CodeRabbit / CI)
```

### Daily Rhythm

```
Morning:    Write 2-3 specs. Generate + review first feature.
Midday:     Generate + review remaining features. Fix review issues.
Afternoon:  Integration testing. Fix cross-feature bugs.
Evening:    Deploy. Write tomorrow's specs.
```

### Solo Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Review fatigue (you wrote the spec AND review the output) | Automated review is NON-NEGOTIABLE. CodeRabbit catches what your tired eyes miss. |
| Knowledge silos (only you understand the codebase) | Keep CLAUDE.md comprehensive. It IS the documentation. |
| Over-scoping (no one to say "that's too much") | One spec = one feature. If spec exceeds 2 pages, split it. |
| Burnout (you do everything) | Set a daily PR limit (e.g., 5 PRs/day max). Velocity compounds. |

### Solo Tips

1. **Wait 10 minutes before reviewing.** Don't review immediately after generating. Fresh eyes catch more.
2. **Use cross-agent validation for architecture decisions.** Run the same question through 2 separate sessions. Compare.
3. **Deploy daily.** Small, frequent deploys catch integration issues early.
4. **Your CLAUDE.md is your team's memory.** Update it every time you discover a recurring issue.

### Expected Throughput

3-5 features/day after week 1 ramp-up. Week 1 is slower (1-2 features/day) as you establish patterns.

---

## Duo

**Our tested configuration.** One backend architect/PM, one frontend developer. Both prompt AI, neither writes code manually.

```
Architect (PM)                    Developer
  ├── Writes specs                  ├── Reads specs
  ├── Generates backend code        ├── Generates frontend code
  ├── Reviews FE PRs                ├── Pushes FE PRs
  ├── Merges all PRs                └── Cannot merge (branch protection)
  └── Tests behavior
```

### Daily Rhythm

```
09:00-09:30  SYNC — Demo yesterday's work. Review open PRs. Assign today's specs.
09:30-12:00  PARALLEL WORK — Both prompt AI on separate features.
13:00-17:00  CONTINUE — Implementation + fix review feedback.
17:00-17:30  ASYNC — Cross-review each other's PRs for tomorrow.
```

### Key Rules

1. **Only the architect can merge.** Prevents velocity from outrunning quality.
2. **Ownership zones are strict.** Backend person doesn't touch `components/`. Frontend person doesn't touch `db/migrations/`. AI doesn't blur these lines — humans enforce them.
3. **Cross-review is mandatory.** Backend reviews frontend PRs and vice versa. Different domain eyes catch different bugs.
4. **Worktrees for isolation.** Each person works in their own git worktree. Never share working directories.

### Duo Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Merge conflicts (both touching shared files) | Ownership zones. Types and constants need explicit coordination. |
| Spec handoff misunderstanding | 15-min spec walkthrough before starting. Don't just throw a doc over the wall. |
| Quality variance (one person reviews more carefully) | Merge is architect-only. Automated review catches what both miss. |
| Scope creep (one person specs faster than the other ships) | Max 2 specs ahead. Don't outrun your teammate. |

### Duo Communication

**Sync channels:**
- Daily standup (15-30 min, demo-focused)
- PR comments (async, specific)
- Spec questions (real-time, before starting)

**What NOT to discuss:**
- Implementation details (let AI decide)
- Which library to use (let AI decide based on CLAUDE.md)
- Code style (CLAUDE.md + linter handle this)

### Expected Throughput

5-10 features/day at peak. Our peak was 19 PRs merged in one day (day 19).

---

## Team

**5-10 people.** The factory model at scale.

```
Product Manager
  └── Writes feature specs (1-2 per day per engineer)

Tech Lead / Architect
  ├── Maintains CLAUDE.md (THE source of truth)
  ├── Reviews architecture decisions
  ├── Decomposes large features into spec-sized chunks
  └── Final merge authority

Engineers (3-5)
  ├── Each runs their own Claude Code session
  ├── Works in personal git worktree
  ├── Local review before push
  └── Cross-reviews 1-2 peers' PRs daily

Automated QA Pipeline
  ├── CodeRabbit on every PR
  ├── CI/CD (build, lint, test)
  └── Staging deployment for behavior testing
```

### Critical Infrastructure

**1. CLAUDE.md is the constitution.**
Every AI agent reads it on every session. It must be:
- Comprehensive (all patterns, conventions, rules)
- Current (updated when patterns change)
- Concise (< 150 lines — AI context is expensive)

Without it, each engineer's AI invents different patterns. The codebase fractures within a week.

**2. Worktrees are mandatory.**
5 engineers running AI sessions on the same branch = guaranteed conflicts. Each engineer gets their own worktree:

```bash
git worktree add ../worktree-alice feature/alice-auth
git worktree add ../worktree-bob feature/bob-dashboard
```

**3. Branch protection is guardrails, not bureaucracy.**
- No direct push to main
- Required reviews (automated + 1 human)
- CI must pass
- No self-merges (prevents rubber-stamping)

**4. Spec templates are standardized.**
Every engineer uses the same spec template (S1-S6). Without standardization, spec quality varies wildly and AI output quality varies with it.

### Team Weekly Rhythm

```
Monday AM:     Sprint planning. PM distributes specs.
Mon-Thu:       Engineers work independently. Daily standup optional (async OK).
Thursday PM:   Integration testing. Cross-team review session.
Friday AM:     Deploy to staging. PM + QA verify behavior.
Friday PM:     Retrospective. Update CLAUDE.md with new learnings.
```

### Team Roles Redefined

| Traditional Role | Spec-First Role |
|-----------------|----------------|
| PM writes user stories | PM writes specs (S1-S6) — more detail than user stories |
| Engineer writes code | Engineer prompts AI + reviews output |
| QA tests after build | QA scenarios written in spec BEFORE build |
| Architect reviews code | Architect maintains CLAUDE.md + reviews architecture |
| Tech lead assigns tasks | Tech lead decomposes specs + resolves conflicts |

### Team Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| CLAUDE.md divergence (everyone has different mental model) | Weekly CLAUDE.md review in retrospective. One person owns it. |
| Spec quality variance | Spec template + review. PM reviews specs before engineers start. |
| AI generates inconsistent patterns | CLAUDE.md conventions + linter + automated review |
| Knowledge silos (each person only knows their area) | Rotate cross-reviews. Everyone reviews outside their domain 1x/week. |
| Merge conflicts at scale | Small PRs (< 300 lines). Merge frequently. Feature flags for WIP. |

### Expected Throughput

15-30 features/day with 5 engineers. The bottleneck shifts from coding to **spec writing** and **review**.

---

## Scaling Decision Matrix

| Signal | Action |
|--------|--------|
| Solo → spending > 30% time on review | Add a second person (duo) |
| Duo → specs backing up (writing faster than shipping) | Add an engineer |
| Team → merge conflicts increasing | Improve CLAUDE.md conventions + smaller PRs |
| Team → fix:feat ratio climbing above 3:1 | Invest in spec quality training |
| Any → context exhaustions > 5/day | Use shorter, focused sessions |
