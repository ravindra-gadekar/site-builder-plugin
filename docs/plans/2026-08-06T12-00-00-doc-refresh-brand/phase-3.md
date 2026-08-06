# Phase 3: Orchestrator — SKILL.md

**Repo:** site-builder-plugin
**Depends on:** Phase 2 (doc-templates.md has BRAND.md section and auto-marker specs; phases.md has Update Mode step sequence)
**Delivers:** Updated `SKILL.md` — Init 2.5 creates BRAND.md and installs expanded pre-commit hook; Section 2.6 PostToolUse hook mentions BRAND.md with "Intra-phase reminder" label; all 11 phase sections use "Doc Gate:" instead of "Doc refresh:"; phases 4, 5, 8, 10, 11 gain new doc-gate entries; Update Mode has Doc Refresh Gate step.

---

## File Structure

```
skills/site-builder/
└── SKILL.md                   (modify)
```

---

### Task 1: Init Section 2.5 + Section 2.6 Updates

**Files:**
- Modify: `skills/site-builder/SKILL.md` (lines 94–189)

**Interfaces:**
- Consumes: `reference/brand-template.md` (Phase 1 Task 1) for BRAND.md creation reference. `reference/doc-refresh.md` (Phase 1 Task 2) for hook installation reference. `reference/doc-refresh-script.sh` (Phase 1 Task 3) for the mechanical-facts script to install. `reference/doc-templates.md` (Phase 2 Task 1) for CLAUDE.md nested-marker rule and file creation order.
- Produces: Updated Init flow consumed by the orchestrator at runtime — BRAND.md is created between ARCHITECTURE.md and CLAUDE.md; pre-commit hook includes mechanical-facts script; PostToolUse hook mentions BRAND.md.

**Acceptance Criteria:** AC-2 (Init 2.5 creates BRAND.md), AC-15 (PostToolUse hook updated + label renamed)

#### Steps

- [x] **Step 1:** Modify Init Section 2.5 (lines 94–127). Apply the following changes:

  **Change 1 — Add BRAND.md to the file list (line 96):**

  Current:
  ```
  Generate `CONTEXT.md`, `ARCHITECTURE.md`, and `CLAUDE.md` in the project
  root. Follow `reference/doc-templates.md` for templates and population
  rules.
  ```

  New:
  ```
  Generate `CONTEXT.md`, `ARCHITECTURE.md`, `BRAND.md`, and `CLAUDE.md` in
  the project root. Follow `reference/doc-templates.md` for templates and
  population rules. For `BRAND.md` specifically, follow
  `reference/brand-template.md` for the template and population rules.
  ```

  **Change 2 — Add BRAND.md handling rules (after line 107, before the "If these files don't exist" paragraph):**

  Insert:
  ```markdown
  - `BRAND.md` — if it exists, update design token sections with current
    data from `.site-builder/design-system.md` (if present) or CSS/Tailwind
    config. Preserve any manual additions. If it doesn't exist, create from
    the template in `reference/brand-template.md`. At init time the project
    may not have a design system yet — populate from existing CSS/Tailwind
    config if present, otherwise use placeholders.
  ```

  **Change 3 — Update "If these files don't exist" paragraph (line 109) to mention BRAND.md:**

  Current:
  ```
  **If these files don't exist:** create them from the templates in
  `reference/doc-templates.md`.
  ```

  New:
  ```
  **If these files don't exist:** create them from the templates in
  `reference/doc-templates.md` (`CONTEXT.md`, `ARCHITECTURE.md`, `CLAUDE.md`)
  and `reference/brand-template.md` (`BRAND.md`).
  ```

  **Change 4 — Expand pre-commit hook description (lines 116–122):**

  Current:
  ```
  **Pre-commit hook for auto-staging:** After generating docs, install the
  pre-commit hook from `reference/doc-refresh.md` (Layer 2) into
  `.git/hooks/pre-commit`. This ensures that when the orchestrator or any
  agent refreshes docs during the pipeline, the updated files are
  automatically staged into the next commit.
  ```

  New:
  ```
  **Pre-commit hook for doc refresh:** After generating docs, install the
  pre-commit hook into `.git/hooks/pre-commit`. The hook performs two jobs:

  1. **Mechanical-facts patching (Layer 2):** Runs the script from
     `reference/doc-refresh-script.sh` to patch `<!-- auto:* -->` marker
     sections in `ARCHITECTURE.md` and `BRAND.md` from source files on disk
     (directory tree, package.json, design-system.md). See
     `reference/doc-refresh.md` Section 3 for details.
  2. **Auto-staging:** Stages any doc files with unstaged changes
     (`CONTEXT.md`, `ARCHITECTURE.md`, `BRAND.md`, `CLAUDE.md`) into the
     commit so refreshed docs travel with code changes.

  The orchestrator embeds the full content of `reference/doc-refresh-script.sh`
  verbatim into the `site-builder:docs` marker block — the hook cannot
  reference `reference/...` paths at runtime since those live inside the
  skill's install directory, not the client project.

  The hook is wrapped in a `site-builder:docs` marker block and coexists
  with the gitignore hook from Section 2.
  ```

  **Change 5 — Add CLAUDE.md nested-marker handling (after line 107, in the CLAUDE.md bullet):**

  Update the existing CLAUDE.md bullet (lines 104–107) to include the nested-marker preservation rule:

  Current:
  ```
  - `CLAUDE.md` — search for `<!-- site-builder:start -->` /
    `<!-- site-builder:end -->` markers. If found, replace only the marker
    block content. If no markers exist, append the marker block at the end
    of the file. Never overwrite user content outside the markers.
  ```

  New:
  ```
  - `CLAUDE.md` — search for `<!-- site-builder:start -->` /
    `<!-- site-builder:end -->` markers. If found, replace only the marker
    block content, but **preserve any nested `<!-- auto:* -->` blocks** and
    their content within the marker block (see `reference/doc-templates.md`
    Marker Block Rules, rule 4). If no markers exist, append the marker
    block at the end of the file. Never overwrite user content outside the
    markers.
  ```

