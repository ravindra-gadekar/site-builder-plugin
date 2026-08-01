# Phase 3: Pipeline Phases & Status

**Repo:** site-builder-plugin
**Depends on:** Phase 2 (Phase 8/9/10 and Mode Promotion all assume the `local-dev`-only git protocol and demo/prod-only mode selection are already in place)
**Delivers:** Phase 3 PREPARE re-runs `/gitignore rebuild` after framework selection; Phase 8 INTEGRATE spawns `social-integration-agent` only; Phase 9 DEPLOY asks a hosting-agnostic question before spawning `deploy-agent`; a new Phase 10 ANALYTICS runs post-deploy; Mode Promotion Flow verifies all demo-branch PRs are merged before promoting; `status.md`'s template moves to `pipeline_version: 3` with v2→v3 resume rules; `phases.md` documents all 10 phases.

## File Structure

```
skills/site-builder/
├── SKILL.md                 (modify — PREPARE gitignore step, Phase 8, Phase 9, new Phase 10, Mode Promotion Flow, Status Tracking template, Pipeline Versioning)
└── reference/
    └── phases.md            (modify — phase count, Phase 8 agent list, new Phase 10 definition)
```

---

### Task 1: PREPARE re-runs `/gitignore rebuild`; Phase 8 INTEGRATE becomes social-only

**Files:**
- Modify: `skills/site-builder/SKILL.md`

**Interfaces:**
- Consumes: Phase 1 Task 2's `/gitignore rebuild` delegation pattern (Init's first call).
- Produces: The framework-aware `.gitignore` state that Phase 6 DEVELOP's build verification assumes is already correct.

**Acceptance Criteria:** "`.gitignore` setup is delegated to `/gitignore rebuild` during init (universal patterns), and re-run during Phase 3 PREPARE after framework selection (adds framework-specific patterns)", "Phase 8 INTEGRATE runs `social-integration-agent` only (analytics removed from this phase)".

**Steps (Write-and-review):**

1. **Write content.** In `### Phase 3: PREPARE`, replace the current `**Step 4: Set up \`.gitignore\`**` subsection (which inline-generates a framework-specific `.gitignore` with a hardcoded pattern table) with:

   ```markdown
   **Step 4: Re-run gitignore setup for the selected framework**

   Init (Phase 1 Task 2 of this plugin's own git workflow reference) already
   ran `/gitignore rebuild` before the framework was known, producing
   universal/secrets/build/cache/ide/OS categories. Now that the framework is
   selected (Step 2b), re-run it to add framework-specific patterns:

   ```
   Invoke /gitignore rebuild
   ```

   The `/gitignore` skill's tech-stack detection picks up the newly scaffolded
   framework's marker files (`astro.config.mjs`, `next.config.js`, etc.) and
   merges in the matching category (`.astro/`, `.next/`, `.nuxt/`, `dist/`,
   `build/`) without disturbing the universal categories already present.

   Note: `.site-builder/` should NOT be in `.gitignore` — it contains project
   artifacts (status.md, project-brief.md, design-system.md, content files,
   audit reports) that should be committed and tracked. The gitignore skill's
   catalog does not include `.site-builder/`, so no exclusion is needed.
   ```

   In `### Phase 8: INTEGRATE (parallel)`, replace:

   ```markdown
   1. Spawn both agents in parallel:
      - `social-integration-agent`
      - `analytics-agent`
   2. Wait for BOTH to complete
   3. Verify code changes don't break the build: `npm run build`
   ```

   with:

   ```markdown
   1. Spawn `social-integration-agent`.
   2. Wait for completion.
   3. Verify code changes don't break the build: `npm run build`

   Analytics no longer runs here — it moved to the new Phase 10 ANALYTICS,
   which runs after deployment so the analytics-agent can verify tracking on
   a live URL instead of a local build.
   ```

2. **Verify references.** Grep `### Phase 3: PREPARE` for the old hardcoded pattern table (`**Common patterns (all frameworks):**`) — absent. Grep `### Phase 8: INTEGRATE` for `analytics-agent` — zero matches (moved entirely out of this phase).
3. **Commit:** `docs(site-builder): delegate PREPARE gitignore re-run and make Phase 8 social-only`

