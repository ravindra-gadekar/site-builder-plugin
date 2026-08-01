# Site Builder CLI Redesign — Design Spec

**Project:** Site Builder Agents
**Repo(s):** `site-builder-plugin` (mono-repo)
**Scope:** Redesign `/site-builder` orchestrator to support composable CLI flags, simplify build modes from 3 to 2, delegate git/gitignore to Fullstack Dev skills, and make deployment hosting-agnostic
**Approach:** Composable Flags with Interactive Mode Selection

---

## 1. Overview

The `/site-builder` orchestrator currently runs as a single monolithic workflow with no CLI flags — all configuration happens interactively. It manages its own git operations (commit, push, PR, squash-merge, reset), generates `.gitignore` inline during the PREPARE phase, hardcodes three build modes (demo/stage/prod) with dedicated working branches, and assumes Vercel for deployment.

This redesign introduces three composable flags (`--init`, `--auto`, `--parallel`), eliminates the stage mode (leaving demo and prod), switches the git workflow to use `local-dev` as the universal working branch with delegation to the `/git` and `/gitignore` skills, makes the deploy phase hosting-agnostic by asking the user where to deploy, and splits analytics verification into a new post-deploy phase.

The result is a smaller, more modular SKILL.md that follows the same flag-dispatch patterns already proven in sibling skills (`/project --init`, `/refactor --auto --parallel`), integrates cleanly with the Fullstack Dev plugin ecosystem, and gives users explicit control over pipeline behavior.

---

## 2. Architecture

### Flag Dispatch Layer

SKILL.md opens with a flag dispatch table before any pipeline logic. Flags are parsed from `$ARGUMENTS` as raw text (Claude Code slash commands have no native flag parser — the model interprets them).

```
/site-builder [--init] [--auto] [--parallel]

Parse $ARGUMENTS:
+-- --init present   -> Run initialization checks (Init section), then EXIT
+-- No flags         -> Full interactive mode (ask everything)
+-- --auto           -> Modifier: skip optional prompts, keep approval gates
+-- --parallel       -> Modifier: dispatch read-only agents simultaneously

Composable examples:
  /site-builder --init              -> Init only, then stop
  /site-builder                     -> Interactive pipeline
  /site-builder --auto              -> Pipeline, fewer prompts
  /site-builder --auto --parallel   -> Pipeline, fewer prompts, parallel agents
  /site-builder --init --auto       -> Init (auto-accepting defaults), then stop
```

### Module Boundaries

SKILL.md is restructured into these logical sections:

| Section | Responsibility |
|---------|---------------|
| **Flag Dispatch** | Parse flags from `$ARGUMENTS`, route to init or pipeline |
| **Init** | Git, remote, `local-dev`, gitignore, MCP configs — replaces old Prerequisites |
| **Mode Selection** | Ask demo/prod (first run) or read from `status.md` (return run) |
| **Pipeline Execution** | 10 phases: DISCOVER through ANALYTICS |
| **Mode Promotion** | Demo -> prod one-way PR workflow |
| **Update Mode** | Post-completion changes with minimum agent set |
| **Status Tracking** | `status.md` read/write |

### Delegation Points

| Operation | Delegated To |
|-----------|-------------|
| Commit formatting, branch naming conventions, stash safety | `/git` skill conventions (adopted as patterns, not invoked directly) |
| Phase-boundary PRs | `mcp__github__create_pull_request` directly (orchestrator controls the target branch per mode) |
| `.gitignore` generation, hook installation, violation scanning | `/gitignore` skill |
| Framework docs lookup | context7 MCP |
| GitHub PRs/issues | `mcp__github__*` MCP tools |

**Why not `/git publish` for PRs:** The `/git` skill's `publish` command reads a single `targetBranch` from `config.json` per repo (e.g., `main`). Site-builder needs PRs to target different branches depending on mode (demo branch vs DEPLOY_BRANCH). Rather than extending `/git publish` with a `--base` override, the orchestrator calls `mcp__github__create_pull_request` directly for phase-boundary PRs while adopting `/git`'s conventions for commit messages, branch naming (`<type>/<name>`), and stash safety (universal stash-push before operations, pop on all exit paths).

### What Changes vs Current SKILL.md