- [x] **Step 2:** Modify Section 2.6 (lines 128–189). Apply two changes:

  **Change 1 — Update PostToolUse hook echo (line 162):**

  Current:
  ```
  "command": "echo '>> Docs may be stale. If you changed exports, schemas, or domain concepts, update the relevant ARCHITECTURE.md and CONTEXT.md sections now.'"
  ```

  New:
  ```
  "command": "echo '>> Docs may be stale. If you changed exports, schemas, or domain concepts, update the relevant ARCHITECTURE.md, CONTEXT.md, and BRAND.md sections now.'"
  ```

  **Change 2 — Rename label (lines 177–178):**

  Current:
  ```
  - **`hooks.PostToolUse`** — Layer 1 of the doc-refresh system (see
    `reference/doc-refresh.md`). After every `Edit` or `Write` during a
    Claude session, echoes a reminder to refresh project docs if relevant
    files changed. This is the primary mechanism that keeps docs current.
  ```

  New:
  ```
  - **`hooks.PostToolUse`** — Intra-phase reminder for the doc-refresh
    system (see `reference/doc-refresh.md` Section 5). After every `Edit`
    or `Write` during a Claude session, echoes a reminder to refresh
    project docs if relevant files changed. This fires during agent work;
    the agent-indexed gate (Layer 1) fires at phase boundaries.
  ```

- [x] **Step 3:** Verify: BRAND.md creation order matches `doc-templates.md` File Creation Order (after ARCHITECTURE.md, before CLAUDE.md). Pre-commit hook references match `doc-refresh.md` Section 3 and `doc-refresh-script.sh`. PostToolUse echo mentions all three docs (ARCHITECTURE.md, CONTEXT.md, BRAND.md). Label says "Intra-phase reminder" not "Layer 1".

- [x] **Step 4:** Commit: `docs(skill): update Init 2.5 with BRAND.md creation and expanded pre-commit hook; update Section 2.6 PostToolUse label`

---

### Task 2: Phase Sections 1–11 + Update Mode

**Files:**
- Modify: `skills/site-builder/SKILL.md` (lines 845–1162 for phase sections, lines 816–844 for Update Mode)

