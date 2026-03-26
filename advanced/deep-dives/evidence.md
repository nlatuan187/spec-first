# Evidence: The Real Numbers

Every number in this document comes from `git log`, GitHub API, or Claude Code conversation files. No estimates, no projections — archaeology.

---

## The Project

A full-stack SaaS platform built in 24 calendar days by 2 people using spec-first development with Claude Code.

**What shipped:**
- Authentication + role-based access
- Dual payment gateway (2 providers) with webhook reconciliation
- AI-powered content generation (multimodal: text, image, video)
- Content scheduling calendar
- Automated publishing pipeline (multi-platform)
- Web crawling + content classification
- Public microsites with SEO
- Credit-based billing system with atomic transactions
- i18n (2 languages)
- 107 REST API endpoints
- 19 PostgreSQL tables with Row-Level Security

---

## Raw Numbers

### Codebase

| Metric | Count |
|--------|-------|
| Lines of TypeScript/TSX | 82,239 |
| API route files | 107 |
| React components | 119 |
| Zustand stores | 9 |
| Database tables | 19 |
| Database RPCs | 13 |
| Migration files | 19 |
| Test files | 107 |
| npm dependencies | 57 |
| Specification documents | 45 |

### Git Activity

| Metric | Count |
|--------|-------|
| Total commits | 626 |
| Active days (days with commits) | 17 of 24 |
| PRs created | 120 |
| PRs merged | 106 |
| PRs closed without merge | 11 |
| Issues filed | 156 |
| Co-authored with AI | 508 (81%) |
| Full reverts | 6 |

### Velocity by Week

| Week | Commits | PRs Merged | Commits/Day |
|------|---------|------------|-------------|
| W1 (Mar 2-8) | 34 | 5 | 4.9 |
| W2 (Mar 9-15) | 120 | 18 | 17.1 |
| W3 (Mar 16-22) | 312 | 52 | 44.6 |
| W4 (Mar 23-25)* | 160 | 31 | 53.3 |

*W4 is only 3 days. The acceleration is real — spec quality improved, patterns established, velocity compounded.

### Author Breakdown

| Author | Commits | PRs | Role |
|--------|---------|-----|------|
| PM/Architect | 290 | 47 | Specs, backend, architecture |
| Frontend Dev | 336 | 73 | UI, stores, i18n |

### Burst Pattern

73.2% of commits occurred in **burst sessions** — clusters of commits less than 5 minutes apart. 123 burst sessions averaging 3.7 commits each.

Largest burst: 14 commits in 3 minutes.

This pattern is the fingerprint of AI-generated code. A human reviews, the AI generates, commits happen in rapid succession.

---

## The Honest Math

### Traditional Estimate

For a SaaS of this scope (auth, payments, AI, i18n, 107 endpoints, publishing pipeline):

- **Traditional team**: 3-4 senior full-stack developers + 1 PM = 4-5 people
- **Traditional timeline**: 6-9 months
- **Traditional developer-days**: 4 people × 7.5 months × 20 days = **600 developer-days**

### Actual

- **Team**: 2 people × 17 active days = **34 developer-days**

```
Developer-day multiplier = 600 / 34 = 17.6x
```

### Human Hours Decomposition

| Activity | Estimated Hours | Traditional Equivalent |
|----------|:--------------:|:---------------------:|
| Spec writing (45 specs) | ~68 | ~300 (requirements + coding) |
| PR review (120 PRs) | ~60 | ~60 (same, but reviewing AI code) |
| Issue management (156 issues) | ~26 | ~26 (same) |
| Architecture / debugging | ~40 | ~40 (same) |
| Prompting / AI interaction | ~30 | 0 (NEW overhead) |
| **Total** | **~225** | **~3,200** |

```
Human-hour multiplier = 3,200 / 225 = 14.2x
```

### After Adjustments

Accounting for:
- Product thinking not captured in git (~15% overhead)
- Rework from AI bugs (fix:feat ratio 2.93:1)
- Learning curve (~10% overhead in week 1-2)
- UX research, user testing (not in git)