- **Removed:** Entire "Git Operations Protocol" section (~100 lines of commit/push/PR/squash-merge/reset logic), inline `.gitignore` setup in PREPARE phase, all "stage" mode references (~15+ sections), Vercel-specific deployment assumptions
- **Added:** Flag dispatch table, init section with `/git` and `/gitignore` delegation, Phase 10 ANALYTICS
- **Modified:** Mode selection (3->2), branch setup (demo/stage/prod working branches -> `local-dev` only), all PR target references, deploy phase (hosting-agnostic), Phase 8 INTEGRATE (analytics removed, social only)

---

## 3. Data Flow

### Init Flow

Runs when `--init` is passed explicitly, or auto-detected on first pipeline run (no `status.md` or `init` not marked complete).

```
/site-builder --init
  |
  +-- 1. Git check
  |    +-- git initialized? -> If not, offer git init
  |    +-- remote origin set? -> If not, offer to configure or skip (local-only dev)
  |    +-- local-dev branch exists and checked out?
  |        -> If not, create and checkout local-dev
  |
  +-- 2. Gitignore setup
  |    +-- Delegate to /gitignore rebuild
  |        Generates .gitignore from catalog + installs POSIX pre-commit hook
  |        Note: framework is not yet known at init time (selected after Phase 2).
  |        Init produces a .gitignore with universal/secrets/build/cache/ide/OS
  |        categories only. Phase 3 PREPARE re-runs /gitignore rebuild after
  |        framework selection to add framework-specific patterns (.astro/, .next/, etc.)
  |
  +-- 3. MCP configuration
  |    +-- context7 (required): check .mcp.json, configure if missing
  |    +-- image-gen (optional): offer Nano Banana or other provider
  |    +-- agentation (optional): offer real-time visual feedback
  |    +-- UI UX Pro Max (optional): offer curated design database
  |    Same .mcp.json merge rules as current prerequisites
  |
  +-- 4. Mark init: complete in status.md
  +-- EXIT (init-only, does not start pipeline)
```

`--auto` modifier on init: auto-accept defaults for optional MCPs (skip image-gen, agentation, UI UX Pro Max unless explicitly needed). context7 is always configured since it is required.

### Pipeline Flow

```
/site-builder [--auto] [--parallel]
  |
  +-- Auto-init guard
  |    +-- status.md has init: complete? -> skip, proceed to mode selection
  |    +-- No status.md or init not complete? -> run init, mark complete
  |
  +-- Mode selection (first run only)
  |    +-- Ask: demo or prod?
  |    +-- Demo: PR target = demo branch (created lazily at first phase boundary)
  |    |    Lazy creation: before first PR, check if remote demo branch exists
  |    |      Exists -> reuse (warn if it has commits from a previous run)
  |    |      Does not exist -> create from DEFAULT_BRANCH:
  |    |        git push REMOTE_NAME DEFAULT_BRANCH:refs/heads/demo
  |    +-- Prod: PR target = DEPLOY_BRANCH or DEFAULT_BRANCH
  |    +-- Store in status.md
  |
  +-- Pipeline: 10 phases (see Section 5)
  |    |
  |    |  Phase Boundary Git Protocol:
  |    |    1. Commit on local-dev (conventional commit message)
  |    |    2. Push to typed branch: git push REMOTE_NAME local-dev:feature/<phase-name>
  |    |    3. Create PR via mcp__github__create_pull_request
  |    |       - Demo mode: PR targets demo branch
  |    |       - Prod mode: PR targets DEPLOY_BRANCH
  |    |    4. Squash-merge the PR
  |    |    5. Local-dev is NOT reset -- granular commits stay on local-dev,
  |    |       squash commit lives on the target branch. No sync needed because
  |    |       local-dev never tracks the target branch; it is a one-way flow.
  |    |       Next phase boundary pushes the next batch of local-dev commits
  |    |       to a new typed branch.
  |    |    6. Never push local-dev to remote
  |    |
  |    +-- Phase 10 ANALYTICS -> pipeline complete
  |
  +-- Post-pipeline: update mode
       +-- Detect completed state, ask what to change
       +-- Map to minimum agent set, re-audit, commit via /git
```

### Mode Promotion Flow (demo -> prod, one-way)

Triggered when the user says "make it prod" / "push to prod" / "go live":

