# Phase 3: Orchestrator + Deploy Agent Sync

**Repo:** site-builder-plugin
**Depends on:** Phase 2 (`seo-indexing-agent` must exist to be dispatched by name; Phase 1 Section E must be rewritten before `deploy-agent.md` §7b can be brought in line with it)
**Delivers:** `agents/deploy-agent.md` §7b rewritten to the inline IndexNow pattern (matching Phase 1 Task 1's Section E rewrite, closing the spec's original inconsistency), and `skills/site-builder/SKILL.md` updated with the Phase 11 dispatch, `pipeline_version` v3→v4 resume rules, status tracking, and PR schedule.

## File Structure

```
agents/
└── deploy-agent.md      [MODIFY — §7b only]
skills/site-builder/
└── SKILL.md              [MODIFY — 2 tasks, same file, sequential edits]
```

### Task 1: Rewrite `deploy-agent.md` §7b to the inline IndexNow pattern

**Files:**
- Modify: `agents/deploy-agent.md`

**Interfaces:**
- Consumes: `sitemap-indexnow.md` Section E (rewritten, Phase 1 Task 1) — this task's new §7b content must match Section E's inline pattern exactly (same YAML shape, same "no separate script" statement)
- Produces: `deploy-agent.md` §7b (rewritten) — no downstream plan consumers; this is the fix that eliminates the spec's original contradiction (Phase 9 no longer creates `scripts/ping-indexnow.mjs`, so Phase 11/`seo-indexing-agent` never has to migrate one)

**Acceptance Criteria:** AC12 (IndexNow notification entirely inline in CI/CD workflow YAML — this is the Phase-9-side half of that requirement; Phase 1 Task 1 was the reference-doc half)

**Steps (Documentation: Write-and-review):**

1. **Write content** — Replace steps 4-5 of the existing "### 7b. IndexNow Integration" section (currently: "**Create ping script** at `scripts/ping-indexnow.mjs`..." and "**Add post-deploy CI/CD step:**...") with:

   ````markdown
   4. **Add the inline post-deploy CI/CD step** (from
      `skills/site-builder/reference/sitemap-indexnow.md` Section E — no
      separate script file is created; the `grep`/`jq`/`curl` sequence is
      inlined directly into the workflow config), substituting the actual
      site domain, detected key, and sitemap path from steps 1-3 above:
      - **GitHub Actions:** insert the full inline `run: |` block from
        Section E immediately after the deploy step in
        `.github/workflows/deploy.yml`
      - **Vercel:** insert the same block as a post-build command in
        `vercel.json`, or a deploy hook that runs it
      - **Netlify:** insert the same block as a `[[plugins]]` `onSuccess`
        command, or a post-processing step in `netlify.toml`

   5. **Include in the deploy commit** alongside CI/CD pipeline files:

      ```text
      feat: add CI/CD pipeline, deployment config, and inline IndexNow notification step
      ```
   ````

   Renumber the old step 6 ("Include in the deploy commit") away since it is now merged into the new step 5 above — the section should end at step 5, not have a duplicate step 6.

2. **Verify references** — Grep the file for `ping-indexnow.mjs` or `scripts/ping-indexnow` — must be zero matches after this edit. Confirm the "**Process**" line still attributes the pattern to `sitemap-indexnow.md` Section E (unchanged attribution, only the *content* of what Section E documents changed).

3. **Commit** — `docs(site-builder): sync deploy-agent §7b to inline IndexNow pattern`

---

### Task 2: `SKILL.md` — Phase 11 dispatch, Pipeline Complete move, description bump

**Files:**
- Modify: `skills/site-builder/SKILL.md`

**Interfaces:**
- Consumes: `agents/seo-indexing-agent.md` (Phase 2 Task 1 — spawned by name), `phases.md` Phase 11 entry (Phase 2 Task 2 — same Gate/Inputs/Output wording)
- Produces: `SKILL.md` Phase 11 pipeline-execution section — consumed by Task 3 below (status tracking references the same phase name "AUTO-INDEXING")

**Acceptance Criteria:** AC7 (Phase 11 in phase list + dispatch table, `seo-indexing-agent` in agent spawning pattern, Pipeline Complete section moved after Phase 11)

**Steps (Documentation: Write-and-review):**