---

### Task 2: Hosting-agnostic Phase 9 DEPLOY question + new Phase 10 ANALYTICS

**Files:**
- Modify: `skills/site-builder/SKILL.md`

**Interfaces:**
- Consumes: None from an earlier task in this plan. The new Phase 10 ANALYTICS prose written here *describes* the site-builder pipeline's own Phase 6 DEVELOP → Phase 10 ANALYTICS runtime data flow (analytics scaffolding produced at pipeline-runtime, independent of this implementation plan's phase order) — it does not require `agents/developer-agent.md` to already be edited. Phase 4 Task 2 of this plan (developer-agent.md scaffolding step) makes that description true in the agent's own file; the two edits are independent and consistent, not sequentially dependent.
- Produces: The hosting choice passed as input to `deploy-agent` (consumed by Phase 4 Task 1 of this plan, which updates `deploy-agent.md` to receive it instead of asking itself); the "Phase 10 ANALYTICS" checkpoint consumed by Task 4's `status.md` template rewrite and by Task 5's `phases.md` update. The prose written here also sets the expectation that Phase 4 Task 3 (`analytics-agent.md`) and Phase 4 Task 2 (`developer-agent.md`) implement.

**Acceptance Criteria:** "Phase 9 DEPLOY asks 'Where do you want to deploy?' with options (Vercel, Netlify, custom hosting, other) in both demo and prod modes — does not assume any hosting platform", "Phase 9 DEPLOY: if existing CI/CD is detected, asks user whether to keep or reconfigure", "Phase 10 ANALYTICS (new) runs after deploy... Phase 6 DEVELOP lays down analytics scaffolding code... Phase 10 asks user for real credentials..., injects them, and verifies tracking fires on the deployed URL", "Pipeline is now 10 phases: DISCOVER, ARCHITECT, PREPARE, DESIGN, CONTENT, DEVELOP, AUDIT, INTEGRATE, DEPLOY, ANALYTICS", "Deploy phase hosting question is asked by the orchestrator before spawning deploy-agent; hosting choice is passed as input to the agent".

**Steps (Write-and-review):**