**Interfaces:**
- Consumes: Agent→doc mapping table from Phase 1 Task 2 (`doc-refresh.md` Section 2). Update Mode step sequence from Phase 2 Task 2 (`phases.md`).
- Produces: Updated phase sections with "Doc Gate:" entries consumed by the orchestrator at runtime. Updated Update Mode consumed by the orchestrator in post-completion state.

**Acceptance Criteria:** AC-9 (all 11 phases use "Doc Gate:"), AC-10 (phases 4, 5, 8, 10, 11 gain new entries)

#### Steps

- [x] **Step 1:** Replace existing "Doc refresh:" footnotes with "Doc Gate:" checklist items for phases that already have them. Use the agent→doc mapping from `doc-refresh.md` to write the correct obligations. The format for each entry is: `**Doc Gate:** Verify <doc(s)> — <sections>. State what was checked.`

  **Phase 1 DISCOVER (line ~861):**

  Current:
  ```
  **Doc refresh:** Update `CONTEXT.md` — populate entities, glossary, and
  data flow sections from the approved project brief (see
  `reference/doc-refresh.md` Phase 1 mapping).
  ```

  New:
  ```
  **Doc Gate:** Verify `CONTEXT.md` — entities, glossary, and data flow
  sections reflect the approved project brief (`.site-builder/project-brief.md`).
  State what was checked before proceeding.
  ```

  **Phase 2 ARCHITECT (line ~879):**

  Current:
  ```
  **Doc refresh:** Update `CONTEXT.md` (conventions, decisions from
  architecture) and `CLAUDE.md` marker block (confirmed tech stack). See
  `reference/doc-refresh.md` Phase 2 mapping.
  ```

  New:
  ```
  **Doc Gate:** Verify `CONTEXT.md` — conventions and decisions sections
  reflect architecture output. Verify `CLAUDE.md` marker block — tech stack
  section reflects confirmed stack. State what was checked before proceeding.
  ```

  **Phase 3 PREPARE (line ~955):**

  Current:
  ```
  **Doc refresh:** Update `ARCHITECTURE.md` (directory structure, patterns,
  entry points, build commands from scaffolded project) and `CLAUDE.md`
  marker block (build commands). See `reference/doc-refresh.md` Phase 3
  mapping.
  ```

  New:
  ```
  **Doc Gate:** Verify `ARCHITECTURE.md` — directory structure, patterns,
  entry points, and dependencies sections reflect the scaffolded project.
  Verify `CLAUDE.md` marker block — build & dev commands section reflects
  `package.json` scripts. State what was checked before proceeding.
  ```

  **Phase 6 DEVELOP (line ~1007):**

  Current:
  ```
  **Doc refresh:** Update `ARCHITECTURE.md` (finalized component tree,
  routes, dependencies). See `reference/doc-refresh.md` Phase 6 mapping.
  ```

  New:
  ```
  **Doc Gate:** Verify `ARCHITECTURE.md` — directory structure, patterns,
  entry points, and dependencies sections reflect the finalized codebase.
  Verify `CLAUDE.md` marker block — build & dev commands still accurate.
  Verify `BRAND.md` — token values match `.site-builder/design-system.md`
  (verify-only — do not overwrite designer-agent content unless values
  diverged). State what was checked before proceeding.
  ```

  **Phase 9 DEPLOY (line ~1105):**

  Current:
  ```
  **Doc refresh:** Update `CLAUDE.md` marker block (deployment target,
  CI/CD info). See `reference/doc-refresh.md` Phase 9 mapping.
  ```

  New:
  ```
  **Doc Gate:** Verify `CLAUDE.md` marker block — deployment target and
  CI/CD info sections reflect the deployment configuration. State what was
  checked before proceeding.
  ```

