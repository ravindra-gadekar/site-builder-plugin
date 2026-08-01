# Phase 2: Mode Selection & Git Delegation

**Repo:** site-builder-plugin
**Depends on:** Phase 1 (Init guarantees `local-dev` is checked out and `.gitignore` exists before this phase's logic runs)
**Delivers:** Build mode narrowed to demo/prod; `## Build Mode & Branch Setup` → `### Step 3: Branch Setup` no longer creates per-mode working branches (`demo`/`stage`/`prod`) — all commits happen on `local-dev`; the ~108-line `### Git Operations Protocol` section is replaced by a lighter protocol that adopts `/git` skill conventions, creates the `demo` branch lazily at the first phase-boundary PR, and implements an explicit branch guard.

## File Structure

```
skills/site-builder/
└── SKILL.md   (modify — Step 2 Ask Build Mode, Step 3 Branch Setup, Git Operations Protocol)
```

---

### Task 1: Narrow build mode to demo/prod

**Files:**
- Modify: `skills/site-builder/SKILL.md`

**Interfaces:**
- Consumes: `## Init` section from Phase 1 (guarantees `local-dev` exists before this question is asked).
- Produces: The mode value (`demo` | `prod`) stored in `status.md` under Build Configuration, consumed by Task 2 (branch setup), Task 3 (git protocol / lazy demo branch), and by Phase 3 Task 3 (Mode Promotion Flow).

**Acceptance Criteria:** "Only two build modes exist: demo and prod (stage is completely removed)", "Mode is asked interactively on first run and stored in `status.md` for subsequent runs".

**Steps (Write-and-review):**

1. **Write content.** Replace the current `### Step 2: Ask Build Mode` section (which presents Demo/Stage/Prod) with:

   ```markdown
   ### Step 2: Ask Build Mode

   Present two options to the user:

   **Demo mode** — Build a preview site for client approval. Partial or full
   pages. All work happens on `local-dev`; nothing is pushed to a shared
   branch until the first phase boundary, when a `demo` branch is created
   lazily (see Step 3 and the Git Operations Protocol below) and a PR targets
   it. Production is never touched until the client approves and you say
   "make it prod." Works for both existing and new websites.

   **Prod mode** — Build on `local-dev`, with phase-boundary PRs targeting
   `DEPLOY_BRANCH` (or `DEFAULT_BRANCH` if no separate deploy branch) through
   the standard PR workflow. All pages and configuration. Use when you're
   ready to go live immediately.

   Store the choice in `status.md` under Build Configuration: `Mode: [demo|prod]`.
   ```

2. **Verify references.** Grep the replaced section for the word `Stage` (case-insensitive) — zero matches. Confirm `**Demo mode**` and `**Prod mode**` each appear exactly once in this section.
3. **Commit:** `docs(site-builder): remove stage mode from build mode selection`

---

### Task 2: Branch Setup — `local-dev` only, no per-mode working branches

**Files:**
- Modify: `skills/site-builder/SKILL.md`

**Interfaces:**
- Consumes: Task 1's `Mode` value; `## Init` section's `local-dev` checkout guarantee (Phase 1 Task 2).
- Produces: A `### Step 3: Branch Setup` that Task 3 (Git Operations Protocol) relies on for "no separate working branch to create or push".

**Acceptance Criteria:** "All work happens on `local-dev` branch — the orchestrator never checks out demo, prod, or any other branch", "Demo mode creates a `demo` branch lazily at the first phase boundary PR, not during init", "Prod mode targets `DEPLOY_BRANCH` (or `DEFAULT_BRANCH` if no separate deploy branch) for PRs".

**Steps (Write-and-review):**

1. **Write content.** Replace the entire current `### Step 3: Branch Setup` section (which creates and checks out `demo`/`stage`/`prod` branches under 4 sub-cases) with:

   ```markdown
   ### Step 3: Branch Setup

   There is no per-mode branch to create or check out. `local-dev` (verified
   in Init, Phase 1 of this plugin's own git workflow) is the only branch the
   orchestrator ever works on or checks out. Set the PR-target base branch
   for the chosen mode, without touching the working tree:

   | Mode | Base branch (PR target) | When it's created |
   |------|--------------------------|--------------------|
   | Demo | `demo` | Lazily, before the *first* phase-boundary PR (see Git Operations Protocol below) — not here, not during Init |
   | Prod | `DEPLOY_BRANCH` (or `DEFAULT_BRANCH` if none) | Already exists — it's the repo's real deploy branch |

   Store the base branch in `status.md` under Build Configuration:
   `Base branch (PR target): [demo|DEPLOY_BRANCH]`.

   If `HAS_REMOTE = false` (no remote — see Step 1), there is no PR target.
   All work stays on `local-dev`, committed locally, no push. Store
   `Base branch (PR target): none (no remote)`.
   ```

2. **Verify references.** Grep the section for `git checkout -b demo`, `git checkout -b stage`, `git checkout -b prod`, and `IMPORTANT: In prod mode, the working branch is` — all must be absent. Confirm the new section is strictly shorter than the ~63-line original it replaces.
3. **Commit:** `docs(site-builder): replace per-mode branch creation with local-dev-only branch setup`

---

### Task 3: Replace Git Operations Protocol with `/git`-convention-adopting protocol and lazy demo branch creation

**Files:**
- Modify: `skills/site-builder/SKILL.md`

**Interfaces:**
- Consumes: Task 2's base-branch value; `/git` skill's commit-message and branch-naming conventions (`.claude/skills/git/SKILL.md` — adopted as patterns, referenced but not invoked, per the spec's "Why not `/git publish` for PRs" rationale).
- Produces: The phase-boundary PR flow that every later pipeline phase description (Phase 3-9, Phase 10 of this plan) assumes is in effect. Also produces the "at each phase boundary" remote re-check behavior reused unchanged from the current file.

**Acceptance Criteria:** "Demo mode creates a `demo` branch lazily at the first phase boundary PR, not during init", "Prod mode targets `DEPLOY_BRANCH`... for PRs", "All work happens on `local-dev` branch — the orchestrator never checks out demo, prod, or any other branch", "Git operations adopt `/git` skill conventions for commit messages, branch naming (`<type>/<name>`), and stash safety; phase-boundary PRs use `mcp__github__create_pull_request` directly (not `/git publish`) because the orchestrator controls the PR target branch per mode", "All references to 'stage' mode are removed from SKILL.md".

**Steps (Write-and-review):**

1. **Write content.** Replace the entire block from `### Git Operations Protocol` through the end of `### Prod Mode: Post-Production Default Branch Sync` (everything up to, but not including, `### Step 4: Demo Scope`) with:

   ````markdown
   ### Git Operations Protocol

   **ALL git operations are centralized in the orchestrator. Agents produce
   files — they never commit, push, or create PRs.** This protocol adopts the
   `/git` skill's conventions (commit message format, `<type>/<name>` branch
   naming, universal stash safety) as patterns. It does not invoke `/git`
   directly for PR creation, because `/git publish` reads a single
   `targetBranch` per repo from `config.json`, while site-builder needs PRs to
   target `demo` or `DEPLOY_BRANCH` depending on mode — so phase-boundary PRs
   call `mcp__github__create_pull_request` directly instead.

   #### Commit Checkpoints

   The orchestrator commits on `local-dev` after each meaningful sub-task,
   using Conventional Commits (adopting `/git` skill formatting):

   | Phase | Checkpoint | Commit message |
   |-------|-----------|----------------|
   | 3. PREPARE | Old files removed | `chore: remove old website files for clean rebuild` |
   | 3. PREPARE | Scaffold complete | `feat: scaffold [framework] project` |
   | 4. DESIGN | Design system written | `feat: add design system tokens and wireframes` |
   | 5. CONTENT | Content plan + copy written | `feat: add content plan and page copy` |
   | 6. DEVELOP | Design tokens implemented | `feat: implement design tokens in code` |
   | 6. DEVELOP | Shared components built | `feat: add shared components (Header, Footer, SEOHead, etc.)` |
   | 6. DEVELOP | Each page built | `feat: add [page-name] page` |
   | 6. DEVELOP | SEO implementation | `feat: add sitemap, robots.txt, JSON-LD, llms.txt` |
   | 6. DEVELOP | Performance optimization | `perf: optimize images, lazy loading, code splitting` |
   | 7. AUDIT | Each fix cycle | `fix: address audit findings (cycle [N])` |
   | 8. INTEGRATE | Social integration | `feat: add social media integration` |
   | 9. DEPLOY | CI/CD setup | `feat: add CI/CD pipeline and deployment config` |
   | 10. ANALYTICS | Credentials injected and verified | `feat: connect analytics credentials and verify tracking` |

   **Before each commit, the orchestrator:**
   1. Check `.gitignore` — add new patterns if framework tooling generated new output directories (or re-run `/gitignore rebuild`)
   2. Run `git status` — verify no unwanted files (secrets, temp files, IDE configs)
   3. Stage only relevant files — never `git add .` blindly. Use specific paths or `git add -A` after `.gitignore` is verified correct.
   4. Commit with the appropriate message

   #### Orchestrator Branch Guard

   Adopting the `/git` skill's iron rule ("all exit paths pop the stash"), the
   orchestrator runs its own guard before any git operation in this protocol —
   it does not call `/git`'s guard directly, since site-builder's stash scope
   spans the whole pipeline session, not a single command invocation:

   1. Verify current branch is `local-dev`. If not, `git checkout local-dev` (Init, Phase 1 of this plugin's own git workflow, guarantees this branch exists).
   2. Before any operation that could touch uncommitted work (push, reset, branch creation), check `git status --porcelain`. If uncommitted changes exist that are *not* the orchestrator's own pending commit, stash them: `git stash push -u -m "pre-site-builder-op-stash"`.
   3. After the operation completes (success or failure), pop the stash if one was created: `git stash pop`. On pop conflict, inform the user and leave the stash for manual resolution — never silently drop it.
   4. **Never** `git checkout demo`, `git checkout prod`, or `git checkout DEPLOY_BRANCH`. All local work stays on `local-dev`; only pushes and PRs reference other branches.

   #### With-Remote Workflow (`HAS_REMOTE = true`)

   Commits happen per sub-task, locally, on `local-dev`. PRs happen at phase
   boundaries (remotely). This keeps granular local history while avoiding PR
   noise (~7-9 PRs per build instead of ~15-20).

   **Per sub-task (at each commit checkpoint):** stage relevant files, commit
   locally on `local-dev`, continue working — no push yet.

   **At each phase boundary (when a phase completes):**

   1. **Demo mode only, first phase boundary of the build:** check whether the
      remote `demo` branch exists (`git ls-remote --heads REMOTE_NAME demo`).
      - Exists → reuse it (warn if it already has commits from a previous run: "The `demo` branch already has commits. Continuing on top of them.")
      - Does not exist → create it from `DEFAULT_BRANCH`: `git push REMOTE_NAME DEFAULT_BRANCH:refs/heads/demo`
      This is the *only* place the `demo` branch is created — never during Init, never during Branch Setup.
   2. Push accumulated commits from `local-dev` to a feature branch, adopting `/git`'s `<type>/<name>` naming: `git push REMOTE_NAME local-dev:feature/<phase-name>`
   3. Create PR via `mcp__github__create_pull_request` targeting the mode's base branch (from Step 3: `demo` or `DEPLOY_BRANCH`).
   4. **Squash merge** the PR — one clean commit per phase on the base branch, granular sub-task history preserved in the PR on GitHub.
   5. **`local-dev` is NOT reset.** Unlike a single-target branch workflow, `local-dev` never tracks the base branch — it's a one-way flow. Granular commits stay on `local-dev`; the squash commit lives on the base branch. The next phase boundary pushes the next batch of `local-dev` commits to a *new* typed branch (no drift, no conflict).
   6. **Never push `local-dev` to remote.** Only typed feature branches (`feature/<phase-name>`) are pushed.

   **Phase boundary PR schedule:**

   | After Phase | PR branch name | PR title |
   |-------------|---------------|----------|
   | 3. PREPARE | `feature/prepare-scaffold` | `feat: prepare workspace and scaffold [framework] project` |
   | 4. DESIGN | `feature/design-system` | `feat: add design system tokens and wireframes` |
   | 5. CONTENT | `feature/content` | `feat: add content plan and page copy` |
   | 6. DEVELOP | `feature/develop-pages` | `feat: implement all pages with SEO and performance` |
   | 7. AUDIT | `fix/audit-findings` | `fix: address audit findings` |
   | 8. INTEGRATE | `feature/social-integration` | `feat: add social media integration` |
   | 9. DEPLOY | `feature/deployment` | `feat: add CI/CD pipeline and deployment config` |
   | 10. ANALYTICS | `feature/analytics-credentials` | `feat: connect analytics credentials and verify tracking` |

   **At each phase boundary, re-check for remote:** run `git remote`. If a
   remote was added since the last check, log detection, run the empty-repo
   guard (push `main` first if the remote has zero branches), push
   `local-dev`'s accumulated history to a feature branch, and set
   `HAS_REMOTE = true` for all subsequent operations. Update `status.md` with
   the remote name and URL.

   #### Without-Remote Workflow (`HAS_REMOTE = false`)

   After each commit checkpoint: stage relevant files, commit to `local-dev`
   with the appropriate message, no push, no PR, continue working.

   #### Prod Mode: Post-Production Default Branch Sync

   If `DEPLOY_BRANCH` differs from `DEFAULT_BRANCH`, the default branch stays
   the "golden" branch — only post-production tested, bug-free code goes
   there. At each phase boundary in prod mode, if `DEPLOY_BRANCH` is ahead of
   `DEFAULT_BRANCH`, ask: "Your deploy branch has changes not yet in the
   default branch. If post-production testing has passed for previous
   changes, want to sync the tested code to `DEFAULT_BRANCH`?" On
   confirmation: create PR `DEPLOY_BRANCH` → `DEFAULT_BRANCH`, merge it. On
   skip: note it in `status.md`, ask again at the next phase boundary. Never
   force the sync.
   ````

2. **Verify references.** Grep the replaced block for `stage`, `git reset --hard REMOTE_NAME/[base-branch]`, and `Stage mode` — all absent (the `reset --hard` sync-after-squash step no longer applies since `local-dev` is never reset to a base branch). Grep for `demo` branch creation and confirm it only appears under "With-Remote Workflow", not under Branch Setup (Task 2) or Init (Phase 1). Confirm `### Step 4: Demo Scope` (unmodified, immediately following) is still present and intact.
3. **Commit:** `docs(site-builder): replace git operations protocol with local-dev-only, /git-convention-adopting flow`

---

### Task 4: Git Error Handling section — confirm no stage references

**Files:**
- Modify: `skills/site-builder/SKILL.md`

**Interfaces:**
- Consumes: Task 3's protocol (this section, further down in the file under "User Interruption Handling", describes retry/skip/stop behavior for git failures).
- Produces: No new interface — this task is a targeted sweep, not a new section.

**Acceptance Criteria:** "All references to 'stage' mode are removed from SKILL.md" (branch-collision and merge-conflict error handling subsections).

**Steps (Write-and-review):**

1. **Write content.** The existing `### Git Error Handling` subsection (under "User Interruption Handling", far below the Git Operations Protocol) already refers generically to "the working branch" and does not name `demo`/`stage`/`prod` explicitly — re-read it after Task 3's edit lands and confirm no branch-name-specific stage reference survived (it shouldn't, since Task 3's rewrite removed all mode-specific branch mentions upstream). If any residual phrase like "Stage mode:" or a reference to a `stage` branch is found in this subsection, replace it with the equivalent demo/prod-only phrasing consistent with Task 3's protocol (e.g. "fall back to without-remote workflow for this phase boundary only" stays unchanged; only mode-name lists need pruning).
2. **Verify references.** Grep the whole `SKILL.md` file (not just this section) for the case-insensitive pattern `stage` and confirm the only remaining matches, if any, are unrelated English words (there are none expected — `stage` as a mode word should be fully gone after Phase 2 and Phase 3 Task 2's Status Tracking rewrite). This is the authoritative Phase 2 completion check.
3. **Commit:** `docs(site-builder): sweep remaining stage-mode references from git error handling`

---

## Phase 2 Complete

`SKILL.md`'s Build Mode & Branch Setup section now asks demo/prod only, creates no per-mode working branch (everything happens on `local-dev`), and the Git Operations Protocol adopts `/git` skill conventions while creating the `demo` branch lazily at the first phase-boundary PR. An explicit Orchestrator Branch Guard prevents ever checking out a non-`local-dev` branch. Grep confirms zero remaining `stage`-mode references in `SKILL.md`.

**Next:** `phase-3.md`
