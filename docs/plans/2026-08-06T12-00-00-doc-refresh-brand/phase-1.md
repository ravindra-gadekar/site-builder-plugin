# Phase 1: Foundation — Reference Documents

**Repo:** site-builder-plugin
**Depends on:** None
**Delivers:** Three reference documents that define the new doc-refresh system — `brand-template.md` (BRAND.md template), rewritten `doc-refresh.md` (agent-indexed gate + mechanical-facts script design), and `doc-refresh-script.sh` (POSIX sh pre-commit script template).

---

## File Structure

```
skills/site-builder/reference/
├── brand-template.md          (create)
├── doc-refresh.md             (modify — full rewrite)
└── doc-refresh-script.sh      (create)
```

---

### Task 1: Create BRAND.md Template

**Files:**
- Create: `skills/site-builder/reference/brand-template.md`

**Interfaces:**
- Consumes: Designer-agent output format from `agents/designer-agent.md` lines 361–401 (design-system.md section structure: Colors, Typography, Spacing, Shadows, Border Radius, Transitions, Component Patterns)
- Produces: BRAND.md template with `<!-- auto:* -->` marker names (`auto:color-tokens`, `auto:font-stack`, `auto:spacing-scale`) consumed by Phase 1 Task 3 (script) and Phase 2 Task 1 (doc-templates.md)

**Acceptance Criteria:** AC-1 (BRAND.md template with colors, typography, spacing, component patterns)

#### Steps

- [x] **Step 1:** Write `skills/site-builder/reference/brand-template.md` with the following structure:

  **Header section:**
  - Location: Project root (`BRAND.md`)
  - Purpose: Design tokens extracted from the site-builder design system — colors, typography, spacing, and component patterns. Single source of truth for visual identity outside `.site-builder/`.
  - Created by: Init (Section 2.5), after `ARCHITECTURE.md`, before `CLAUDE.md`
  - Updated by: designer-agent (primary owner, Phase 4 DESIGN), developer-agent (secondary/verify-only, Phase 6 DEVELOP — only when `.site-builder/design-system.md` exists), pre-commit script (mechanical token sections only)

  **Template content** — the full BRAND.md template with these sections:

  ```markdown
  # BRAND.md

  ## Brand Direction

  <2-3 sentence design philosophy from design-system.md>

  ## Design Tokens

  ### Colors

  <!-- auto:color-tokens -->
  | Token | Value | Usage |
  |---|---|---|
  | Primary | <hex> | <where used> |
  | Secondary | <hex> | <where used> |
  | Accent | <hex> | <where used> |
  | Background | <hex> | <where used> |
  | Surface | <hex> | <where used> |
  | Text Primary | <hex> | <where used> |
  | Text Secondary | <hex> | <where used> |
  <!-- /auto:color-tokens -->

  ### Typography

  <!-- auto:font-stack -->
  | Role | Family | Weight | Size |
  |---|---|---|---|
  | Heading | <font> | <weight> | <scale> |
  | Body | <font> | <weight> | <scale> |
  | UI | <font> | <weight> | <scale> |
  <!-- /auto:font-stack -->

  ### Spacing

  <!-- auto:spacing-scale -->
  | Token | Value | Usage |
  |---|---|---|
  | xs | <value> | <usage> |
  | sm | <value> | <usage> |
  | md | <value> | <usage> |
  | lg | <value> | <usage> |
  | xl | <value> | <usage> |
  <!-- /auto:spacing-scale -->

  ### Shadows

  <shadow definitions — not auto-managed>

  ### Border Radius

  <border-radius scale — not auto-managed>

  ### Transitions

  <transition presets — not auto-managed>

  ## Component Patterns

  ### Navigation
  <nav pattern description>

  ### Hero
  <hero pattern description>

  ### Cards
  <card pattern description>

  ### Buttons
  <button styles and states>

  ### Footer
  <footer pattern description>

  ## Dark Mode (if applicable)

  <dark mode token mappings>
  ```

  **Population rules:**
  - **Existing codebase (CSS/Tailwind config present):** Extract color values from `tailwind.config.*` theme.extend.colors, font families from theme.extend.fontFamily, spacing from theme.extend.spacing. If raw CSS: parse custom properties from `:root {}`. Populate the token tables with extracted values. Component Patterns section left as placeholders.
  - **Greenfield project (no config):** All token table cells use `<placeholder>` text. Brand Direction says "Pending Phase 4 DESIGN". Component Patterns section left as placeholders.
  - **After Phase 4 DESIGN:** designer-agent populates ALL sections from `.site-builder/design-system.md`. This is the primary population event.
  - **After Phase 6 DEVELOP:** developer-agent verifies that BRAND.md tokens still match design-system.md (tokens may have been adjusted during implementation). Verify-only — do not overwrite designer-agent content unless values diverged.