1. **Write content.** In `### Phase 9: DEPLOY`, insert a new step 0 before the existing `1. Spawn deploy-agent with prompt:`:

   ```markdown
   0. **Ask hosting preference** (before spawning `deploy-agent`, in both demo
      and prod modes): "Where do you want to deploy?" via `AskUserQuestion`
      with options:
      - **Vercel** — recommended for most frameworks, best DX, free tier
      - **Netlify** — strong alternative, especially for static output
      - **Custom hosting** — VPS, shared hosting, IIS, or other self-managed target
      - **Other** — user specifies

      If Step 2c (Hosting Compatibility Check) already recorded a hosting
      decision in `status.md` (`change-hosting` or `proceed-anyway`), present
      that as the pre-filled recommendation rather than asking from scratch.

      Store the choice in `status.md` under Build Configuration:
      `Hosting platform: [vercel|netlify|custom|other — detail]`.
   ```

   Change the existing step 1 from:

   ```markdown
   1. Spawn `deploy-agent` with prompt:
      - Inject tech stack, hosting preferences, hosting compatibility decision from `status.md`
      - Inject environment inventory from `project-brief.md` (parsed server configs, CI/CD workflows, .env variables, old sitemap URLs)
      - Agent performs: config translation, CI/CD pipeline update, .env migration, sitemap verification, staging deployment
   ```

   to:

   ```markdown
   1. Spawn `deploy-agent` with prompt:
      - Inject the hosting platform chosen in Step 0 above (as an explicit input — the agent no longer asks the user itself)
      - Inject tech stack, hosting compatibility decision from `status.md`
      - Inject environment inventory from `project-brief.md` (parsed server configs, CI/CD workflows, .env variables, old sitemap URLs)
      - Agent performs: existing-CI/CD assessment (asks user to keep or reconfigure any detected pipeline — see `agents/deploy-agent.md` "Assess & Update Existing CI/CD"), config translation, CI/CD pipeline update, .env migration, sitemap verification, staging deployment
   ```

   After `Update status.md: Phase 9 DEPLOY → completed` and before `### Pipeline Complete`, insert:

   ````markdown
   ### Phase 10: ANALYTICS

   1. Spawn `analytics-agent` with prompt:
      - Inject the live deployment URL from Phase 9 DEPLOY's report
      - Inject the analytics scaffolding already in the codebase from Phase 6 DEVELOP (GA4 snippet, cookie consent banner, conversion event stubs — scaffolded but without real credentials)
      - Agent's task: ask the user for real credentials (tracking IDs, API keys) for each scaffolded platform, inject them into the environment configuration, and verify tracking fires on the live deployed URL — not a local build
   2. Wait for agent completion → `.site-builder/integration-reports/analytics.md` updated with verification results
   3. **APPROVAL GATE:** Present verification results to user
      - Show: which platforms verified successfully (tracking event observed on live URL), which are still pending manual client action (e.g. GSC domain verification)
      - Ask: "Analytics verification complete. [N] platforms confirmed live. Approve, or provide corrected credentials to retry?"
      - On approval → pipeline complete
      - On retry → re-run analytics-agent with corrected credentials

   Update `status.md`: Phase 10 ANALYTICS → completed
   ````

   Finally, update `### Pipeline Complete`'s report bullets — replace:

   ```markdown
   - "Website build complete! Here's the summary:"
   - Pages built: [list]
   - Audit results: all passed (or remaining issues)
   - Analytics: [status]
   - Social: [status]
   - Deployment: [staging URL]
   - Manual tasks: [list from integration reports]
   - **Current branch:** `[demo|stage]` — all changes are here, production branch is untouched (demo/stage mode)
   - **Current branch:** `[DEPLOY_BRANCH]` — changes are live (prod mode)
   - If demo/stage mode: "When ready to push to production, say 'make it prod' or 'push to prod.'"
   ```

   with:

   ```markdown
   - "Website build complete! Here's the summary:"
   - Pages built: [list]
   - Audit results: all passed (or remaining issues)
   - Analytics: [status — verified live or pending client action]
   - Social: [status]
   - Deployment: [live/staging URL]
   - Manual tasks: [list from integration reports]
   - **Working branch:** `local-dev` — all pipeline commits live here (unchanged in both modes)
   - **Demo mode:** production is untouched; the `demo` branch holds the squash-merged PRs. When ready, say "make it prod" to promote.
   - **Prod mode:** changes are already live on `DEPLOY_BRANCH` via phase-boundary PRs — no separate promotion step.
   ```

2. **Verify references.** Grep `### Phase 9: DEPLOY` for `AskUserQuestion` and `Where do you want to deploy?` — present. Grep the file for `### Phase 10: ANALYTICS` — exactly one match, positioned between `Update status.md: Phase 9 DEPLOY → completed` and `### Pipeline Complete`. Grep `### Pipeline Complete` for `[demo|stage]` — absent.
3. **Commit:** `docs(site-builder): add hosting question and Phase 10 ANALYTICS after deploy`

---

### Task 3: Mode Promotion Flow — pre-promotion PR-merged check, demo-only, one-way

**Files:**
- Modify: `skills/site-builder/SKILL.md`

**Interfaces:**
- Consumes: Task 2's Phase 9/10 checkpoints (promotion may re-run them); the `demo` branch's remote PR history from Phase 2 Task 3's phase-boundary PR schedule.
- Produces: The `mode: prod` transition in `status.md`, consumed by all subsequent phase-boundary PRs (they now target `DEPLOY_BRANCH`).

**Acceptance Criteria:** "Demo -> prod promotion is one-way: creates PR from demo branch to DEPLOY_BRANCH, updates status.md", "Demo -> prod promotion verifies all phase-boundary PRs targeting demo are merged before creating the promotion PR", "All work happens on `local-dev` branch — the orchestrator never checks out demo, prod, or any other branch" (promotion must not check out `demo` locally), "All references to 'stage' mode are removed from SKILL.md".

**Steps (Write-and-review):**

