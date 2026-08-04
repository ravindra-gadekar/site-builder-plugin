# Doc Refresh & BRAND.md — Design Spec

**Created:** 2026-08-04T16:45:00
**Status:** Draft
**Author:** AI + Ravindra Gadekar

## Overview

The site-builder plugin generates `CONTEXT.md`, `ARCHITECTURE.md`, and `CLAUDE.md` during `--init` and is supposed to keep them current as phases complete. In practice, the refresh mechanism is unreliable — it relies on prose footnotes in SKILL.md that get dropped under context pressure — and `BRAND.md` is entirely missing from the site-builder pipeline despite Phase 4 DESIGN producing a full design system. Additionally, Update Mode (post-completion add/remove/update requests) has zero doc-refresh step, so docs go stale the moment the user starts iterating after handoff.

This spec redesigns the two-layer doc-refresh system into a hybrid: a deterministic pre-commit script for mechanical facts (directory trees, dependency tables, design tokens, agent/phase counts) and an agent-indexed checklist gate for judgment content (domain model, conventions, architecture rationale). It also adds BRAND.md as a first-class managed document and inserts a hard doc-refresh gate into Update Mode.

## Architecture

### Three doc buckets

| Bucket | Docs | What's in them |
|---|---|---|
| **Managed root docs** | `CONTEXT.md`, `ARCHITECTURE.md`, `CLAUDE.md` | Project-wide domain model, architecture, Claude instructions |
| **Brand doc** (new) | `BRAND.md` | Design tokens: colors, typography, spacing, component patterns — sourced from `.site-builder/design-system.md` |
| **Pipeline artifacts** | `.site-builder/*.md` | Phase outputs — these are the *source of truth* that docs are derived from |

### Layer 1 redesign: Agent-indexed checklist gate

Replace phase-indexed "Doc refresh:" footnotes with an **agent-indexed mapping**. The refresh obligation follows the *agent that ran*, not the phase number. This means the same table works for both pipeline phases and Update Mode (which selects agents, not phases).

**Agent → doc mapping:**

| Agent | Docs it must refresh | Sections affected |
|---|---|---|
| discovery-agent | `CONTEXT.md` | Entities, Glossary, Data Flow |
| architect-agent | `CONTEXT.md`, `CLAUDE.md` | Conventions, Decisions; Tech Stack |
| developer-agent | `ARCHITECTURE.md`, `BRAND.md` | Directory Structure, Patterns, Entry Points, Dependencies; all tokens |
| designer-agent | `BRAND.md` | All sections (colors, typography, spacing, component patterns) |
| content-agent | `CONTEXT.md` | Glossary (new terms from content) |
| deploy-agent | `CLAUDE.md` | Deployment target, CI/CD |
| analytics-agent | `CLAUDE.md` | Analytics config reference |
| seo-indexing-agent | `CLAUDE.md` | Indexing config reference |
| social-integration-agent | `ARCHITECTURE.md` | Integrations |

**Gate enforcement:** After every agent completes (pipeline or Update Mode), the orchestrator must:
1. Read each doc listed for that agent
2. Verify the relevant sections reflect the agent's output
3. State what was checked ("ARCHITECTURE.md directory tree updated to reflect new `/api` route") before proceeding

This is the same "must state what you checked" pattern as Phase 7's audit quality gate — not a footnote, not optional.

### Layer 2 redesign: Mechanical-facts pre-commit script

A POSIX `sh` script replaces the staging-only hook. It handles **mechanical-fact sections** derivable from files on disk without judgment:

| Doc | Sections handled by script | Source |
|---|---|---|
| `ARCHITECTURE.md` | Directory Structure, Dependencies, Build & Dev | `find`, `package.json` |
| `BRAND.md` | Color tokens, Font stack, Spacing scale | `.site-builder/design-system.md` (grep for token blocks) |
| `CLAUDE.md` | Agent count, Phase count (inside marker block) | `ls agents/` count, `phases.md` grep |

The script runs at pre-commit time. It reads the source files, extracts the mechanical values, and patches only those sections using `<!-- auto:section-name -->` / `<!-- /auto:section-name -->` markers within each doc. Judgment sections are left untouched.