- [x] **Step 2:** Verify template sections align with designer-agent output format — every section in `.site-builder/design-system.md` (Colors, Typography, Spacing, Component Patterns) has a corresponding section in the BRAND.md template. Verify auto-marker names are consistent: `auto:color-tokens`, `auto:font-stack`, `auto:spacing-scale`.

- [x] **Step 3:** Commit: `docs(reference): add brand-template.md for BRAND.md template and population rules`

---

### Task 2: Rewrite Doc-Refresh Reference

**Files:**
- Modify: `skills/site-builder/reference/doc-refresh.md`

**Interfaces:**
- Consumes: Existing `doc-refresh.md` content (lines 1–138) for structural understanding of what to replace
- Produces: Agent→doc mapping table consumed by Phase 2 Task 2 (phases.md), Phase 3 Task 2 (SKILL.md phase sections), and Phase 4 Tasks 1–3 (agent doc-gate obligations). Section-ownership boundary rules consumed by Phase 1 Task 3 (script) and Phase 2 Task 1 (doc-templates.md auto-markers).

**Acceptance Criteria:** AC-3 (agent-indexed mapping table), AC-4 (checklist gate pattern), AC-5 (mechanical-facts script description), AC-24 (section ownership boundary), AC-25 (audit agents excluded)

#### Steps