1. **Write content:**

   a. Frontmatter `description` (line 3): change `"...Runs 14 specialist agents through a 10-phase workflow..."` to `"...Runs 15 specialist agents through an 11-phase workflow..."`.

   b. Insert a new `### Phase 11: AUTO-INDEXING` section immediately after `### Phase 10: ANALYTICS` and its `Update status.md: Phase 10 ANALYTICS → completed` line, and immediately **before** `### Pipeline Complete` — this insertion point is what moves Pipeline Complete to after Phase 11 (no separate cut/paste needed, the new section is simply the last phase before it):

      ```markdown
      ### Phase 11: AUTO-INDEXING

      1. Spawn `seo-indexing-agent` with prompt:
         - Inject framework, hosting platform, and deploy branch from `status.md`
         - Inject the live deployment URL from Phase 9 DEPLOY's report (for
           post-deploy verification)
         - Agent's task: patch the sitemap config with a git-derived `lastmod`
           resolver, verify/create the IndexNow key file and inline CI
           post-deploy notification step, scaffold an RSS/Atom feed, and patch
           `robots.txt`
      2. **DIFF APPROVAL GATE** (within agent execution): the agent presents
         every proposed file change before writing — same presentation pattern
         as deploy-agent's Config Translation Review Gate. Wait for the agent
         to report the user's approval before treating the phase as complete.
      3. Wait for agent completion → `.site-builder/integration-reports/seo-indexing.md`
      4. **APPROVAL GATE:** Present the agent's summary report to the user
         - Show: git-lastmod resolver status, IndexNow status, RSS feed status,
           `robots.txt` status, any `⚠` warnings
         - Ask: "Auto-indexing configured. [N] components verified, [M]
           warnings. Approve, or provide corrections to retry?"
         - On approval → pipeline complete
         - On retry → re-run `seo-indexing-agent` with corrected input

      Update `status.md`: Phase 11 AUTO-INDEXING → completed

      ### Pipeline Complete

      Report to user:
      - "Website build complete! Here's the summary:"
      - Pages built: [list]
      - Audit results: all passed (or remaining issues)
      - Analytics: [status — verified live or pending client action]
      - Social: [status]
      - Auto-indexing: [status — git-lastmod/IndexNow/RSS feed verified, or pending]
      - Deployment: [live/staging URL]
      - Manual tasks: [list from integration reports]
      - **Working branch:** `local-dev` — all pipeline commits live here (unchanged in both modes)
      - **Demo mode:** production is untouched; the `demo` branch holds the squash-merged PRs. When ready, say "make it prod" to promote.
      - **Prod mode:** changes are already live on `DEPLOY_BRANCH` via phase-boundary PRs — no separate promotion step.
      ```

      This block **replaces** the existing `### Pipeline Complete` section in
      place (same content, plus the new "Auto-indexing:" summary line) —
      delete the old standalone `### Pipeline Complete` section that
      previously followed Phase 10 directly, since it is now the tail of this
      inserted block.

   c. Commit Checkpoints table (in the "Git Operations Protocol" section):
      add a row after the existing `10. ANALYTICS` row:
      ```markdown
      | 11. AUTO-INDEXING | Git-lastmod + IndexNow + feed configured | `feat: add git-derived lastmod, RSS feed, and IndexNow enhancements` |
      ```