**Section ownership boundary:** Each auto-managed section is wrapped in its own `<!-- auto:* -->` markers. The script only writes inside these markers. The Layer 1 gate only writes outside them. Neither touches the other's territory.

### BRAND.md: New managed doc

- **Template** added to `reference/brand-template.md`
- **Created during Init** (Section 2.5, after ARCHITECTURE.md, before CLAUDE.md)
- **Populated** from existing CSS/Tailwind config if present; placeholder sections for greenfield projects
- **Refreshed** by designer-agent (Phase 4) and developer-agent (Phase 6) via the agent-indexed gate
- **Mechanical sections** (raw token values) also refreshed by the pre-commit script from `.site-builder/design-system.md`

### Update Mode: Hard doc-refresh gate

Update Mode's current 4-step flow becomes 5 steps:

1. Ask user what needs changing
2. Map requested changes to minimum set of agents
3. Run only those agents + audit loop for changed areas
4. **Doc Refresh Gate (new):** For each agent that ran in step 3, verify its docs per the agent-indexed mapping. Block deploy until verified.
5. Deploy through existing CI/CD pipeline

## Data Flow

### Pipeline flow (phases running in order)

```
Phase N agent runs
    ↓
Agent writes output to .site-builder/*.md
    ↓
Orchestrator hits phase boundary
    ↓
Layer 1 Gate fires:
    ├── Look up agent in agent→doc mapping
    ├── Read each mapped doc
    ├── Read the agent's .site-builder/ output
    ├── Update judgment sections (entities, conventions, rationale)
    ├── Verify sections match agent output
    └── State what was checked → proceed to next phase
    ↓
User makes commits during or after the phase
    ↓
Layer 2 Pre-commit script fires:
    ├── Read .site-builder/design-system.md → extract tokens → patch BRAND.md auto markers
    ├── Run find on project tree → patch ARCHITECTURE.md directory structure markers
    ├── Read package.json → patch ARCHITECTURE.md dependencies markers
    ├── Count agents/*.md → patch CLAUDE.md agent count markers
    └── git add all patched docs
    ↓
Commit includes both code changes AND fresh docs
```

### Update Mode flow (post-completion changes)

```
User asks to add/remove/update something
    ↓
Orchestrator selects minimum agent set
    ↓
Selected agents run, write to .site-builder/ and source files
    ↓
Orchestrator hits Doc Refresh Gate (step 4):
    ├── For EACH agent that ran:
    │   ├── Look up agent in agent→doc mapping
    │   ├── Read mapped docs + agent's .site-builder/ output
    │   ├── Update judgment sections
    │   └── Verify and state what was checked
    └── All agents' docs verified → unblock deploy
    ↓
User commits
    ↓
Layer 2 pre-commit script patches mechanical sections
    ↓
Deploy proceeds (step 5)
```

### Conflict prevention between layers

The two layers never write to the same lines. Enforced structurally via `<!-- auto:* -->` markers:

```markdown
## Directory Structure          ← Layer 1 (judgment: writes the intro sentence)

<!-- auto:directory-structure -->
src/
├── components/    # UI components
├── pages/         # Route pages
└── layouts/       # Page layouts
<!-- /auto:directory-structure -->

## Key Patterns                 ← Layer 1 (judgment: pattern descriptions)
```

Layer 2 script uses sed/awk to find markers, replace content between them, leave everything else untouched. Layer 1 (orchestrator/agent) never modifies content inside auto markers.

### Staleness windows

| Scenario | How long docs can be stale | Why acceptable |
|---|---|---|
| Mid-phase (agent still running) | Minutes | Agent hasn't finished producing the data yet |
| Between phase boundary and next commit | Until next commit | Layer 2 catches mechanical facts; Layer 1 already caught judgment facts at boundary |
| Outside a Claude session (manual code edits) | Until next commit | Layer 2 script still fires — mechanical facts stay fresh. Judgment sections may drift, caught on next pipeline run |
| Update Mode | Zero after step 4 | Hard gate blocks deploy until docs verified |

## File Changes

### New files

| File | Purpose |
|---|---|
| `skills/site-builder/reference/brand-template.md` | BRAND.md template + population rules |
| `skills/site-builder/reference/doc-refresh-script.sh` | POSIX sh pre-commit script template for mechanical-facts patching |