**Honest multiplier: 10-15x** depending on project complexity.

### Why Not 100x?

1. **Review time doesn't compress.** AI generates 100 lines in 3 seconds. Reviewing takes 5-10 minutes. Humans become the bottleneck.

2. **The fix tax is real.** Fix:feat ratio of 2.93:1 means 75% of commits were fixing AI output. This improves with better specs (from 5:1 to 1.5:1) but never reaches zero.

3. **Architecture is still slow.** Deciding *what* to build, *why*, and *how modules connect* takes the same time whether you code manually or not. Specs take 1-2 hours each.

### But 10-15x Is Transformative

| | Traditional | Spec-First |
|--|------------|-----------|
| Team | 4-5 people | 2 people |
| Time | 7.5 months | 24 days |
| Cost (US rates) | $300K+ | ~$15K |
| Cost (emerging market) | $60-90K | ~$5K |

Two people now have the output of a 10-person team. A small team can ship what previously required a department.

---

## Cost Breakdown (24 Days)

| Item | Cost |
|------|------|
| Claude Code Pro (2 seats × $100/mo) | $160 |
| Claude API overages | ~$200 |
| Database (Supabase free tier) | $0 |
| Hosting (Vercel free tier) | $0 |
| CodeRabbit (free tier) | $0 |
| **Total infrastructure** | **~$360** |

Human cost is separate and market-dependent. The infrastructure cost for AI-assisted development is trivially low.

---

## Conversation Analytics

From 753 Claude Code conversation files (350MB+ of JSONL data):

| Metric | Value |
|--------|-------|
| Total conversation sessions | 62 |
| Total user messages | ~14,000 |
| Context window exhaustions | 113 |
| "Ultrathink" invocations | 259 |
| Parallel agent sessions | 11 (single day) |
| Mega-conversations (>25M) | 4 |

### Parallel Agent Architecture

On a single day (March 8), the PM ran 11 AI agents simultaneously — each in its own git worktree, each working on a different part of the system:

| Agent | Task | Messages | Outcome |
|-------|------|----------|---------|
| Agent 0 | Repository setup + fork | 59 | Failed first run, wiped and re-run |
| Agent 1 | Legacy code cleanup | 149 | Most complex, multiple fixes needed |
| Agent 2 | Database migration | 7 | Clean execution |
| Agent 3 | Constants + config | 9 | Clean execution |
| Agent 4 | CRUD services | 19 | Moderate intervention |
| Agent 5 | Documentation | 22 | Failed: lost Unicode diacritics |
| Agent 6 | Address normalization | 10 | Clean execution |
| Agent 7 | API routes (Wave 2) | 33 | Depended on Wave 1 |
| Agent 8 | AI integration (Wave 2) | 34 | Depended on Wave 1 |
| Agent 9 | Test suites (Wave 2) | 49 | Depended on Wave 1 |
| Agent 10 | Final integration (Wave 2) | 79 | Most messages |
| Merge Agent | Combine all branches | 8 | Surprisingly clean |

Simple, isolated tasks (agents 2, 3, 6) completed with <10 messages. Complex, cross-cutting tasks (agents 1, 10) required 10-15x more interaction.

---

## Metrics Dashboard

Track these weekly. Trends matter more than absolute values.

| Metric | Week 1 | Week 2 | Week 3 | Week 4 | Target |
|--------|:------:|:------:|:------:|:------:|:------:|
| Fix:feat ratio | ~5:1 | ~3:1 | ~2:1 | ~1.5:1 | < 2.5:1 |
| PRs/day | 0.7 | 2.6 | 7.4 | 10.3 | Increasing |
| Commits/day | 4.9 | 17.1 | 44.6 | 53.3 | Increasing |
| Median merge time | 4+ hrs | ~2 hrs | ~1 hr | ~45 min | < 90 min |
| Reverts | 0 | 1 | 3 | 2 | < 2/week |
| Context exhaustions | 5 | 12 | 54 | 42 | Decreasing |

The fix:feat ratio improving from 5:1 to 1.5:1 is the single most important metric. It proves that spec quality directly determines output quality.