- [x] **Step 1:** Rewrite `skills/site-builder/reference/doc-refresh.md` with the following structure. Replace all existing content.

  **Section 1 — Overview:**
  - Title: "Doc Refresh Mechanism"
  - Intro paragraph: how CONTEXT.md, ARCHITECTURE.md, BRAND.md, and CLAUDE.md stay in sync.
  - Two-layer table:

    | Layer | Trigger | What it does |
    |---|---|---|
    | **Layer 1: Agent-indexed checklist gate** | Orchestrator completes a phase or Update Mode agent run | Verifies judgment-content sections in mapped docs match the agent's output |
    | **Layer 2: Mechanical-facts pre-commit script** | Every `git commit` | Patches mechanical sections inside `<!-- auto:* -->` markers from source files on disk |

  **Section 2 — Layer 1: Agent-Indexed Checklist Gate:**

  - Agent→doc mapping table (the authoritative table for the entire system):

    | Agent | Docs it must refresh | Sections affected |
    |---|---|---|
    | discovery-agent | `CONTEXT.md` | Entities, Glossary, Data Flow |
    | architect-agent | `CONTEXT.md`, `CLAUDE.md` | Conventions, Decisions; Tech Stack |
    | developer-agent | `ARCHITECTURE.md`, `CLAUDE.md`, `BRAND.md` | Directory Structure, Patterns, Entry Points, Dependencies; Build & Dev commands (CLAUDE.md marker block); verify BRAND.md tokens match design-system.md (Phase 6 only — not Phase 3, when design-system.md does not yet exist) |
    | designer-agent | `BRAND.md` (primary owner) | All sections (colors, typography, spacing, component patterns) |
    | content-agent | `CONTEXT.md` | Glossary (new terms from content) |
    | deploy-agent | `CLAUDE.md` | Deployment target, CI/CD |
    | analytics-agent | `CLAUDE.md` | Analytics config reference |
    | seo-indexing-agent | `CLAUDE.md` | Indexing config reference |
    | social-integration-agent | `ARCHITECTURE.md` | Integrations |

  - Gate enforcement procedure (after every agent completes):
    1. Read each doc listed for that agent
    2. Verify the relevant sections reflect the agent's output
    3. State what was checked (e.g., "ARCHITECTURE.md directory tree updated to reflect new `/api` route") before proceeding
  - Note: this is the same "must state what you checked" pattern as Phase 7's audit quality gate.

  - **Audit agents excluded by design:** The 6 audit agents (seo-audit, technical-audit, content-quality, ai-search, schema-audit, accessibility-audit) are absent from the mapping intentionally — they are read-only analyzers whose findings are acted on by content-agent and developer-agent, which ARE in the mapping. Do not add doc-gate obligations to audit agents during implementation.

  **Section 3 — Layer 2: Mechanical-Facts Pre-Commit Script:**

  - Description: a POSIX `sh` script template at `reference/doc-refresh-script.sh`, installed into `.git/hooks/pre-commit` during Init.
  - What it patches:

    | Doc | Sections handled by script | Auto-marker name | Source |
    |---|---|---|---|
    | `ARCHITECTURE.md` | Directory Structure | `auto:directory-structure` | `find . -maxdepth 2` excluding node_modules/.git/gitignored |
    | `ARCHITECTURE.md` | Dependencies | `auto:dependencies` | `package.json` dependencies + devDependencies |
    | `ARCHITECTURE.md` | Build & Dev | `auto:build-dev` | `package.json` scripts |
    | `BRAND.md` | Color tokens | `auto:color-tokens` | `.site-builder/design-system.md` color token blocks |
    | `BRAND.md` | Font stack | `auto:font-stack` | `.site-builder/design-system.md` typography section |
    | `BRAND.md` | Spacing scale | `auto:spacing-scale` | `.site-builder/design-system.md` spacing section |

  - What it does NOT patch: Agent/phase counts in `CLAUDE.md` (those are plugin-repo values, not client-project values). CLAUDE.md's Build & Dev commands are refreshed by the developer-agent gate (Layer 1), not the script.
  - Script behavior: reads source files, extracts mechanical values, patches only content between `<!-- auto:X -->` / `<!-- /auto:X -->` markers using sed/awk. Exits 0 on every error path.
  - CRLF handling: preprocesses input with `tr -d '\r'` before sed/awk pattern matching.

  **Section 4 — Section Ownership Boundary:**

  - Each auto-managed section is wrapped in `<!-- auto:* -->` markers.
  - The script (Layer 2) only writes inside these markers.
  - The agent gate (Layer 1) only writes outside them.
  - Neither touches the other's territory.
  - **Exception — `auto:build-commands` in CLAUDE.md:** This marker exists
    solely so its content survives site-builder marker-block replacement
    (the nested-marker preservation rule). It is owned by the developer-agent
    gate (Layer 1), NOT the pre-commit script. The script never patches
    CLAUDE.md. This is the only `auto:*` marker where Layer 1 writes inside
    the markers rather than outside them.

  **Section 5 — Intra-Phase Reminder (PostToolUse Hook):**

  - The PostToolUse hook (`echo 'Docs may be stale...'`) is retained as an intra-phase nudge.
  - It fires during agent work; the gate fires at phase boundaries. Different scope, both useful.
  - The echo message mentions BRAND.md alongside ARCHITECTURE.md and CONTEXT.md.
  - Label: "Intra-phase reminder" (not "Layer 1" — that label now belongs to the gate).

  **Section 6 — Nested Marker Rule for CLAUDE.md:**

  - Auto-markers can appear inside the `<!-- site-builder:start -->` / `<!-- site-builder:end -->` block.
  - When replacing site-builder marker block content, the orchestrator must preserve nested `<!-- auto:* -->` blocks and their content.
  - The orchestrator replaces only the text outside auto-markers within the site-builder block.

  **Section 7 — Staleness Windows:**

  | Scenario | How long docs can be stale | Why acceptable |
  |---|---|---|
  | Mid-phase (agent still running) | Minutes | Agent hasn't finished producing the data yet |
  | Between phase boundary and next commit | Until next commit | Layer 2 catches mechanical facts; Layer 1 already caught judgment facts at boundary |
  | Outside a Claude session (manual code edits) | Until next commit | Layer 2 script still fires — mechanical facts stay fresh. Judgment sections may drift, caught on next pipeline run |
  | Update Mode | Zero after Doc Refresh Gate | Hard gate blocks deploy until docs verified |

  **Section 8 — Error Handling:**

  Include the error handling tables from the spec: Layer 1 gate failures, Layer 2 script failures, Update Mode gate failures. End with the key principle: "Layer 2 never blocks commits on doc-refresh failure. It exits 0 on every error path."

  **Section 9 — Hook Installation:**

  - Installed during Init (Section 2.5), after doc generation.
  - The pre-commit hook now contains BOTH the auto-staging logic (for docs refreshed by Layer 1) AND the mechanical-facts patching script (Layer 2).
  - Both use the `site-builder:docs` marker block in `.git/hooks/pre-commit`.
  - Coexists with the gitignore hook's `site-builder:gitignore` marker block.
  - Installation rules: same as current doc-refresh.md (create if absent, append if no marker, replace if marker exists).

