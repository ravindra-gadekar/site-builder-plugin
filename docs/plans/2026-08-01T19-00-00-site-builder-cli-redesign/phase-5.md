# Phase 5: Docs Cleanup & Verification

**Repo:** site-builder-plugin
**Depends on:** Phase 4 (README.md's Git Workflow section and pipeline diagram describe the fully-redesigned behavior from Phases 1-4; verification in Task 3 checks the cumulative result of every prior phase)
**Delivers:** `README.md` and `CONTEXT.md` reflect demo/prod modes, the `local-dev`-only git workflow, and the 10-phase pipeline; a final repo-wide grep confirms zero `stage`-mode references remain across all 8 files named in the spec's acceptance criteria.

## File Structure

```
CONTEXT.md   (modify — Build Mode glossary entry)
README.md    (modify — Build Modes table, Git Workflow section, pipeline diagram, approval gates count)
```

---

### Task 1: `README.md` — demo/prod modes, `local-dev`-only git workflow, 10-phase diagram

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: Phase 2's git protocol (branch mapping table), Phase 3's Phase 10 ANALYTICS section, Phase 1's flag dispatch (`--init`/`--auto`/`--parallel`).
- Produces: No further consumers — `README.md` is the project's public-facing entry point.

**Acceptance Criteria:** "All references to 'stage' mode are removed from... README.md", "Pipeline is now 10 phases: DISCOVER, ARCHITECT, PREPARE, DESIGN, CONTENT, DEVELOP, AUDIT, INTEGRATE, DEPLOY, ANALYTICS" (README's pipeline diagram must match).

**Steps (Write-and-review):**

1. **Write content.** Replace the `## Build Modes` section (the table plus its "How it works" and "Branch detection" subsections) — currently:

   ```markdown
   ## Build Modes

   Choose a mode when starting the pipeline:

   | Mode | Branch | Pages | Use case |
   |------|--------|-------|----------|
   | **Demo** | `demo` | Partial or full | Client previews, prospecting unknown clients |
   | **Stage** | `stage` | All pages | Full development and testing before production |
   | **Prod** | `DEPLOY_BRANCH` | All pages | Direct to production (no safety branch) |

   ### How it works

   - **Demo & Stage** — working branch is created from the default branch, production is never touched. When ready, say "make it prod" to promote.
   - **Prod** — code goes directly to the CI/CD deploy branch. Use when you're confident and ready to go live.
   - **All modes** use the same git workflow: commit locally → push to `feature/<name>` branch → PR to base → merge → sync. Never push directly to the base branch.

   ### Branch detection

   The orchestrator detects both the **default branch** (GitHub base) and the **CI/CD deploy branch** (what triggers production deployment). They may be different — e.g., `develop` as default and `production` as deploy. The default branch is treated as the "golden" branch — only post-production tested, bug-free code goes there.
   ```

   with:

   ```markdown
   ## Build Modes

   Choose a mode when starting the pipeline (`/site-builder`, after Init):

   | Mode | PR target | Pages | Use case |
   |------|-----------|-------|----------|
   | **Demo** | `demo` (created lazily on the first phase-boundary PR) | Partial or full | Client previews, prospecting unknown clients |
   | **Prod** | `DEPLOY_BRANCH` (or default branch if none) | All pages | Direct to production |

   ### How it works

   - All pipeline work happens on a single branch, `local-dev` — the orchestrator never checks out `demo`, `prod`, or any other branch.
   - **Demo** — phase-boundary PRs target `demo`, created lazily the first time one is needed (not upfront). Production is never touched until you say "make it prod," which promotes via a PR from `demo` to `DEPLOY_BRANCH` after verifying every demo PR is already merged.
   - **Prod** — phase-boundary PRs target `DEPLOY_BRANCH` directly. Use when you're confident and ready to go live.
   - **Both modes** use the same flow: commit on `local-dev` → push to `feature/<name>` → PR to the mode's base branch → squash merge. `local-dev` itself is never reset and never pushed. Never push directly to the base branch.

   ### Branch detection

   The orchestrator detects both the **default branch** (GitHub base) and the **CI/CD deploy branch** (what triggers production deployment). They may be different — e.g., `develop` as default and `production` as deploy. The default branch is treated as the "golden" branch — only post-production tested, bug-free code goes there.
   ```

   Replace the `### 9-Phase Pipeline` heading and diagram — currently:

   ```markdown
   ### 9-Phase Pipeline

   ```
   Phase 1: DISCOVER    → Business analysis, competitor research, codebase inventory, document extraction
   Phase 2: ARCHITECT   → Tech stack confirmation, site map, URL structure, components
   Phase 3: PREPARE     → Clean old files, scaffold new project, set up .gitignore
   Phase 4: DESIGN      → Visual identity, design tokens, wireframes, anti-AI-look validation
   Phase 5: CONTENT     → Page copy, meta tags, image planning (real assets first)
   Phase 6: DEVELOP     → Working website code (chunked: pages → SEO → performance)
   Phase 7: AUDIT       → 6 parallel quality checks with fix loop (max 3 cycles)
   Phase 8: INTEGRATE   → Social media + analytics setup (all optional/skippable)
   Phase 9: DEPLOY      → CI/CD pipeline + staging deployment
   ```

   ### Approval Gates

   4 user approval gates (Discover, Architect, Design, Deploy) and 1 quality gate (all 6 audits must pass).
   ```

   with:

   ```markdown
   ### 10-Phase Pipeline

   ```
   Phase 1: DISCOVER    → Business analysis, competitor research, codebase inventory, document extraction
   Phase 2: ARCHITECT   → Tech stack confirmation, site map, URL structure, components
   Phase 3: PREPARE     → Clean old files, scaffold new project, set up .gitignore
   Phase 4: DESIGN      → Visual identity, design tokens, wireframes, anti-AI-look validation
   Phase 5: CONTENT     → Page copy, meta tags, image planning (real assets first)
   Phase 6: DEVELOP     → Working website code (chunked: pages → SEO → performance → analytics scaffolding)
   Phase 7: AUDIT       → 6 parallel quality checks with fix loop (max 3 cycles)
   Phase 8: INTEGRATE   → Social media setup (all optional/skippable)
   Phase 9: DEPLOY      → Hosting-agnostic CI/CD pipeline + staging deployment
   Phase 10: ANALYTICS  → Real credentials injected, tracking verified on the live URL
   ```

   ### Approval Gates

   5 user approval gates (Discover, Architect, Design, Deploy, Analytics) and 1 quality gate (all 6 audits must pass).
   ```

   Replace the `## Git Workflow` section (from the heading through the `### Prod mode sync` subsection) — currently:

   ```markdown
   ## Git Workflow

   All git operations are centralized in the orchestrator. Agents produce files — they never commit, push, or create PRs. Remote name is detected dynamically (not hardcoded to `origin`).

   **With remote:** Commits happen per sub-task locally on the working branch (`demo`/`stage`/`prod`). PRs happen at phase boundaries (~7-9 PRs per build, not per-commit). Squash merge keeps clean phase-level commits on the base branch.

   ```
   1. Orchestrator commits locally on the working branch (demo/stage/prod)
   2. At phase boundary: push to feature branch (git push REMOTE_NAME HEAD:feature/<phase-name>)
   3. Create PR targeting the base branch (demo/stage/DEPLOY_BRANCH)
   4. Squash merge PR
   5. Sync local: git reset --hard REMOTE_NAME/<base-branch>
   ```

   **Branch mapping:**

   - Demo mode: working branch = `demo`, PR target = `demo`
   - Stage mode: working branch = `stage`, PR target = `stage`
   - Prod mode: working branch = `prod`, PR target = `DEPLOY_BRANCH`

   No direct pushes to any base branch, ever.

   **Without remote:** Commits happen locally with no push or PR. If a remote is added later, accumulated commits are pushed at the next phase boundary.

   ### Promotion (demo/stage → production)

   When user says "make it prod":
   - **With remote:** PR from working branch → `DEPLOY_BRANCH` (goes live)
   - **Without remote:** Local merge of working branch into `DEFAULT_BRANCH`
   - Post-production testing
   - After confirmed stable → sync `DEPLOY_BRANCH` → `DEFAULT_BRANCH` (golden branch updated)

   ### Prod mode sync

   If `DEPLOY_BRANCH` differs from `DEFAULT_BRANCH`, the orchestrator periodically asks if post-production testing passed and offers to sync tested code back to the default branch via PR.
   ```

   with:

   ```markdown
   ## Git Workflow

   All git operations are centralized in the orchestrator, adopting the
   Fullstack Dev `/git` skill's conventions (commit format, `<type>/<name>`
   branch naming, universal stash safety). Agents produce files — they never
   commit, push, or create PRs. Remote name is detected dynamically (not
   hardcoded to `origin`). Everything happens on a single branch, `local-dev`
   — the orchestrator never checks out `demo`, `prod`, or any other branch.

   **With remote:** Commits happen per sub-task locally on `local-dev`. PRs
   happen at phase boundaries (~7-9 PRs per build, not per-commit). Squash
   merge keeps clean phase-level commits on the base branch. `local-dev`
   itself is never reset — the next phase boundary just pushes the next batch
   of commits to a new feature branch.

   ```
   1. Orchestrator commits locally on local-dev
   2. At phase boundary: push to feature branch (git push REMOTE_NAME local-dev:feature/<phase-name>)
   3. Create PR targeting the mode's base branch (demo/DEPLOY_BRANCH)
   4. Squash merge PR
   5. local-dev is untouched -- next phase boundary pushes the next batch
   ```

   **Branch mapping:**

   - Demo mode: PR target = `demo` (created lazily on the first phase-boundary PR — never during Init or Branch Setup)
   - Prod mode: PR target = `DEPLOY_BRANCH`

   No direct pushes to any base branch, ever.

   **Without remote:** Commits happen locally with no push or PR. If a remote is added later, accumulated commits are pushed at the next phase boundary.

   ### Promotion (demo → production)

   When user says "make it prod": the orchestrator first verifies every
   phase-boundary PR targeting `demo` is already merged (offering to
   auto-merge any that are still open), then:
   - **With remote:** PR from `demo` → `DEPLOY_BRANCH` (goes live)
   - **Without remote:** nothing to promote remotely — mode simply flips to `prod` for future phase-boundary work
   - Post-production testing
   - After confirmed stable → sync `DEPLOY_BRANCH` → `DEFAULT_BRANCH` (golden branch updated)

   Prod mode has no promotion step — code is already live via phase-boundary PRs targeting `DEPLOY_BRANCH` directly.

   ### Prod mode sync

   If `DEPLOY_BRANCH` differs from `DEFAULT_BRANCH`, the orchestrator periodically asks if post-production testing passed and offers to sync tested code back to the default branch via PR.
   ```

   Finally, in the `### Tech Stack Migration` subsection under "What It Does", replace:

   ```markdown
   When migrating to a new framework, the Phase 3 PREPARE phase handles cleanup and scaffolding. The working branch (demo/stage) keeps original code safe on the production branch. Reference old files via `git show` during migration. If it fails, delete the branch and start fresh.
   ```

   with:

   ```markdown
   When migrating to a new framework, the Phase 3 PREPARE phase handles cleanup and scaffolding. Working on `local-dev` (with phase-boundary PRs, never a direct push) keeps original code safe on the production branch. Reference old files via `git show` during migration. If it fails, the orchestrator can discard the unpushed `local-dev` commits and start fresh — production is untouched either way.
   ```

2. **Verify references.** Grep `README.md` for the case-insensitive pattern `stage` — zero matches. Grep for `10-Phase Pipeline` and `Phase 10: ANALYTICS` — each present exactly once. Grep for `5 user approval gates` — present.
3. **Commit:** `docs(readme): demo/prod modes, local-dev-only git workflow, 10-phase pipeline`

---

### Task 2: `CONTEXT.md` — Build Mode glossary entry

**Files:**
- Modify: `CONTEXT.md`

**Interfaces:**
- Consumes: None new.
- Produces: None new — this is the project's own domain-model glossary, read by future `/plan` and `/brainstorm` runs, not by the site-builder pipeline itself.

**Acceptance Criteria:** "All references to 'stage' mode are removed from... CONTEXT.md".

**Steps (Write-and-review):**

1. **Write content.** In the `### Glossary` table, replace the row:

   ```markdown
   | Build Mode | One of Demo / Stage / Prod — determines target branch and page scope for a build |
   ```

   with:

   ```markdown
   | Build Mode | One of Demo / Prod — determines the PR target branch and page scope for a build |
   ```

2. **Verify references.** Grep `CONTEXT.md` for the case-insensitive pattern `stage` — zero matches.
3. **Commit:** `docs(context): update Build Mode glossary entry to demo/prod`

---

### Task 3: Repo-wide verification — zero `stage`-mode references remain

**Files:**
- Verify only (no modifications expected): `skills/site-builder/SKILL.md`, `skills/site-builder/reference/phases.md`, `agents/developer-agent.md`, `agents/analytics-agent.md`, `README.md`, `CLAUDE.md`, `CONTEXT.md`, `ARCHITECTURE.md`

**Interfaces:**
- Consumes: The cumulative output of Phases 1-5.
- Produces: A pass/fail confirmation for the spec's final cross-file acceptance criterion. No file content is produced.

**Acceptance Criteria:** "All references to 'stage' mode are removed from SKILL.md, phases.md, developer-agent.md, analytics-agent.md, README.md, CLAUDE.md, CONTEXT.md, and ARCHITECTURE.md."

**Steps (Write-and-validate — no code/config to author, this task is pure verification):**

1. **Run the checks.** Two sweeps across the same 8 files:

   **Sweep A — `stage` mode references.** Grep each file for the case-insensitive pattern `stage`, matching on the mode word specifically (a literal match for `stage` — this repo's prose has no unrelated words containing "stage" as a substring in these particular files, so a plain case-insensitive grep is sufficient; confirmed during this plan's research phase for `CLAUDE.md`, `ARCHITECTURE.md`, and `agents/analytics-agent.md`, which had zero `stage` matches even before Phases 1-4 ran).

   **Sweep B — stale `9-phase` and `pipeline_version: 2` references.** Grep the same 8 files for the patterns `9-phase` and `pipeline_version: 2`. All matches should be zero after Phases 1-4 (Phase 1 Task 1 updated the frontmatter, Phase 3 Task 4 updated Pipeline Versioning and Mode Detection, Phase 4 Task 2 updated `developer-agent.md`'s Project Scaffold note). The only acceptable surviving instance of `pipeline_version: 2` is inside the v2→v3 resume-rule prose in `SKILL.md` (where it's mentioned as the old value to detect, not as a current default).

2. **Evaluate results:**
   - `skills/site-builder/SKILL.md`, `skills/site-builder/reference/phases.md`, `agents/developer-agent.md`, `README.md`, `CONTEXT.md` → must be zero `stage` matches after Phases 1-5.
   - `CLAUDE.md`, `ARCHITECTURE.md`, `agents/analytics-agent.md` → must remain zero `stage` matches.
   - `skills/site-builder/SKILL.md`, `agents/developer-agent.md` → must have zero `9-phase` matches (they had occurrences before this plan; all updated in prior phases). `README.md` → zero (updated in Phase 5 Task 1 to say `10-Phase Pipeline`).
   - Any match found → identify which task should have removed it (cross-reference Phases 1-5's task list above), fix it directly in this task using the same Write-and-review pattern as the originating task, and re-run the grep.
3. **Commit** (only if a fix was needed in step 2): `docs: sweep final stage-mode reference missed by earlier phase`. If zero fixes were needed, this task makes no commit — report the clean grep result instead.

---

## Phase 5 Complete

`README.md` and `CONTEXT.md` now describe the demo/prod, `local-dev`-only, 10-phase pipeline. A repo-wide grep confirms every file named in the spec's acceptance criteria — `SKILL.md`, `phases.md`, `developer-agent.md`, `analytics-agent.md`, `README.md`, `CLAUDE.md`, `CONTEXT.md`, `ARCHITECTURE.md` — has zero remaining `stage`-mode references. The Site Builder CLI Redesign is fully implemented.

**Next:** Plan complete.