```
1. Read status.md -> confirm demo mode, all phases complete
2. Pre-promotion check: verify all phase-boundary PRs targeting demo are merged.
   If any are open -> warn user, offer to auto-merge or abort.
3. Create PR: demo branch -> DEPLOY_BRANCH (via mcp__github__)
4. Merge PR
5. Stay on local-dev -- never checkout away
6. Update status.md: mode -> prod, PR target -> DEPLOY_BRANCH
7. Future commits target prod via /git conventions
8. Re-run Phase 9 DEPLOY if hosting needs reconfiguration for prod
9. Re-run Phase 10 ANALYTICS for production verification
```

---

## 4. Error Handling

### Init Failures

| Failure | Recovery |
|---------|----------|
| Git not installed | Abort with: "Git is required. Install git and re-run --init." |
| Remote unreachable | Allow skip: "Can't reach remote. Continue with local-only dev?" |
| `/gitignore rebuild` fails | Warn and continue. Manual `.gitignore` setup is an option. |
| MCP configuration fails (context7) | Save checkpoint. Inform user to fix and re-run `--init`. |
| MCP configuration fails (optional) | Skip the optional MCP, note in status.md, continue. |

### Pipeline Failures

| Failure | Recovery |
|---------|----------|
| Agent hits maxTurns (60) | Save progress, re-spawn with narrowed scope. After 2 retries, escalate to user. |
| `npm run build` fails after a phase | Developer-agent fixes before proceeding. |
| Git push/PR fails | Retry once after 10s. On second failure: offer retry, skip PR (keep local commit), or stop. |
| Branch name collision on push | Auto-append timestamp suffix: `feature/<name>-1720180000` |
| PR merge conflict | Pull, rebase, retry. If conflicts persist, escalate to user. |
| Session ends mid-pipeline | status.md preserves state. `/site-builder` resumes from last incomplete phase. |

### Flag Validation

| Invalid Input                        | Response                                                                                         |
|--------------------------------------|--------------------------------------------------------------------------------------------------|
| Unknown flag (e.g., `--verbose`)     | Log "Ignoring unknown flag: `--verbose`" and continue (forward compatibility with user feedback) |
| `--init` combined with pipeline flags | Init runs first, then EXIT. Pipeline flags are noted but not acted on.                          |

---

## 5. Testing Strategy

This is a Markdown-only plugin — no automated test suite exists. Testing is manual verification:

| What to Test | How |
|-------------|-----|
| Flag parsing | Run `/site-builder`, `/site-builder --init`, `/site-builder --auto`, `/site-builder --auto --parallel` and verify correct routing |
| Init flow | Run `--init` in a fresh project (no git), a project with git but no remote, and a fully configured project |
| Mode selection | Verify demo/prod question appears on first run, is skipped on return run |
| Git delegation | Verify commits go to `local-dev`, pushes go to typed branches, PRs target correct base branch |
| Mode promotion | Complete pipeline in demo mode, say "make it prod", verify PR from demo -> DEPLOY_BRANCH |
| Deploy phase | Verify hosting question appears in both demo and prod modes with all options |
| Analytics phase | Verify Phase 10 asks for credentials, replaces placeholders, verifies on live URL |
| Session resume | Kill mid-pipeline, re-run `/site-builder`, verify it resumes from correct phase |
| --auto behavior | Verify optional prompts are skipped, approval gates still pause |
| --parallel behavior | Verify Phase 7 audit agents dispatch simultaneously |

---

## 6. Acceptance Criteria