2. **Verify references** — Confirm there is exactly one `### Pipeline Complete` heading in the file (no duplicate left behind from the old location). Confirm the Phase 11 section's spawn prompt references `seo-indexing-agent` — the exact `name:` value from `agents/seo-indexing-agent.md`'s frontmatter (Phase 2 Task 1). Confirm the Commit Checkpoints table now has 11 phase-related rows (3 PREPARE has 2 rows, so count phases represented, not raw row count — verify Phase 11's row was appended, not inserted mid-table).

3. **Commit** — `feat(site-builder): dispatch Phase 11 AUTO-INDEXING from the orchestrator`

---

### Task 3: `SKILL.md` — `pipeline_version` v3→v4, resume rules, status tracking, PR schedule

**Files:**
- Modify: `skills/site-builder/SKILL.md`

**Interfaces:**
- Consumes: Task 2's Phase 11 section (must exist first — the resume rules and status template reference "Phase 11 AUTO-INDEXING" by the same name Task 2 introduced)
- Produces: `pipeline_version: 4` + v3→v4 resume rules, `## Phase 11 Progress (AUTO-INDEXING)` status template section — no downstream plan consumers, this is the pipeline's resumability contract for existing in-progress client builds

**Acceptance Criteria:** AC7 (`pipeline_version` bumped v3→v4 with concrete resume-transition rules — completed v3 → optional upgrade offer; mid-run v3 → add Phase 11 pending; status tracking template gains Phase 11 entry; Phase boundary PR schedule entry added)

**Steps (Documentation: Write-and-review):**

1. **Write content:**

   a. **Pipeline Versioning section** — after the existing "**Resume rules for v2 → v3 transition:**" block, add:

      ```markdown
      - `pipeline_version: 4` — current 11-phase pipeline (adds Phase 11
        AUTO-INDEXING: git-derived lastmod, inline IndexNow CI notification,
        RSS/Atom feed).

      **Resume rules for v3 → v4 transition:**

      - If `status.md` has `pipeline_version: 3` and Phases 1-10 are all
        `completed`:
        - Treat this as a completed v3 build. Offer: "This build finished
          under the previous 10-phase pipeline. Run the new Phase 11
          AUTO-INDEXING as an optional upgrade? It configures git-derived
          sitemap dates, IndexNow notification, and an RSS feed." On accept,
          add `Phase 11 AUTO-INDEXING: in-progress` to `status.md`, bump
          `pipeline_version` to `4`, and dispatch `seo-indexing-agent` as
          described in Phase 11 above. On decline, leave Phase 11 unset — do
          not silently mark it completed or skipped.
      - If `status.md` has `pipeline_version: 3` and phases are mid-run:
        - Add `Phase 11 AUTO-INDEXING: pending` to `status.md`, bump
          `pipeline_version` to `4`. Continue resuming from the last
          incomplete phase as usual — Phase 11 becomes reachable once Phase
          10 completes.
      - Update `pipeline_version` to `4` in `status.md` as part of either
        transition above.
      ```

      Also update the existing bullet `- pipeline_version: 3 — current
      10-phase pipeline...` to read `- pipeline_version: 3 — 10-phase
      pipeline (superseded by v4, retained for resume compatibility)`, since
      it is no longer "current" once this task lands.

   b. **Status Tracking template** — in the `## Pipeline Status` list, add
      after `- Phase 10 ANALYTICS: [pending|in_progress|completed] ([date])`:
      ```markdown
      - Phase 11 AUTO-INDEXING: [pending|in_progress|completed] ([date])
      ```

      In `## Build Configuration`, change `- Pipeline version: 3` to
      `- Pipeline version: 4`.

      In `## Phase 9 Progress (DEPLOY)`, change the line
      `- [ ] IndexNow ping script created and added to CI/CD post-deploy step`
      to `- [ ] IndexNow inline CI notification step added (no separate
      script file)` — this keeps the status template consistent with the
      Task 1 rewrite of `deploy-agent.md` §7b.

      After `## Phase 10 Progress (ANALYTICS)`, add:
      ```markdown
      ## Phase 11 Progress (AUTO-INDEXING)

      - [ ] Git-lastmod resolver patched into sitemap config
      - [ ] IndexNow key file verified/created
      - [ ] IndexNow inline CI notification step verified/created
      - [ ] RSS/Atom feed scaffolded (or explicitly skipped — no content)
      - [ ] robots.txt references sitemap + feed
      - [ ] GitHub Actions fetch-depth: 0 confirmed (GitHub Actions only)
      ```

      In `## Agent Outputs`, add:
      ```markdown
      - seo-indexing.md: [pending|written]
      ```

   c. **Phase boundary PR schedule table** — add a row after the existing
      `10. ANALYTICS` row:
      ```markdown
      | 11. AUTO-INDEXING | `feature/auto-indexing` | `feat: add git-derived lastmod, RSS feed, and IndexNow enhancements` |
      ```

2. **Verify references** — Confirm `pipeline_version: 4` appears exactly once as "current" in the Pipeline Versioning section (v1/v2/v3 remain listed as historical/superseded, not deleted — resume compatibility requires the old rules to stay). Confirm the Phase 11 Progress checklist items match Phase 2 Task 2's `phases.md` checklist word-for-word (same 6 items, same order) so the two docs don't drift. Confirm the PR schedule branch name (`feature/auto-indexing`) matches the spec's acceptance criteria verbatim.

3. **Commit** — `feat(site-builder): bump pipeline_version to 4 for Phase 11 AUTO-INDEXING`

---

## Phase 3 Complete

`deploy-agent.md` no longer creates a separate IndexNow script (matching Phase 1's rewritten Section E), and `SKILL.md` fully dispatches, gates, and tracks Phase 11 AUTO-INDEXING as the pipeline's new 11th and final phase, with resume rules for every in-flight v3 build.

**Next:** `phase-4.md`