- [x] **Step 2:** Verify: all 9 agents in the mapping table exist in `agents/` (confirmed: discovery, architect, developer, designer, content, deploy, analytics, seo-indexing, social-integration). Verify auto-marker names are consistent with Task 1 (brand-template.md): `auto:color-tokens`, `auto:font-stack`, `auto:spacing-scale`. Verify ARCHITECTURE.md markers: `auto:directory-structure`, `auto:dependencies`, `auto:build-dev`.

- [x] **Step 3:** Commit: `docs(reference): rewrite doc-refresh.md with agent-indexed gate and mechanical-facts script`

---

### Task 3: Create Pre-Commit Script Template

**Files:**
- Create: `skills/site-builder/reference/doc-refresh-script.sh`

**Interfaces:**
- Consumes: Auto-marker names from Task 1 (`auto:color-tokens`, `auto:font-stack`, `auto:spacing-scale`) and Task 2 (`auto:directory-structure`, `auto:dependencies`, `auto:build-dev`). Section ownership rules from Task 2 (script writes only inside markers).
- Produces: Complete POSIX sh script template consumed by Phase 3 Task 1 (SKILL.md Init 2.5 references this script for hook installation)

**Acceptance Criteria:** AC-6 (script exists as POSIX sh), AC-7 (exits 0 on all error paths), AC-8 (preprocesses with `tr -d '\r'`), AC-23 (POSIX-compliant, CRLF-safe)

#### Steps

