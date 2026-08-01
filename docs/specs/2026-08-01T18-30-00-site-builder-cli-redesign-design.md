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
| Branch guards, stash safety, commit, push, PR | `/git` skill conventions |
| `.gitignore` generation, hook installation, violation scanning | `/gitignore` skill |
| Framework docs lookup | context7 MCP |
| GitHub PRs/issues | `mcp__github__*` MCP tools |

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
  |    +-- Prod: PR target = DEPLOY_BRANCH or DEFAULT_BRANCH
  |    +-- Store in status.md
  |
  +-- Pipeline: 10 phases (see Section 5)
  |    |
  |    |  Git at phase boundaries (via /git skill):
  |    |    Commit on local-dev
  |    |    Push to typed branch: feature/<phase-name> or fix/<phase-name>
  |    |    PR targeting mode's base branch
  |    |    Never push local-dev to remote
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
2. Create PR: demo branch -> DEPLOY_BRANCH (via mcp__github__)
3. Merge PR
4. Stay on local-dev -- never checkout away
5. Update status.md: mode -> prod, PR target -> DEPLOY_BRANCH
6. Future commits target prod via /git conventions
7. Re-run Phase 9 DEPLOY if hosting needs reconfiguration for prod
8. Re-run Phase 10 ANALYTICS for production verification
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

| Invalid Input | Response |
|---------------|----------|
| Unknown flag (e.g., `--verbose`) | Ignore silently (forward compatibility, same as `/brainstorm --parallel` pattern) |
| `--init` combined with pipeline flags | Init runs first, then EXIT. Pipeline flags are noted but not acted on. |

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
- [ ] `--parallel` flag dispatches Phase 7 audit agents simultaneously instead of sequentially
- [ ] Flags are composable: `/site-builder --init --auto`, `/site-builder --auto --parallel` work correctly
- [ ] Unknown flags are silently ignored (forward compatibility)
- [ ] Only two build modes exist: demo and prod (stage is completely removed)
- [ ] Mode is asked interactively on first run and stored in `status.md` for subsequent runs
- [ ] Demo mode creates a `demo` branch lazily at the first phase boundary PR, not during init
- [ ] Prod mode targets `DEPLOY_BRANCH` (or `DEFAULT_BRANCH` if no separate deploy branch) for PRs
- [ ] Demo -> prod promotion is one-way: creates PR from demo branch to DEPLOY_BRANCH, updates status.md
- [ ] All work happens on `local-dev` branch — the orchestrator never checks out demo, prod, or any other branch
- [ ] Git operations (commit, push, PR) follow `/git` skill conventions: commit on `local-dev`, push to typed branches (`feature/<phase>`, `fix/<phase>`), never push `local-dev` to remote
- [ ] `.gitignore` setup is delegated to `/gitignore rebuild` during init — no inline gitignore generation in PREPARE or any other phase
- [ ] Pre-commit hook installed by `/gitignore rebuild` uses POSIX-only sh syntax (no bash arrays, `[[ ]]`, or `<<<`)
- [ ] Phase 8 INTEGRATE runs `social-integration-agent` only (analytics removed from this phase)
- [ ] Phase 9 DEPLOY asks "Where do you want to deploy?" with options (Vercel, Netlify, custom hosting, other) in both demo and prod modes — does not assume any hosting platform
- [ ] Phase 9 DEPLOY: if existing CI/CD is detected, asks user whether to keep or reconfigure
- [ ] Phase 10 ANALYTICS (new) runs after deploy: asks user for tracking IDs/API keys, replaces placeholders from Phase 6, commits via `/git`, verifies tracking on deployed URL
- [ ] Pipeline is now 10 phases: DISCOVER, ARCHITECT, PREPARE, DESIGN, CONTENT, DEVELOP, AUDIT, INTEGRATE, DEPLOY, ANALYTICS
- [ ] `status.md` tracks `init: complete/pending` and no longer contains stage mode references
- [ ] Init runs once and is recorded in `status.md` — no phase re-checks prerequisites
- [ ] Session resume reads `status.md` and resumes from the last incomplete phase without re-running completed work
- [ ] All references to "stage" mode are removed from SKILL.md, phases.md, deploy-agent.md, README.md, CLAUDE.md, CONTEXT.md, and ARCHITECTURE.md

---

## 7. Out of Scope

- **Client-project doc-sync** (auto-updating CLAUDE.md/ARCHITECTURE.md/CONTEXT.md via pre-commit hook) — this is being fixed in the Fullstack Dev plugin first, then site-builder will consume it
- **Subcommand architecture** (`/site-builder init`, `/site-builder build`) — composable flags chosen instead; subcommands can be added later if needed
- **Prod -> demo reverse mode change** — one-way promotion only for now
- **`--demo` / `--prod` as CLI flags** — mode selection stays interactive to ensure the user makes a conscious choice; can be added as flags in a future iteration
- **Analytics placeholder implementation details** — Phase 6 DEVELOP already handles code generation; this spec only defines when analytics configuration and verification happens (Phase 10)
- **New agent definitions** — no new agents are created; existing agents are restructured
