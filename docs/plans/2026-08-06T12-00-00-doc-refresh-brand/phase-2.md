# Phase 2: Template, Phases & Checklist Updates

**Repo:** site-builder-plugin
**Depends on:** Phase 1 (auto-marker names from `brand-template.md` and `doc-refresh.md`, script marker names from `doc-refresh-script.sh`)
**Delivers:** Updated `doc-templates.md` (auto-markers in templates, BRAND.md section, CLAUDE.md nested-marker rules), updated `phases.md` (Update Mode Doc Refresh Gate), updated `handoff-checklist.md` (BRAND.md + auto-marker verification).

---

## File Structure

```
skills/site-builder/reference/
├── doc-templates.md           (modify)
├── phases.md                  (modify)
└── handoff-checklist.md       (modify)
```

---

### Task 1: Update Doc-Templates with Auto-Markers and BRAND.md

**Files:**
- Modify: `skills/site-builder/reference/doc-templates.md`

**Interfaces:**
- Consumes: Auto-marker names from Phase 1 Task 1 (`auto:color-tokens`, `auto:font-stack`, `auto:spacing-scale`) and Phase 1 Task 2 (`auto:directory-structure`, `auto:dependencies`, `auto:build-dev`). BRAND.md template from Phase 1 Task 1 (`brand-template.md`). Nested-marker rule from Phase 1 Task 2 (`doc-refresh.md` Section 6).
- Produces: Updated ARCHITECTURE.md template with auto-markers consumed by Phase 1 Task 3 (script expects these markers in target docs). BRAND.md section pointer consumed by Phase 3 Task 1 (SKILL.md Init 2.5 references doc-templates.md). CLAUDE.md nested-marker rule consumed by Phase 3 Task 1 (SKILL.md Init 2.5 marker block handling). Updated Architecture Reference lookup order consumed by Phase 3 Task 1 (SKILL.md CLAUDE.md template).

**Acceptance Criteria:** AC-12 (auto-markers in mechanical sections), AC-13 (CLAUDE.md marker block rules amended), AC-14 (CLAUDE.md Architecture Reference includes BRAND.md)

#### Steps

- [ ] **Step 1:** Add `<!-- auto:* -->` markers to the ARCHITECTURE.md template (Section 2, lines 124–185).

  Wrap the Directory Structure section's code block:
  ```markdown
  ## Directory Structure

  <!-- auto:directory-structure -->
  ```text
  <project-root>/
  ├── <dir>/          # <purpose>
  └── <file>          # <purpose>
  ```
  <!-- /auto:directory-structure -->
  ```

  Wrap the Dependencies section's tables:
  ```markdown
  ## Dependencies

  <!-- auto:dependencies -->
  ### Runtime

  | Dependency | Purpose |
  |---|---|
  | <name> | <what it provides> |

  ### Dev

  | Dependency | Purpose |
  |---|---|
  | <name> | <what it provides> |
  <!-- /auto:dependencies -->
  ```

  Wrap the Build & Dev section's code block:
  ```markdown
  ## Build & Dev

  <!-- auto:build-dev -->
  ```bash
  <install command>     # install dependencies
  <dev command>         # start dev server
  <build command>       # build for production
  <preview command>     # preview production build locally
  ```
  <!-- /auto:build-dev -->
  ```

  The rest of ARCHITECTURE.md (Purpose, Key Patterns, Entry Points, Testing) remains unwrapped — these are judgment sections managed by Layer 1 only.

- [ ] **Step 2:** Add BRAND.md section as Section 4 (after the existing Section 3: CLAUDE.md, before the "File Creation Order" section).

  ```markdown
  ## 4. BRAND.md

  **Location:** Project root (`BRAND.md`)
  **Purpose:** Design tokens — colors, typography, spacing, and component
  patterns. Single source of truth for visual identity outside `.site-builder/`.
  **Created by:** Init (Section 2.5), after `ARCHITECTURE.md`, before `CLAUDE.md`
  **Updated by:** designer-agent (primary owner, Phase 4 DESIGN),
  developer-agent (verify-only, Phase 6 DEVELOP), pre-commit script
  (mechanical token sections only via auto-markers)

  ### Template

  See `reference/brand-template.md` for the full template, auto-marker
  placement, and population rules.

  ### Auto-Marker Sections

  Three sections are wrapped in `<!-- auto:* -->` markers and managed by
  the pre-commit script (Layer 2):

  | Marker | Section | Source |
  |---|---|---|
  | `auto:color-tokens` | Colors table | `.site-builder/design-system.md` ### Colors |
  | `auto:font-stack` | Typography table | `.site-builder/design-system.md` ### Typography |
  | `auto:spacing-scale` | Spacing table | `.site-builder/design-system.md` ### Spacing |

  All other sections (Brand Direction, Shadows, Border Radius, Transitions,
  Component Patterns, Dark Mode) are judgment content managed by the
  designer-agent gate (Layer 1) only.
  ```