### Modified files

| File | What changes |
|---|---|
| `skills/site-builder/reference/doc-refresh.md` | Rewrite both layers: Layer 1 → agent-indexed gate; Layer 2 → mechanical-facts script with auto-markers. Add BRAND.md. Add section-ownership boundary rules. |
| `skills/site-builder/reference/doc-templates.md` | Add BRAND.md template pointer. Add `<!-- auto:* -->` marker specs to template sections. Update CLAUDE.md template Architecture Reference to include BRAND.md. |
| `skills/site-builder/reference/phases.md` | Expand Update Mode from 4 to 5 steps (add Doc Refresh Gate as step 4). Add agent→doc mapping table as reference. |
| `skills/site-builder/SKILL.md` | Init 2.5: add BRAND.md creation + expanded pre-commit hook. All phase sections: replace "Doc refresh:" footnotes with "Doc Gate:" checklist items. Phases 4, 5, 8, 10, 11: add missing doc-gate entries. Update Mode: reference 5-step flow. |
| `skills/site-builder/reference/handoff-checklist.md` | Add BRAND.md and "all auto-marker sections populated" to verification list. |
| `agents/designer-agent.md` | Add doc-gate obligation for BRAND.md (all sections). |
| `agents/developer-agent.md` | Add doc-gate obligation for BRAND.md alongside ARCHITECTURE.md. Remove stale `refresh-architecture.mjs` reference. |
| `agents/content-agent.md` | Add doc-gate obligation for CONTEXT.md Glossary. |
| `agents/analytics-agent.md` | Add doc-gate obligation for CLAUDE.md marker block. |
| `agents/seo-indexing-agent.md` | Add doc-gate obligation for CLAUDE.md marker block. |
| `agents/social-integration-agent.md` | Add doc-gate obligation for ARCHITECTURE.md integrations. |

## Error Handling

### Layer 1 Gate failures

| Failure | Recovery |
|---|---|
| Orchestrator skips gate (context pressure) | Layer 2 catches mechanical facts. Judgment sections stay stale until next agent run. |
| Doc file doesn't exist when gate fires | Gate creates it from template. Log: "Created missing [doc] from template." |
| Agent's `.site-builder/` output file is missing (phase skipped) | Skip refresh for that doc. Log: "No [file] found — skipping [doc] refresh." Do not create a doc with empty content. |
| Orchestrator states "checked" without actually updating (hallucinated compliance) | No programmatic defense. Mitigated by: (a) requiring the orchestrator to name what specifically changed; (b) Layer 2 catching the mechanical subset independently. |

### Layer 2 Script failures

| Failure | Recovery |
|---|---|
| Source file missing (`.site-builder/design-system.md`, `package.json`) | Skip that section's patching. Exit 0 — never block the commit. |
| Source file malformed (unparseable JSON) | Skip section. Log to stderr. Exit 0. |
| Auto-markers missing from doc file | Skip that section. Never write outside markers. Exit 0. |
| Script syntax error (bug in shipped template) | Pre-commit hook fails, `git commit` aborts. User can `git commit --no-verify` to bypass. |
| Windows without Git Bash sh | `.git/hooks/pre-commit` runs under Git Bash's sh. If unavailable, commit proceeds without hook. |

### Update Mode gate failures

| Failure | Recovery |
|---|---|
| Gate blocks deploy, user wants to ship anyway | Orchestrator offers: "Doc refresh incomplete for [list]. Deploy anyway, or let me finish the refresh first?" User can override. |
| No agents ran (manual change outside pipeline) | Skip step 4, proceed to deploy. Layer 2 still patches mechanical facts on commit. |

### Key principle

Layer 2 never blocks commits on doc-refresh failure. It exits 0 on every error path. A broken refresh script must never prevent a user from committing their actual code.

## Testing Strategy

Since this repo is Markdown-only (no runtime, no test framework), testing is structural verification.

### Script template verification

| What to test | How |
|---|---|
| Script parses without errors | `sh -n doc-refresh-script.sh` |
| Marker extraction works on sample docs | Create scratch doc with `<!-- auto:* -->` markers, run extraction logic, confirm only marker content replaced |
| Script exits 0 when source files missing | Run script in empty directory |
| POSIX compliance | `checkbashisms doc-refresh-script.sh` or manual review |

