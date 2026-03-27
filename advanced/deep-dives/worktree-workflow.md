# Worktree Workflow: From Idea to Merge

A complete, step-by-step guide to shipping features with multiple AI sessions, git worktrees, and clean session boundaries. Works for teams who have never used worktrees.

---

## The Core Idea

Each feature lives in its own isolated environment:
- **Its own branch** — changes don't mix with other features
- **Its own folder (worktree)** — you can have 3 features "in progress" simultaneously without stashing or switching branches
- **Its own AI sessions** — spec session, implement session, review session each have fresh context

The output of each session is a file that becomes the input to the next session. Nothing passes between sessions except files.

---

## Concepts for Non-GitHub Users

**Issue** = a numbered task description. GitHub Issue #123 is like a task card in Trello or Jira. It has a title, description, and ID you can reference.

**Branch** = an isolated copy of the codebase. Changes on branch `feature/photo-upload` don't affect `main` until you merge. Think of it as a parallel track — you work on the track, then merge it back to the main line.

**Worktree** = a local folder that points to a specific branch. Without worktrees, switching branches means your editor changes. With worktrees, you have one folder per branch — open them simultaneously, switch between them like tabs.

**PR (Pull Request)** = "I made changes on this branch. Please review before merging to main." It's the formal review step before changes become official.

**Merge** = accepting the changes from a branch into main. After merge, the feature is in production on the next deploy.

---

## Full Workflow: Issue to Merge

```
HUMAN: Create GitHub issue
   ↓
SESSION A: Write spec (spec-first AI session)
   ↓ [handoff: spec file]
SESSION B: Review spec (cold AI session)
   ↓ [handoff: updated spec file]
SESSION C: Implement (fresh AI session, in worktree)
   ↓ [handoff: git diff / commits]
SESSION D: Review code (cold AI session)
   ↓ [handoff: review findings]
HUMAN: Fix critical issues, merge PR
```

Each arrow is a session boundary. Sessions don't share context.

---

## Step-by-Step

### Step 1 — Create the issue

On GitHub: go to your repo → Issues → New Issue

```
Title: User profile photo upload
Body:
  Agent needs to upload a profile photo.
  Photo should appear immediately after upload.
  Max size: 5MB. Supported formats: JPG, PNG, WebP.
  Related to #112 (profile page).
```

The issue gives the feature a number (`#123`) you'll use everywhere.

---

### Step 2 — Create a worktree for this feature

```bash
# From your main repo directory
git worktree add ../feature-photo-upload feature/photo-upload-123
cd ../feature-photo-upload
```

Now you have a new folder `../feature-photo-upload` with a fresh branch `feature/photo-upload-123`. Your main repo folder still has `main`. Both are available at the same time.

Open the worktree folder in your editor. All AI sessions for this feature run here.

---

### Step 3 — Session A: Write the spec (dedicated session)

Open a **new AI session** in the worktree folder. Do not reuse an existing session.

**Claude Code:**
```bash
cd ../feature-photo-upload
claude  # opens new session in this directory
```

**Prompt:**
```
Read CLAUDE.md, then:
/spec User profile photo upload — agents upload a profile photo (max 5MB, JPG/PNG/WebP), it appears immediately after upload. Related to profile page (#112).
```

The `/spec` command generates a full S1-S6 spec and saves it to `specs/profile-photo-upload.md`.

**When done: close this session. The spec file is the handoff.**

---

### Step 4 — Session B: Review the spec (cold session)

Open a **new AI session**. No context from Session A.

```
Read CLAUDE.md, then:
Read specs/profile-photo-upload.md

Apply the review checklist from spec-first/advanced/templates/review-checklist.md — but for SPECS, not code.
Check:
- S1: Does it cover auth failure, API failure, file too large, wrong format, concurrent upload?
- S3: What other features does photo upload affect? User profile display, email notifications?
- Deployment constraints: What are the S3 file size limits? What's the timeout on upload routes?

Output any gaps as specific missing items.
```

Spec reviewer fixes gaps and saves the updated spec.

**When done: close this session.**

---

### Step 5 — Session C: Implement (fresh session in worktree)

Open a **new AI session** in the worktree folder.

```
Read CLAUDE.md, then implement the spec at specs/profile-photo-upload.md

Create feature branch: feature/photo-upload-123
Implement all files. Commit with: "feat(#123): user profile photo upload"
```

AI implements across all relevant files — API route, service, component, migration.

During a long implementation session, fill in `spec-first/during-coding/implementation-brief.md` to track progress. If context gets long: save the brief, end the session, start fresh and paste the brief.

Run spec-check before ending:
```
/spec-check specs/profile-photo-upload.md
```

Fix any gaps, then commit.

**When done: close this session.**

---

### Step 6 — Session D: Review code (cold session)

Open a **new AI session**. No context from Session C.

```
Read CLAUDE.md, then:
git diff origin/main

Apply Pass 1 (Critical) then Pass 2 (Informational) from spec-first/advanced/templates/review-checklist.md.
Format: [file:line] Problem → recommended fix
AUTO-FIX what you can. Flag the rest.
```