- [x] **Step 1:** Write `skills/site-builder/reference/doc-refresh-script.sh` with the following content:

  ```sh
  #!/bin/sh
  # Site Builder — mechanical-facts doc refresh (pre-commit)
  # Patches ARCHITECTURE.md and BRAND.md auto-marker sections from source files.
  # Exits 0 on ALL error paths — never blocks a commit.

  # --- CRLF safety (Windows Git Bash) ---
  # All file reads are piped through tr -d '\r' before sed/awk processing.

  set -e
  trap 'exit 0' EXIT

  # --- Helper: patch content between auto-markers ---
  # Usage: patch_auto_section <file> <marker-name> <new-content>
  # If file or markers are missing, skip silently.
  patch_auto_section() {
    _file="$1"
    _marker="$2"
    _content="$3"
    _open="<!-- auto:${_marker} -->"
    _close="<!-- /auto:${_marker} -->"

    [ -f "$_file" ] || return 0

    # Check markers exist (CRLF-safe)
    tr -d '\r' < "$_file" | grep -q "$_open" || return 0
    tr -d '\r' < "$_file" | grep -q "$_close" || return 0

    # Replace content between markers using awk (CRLF-safe)
    _tmp="${_file}.tmp.$$"
    tr -d '\r' < "$_file" | awk -v open="$_open" -v close="$_close" -v content="$_content" '
      $0 == open { print; printf "%s\n", content; skip=1; next }
      $0 == close { skip=0 }
      !skip { print }
    ' > "$_tmp"

    mv "$_tmp" "$_file"
  }

  # --- ARCHITECTURE.md: Directory Structure ---
  if [ -f "ARCHITECTURE.md" ]; then
    dir_tree=$(find . -maxdepth 2 \
      -not -path './.git*' \
      -not -path './node_modules*' \
      -not -path './.site-builder*' \
      -not -name '*.tmp' \
      2>/dev/null | sort | head -80 || true)

    if [ -n "$dir_tree" ]; then
      # Format as indented tree (simplified)
      formatted=$(echo "$dir_tree" | sed 's|^\./||' | sed 's|[^/]*/|  |g' || true)
      patch_auto_section "ARCHITECTURE.md" "directory-structure" "\`\`\`
  ${formatted}
  \`\`\`"
    fi
  fi

  # --- ARCHITECTURE.md: Dependencies ---
  if [ -f "ARCHITECTURE.md" ] && [ -f "package.json" ]; then
    deps=$(tr -d '\r' < package.json | awk '
      /"dependencies"/ { in_deps=1; next }
      /"devDependencies"/ { in_devdeps=1; next }
      in_deps && /\}/ { in_deps=0 }
      in_devdeps && /\}/ { in_devdeps=0 }
      in_deps && /"[^"]+":/ {
        gsub(/[",]/, ""); gsub(/^[ \t]+/, "");
        split($0, a, ": "); deps_list = deps_list "| " a[1] " | " a[2] " |\n"
      }
      in_devdeps && /"[^"]+":/ {
        gsub(/[",]/, ""); gsub(/^[ \t]+/, "");
        split($0, a, ": "); devdeps_list = devdeps_list "| " a[1] " | " a[2] " |\n"
      }
      END {
        if (deps_list) { printf "### Runtime\n\n| Package | Version |\n|---|---|\n%s\n", deps_list }
        if (devdeps_list) { printf "### Dev\n\n| Package | Version |\n|---|---|\n%s\n", devdeps_list }
      }
    ' 2>/dev/null || true)

    if [ -n "$deps" ]; then
      patch_auto_section "ARCHITECTURE.md" "dependencies" "$deps"
    fi
  fi

  # --- ARCHITECTURE.md: Build & Dev ---
  if [ -f "ARCHITECTURE.md" ] && [ -f "package.json" ]; then
    build_cmds=$(tr -d '\r' < package.json | awk '
      /"scripts"/ { in_scripts=1; next }
      in_scripts && /\}/ { in_scripts=0 }
      in_scripts && /"[^"]+":/ {
        gsub(/[",]/, ""); gsub(/^[ \t]+/, "");
        split($0, a, ": ");
        printf "npm run %s  # %s\n", a[1], a[2]
      }
    ' 2>/dev/null || true)

    if [ -n "$build_cmds" ]; then
      patch_auto_section "ARCHITECTURE.md" "build-dev" "\`\`\`bash
  ${build_cmds}
  \`\`\`"
    fi
  fi

  # --- BRAND.md: Design Tokens (from .site-builder/design-system.md) ---
  DESIGN_SYSTEM=".site-builder/design-system.md"
  if [ -f "BRAND.md" ] && [ -f "$DESIGN_SYSTEM" ]; then
    ds_content=$(tr -d '\r' < "$DESIGN_SYSTEM" || true)

    # Extract color tokens (lines between ### Colors and next ###)
    colors=$(echo "$ds_content" | awk '
      /^### Colors/ { found=1; next }
      found && /^###/ { exit }
      found { print }
    ' || true)
    [ -n "$colors" ] && patch_auto_section "BRAND.md" "color-tokens" "$colors"

    # Extract font stack (lines between ### Typography and next ###)
    fonts=$(echo "$ds_content" | awk '
      /^### Typography/ { found=1; next }
      found && /^###/ { exit }
      found { print }
    ' || true)
    [ -n "$fonts" ] && patch_auto_section "BRAND.md" "font-stack" "$fonts"

    # Extract spacing scale (lines between ### Spacing and next ###)
    spacing=$(echo "$ds_content" | awk '
      /^### Spacing/ { found=1; next }
      found && /^###/ { exit }
      found { print }
    ' || true)
    [ -n "$spacing" ] && patch_auto_section "BRAND.md" "spacing-scale" "$spacing"
  fi

  # --- Stage patched docs ---
  for f in ARCHITECTURE.md BRAND.md; do
    if [ -f "$f" ] && git diff --name-only 2>/dev/null | grep -qx "$f"; then
      git add "$f"
    fi
  done

  # Also auto-stage Layer 1 refreshed docs (CONTEXT.md, CLAUDE.md)
  for f in CONTEXT.md CLAUDE.md; do
    if [ -f "$f" ] && git diff --name-only 2>/dev/null | grep -qx "$f"; then
      git add "$f"
    fi
  done

  exit 0
  ```

  **Key design decisions in the script:**
  - `trap 'exit 0' EXIT` ensures exit 0 on any unexpected error, even with `set -e`.
  - Every file-reading operation pipes through `tr -d '\r'` for CRLF safety.
  - Missing files, missing markers, and parse failures all result in silent skips — never an error exit.
  - The script does NOT patch CLAUDE.md — CLAUDE.md's auto-markers exist for the nested-preservation rule (Layer 1 orchestrator), not for script patching.
  - Agent/phase counts are NOT patched — they are plugin-repo values set at install time.
  - The awk-based `patch_auto_section` function replaces only content between matching markers, leaving everything else untouched.
  - Auto-staging at the end covers both Layer 2 patched files (ARCHITECTURE.md, BRAND.md) and Layer 1 refreshed files (CONTEXT.md, CLAUDE.md).