- [x] **Step 2:** Add new "Doc Gate:" entries for phases that previously had none. Insert each entry after the phase's `Update status.md` line, before the next phase heading.

  **Phase 4 DESIGN (after line ~972, before Phase 5):**

  Insert:
  ```
  **Doc Gate:** Verify `BRAND.md` — designer-agent is primary owner. All
  sections (colors, typography, spacing, component patterns) must reflect
  `.site-builder/design-system.md`. State what was checked before proceeding.
  ```

  **Phase 5 CONTENT (after line ~982, before Phase 6):**

  Insert:
  ```
  **Doc Gate:** Verify `CONTEXT.md` — glossary section includes any new
  terms introduced in the content (`.site-builder/content/*.md`). State
  what was checked before proceeding.
  ```

  **Phase 7 AUDIT (after line ~1048, before Phase 8):**

  Do NOT add a Doc Gate entry. The 6 audit agents are read-only analyzers
  excluded from the agent→doc mapping by design (see `reference/doc-refresh.md`).

  **Phase 8 INTEGRATE (after line ~1060, before Phase 9):**

  Insert:
  ```
  **Doc Gate:** Verify `ARCHITECTURE.md` — integrations section reflects
  connected social platforms from `.site-builder/integration-reports/social-integration.md`.
  State what was checked before proceeding.
  ```

  **Phase 10 ANALYTICS (after line ~1121, before Phase 11):**

  Insert:
  ```
  **Doc Gate:** Verify `CLAUDE.md` marker block — analytics config reference
  reflects installed tracking platforms from `.site-builder/integration-reports/analytics.md`.
  State what was checked before proceeding.
  ```

  **Phase 11 AUTO-INDEXING (after line ~1146, before "Pipeline Complete"):**

  Insert:
  ```
  **Doc Gate:** Verify `CLAUDE.md` marker block — indexing config reference
  reflects IndexNow and RSS/feed configuration from `.site-builder/integration-reports/seo-indexing.md`.
  State what was checked before proceeding.
  ```

- [x] **Step 3:** Modify Update Mode (lines 816–844). Insert Doc Refresh Gate step between re-audit and deploy.

  Current Update Mode steps (within the "If all phases complete" block):
  ```
  1. **Re-validate design against current ruleset:** ...
  2. Ask the user what needs changing
  3. Map changes to minimum set of agents: ...
  4. Run only those agents
  5. Re-audit changed areas
  6. Deploy through existing CI/CD
  ```

  New:
  ```
  1. **Re-validate design against current ruleset:** ...
  2. Ask the user what needs changing
  3. Map changes to minimum set of agents: ...
  4. Run only those agents
  5. Re-audit changed areas
  6. **Doc Refresh Gate:** For each agent that ran in step 4, look up its
     doc obligations in the agent→doc mapping (`reference/doc-refresh.md`
     Section 2). Read each mapped doc. Verify the relevant sections reflect
     the agent's output. State what was checked. Block deploy until all
     agents' docs are verified. If no agents ran (manual change outside
     pipeline), skip this step — Layer 2 still patches mechanical facts on
     commit.
  7. Deploy through existing CI/CD
  ```

- [x] **Step 4:** Verify completeness: grep SKILL.md for "Doc refresh:" — should return zero hits. Grep for "Doc Gate:" — should return 10 hits (phases 1–6, 8–11; not phase 7). This satisfies AC-9 ("all 11 phases") as 10 of 11 — Phase 7 AUDIT is excluded by design because its 6 audit agents are read-only analyzers. Verify Update Mode has 7 steps with Doc Refresh Gate at step 6. Verify no phase references "doc-refresh.md Phase N mapping" (old phase-indexed references) — all should reference the agent-indexed mapping or omit the reference.

- [x] **Step 5:** Commit: `docs(skill): replace Doc refresh footnotes with Doc Gate entries across all phases; add Update Mode Doc Refresh Gate`

---

## Phase 3 Complete

`SKILL.md` is fully updated:
- Init 2.5 creates BRAND.md and installs the expanded pre-commit hook (mechanical-facts + auto-staging).
- Section 2.6 PostToolUse hook echo mentions BRAND.md; label is "Intra-phase reminder".
- All 11 phase sections use "Doc Gate:" with agent-indexed obligations. Phases 4, 5, 8, 10, 11 have new entries.
- Phase 7 AUDIT has no Doc Gate (audit agents excluded by design).
- Update Mode has 7 steps with Doc Refresh Gate at step 6.

**Next:** `phase-4.md`