Cold review catches what the implementation session rationalized away:
- Security issues the implementation "knew" were acceptable
- Race conditions the implementation "knew" the spec covered
- Missing error states the implementation "knew" would be added later

**When done: close this session. Review findings are the handoff.**

---

### Step 7 — Fix and push

Human reviews the review findings. Fix Critical issues (auto-fixed or manually).

```bash
git push origin feature/photo-upload-123
gh pr create --title "feat(#123): user profile photo upload" --body "Closes #123"
```

---

### Step 8 — Merge

After automated review (CodeRabbit) + human approval:

```bash
gh pr merge --squash
```

Clean up:
```bash
cd ..
git worktree remove feature-photo-upload
git branch -d feature/photo-upload-123
```

---

## Multi-Agent Configuration

For teams where different people (or different AI tools) handle different phases:

```
PM: Creates issues
↓
Claude Code (spec-first): Session A+B (spec writing + review)
↓
Developer / Claude Code: Session C (implementation)
↓
Claude Code (cold): Session D (code review)
↓
PM + Developer: Merge decision
```

**Key rule:** whoever does Session D must NOT have been involved in Session C. If the same developer did the implementation, use a different AI tool or explicitly start a fresh session with no context.

---

## Working on Multiple Features Simultaneously

Worktrees let you have 3 features "in progress" at the same time:

```
~/myapp/                         ← main branch (production)
~/feature-photo-upload/          ← feature/photo-upload-123
~/feature-email-notifications/   ← feature/email-notifications-124
~/bugfix-search-crash/           ← fix/search-crash-125
```

Each folder is a separate environment. Each has its own spec, its own AI sessions, its own branch.

Switch between features by switching folders. No stashing, no branch switching conflicts.

```bash
# List all worktrees
git worktree list

# Add a new feature worktree
git worktree add ../feature-email-notifications feature/email-notifications-124

# Remove after merge
git worktree remove ../feature-photo-upload
```

---

## Session Discipline: The Key Rules

**1. New session = new job.** Don't carry spec-writing context into implementation. Don't carry implementation context into review.

**2. Handoff via file, not conversation.** The spec file, not memory of the spec conversation. The diff, not memory of why the code was written.

**3. Review session must be cold.** If you open review in the same session as implementation, the review is biased. Every AI tool has a way to open a fresh session — use it.

**4. Commit at each phase boundary.** "Spec written" commit. "Implementation complete" commit. "Review fixes applied" commit. Each is a checkpoint you can return to.

**5. The brief bridges long sessions.** If Session C gets long (50+ messages), don't fight the context limit. Fill in `implementation-brief.md`, start a new session, paste the brief, continue. 5 minutes of state capture saves 20 minutes of context rebuilding.

---

## Common Questions

**"Do I need worktrees? Can I just use branches?"**

You can use branches without worktrees. The difference: with branches, you run `git stash` + `git checkout` to switch features, which can cause conflicts and confusion. With worktrees, you switch folders — two features are open simultaneously, no conflict.

For solo developers: worktrees are a quality-of-life upgrade, not required.
For teams: worktrees prevent "I thought I was on main but I was on feature-x" incidents.

**"Can I spec and implement in the same session?"**

You can. The cost: context contamination. The spec you just wrote is in memory, so the AI "knows" things about the implementation that it shouldn't. Error states you intended to handle might get rationalized away. The session works — but the output quality is lower than two clean sessions.

Short features (< 2 hours of implementation): combined session is acceptable.
Longer features: separate sessions pay for themselves in review pass rate.

**"What if the spec changes during implementation?"**

Update the spec file. Don't fight reality. The spec is a living document during Session C. If you discover a constraint the spec didn't cover, add it to S1. If the integration is more complex than S3 described, update S3. End of Session C: the spec file reflects what was actually built.

**"We use Cursor/Windsurf/Codex, not Claude Code. Does this work?"**

Yes. The session boundary principle applies to any AI tool:
- Cursor: spec in one Composer window, implement in another, review in a third
- Windsurf: new conversation for each phase
- Codex: separate API calls, no session history

The spec file is always the bridge. The AI tool is interchangeable.

→ [Tool-specific integration guide](../INTEGRATIONS.md)

---

## One-Week Setup for a New Team

| Day | What to Do |
|-----|-----------|
| Day 1 | Set up CLAUDE.md for your project. Run `bash install.sh`. Write your first spec manually (without `/spec`). |
| Day 2 | Use `/spec` for the next feature. Notice what it fills that you would have skipped. |
| Day 3 | Add your first worktree. Implement in it. |
| Day 4 | Run cold review on a completed feature. Note what the cold session caught that the implementation session didn't. |
| Day 5 | Count your fix:feat ratio for the week. Set a target for next week. |
| Week 2 | Refine your CLAUDE.md with platform constraints discovered during review. Enforce Session D for all PRs. |