- [x] **Step 2:** Run script template verification (per spec testing strategy):
  1. `sh -n skills/site-builder/reference/doc-refresh-script.sh` — must parse without errors. **PASS.**
  2. Create a scratch file with sample `<!-- auto:directory-structure -->` / `<!-- /auto:directory-structure -->` markers and known content between them. Run the `patch_auto_section` logic against it. Confirm only marker content is replaced and surrounding text is untouched. **PASS** — found and fixed a real bug during this step: `awk -v close=...` collides with gawk's builtin `close()` function ("cannot use gawk builtin `close' as variable name"), which made the awk call fail silently under `set -e` + `trap 'exit 0' EXIT` (exit 0, but no patching occurred). Renamed the awk vars `open`/`close` → `mstart`/`mend`. Re-ran: marker content replaced correctly, surrounding text untouched.
  3. Run the script in an empty scratch directory (no `ARCHITECTURE.md`, no `BRAND.md`, no `package.json`). Confirm exit code is 0. **PASS.**

- [x] **Step 3:** Verify POSIX compliance: no bash arrays, no `[[ ]]`, no herestrings, no process substitution. All conditionals use `[ ]`. Verify auto-marker names match Task 1 and Task 2: `auto:directory-structure`, `auto:dependencies`, `auto:build-dev`, `auto:color-tokens`, `auto:font-stack`, `auto:spacing-scale`.

- [x] **Step 4:** Commit: `feat(reference): add doc-refresh-script.sh pre-commit template for mechanical-facts patching`

---

## Phase 1 Complete

Three reference documents now define the full doc-refresh system:
- `brand-template.md` — BRAND.md template with auto-marker specs and population rules
- `doc-refresh.md` — agent-indexed gate design, mechanical-facts script design, ownership boundary rules
- `doc-refresh-script.sh` — the actual POSIX sh pre-commit script template

**Next:** `phase-2.md`
