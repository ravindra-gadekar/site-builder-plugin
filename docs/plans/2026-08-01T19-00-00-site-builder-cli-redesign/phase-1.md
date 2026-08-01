# Phase 1: Flag Dispatch & Init

**Repo:** site-builder-plugin
**Depends on:** None
**Delivers:** `skills/site-builder/SKILL.md` opens with a flag-dispatch table that routes `$ARGUMENTS` to an `--init`-only flow or the pipeline; the old "Prerequisites Check" section becomes "Init", gaining a `local-dev` branch check and `/gitignore rebuild` delegation; init completion is recorded in `status.md` so no later phase re-checks prerequisites.

## File Structure

```
skills/site-builder/
└── SKILL.md   (modify — frontmatter description, opening section, Prerequisites Check → Init)
```

---

### Task 1: Add Flag Dispatch section and update frontmatter

**Files:**
- Modify: `skills/site-builder/SKILL.md`

**Interfaces:**
- Consumes: None (this is the entry point of the file).
- Produces: A `## Flag Dispatch` section other tasks in this plan reference as "the routing layer." Downstream: Phase 2 Task 1 (mode selection) is reached only via the pipeline branch of this dispatch; Phase 1 Task 3 (`--init` re-run behavior) extends the `--init` branch defined here.

**Acceptance Criteria:** Spec AC "`/site-builder --init` runs git check, gitignore setup... then exits without starting the pipeline" (routing half), "`/site-builder` with no flags runs the full pipeline interactively, auto-running init if not yet complete", "`--auto` flag skips optional prompts... never skips approval gates", "`--parallel` flag enables simultaneous agent dispatch for read-only phases", "Flags are composable", "Unknown flags are silently ignored".

**Steps (Write-and-review):**