- [ ] `/site-builder --init` runs git check, gitignore setup (via `/gitignore rebuild`), and MCP configuration, then exits without starting the pipeline
- [ ] `/site-builder` with no flags runs the full pipeline interactively, auto-running init if not yet complete
- [ ] `--auto` flag skips optional prompts (MCP setup, demo scope, framework recommendation) but never skips approval gates (Phases 1, 2, 4, 9)
- [ ] `--parallel` flag enables simultaneous agent dispatch for read-only phases (Phase 7 AUDIT already runs parallel by default; `--parallel` is a forward-looking flag that signals the orchestrator to parallelize any future parallelizable phases)
- [ ] Flags are composable: `/site-builder --init --auto`, `/site-builder --auto --parallel` work correctly
- [ ] Unknown flags are silently ignored (forward compatibility)
- [ ] Only two build modes exist: demo and prod (stage is completely removed)
- [ ] Mode is asked interactively on first run and stored in `status.md` for subsequent runs
- [ ] Demo mode creates a `demo` branch lazily at the first phase boundary PR, not during init
- [ ] Prod mode targets `DEPLOY_BRANCH` (or `DEFAULT_BRANCH` if no separate deploy branch) for PRs
- [ ] Demo -> prod promotion is one-way: creates PR from demo branch to DEPLOY_BRANCH, updates status.md
- [ ] All work happens on `local-dev` branch — the orchestrator never checks out demo, prod, or any other branch
- [ ] Git operations adopt `/git` skill conventions for commit messages, branch naming (`<type>/<name>`), and stash safety; phase-boundary PRs use `mcp__github__create_pull_request` directly (not `/git publish`) because the orchestrator controls the PR target branch per mode
- [ ] Orchestrator implements its own branch guard: verify `local-dev` is checked out and stash uncommitted work before git operations (adopting `/git`'s iron rule: all exit paths pop the stash)
- [ ] `.gitignore` setup is delegated to `/gitignore rebuild` during init (universal patterns), and re-run during Phase 3 PREPARE after framework selection (adds framework-specific patterns)
- [ ] Verify that `/gitignore rebuild` hook output uses POSIX-only sh syntax; if not, file a follow-up issue against the gitignore skill
- [ ] Phase 8 INTEGRATE runs `social-integration-agent` only (analytics removed from this phase)
- [ ] Phase 9 DEPLOY asks "Where do you want to deploy?" with options (Vercel, Netlify, custom hosting, other) in both demo and prod modes — does not assume any hosting platform
- [ ] Phase 9 DEPLOY: if existing CI/CD is detected, asks user whether to keep or reconfigure
- [ ] Phase 10 ANALYTICS (new) runs after deploy: reuses existing `analytics-agent` with narrowed scope — Phase 6 DEVELOP lays down analytics scaffolding code (GA4 snippet, cookie consent banner, conversion event stubs), Phase 10 asks user for real credentials (tracking IDs, API keys), injects them, and verifies tracking fires on the deployed URL
- [ ] Pipeline is now 10 phases: DISCOVER, ARCHITECT, PREPARE, DESIGN, CONTENT, DEVELOP, AUDIT, INTEGRATE, DEPLOY, ANALYTICS
- [ ] `status.md` tracks `init: complete/pending`, uses `pipeline_version: 3` (was 2 for 9-phase pipeline), and no longer contains stage mode references
- [ ] Resume rules for v2 -> v3: if status.md has `pipeline_version: 2` and all 9 phases complete, on resume under v3, offer to run Phase 10 ANALYTICS as an optional upgrade; if mid-run, remap phases by name and treat ANALYTICS as pending
- [ ] Init runs once and is recorded in `status.md` — no phase re-checks prerequisites
- [ ] `--init` when init is already complete: ask "Init already complete. Re-run to reconfigure? (a) Yes (b) No, exit"
- [ ] Session resume reads `status.md` and resumes from the last incomplete phase without re-running completed work
- [ ] Demo -> prod promotion verifies all phase-boundary PRs targeting demo are merged before creating the promotion PR
- [ ] All references to "stage" mode are removed from SKILL.md, phases.md, developer-agent.md, analytics-agent.md, README.md, CLAUDE.md, CONTEXT.md, and ARCHITECTURE.md
- [ ] `analytics-agent.md` frontmatter updated: description changed from "Phase 7 parallel with social-integration-agent" to reflect Phase 10 solo post-deploy role
- [ ] Deploy phase hosting question is asked by the orchestrator before spawning deploy-agent; hosting choice is passed as input to the agent. deploy-agent.md frontmatter updated to remove "Vercel/Netlify/AWS" and say "hosting-agnostic deployment"

---

## 7. Out of Scope

- **Client-project doc-sync** (auto-updating CLAUDE.md/ARCHITECTURE.md/CONTEXT.md via pre-commit hook) — this is being fixed in the Fullstack Dev plugin first, then site-builder will consume it
- **Subcommand architecture** (`/site-builder init`, `/site-builder build`) — composable flags chosen instead; subcommands can be added later if needed
- **Prod -> demo reverse mode change** — one-way promotion only for now
- **`--demo` / `--prod` as CLI flags** — mode selection stays interactive to ensure the user makes a conscious choice; can be added as flags in a future iteration
- **Analytics placeholder implementation details** — Phase 6 DEVELOP already handles code generation; this spec only defines when analytics configuration and verification happens (Phase 10)
- **New agent definitions** — no new agents are created; existing agents are restructured