- [ ] **Step 3:** Add `<!-- auto:build-commands -->` marker to the CLAUDE.md template (Section 3) and add the nested-marker rule.

  In the CLAUDE.md template (both "Full Generation" and "Append to Existing" variants), wrap the Build & Development Commands section:
  ```markdown
  <!-- auto:build-commands -->
  ## Build & Development Commands

  ```bash
  <install command>     # install dependencies
  <dev command>         # start dev server
  <build command>       # build for production
  <preview command>     # preview production build
  ```
  <!-- /auto:build-commands -->
  ```

  Amend the "Marker Block Rules" subsection (currently at lines 301–309). Add a new rule after rule 3:

  ```markdown
  4. **Preserve nested auto-markers.** When replacing content between the
     site-builder markers, the orchestrator must preserve any nested
     `<!-- auto:* -->` / `<!-- /auto:* -->` blocks and their content. Replace
     only the text outside auto-markers within the site-builder block.
  ```

  Add a note after rule 4 clarifying the `auto:build-commands` exception:

  ```markdown
  **Note on `auto:build-commands`:** Unlike other `auto:*` markers (which
  are owned by the pre-commit script / Layer 2), `auto:build-commands` in
  CLAUDE.md is owned by the developer-agent gate (Layer 1). It exists
  solely so its content survives site-builder marker-block replacement —
  the pre-commit script never patches CLAUDE.md. See
  `reference/doc-refresh.md` Section 4 for the full ownership boundary.
  ```

- [ ] **Step 4:** Update the CLAUDE.md Architecture Reference lookup order (inside the template) to include BRAND.md.

  Current order (lines 265–271):
  ```
  1. Read CONTEXT.md — domain model, data flow, conventions
  2. Read ARCHITECTURE.md — directory structure, patterns, entry points
  3. Read .site-builder/project-brief.md — business requirements
  4. Read .site-builder/site-architecture.md — technical decisions
  5. Read source files — only when the above don't answer your question
  ```

  New order:
  ```
  1. Read CONTEXT.md — domain model, data flow, conventions
  2. Read ARCHITECTURE.md — directory structure, patterns, entry points
  3. Read BRAND.md — design tokens, typography, component patterns
  4. Read .site-builder/project-brief.md — business requirements
  5. Read .site-builder/site-architecture.md — technical decisions
  6. Read source files — only when the above don't answer your question
  ```

- [ ] **Step 5:** Update the "File Creation Order" section (currently lines 315–325) to include BRAND.md:

  ```
  1. CONTEXT.md — domain model
  2. ARCHITECTURE.md — directory structure and patterns
  3. BRAND.md — design tokens (populated from existing CSS/Tailwind config
     or placeholders; enriched by Phase 4 DESIGN)
  4. CLAUDE.md — last, because it references the other docs
  ```

- [ ] **Step 6:** Update the "Population at Init Time vs. Pipeline Enrichment" section (lines 329–342) to include BRAND.md column and Phase 4 DESIGN row.

  Add BRAND.md column to the project-state table:
  ```
  | Project state | CONTEXT.md | ARCHITECTURE.md | BRAND.md | CLAUDE.md |
  |---|---|---|---|---|
  | Empty (only .git/) | Placeholder sections | Placeholder sections | Placeholder tokens | Skeleton with marker block |
  | Existing codebase | Entities from file names | Full directory listing, deps | Tokens from CSS/Tailwind config | Populated tech stack and commands |
  ```

  Add Phase 4 enrichment row:
  ```
  - Phase 4 DESIGN → BRAND.md (all design tokens and component patterns from design-system.md)
  ```

- [ ] **Step 7:** Verify auto-marker names match Phase 1 Task 3 (doc-refresh-script.sh): `auto:directory-structure`, `auto:dependencies`, `auto:build-dev` for ARCHITECTURE.md; `auto:color-tokens`, `auto:font-stack`, `auto:spacing-scale` for BRAND.md; `auto:build-commands` for CLAUDE.md. Verify BRAND.md section references `brand-template.md`.

- [ ] **Step 8:** Commit: `docs(reference): add auto-markers, BRAND.md section, and nested-marker rules to doc-templates.md`

---

### Task 2: Update Phases Reference with Doc Refresh Gate

**Files:**
- Modify: `skills/site-builder/reference/phases.md`

**Interfaces:**
- Consumes: Agent→doc mapping table from Phase 1 Task 2 (`doc-refresh.md` Section 2)
- Produces: Updated Update Mode step sequence consumed by Phase 3 Task 2 (SKILL.md Update Mode must mirror this step sequence)

**Acceptance Criteria:** AC-11 (Update Mode Doc Refresh Gate between re-audit and deploy)

#### Steps