1. **Write content.** Replace everything from `## Promote to Production` through the end of `### After Promotion` (stop before `### Post-Production Sync to Default Branch`, which is prod-specific and unaffected by this change) with:

   ````markdown
   ## Promote to Production

   Triggered when the user says "make it prod," "push to prod," "go live,"
   "client approved," or similar.

   **Only applies to demo mode.** In prod mode, code is already merged into
   `DEPLOY_BRANCH` via phase-boundary PRs — there is no promotion step.

   This is the only time the production branch is touched from a demo build.
   The orchestrator never checks out `demo` locally — the `demo` branch exists
   only on the remote, built up entirely through squash-merged phase-boundary
   PRs (Phase 2 of this plugin's own git workflow). Promotion works entirely
   through PR creation against that remote branch; `local-dev` is never left.

   ### Process

   1. Read `status.md` to confirm: mode is `demo`, all phases complete (or
      user accepts current state), `DEFAULT_BRANCH` and `DEPLOY_BRANCH` names.

   2. **Pre-promotion check — verify all phase-boundary PRs are merged:**
      List PRs targeting `demo` via `mcp__github__pull_request_read` /
      `mcp__github__list_pull_requests`.
      - All merged → continue to step 3.
      - Any open → warn: "PR #[N] ([title]) targeting `demo` is still open."
        Offer: (a) auto-merge it now (if checks pass), (b) abort promotion
        until it's merged manually.
      - If `HAS_REMOTE = false` (no remote — the `demo` branch was never
        created, all commits live only on `local-dev`): skip this check
        entirely, there is nothing to merge.

   3. Show the user what will happen:
      - If `HAS_REMOTE = true`: "This will create a PR from `demo` into `DEPLOY_BRANCH` to trigger production deployment."
      - If `HAS_REMOTE = false`: "No remote is configured, so there's no `demo` branch to promote from. This will simply flip the mode to `prod` — future phase-boundary work targets `DEPLOY_BRANCH` once a remote is added."
      - Show: pages built, audit results, integration status.
      - If demo mode with selected pages only: warn "Only X of Y pages were built. Remaining pages are not included."

   4. Ask: "Proceed with promotion to production?"

   5. On approval:
      - If demo with partial pages: ask "Build remaining pages first, or go live with current pages?"
      - **`HAS_REMOTE = true`:**
        1. Create PR: `demo` → `DEPLOY_BRANCH` via `mcp__github__create_pull_request`.
        2. Merge the PR — site is now live.
        3. Stay on `local-dev` — never checkout `demo` or `DEPLOY_BRANCH` at any point in this flow.
      - **`HAS_REMOTE = false`:** no PR to create — proceed straight to step 6.
      - Re-run Phase 9 DEPLOY if hosting needs reconfiguration for production (see Task 2 of this plan).
      - Re-run Phase 10 ANALYTICS to verify tracking on the production URL (see Task 2 of this plan).

   6. Update `status.md`: `Mode: prod`, `Base branch (PR target): DEPLOY_BRANCH`.

   7. On rejection: mode stays `demo`, ask what needs changing.

   ### After Promotion

   From this point forward:
   - Mode switches to **prod mode** — `DEPLOY_BRANCH` becomes the PR target for all future phase-boundary work.
   - Working branch remains `local-dev` — nothing changes about where commits happen.
   - All subsequent changes follow the same git workflow (commit on `local-dev` → push to `feature/<name>` → PR targeting `DEPLOY_BRANCH` → squash merge). `local-dev` is still never reset and never pushed directly.
   - The `demo` branch (remote) can be kept for reference or deleted — it played no further role once promotion completes.
   ````

2. **Verify references.** Grep the replaced section for `stage`, `git checkout -b prod`, and `git checkout DEFAULT_BRANCH` — all absent. Grep for `Pre-promotion check` — exactly one match. Confirm `### Post-Production Sync to Default Branch` (unmodified) immediately follows `### After Promotion`.
3. **Commit:** `docs(site-builder): rewrite mode promotion with pre-promotion merged-PR check`

---

### Task 4: Status Tracking template → `pipeline_version: 3`, init tracking, Phase 10, v2→v3 resume rules

**Files:**
- Modify: `skills/site-builder/SKILL.md`

**Interfaces:**
- Consumes: Phase 1 Task 3's `init: complete` flag; Task 2's Phase 10 checkpoint; Task 1-3's mode/base-branch vocabulary (`demo`/`prod`, no `stage`).
- Produces: The `status.md` schema every phase's "Update `status.md`: Phase N → completed" instruction (throughout the whole file) writes into — this is the canonical reference downstream implementers and future orchestrator runs read.

**Acceptance Criteria:** "`status.md` tracks `init: complete/pending`, uses `pipeline_version: 3` (was 2 for 9-phase pipeline), and no longer contains stage mode references", "Resume rules for v2 -> v3: if status.md has `pipeline_version: 2` and all 9 phases complete, on resume under v3, offer to run Phase 10 ANALYTICS as an optional upgrade; if mid-run, remap phases by name and treat ANALYTICS as pending", "Session resume reads `status.md` and resumes from the last incomplete phase without re-running completed work".

**Steps (Write-and-review):**

1. **Write content.** Replace the `## Status Tracking` template's fenced block with:

   ````markdown
   ```
   ## Pipeline Status

   - Phase 1 DISCOVER: [pending|in_progress|completed] ([date])
   - Phase 2 ARCHITECT: [pending|in_progress|completed] ([date])
   - Phase 3 PREPARE: [pending|in_progress|completed] ([date])
   - Phase 4 DESIGN: [pending|in_progress|completed] ([date])
   - Phase 5 CONTENT: [pending|in_progress|completed] ([date])
   - Phase 6 DEVELOP: [pending|in_progress|completed] ([date])
   - Phase 7 AUDIT: [pending|in_progress|completed] ([date])
   - Phase 8 INTEGRATE: [pending|in_progress|completed] ([date])
   - Phase 9 DEPLOY: [pending|in_progress|completed] ([date])
   - Phase 10 ANALYTICS: [pending|in_progress|completed] ([date])

   ## Current State

   - Last active phase: [phase name]
   - Audit cycles completed: [0-3]
   - Blocking issues: [none or description]
   - Model fallbacks: [none or list]

   ## Build Configuration

   - Pipeline version: 3
   - Init: [complete|pending]
   - Framework: [astro|nextjs|vue|react]
   - Mode: [demo|prod]
   - Remote: [REMOTE_NAME] ([URL]) or none
   - Remote name: [REMOTE_NAME]
   - Has remote: [true|false]
   - Default branch: [branch name]
   - Deploy branch: [branch name] (same as default if not separate)
   - Base branch (PR target): [demo|DEPLOY_BRANCH|none]
   - Hosting platform: [vercel|netlify|custom|other — detail]
   - Demo scope: [full|selected]
   - Selected pages: [list, if applicable]

   ## Phase 6 Progress (DEVELOP)

   - [ ] Project scaffold + dependencies
   - [ ] Design tokens implementation
   - [ ] Shared components (Header, Footer, SEOHead, Button, Card, CTA)
   - [ ] Page: [page-slug-1]
   - [ ] Page: [page-slug-2]
   - [ ] ...one entry per page from site map...
   - [ ] SEO implementation (sitemap with per-page lastmod + priority, robots, JSON-LD, llms.txt, IndexNow key)
   - [ ] Analytics scaffolding (GA4 snippet, cookie consent banner, conversion event stubs — no real credentials yet)
   - [ ] Performance optimization
   - [ ] Build verification

   ## Phase 9 Progress (DEPLOY)

   - [ ] Hosting platform chosen
   - [ ] CI/CD pipeline setup
   - [ ] IndexNow ping script created and added to CI/CD post-deploy step
   - [ ] Deployment config and environment variables
   - [ ] Sitemap verification (old vs new URLs)
   - [ ] Test deployment

   ## Phase 10 Progress (ANALYTICS)

   - [ ] Real credentials collected from user
   - [ ] Credentials injected into environment configuration
   - [ ] Tracking verified firing on live deployed URL

   ## Agent Outputs

   - project-brief.md: [pending|written]
   - site-architecture.md: [pending|written]
   - design-system.md: [pending|written]
   - content-plan.md: [pending|written]
   - content/: [pending|written] ([N] files)
   - audit-reports/: [pending|written]
   - integration-reports/: [pending|written]

   ## Token Usage Log

   - Phase 1: ~[N]k tokens ([model])
   - Phase 2: ~[N]k tokens ([model])
   - Phase 3: ~[N]k tokens ([model])
   - ...updated after each phase completes...
   ```
   ````

   Further down, in `### Pipeline Versioning`, update the existing version-field prose:

   Replace the current `**Version field in \`status.md\`:**` paragraph and its two version bullets:

   ```markdown
   **Version field in `status.md`:** Add `pipeline_version: 2` to the Build Configuration section.

   - `pipeline_version: 1` — original 8-phase pipeline (no PREPARE phase)
   - `pipeline_version: 2` — current 9-phase pipeline (includes PREPARE)
   ```

   with:

   ```markdown
   **Version field in `status.md`:** `pipeline_version: 3` in the Build Configuration section.

   - `pipeline_version: 1` — original 8-phase pipeline (no PREPARE phase)
   - `pipeline_version: 2` — 9-phase pipeline (added PREPARE, removed since v3)
   - `pipeline_version: 3` — current 10-phase pipeline (demo/prod only, hosting-agnostic deploy, Phase 10 ANALYTICS)
   ```

   Also in `## Mode Detection` → `### First Run (no status.md)`, replace "start 9-phase pipeline from Phase 1" with "start 10-phase pipeline from Phase 1".

   Then, after the existing `**Resume rules for v1 → v2 transition:**` block, add:

   ```markdown
   **Resume rules for v2 → v3 transition:**

   - If `status.md` has `pipeline_version: 2` and Phases 1-9 are all `completed`:
     - Treat this as a completed v2 build. Offer: "This build finished under
       the previous 9-phase pipeline. Run the new Phase 10 ANALYTICS as an
       optional upgrade? It injects real analytics credentials and verifies
       tracking on your live URL." On accept, run Phase 10 as described in
       this plugin's Phase 9 DEPLOY section addendum. On decline, leave Phase
       10 unset — do not silently mark it completed or skipped.
   - If `status.md` has `pipeline_version: 2` and phases are mid-run:
     - Remap phases by name (unaffected by the version bump — phase names
       DISCOVER through DEPLOY are unchanged). Add `Phase 10 ANALYTICS:
       pending` to the status if absent. Continue resuming from the last
       incomplete phase as usual; Phase 10 becomes reachable once Phase 9
       completes.
     - If the in-progress build used `stage` mode (recorded before this
       redesign): treat it as `demo` mode for all remaining phase-boundary
       PRs — `stage` and `demo` used an identical workflow (working branch +
       PRs to a base branch), so no data migration is needed beyond the mode
       label. Warn the user once: "This build was started in the retired
       `stage` mode. Continuing as `demo` mode — behavior is unchanged."
   - Update `pipeline_version` to `3` in `status.md` as part of either
     transition above.
   ```

2. **Verify references.** Grep the Status Tracking fenced block for `stage` — absent. Grep for `Pipeline version: 3` and `Init: [complete|pending]` — each present exactly once. Grep `### Pipeline Versioning` for `Resume rules for v2 → v3 transition` — exactly one match. Grep `SKILL.md` for `9-phase` — zero matches remaining (the version-field prose, Mode Detection first-run text, and frontmatter were the only occurrences, all now updated).
3. **Commit:** `docs(site-builder): bump status.md to pipeline_version 3 with v2→v3 resume rules`

---

### Task 5: `reference/phases.md` — document all 10 phases

**Files:**
- Modify: `skills/site-builder/reference/phases.md`

**Interfaces:**
- Consumes: Task 1's Phase 8 social-only change, Task 2's Phase 9 hosting question and Phase 10 definition.
- Produces: No further consumers within this plan — `phases.md` is a leaf reference doc read directly by agents/users, not re-parsed by other SKILL.md sections.

**Acceptance Criteria:** "Pipeline is now 10 phases: DISCOVER, ARCHITECT, PREPARE, DESIGN, CONTENT, DEVELOP, AUDIT, INTEGRATE, DEPLOY, ANALYTICS", "Phase 8 INTEGRATE runs `social-integration-agent` only (analytics removed from this phase)", "Phase 9 DEPLOY asks 'Where do you want to deploy?'... does not assume any hosting platform", "Phase 10 ANALYTICS (new) runs after deploy...".

**Steps (Write-and-review):**

1. **Write content.** Change the file's opening line from:

   ```markdown
   The site-builder pipeline has 9 sequential phases. Each phase maps to one or more specialist agents. The orchestrator runs phases in order, managing gates between them.
   ```

   to:

   ```markdown
   The site-builder pipeline has 10 sequential phases. Each phase maps to one or more specialist agents. The orchestrator runs phases in order, managing gates between them.
   ```

   Replace the `### Phase 8: INTEGRATE (parallel)` entry:

   ```markdown
   ### Phase 8: INTEGRATE (parallel)
   - **Agents:** social-integration-agent, analytics-agent
   - **Purpose:** Connect social media, analytics, tracking infrastructure
   - **Inputs:** Built website code, `.site-builder/project-brief.md`
   - **Output:** Updated website code, `.site-builder/integration-reports/*.md`
   - **Gate:** None (flows into DEPLOY)
   - **Duration estimate:** 10-15 minutes
   ```

   with:

   ```markdown
   ### Phase 8: INTEGRATE
   - **Agent:** social-integration-agent
   - **Purpose:** Connect social media presence — icons, share buttons, OG meta, schema sameAs links
   - **Inputs:** Built website code, `.site-builder/project-brief.md`
   - **Output:** Updated website code, `.site-builder/integration-reports/social-integration.md`
   - **Gate:** None (flows into DEPLOY)
   - **Duration estimate:** 5-10 minutes
   ```

   Update the `### Phase 9: DEPLOY` entry's Purpose line to mention the hosting question, changing:

   ```markdown
   - **Purpose:** Config translation (server rules → framework/platform config), .env variable migration, CI/CD pipeline in-place update, sitemap verification, staging deployment, production readiness
   ```

   to:

   ```markdown
   - **Purpose:** Orchestrator asks "Where do you want to deploy?" (hosting-agnostic — Vercel, Netlify, custom hosting, or other) before spawning the agent; deploy-agent then performs config translation (server rules → framework/platform config), .env variable migration, CI/CD pipeline in-place update (asking to keep or reconfigure any existing pipeline), sitemap verification, staging deployment, production readiness
   ```

   After the `### Phase 9: DEPLOY` entry (and before `## Update Mode`), insert:

   ```markdown
   ### Phase 10: ANALYTICS
   - **Agent:** analytics-agent
   - **Purpose:** Connect real analytics credentials to the scaffolding Phase 6 DEVELOP already laid down, and verify tracking fires on the live deployed URL
   - **Inputs:** Live deployment URL (from Phase 9 DEPLOY), analytics scaffolding code (GA4 snippet, cookie consent banner, conversion event stubs from Phase 6), `.site-builder/site-architecture.md`
   - **Output:** Injected credentials in environment configuration, `.site-builder/integration-reports/analytics.md` updated with live verification results
   - **Gate:** USER APPROVAL — orchestrator presents verification results, user approves or provides corrected credentials to retry
   - **Duration estimate:** 5-15 minutes
   ```

2. **Verify references.** Grep the file for `9 sequential phases` — absent, replaced by `10 sequential phases`. Grep for `### Phase 10: ANALYTICS` — exactly one match, positioned between `### Phase 9: DEPLOY` and `## Update Mode`. Grep for `analytics-agent` under `### Phase 8` — zero matches.
3. **Commit:** `docs(site-builder): document 10-phase pipeline in phases.md reference`

---

## Phase 3 Complete

`SKILL.md`'s pipeline body now matches the redesign end-to-end: PREPARE delegates its second `.gitignore` pass, INTEGRATE is social-only, DEPLOY asks a hosting-agnostic question up front, a new ANALYTICS phase closes the loop post-deploy, promotion verifies merged PRs before touching production, and `status.md` is versioned for the transition. `phases.md` documents the same 10-phase shape as a standalone reference.

**Next:** `phase-4.md`