### Instruction consistency checks

| What to verify | How |
|---|---|
| Every agent in agent→doc mapping has matching doc-gate obligation in its `.md` file | Grep each agent file for "Doc Gate" |
| SKILL.md uses "Doc Gate:" not "Doc refresh:" | Grep for both strings — old string should have zero hits |
| BRAND.md referenced in all required locations | Grep doc-refresh.md, doc-templates.md, brand-template.md, SKILL.md Init 2.5, handoff-checklist.md, phases.md Update Mode, pre-commit script |
| Auto-marker names in templates match script expectations | Compare `<!-- auto:* -->` strings across doc-templates.md and doc-refresh-script.sh |
| Update Mode has 5 steps with step 4 as Doc Refresh Gate | Read phases.md |
| CLAUDE.md template includes BRAND.md in Architecture Reference | Read doc-templates.md Section 3 |

### Smoke test (manual, first client project run)

- [ ] BRAND.md created in project root during `--init`
- [ ] Pre-commit hook contains mechanical-facts script (not staging-only)
- [ ] Commit after Phase 4 DESIGN produces BRAND.md with real tokens
- [ ] Commit after Phase 6 DEVELOP produces ARCHITECTURE.md with accurate directory tree inside auto-markers
- [ ] Update Mode ("change the primary color") triggers doc refresh gate before deploy

## Acceptance Criteria

- [ ] `BRAND.md` template exists in `reference/brand-template.md` with sections for colors, typography, spacing, and component patterns
- [ ] `SKILL.md` Init Section 2.5 creates `BRAND.md` during init (after ARCHITECTURE.md, before CLAUDE.md), populated from existing CSS/Tailwind config or placeholders for greenfield
- [ ] `reference/doc-refresh.md` contains an agent-indexed mapping table (agent → docs → sections) replacing the old phase-indexed table
- [ ] `reference/doc-refresh.md` Layer 1 describes the checklist gate pattern: orchestrator must name what specifically changed before proceeding
- [ ] `reference/doc-refresh.md` Layer 2 describes the mechanical-facts pre-commit script with `<!-- auto:* -->` marker ownership rules
- [ ] `reference/doc-refresh-script.sh` exists as a POSIX sh script template that patches mechanical sections (directory tree, dependencies, build commands, brand tokens, agent/phase counts) at commit time
- [ ] `reference/doc-refresh-script.sh` exits 0 on all error paths (missing files, parse failures, missing markers)
- [ ] `SKILL.md` phase sections for all 11 phases have "Doc Gate:" checklist items instead of "Doc refresh:" footnotes
- [ ] Phases 4, 5, 8, 10, 11 — which previously had no doc-refresh step — now have doc-gate entries matching the agent-indexed mapping
- [ ] `reference/phases.md` Update Mode is 5 steps, with step 4 being a hard Doc Refresh Gate that blocks deploy until verified
- [ ] `reference/doc-templates.md` adds `<!-- auto:* -->` markers to the mechanical sections of CONTEXT.md, ARCHITECTURE.md, CLAUDE.md, and BRAND.md templates
- [ ] `reference/doc-templates.md` CLAUDE.md template includes BRAND.md in the Architecture Reference lookup order
- [ ] `agents/designer-agent.md` has doc-gate obligation for BRAND.md (all sections)
- [ ] `agents/developer-agent.md` has doc-gate obligation for BRAND.md alongside ARCHITECTURE.md
- [ ] `agents/content-agent.md` has doc-gate obligation for CONTEXT.md Glossary
- [ ] `agents/analytics-agent.md` has doc-gate obligation for CLAUDE.md marker block
- [ ] `agents/seo-indexing-agent.md` has doc-gate obligation for CLAUDE.md marker block
- [ ] `agents/social-integration-agent.md` has doc-gate obligation for ARCHITECTURE.md integrations
- [ ] `reference/handoff-checklist.md` includes BRAND.md and "all auto-marker sections populated" verification
- [ ] Pre-commit script template is POSIX-compliant (no bashisms)
- [ ] Section ownership boundary is clean: script only writes inside `<!-- auto:* -->` markers, orchestrator/agents only write outside them