- [ ] **Step 1:** Modify the Update Mode section (lines 113–118). Insert Doc Refresh Gate step and add agent→doc mapping reference.

  The current `phases.md` Update Mode is a simplified 4-step list. The spec
  requires this section to mirror SKILL.md's full Update Mode flow rather
  than restating a simplified version. Rewrite to match SKILL.md's step
  structure with the new Doc Refresh Gate inserted.

  Current content:
  ```markdown
  ## Update Mode

  When the orchestrator detects an existing `.site-builder/` directory:
  1. Enter update mode — ask user what needs changing
  2. Map requested changes to minimum set of agents
  3. Run only those agents + audit loop for changed areas
  4. Deploy through existing CI/CD pipeline
  ```

  New content (mirrors SKILL.md's full flow):
  ```markdown
  ## Update Mode

  When the orchestrator detects an existing `.site-builder/` directory:
  1. **Re-validate design against current ruleset** — read `.site-builder/design-system.md`, check against `reference/design-principles.md`. If violations found, surface suggestions. If accepted, re-run designer-agent. If dismissed or none found, proceed.
  2. Ask the user what needs changing
  3. Map changes to minimum set of agents:
     - "Update homepage copy" → content-agent + developer-agent + audit loop
     - "Change colors" → designer-agent + developer-agent + audit loop
     - "Add a new page" → architect-agent + content-agent + developer-agent + audit loop
     - "Fix SEO issues" → seo-audit-agent + developer-agent/content-agent
     - "Refresh the design" → designer-agent (with UI UX Pro Max re-query) + developer-agent + audit loop
  4. Run only those agents
  5. Re-audit changed areas
  6. **Doc Refresh Gate** — for each agent that ran in step 4, look up its doc obligations in the agent→doc mapping (`reference/doc-refresh.md` Section 2). Read each mapped doc. Verify the relevant sections reflect the agent's output. State what was checked. Block deploy until all agents' docs are verified. If no agents ran (manual change outside pipeline), skip — Layer 2 still patches mechanical facts on commit.
  7. Deploy through existing CI/CD pipeline

  ### Agent→Doc Mapping Reference

  See `reference/doc-refresh.md` Section 2 for the full agent→doc mapping
  table. The orchestrator uses this table to determine which docs to verify
  for each agent in step 6.
  ```

- [ ] **Step 2:** Verify step numbering: 7 steps total, Doc Refresh Gate is step 6, Deploy is step 7. Steps 1–5 and 7 mirror SKILL.md's existing Update Mode exactly. Verify reference to `doc-refresh.md` is accurate.

- [ ] **Step 3:** Commit: `docs(reference): insert Doc Refresh Gate into phases.md Update Mode`

---

### Task 3: Update Handoff Checklist

**Files:**
- Modify: `skills/site-builder/reference/handoff-checklist.md`

**Interfaces:**
- Consumes: BRAND.md existence from Phase 1 Task 1 (brand-template.md defines what BRAND.md should contain). Auto-marker concept from Phase 1 Task 2 (doc-refresh.md).
- Produces: Updated checklist consumed by the orchestrator at the INTEGRATE → DEPLOY transition.

**Acceptance Criteria:** AC-22 (BRAND.md and auto-marker verification in checklist)

#### Steps

- [ ] **Step 1:** Add a new "Documentation" subsection to the Pre-Deploy Checks section (after the existing "Deployment" subsection, before "Client Handoff Package"). Insert:

  ```markdown
  ### Documentation
  - [ ] BRAND.md present in project root and populated with design tokens (not placeholder text)
  - [ ] All `<!-- auto:* -->` marker sections in ARCHITECTURE.md populated with current data (directory tree, dependencies, build commands)
  - [ ] All `<!-- auto:* -->` marker sections in BRAND.md populated with current data (color tokens, font stack, spacing scale) — skip if before Phase 4 DESIGN
  - [ ] CONTEXT.md entities and glossary reflect the built website
  - [ ] CLAUDE.md marker block contains current tech stack, build commands, and deployment info
  ```

- [ ] **Step 2:** Verify items align with the doc-refresh system: auto-marker checks correspond to Layer 2 sections, judgment-content checks correspond to Layer 1 sections.

- [ ] **Step 3:** Commit: `docs(reference): add BRAND.md and auto-marker verification to handoff-checklist.md`

---

## Phase 2 Complete

Three reference files updated:
- `doc-templates.md` — ARCHITECTURE.md, BRAND.md, and CLAUDE.md templates now include `<!-- auto:* -->` markers; CLAUDE.md marker block rules amended for nested-marker preservation; Architecture Reference includes BRAND.md; file creation order updated.
- `phases.md` — Update Mode now has 7 steps (mirrors SKILL.md), Doc Refresh Gate at step 6.
- `handoff-checklist.md` — Documentation section added with BRAND.md and auto-marker verification items.

**Next:** `phase-3.md`