1. **Write content.** In `skills/site-builder/SKILL.md`, change line 3 of the frontmatter from:

   ```yaml
   description: "Master orchestrator for the site-builder pipeline. Runs 14 specialist agents through a 9-phase workflow to build complete websites from business analysis through deployment. Use when user says /site-builder, 'build a website', 'redesign this site', or 'create website'."
   ```

   to:

   ```yaml
   description: "Master orchestrator for the site-builder pipeline. Runs 14 specialist agents through a 10-phase workflow to build complete websites from business analysis through deployment. Supports --init, --auto, and --parallel flags. Use when user says /site-builder, 'build a website', 'redesign this site', or 'create website'."
   ```

   Then, immediately after the existing intro paragraph ("You manage the complete website design pipeline...") and before the `## Prerequisites Check` heading, insert a new section:

   ````markdown
   ## Flag Dispatch

   Parse `$ARGUMENTS` as raw text (Claude Code slash commands have no native
   flag parser — read the tokens directly).

   ```
   /site-builder [--init] [--auto] [--parallel]

   Parse $ARGUMENTS:
   +-- --init present   -> Run Init (below), then EXIT. Do not start the pipeline.
   +-- No flags         -> Full interactive pipeline (ask everything)
   +-- --auto           -> Modifier: skip optional prompts, keep approval gates
   +-- --parallel       -> Modifier: dispatch read-only agents simultaneously
   +-- Unknown flag (e.g. --verbose) -> Log "Ignoring unknown flag: --verbose", continue

   Composable examples:
     /site-builder --init              -> Init only, then stop
     /site-builder                     -> Interactive pipeline
     /site-builder --auto              -> Pipeline, fewer prompts
     /site-builder --auto --parallel   -> Pipeline, fewer prompts, parallel agents
     /site-builder --init --auto       -> Init (auto-accepting optional-MCP defaults), then stop
   ```

   **`--init` takes priority.** If `--init` is present alongside pipeline flags
   (`--auto`, `--parallel`), run Init only, note the other flags were received
   but not acted on, and EXIT. The pipeline does not start in the same
   invocation — re-run `/site-builder [--auto] [--parallel]` afterward.

   **`--auto` scope.** Skips optional prompts: optional MCP setup during Init
   (image-gen, agentation, UI UX Pro Max — context7 is always configured since
   it's required), demo scope confirmation wording, and framework
   recommendation elaboration. Never skips approval gates: Phase 1 DISCOVER,
   Phase 2 ARCHITECT, Phase 4 DESIGN, Phase 9 DEPLOY, and the Phase 7 AUDIT
   quality gate all still pause for user sign-off.

   **`--parallel` scope.** Signals the orchestrator to dispatch read-only
   agents simultaneously wherever a phase supports it. Phase 7 AUDIT already
   runs its 6 audit agents in parallel by default regardless of this flag;
   `--parallel` is forward-looking for any future parallelizable phase.

   **Unknown flags are forward-compatible.** Log a one-line notice and
   continue — never abort on an unrecognized flag.
   ````

2. **Verify references.** Grep the file for `## Flag Dispatch` and confirm exactly one match, positioned before `## Prerequisites Check`. Grep for the string `9-phase` — matches will still exist in `## Mode Detection` ("start 9-phase pipeline from Phase 1") and `### Pipeline Versioning` (`pipeline_version: 2` — current 9-phase pipeline); these are cleaned up in Phase 3 Task 4 of this plan, not here. Only the *frontmatter description* should already say `10-phase` after this task.
3. **Commit:** `docs(site-builder): add flag dispatch table and update pipeline description to 10 phases`

---

### Task 2: Rewrite Prerequisites Check into Init (git check, gitignore delegation, MCP config)

**Files:**
- Modify: `skills/site-builder/SKILL.md`

**Interfaces:**
- Consumes: `## Flag Dispatch` section from Task 1 (the `--init` branch routes here).
- Produces: `## Init` section (renamed from `## Prerequisites Check`) that Phase 1 Task 3 extends with the completion-flag and re-run behavior, and that Phase 2 Task 1 assumes has already run before mode selection.

**Acceptance Criteria:** "`/site-builder --init` runs git check, gitignore setup (via `/gitignore rebuild`), and MCP configuration, then exits without starting the pipeline", "`.gitignore` setup is delegated to `/gitignore rebuild` during init (universal patterns)... re-run during Phase 3 PREPARE after framework selection", "Verify that `/gitignore rebuild` hook output uses POSIX-only sh syntax; if not, file a follow-up issue against the gitignore skill".

**Steps (Write-and-review):**

1. **Write content.** Rename the `## Prerequisites Check` heading (line 13 of the current file) to `## Init`, and change its intro line from "Before starting the pipeline, verify and auto-configure:" to "Runs when `--init` is passed explicitly, or auto-detected on first pipeline run (Phase 1 Task 3 covers the auto-detect and re-run cases). Verify and auto-configure, in order:".

   Replace the existing `### 1. Git Initialized` subsection (current lines 17-19) with an expanded git check that also covers remote and `local-dev`:

   ```markdown
   ### 1. Git Check

   **1a. Git initialized?** If not, warn: "This project needs a git repo. Run `git init` first." Offer to run `git init` for the user. If the user declines and git is unavailable, abort Init with: "Git is required. Install git and re-run `--init`."

   **1b. Remote origin set?** Run `git remote`. If no remote exists, ask: "No git remote found. Continue with local-only dev, or add a remote now?" On "continue local-only": proceed without a remote — this is a supported, permanent state, not just a temporary skip. If the user later adds a remote, the Phase Boundary Git Protocol (Phase 2 of this plan) detects it automatically. If the remote is unreachable when the user does provide one, allow skip: "Can't reach remote. Continue with local-only dev?"

   **1c. `local-dev` branch exists and is checked out?** Adopting the `/git` skill's branch convention (patterns only — this orchestrator does not invoke `/git` directly, since PR target branches vary by mode):
   - If `local-dev` does not exist: `git checkout -b local-dev` from the current branch.
   - If `local-dev` exists but isn't checked out: `git checkout local-dev`.
   - If already on `local-dev`: continue.

   All later pipeline work happens on `local-dev` — see Phase 2 of this plan for the full branch guard and git protocol.
   ```

   Insert a new `### 2. Gitignore Setup` subsection immediately after the Git Check subsection (before what is currently numbered "### 2. context7 MCP"):

   ```markdown
   ### 2. Gitignore Setup

   Delegate to the `/gitignore` skill rather than generating `.gitignore` inline:

   ```
   Invoke /gitignore rebuild
   ```

   This generates `.gitignore` from the shared pattern catalog and installs the
   POSIX `sh` pre-commit hook (confirmed POSIX-compliant — the hook template in
   the gitignore skill's `reference/gitignore-flow.md` Section 3 explicitly
   avoids bash-only syntax so it runs under `dash`/`ash`, not just `bash`; no
   follow-up issue is needed).

   **Framework is not yet known at init time** (framework selection happens
   after Phase 1 DISCOVER approval, in Step 2b). This first `/gitignore
   rebuild` call produces universal/secrets/build/cache/ide/OS categories only.
   Phase 3 PREPARE re-runs `/gitignore rebuild` after framework selection to
   add framework-specific patterns (`.astro/`, `.next/`, `.nuxt/`, etc.) — see
   Phase 3 Task 1 of this implementation plan.

   If `/gitignore rebuild` fails: warn and continue — "Automatic .gitignore
   setup failed. You can run `/gitignore rebuild` manually, or set up
   `.gitignore` by hand before Phase 3 PREPARE."
   ```

   Renumber the remaining Init subsections: the current `### 2. context7 MCP (Required)` becomes `### 3. context7 MCP (Required)`, `### 3. Image Generation MCP (Optional)` becomes `### 4. ...`, `### 4. Agentation MCP (Optional)` becomes `### 5. ...`, `### 5. UI UX Pro Max (Optional)` becomes `### 6. ...`, `### 6. Analytics MCP` becomes `### 7. ...`. Their body content is unchanged — only the numbers shift to make room for the new Gitignore Setup step. Also renumber the closing `### .mcp.json Handling Rules` subsection's implicit ordering is unaffected (it has no number).

2. **Verify references.** Grep the file for `### 1. Git Initialized` and `### 2. context7 MCP` — both must be gone (replaced by `### 1. Git Check` and `### 3. context7 MCP`). Grep for `/gitignore rebuild` and confirm at least 2 occurrences (this Init call, plus the Phase 3 PREPARE re-run added in Phase 3 Task 1 of this plan — that second occurrence won't exist until Phase 3 runs, so for this task confirm exactly 1 occurrence). Grep for `### 7. Analytics MCP` to confirm the renumbering reached the last subsection.
3. **Commit:** `docs(site-builder): expand Init with local-dev branch check and gitignore delegation`

---

### Task 3: Init completion flag, auto-detect on first pipeline run, and `--init` re-run behavior

**Files:**
- Modify: `skills/site-builder/SKILL.md`

**Interfaces:**
- Consumes: `## Init` section from Task 2.
- Produces: The `init: complete` flag in `status.md`'s Build Configuration block, consumed by Phase 3 Task 4 of this plan (the full `status.md` template rewrite) and by the "Mode Detection" section's first-run check.

**Acceptance Criteria:** "Init runs once and is recorded in `status.md` — no phase re-checks prerequisites", "`--init` when init is already complete: ask 'Init already complete. Re-run to reconfigure? (a) Yes (b) No, exit'", "`/site-builder` with no flags runs the full pipeline interactively, auto-running init if not yet complete".

**Steps (Write-and-review):**

1. **Write content.** At the end of the `## Init` section (after the `.mcp.json Handling Rules` subsection, before `## Build Mode & Branch Setup`), add:

   ```markdown
   ### Completing Init

   1. Record in `.site-builder/status.md` under Build Configuration: `init: complete`.
   2. If Init was invoked via `--init`: report a short summary (git state, gitignore categories applied, MCPs configured/skipped) and EXIT. Do not start the pipeline in the same invocation.
   3. If Init was invoked via the pipeline's auto-detect guard (see below): proceed directly into Build Mode & Branch Setup — no separate exit.

   ### `--init` Re-run Guard

   Before running any Init steps, check `.site-builder/status.md`:

   ```
   status.md exists AND Build Configuration has `init: complete`?
   +-- YES --> Ask: "Init already complete. Re-run to reconfigure?
   |             (a) Yes  (b) No, exit"
   |     +-- (a) Yes --> run full Init flow again (Sections 1-7 above), overwrite init: complete
   |     +-- (b) No  --> EXIT immediately, no changes made
   +-- NO (no status.md, or init missing/pending) --> run Init flow normally
   ```

   This guard applies only when `--init` is passed explicitly. It does not apply to the pipeline's own auto-init guard below, which never re-runs a completed Init.

   ### Pipeline Auto-Init Guard

   When `/site-builder` is invoked with no `--init` flag (interactive, `--auto`, or `--auto --parallel`):

   ```
   .site-builder/status.md exists AND Build Configuration has `init: complete`?
   +-- YES --> Skip Init entirely. Proceed to Build Mode & Branch Setup
   |           (or Mode Detection, for a return run — see below).
   +-- NO  --> Run the full Init flow (Sections 1-7 above) inline, before
               Build Mode & Branch Setup. Do not EXIT after — flow directly
               into the pipeline once Init completes.
   ```

   No later phase re-checks git state, `.gitignore`, or MCP configuration —
   Init is the single source of truth, checked exactly once per project via
   this guard.
   ```

2. **Verify references.** Grep for `### Completing Init`, `### --init Re-run Guard`, and `### Pipeline Auto-Init Guard` — each must appear exactly once. Confirm these three subsections are the last content inside `## Init`, immediately before the `## Build Mode & Branch Setup` heading (unchanged from the current file).
3. **Commit:** `docs(site-builder): add init completion tracking and auto-init guard`

---

## Phase 1 Complete

`SKILL.md` now opens with a `## Flag Dispatch` table that routes `$ARGUMENTS`, followed by a `## Init` section (renamed from Prerequisites Check) covering git/`local-dev`/gitignore/MCP setup, completion tracking in `status.md`, and re-run semantics for `--init`. The pipeline body (`## Build Mode & Branch Setup` onward) is untouched by this phase.

**Next:** `phase-2.md`
