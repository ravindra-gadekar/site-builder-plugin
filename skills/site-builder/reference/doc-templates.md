# Document Templates

Templates for project documentation files generated during `/site-builder
--init`. These make the client project self-documenting for Claude Code
sessions — the orchestrator, agents, and any future maintainer all benefit
from accurate project docs.

---

## How Templates Are Used

1. **Init** creates files using these templates during `/site-builder --init`
   (Section 2.5, after gitignore, before MCP configuration).
2. **Orchestrator** populates placeholder sections by scanning the project's
   existing files — package.json, config files, directory structure, etc.
3. **Refresh** updates existing docs surgically during the pipeline and on
   commits — it does not regenerate from templates. Templates are only used
   for initial creation.

Placeholder text in angle brackets (`<...>`) is replaced with real content.
Sections marked `(conditional)` are only included when the condition is met.

---

## 1. CONTEXT.md

**Location:** Project root (`CONTEXT.md`)
**Purpose:** Domain model, data flow, and conventions. Gives Claude the
business context to make informed decisions throughout the pipeline.
**Created by:** Init (Section 2.5)
**Updated by:** Orchestrator — refreshed after Phase 1 DISCOVER (project
brief populates the domain model) and Phase 2 ARCHITECT (technical
decisions populate conventions).

### Template

```markdown
# CONTEXT.md

## Domain Model

### Entities

| Entity | Description | Source |
|---|---|---|
| <EntityName> | <what it represents in the business> | <file or section where defined> |

### Relationships

<how entities relate — e.g., "A Business has many Services, each Service
has a landing page">

### Glossary

| Term | Meaning |
|---|---|
| <term> | <definition used consistently across the project> |

## Data Flow

<how content and data move through the website — CMS, static files,
API calls, form submissions, analytics events>

### Request Lifecycle

1. <step 1 — e.g., visitor requests page from CDN/server>
2. <step 2 — e.g., framework renders page with content from CMS/static>
3. <step 3 — e.g., client-side JS hydrates interactive components>

### Integrations (if applicable)

<third-party services the site talks to — CMS, payment, booking, email,
analytics, search>

## Conventions

### Naming

| Context | Convention | Example |
|---|---|---|
| Pages | <pattern> | <example> |
| Components | <pattern> | <example> |
| Styles | <pattern> | <example> |

### Patterns

<architectural patterns in use — e.g., component-based UI, content
collections, island architecture, SSR vs SSG>

### Decisions

<key technical decisions and their rationale — e.g., "Chose Astro for
static-first performance; images served via CDN with lazy loading">
```

### Population Rules

- **Entities** are seeded from the business type (e.g., restaurant →
  Menu, Location, Reservation; SaaS → Plan, Feature, User). Populated
  after Phase 1 DISCOVER from the project brief.
- **Glossary** is seeded from entity names and industry terms found in
  the project brief.
- **Data Flow** is inferred from the framework choice (SSG vs SSR),
  any CMS/API integrations, and form handlers.
- **Conventions** are populated after Phase 2 ARCHITECT from the
  architecture decisions.

---

## 2. ARCHITECTURE.md

**Location:** Project root (`ARCHITECTURE.md`)
**Purpose:** Repo-specific architecture — directory structure, key
patterns, entry points, dependencies. Lets Claude navigate the project
without reading every file.
**Created by:** Init (Section 2.5)
**Updated by:** Orchestrator — refreshed after Phase 3 PREPARE (scaffold
creates the directory structure) and Phase 6 DEVELOP (components, pages,
and integrations finalize the architecture).

### Template

```markdown
# Architecture

## Purpose

<one-paragraph description of what this website does and who it serves>

## Directory Structure

<!-- auto:directory-structure -->
```text
<project-root>/
├── <dir>/          # <purpose>
├── <dir>/          # <purpose>
└── <file>          # <purpose>
```
<!-- /auto:directory-structure -->

## Key Patterns

### <Pattern Name>

<description — e.g., "File-based routing", "Content collections",
"Island architecture">

**Example:**
```
<brief code or file structure example>
```

## Entry Points

| Entry Point | Type | Purpose |
|---|---|---|
| <file or route> | <page/layout/API/config> | <what it handles> |

## Dependencies

<!-- auto:dependencies -->
### Runtime

| Dependency | Purpose |
|---|---|
| <name> | <what it provides — e.g., UI framework, CSS, routing> |

### Dev

| Dependency | Purpose |
|---|---|
| <name> | <what it provides — e.g., bundler, linter, testing> |
<!-- /auto:dependencies -->

## Build & Dev

<!-- auto:build-dev -->
```bash
<install command>     # install dependencies
<dev command>         # start dev server
<build command>       # build for production
<preview command>     # preview production build locally
```
<!-- /auto:build-dev -->

## Testing

| Type | Framework | Location |
|---|---|---|
| <unit/e2e/visual> | <framework> | <directory> |
```

### Population Rules

- **Directory Structure** is generated from a depth-2 listing of the
  project, excluding `node_modules/`, `.git/`, and gitignored paths.
  If the project is empty at init time, this section is left as a
  placeholder and populated after Phase 3 PREPARE scaffolds the project.
- **Key Patterns** are inferred from the framework (e.g., Astro →
  content collections + island architecture; Next.js → App Router +
  server components).
- **Entry Points** are detected from route files, layout files, config
  files, and API routes.
- **Dependencies** are read from `package.json` if it exists. Split
  into runtime (`dependencies`) and dev (`devDependencies`). Only
  significant dependencies — not every transitive package.
- **Build & Dev** commands come from `package.json` scripts. If no
  `package.json` exists yet, populated after Phase 3 PREPARE.

---

## 3. CLAUDE.md

**Location:** Project root (`CLAUDE.md`)
**Purpose:** Instructions for Claude Code. The primary file Claude reads
to understand the project and how to work within it.
**Created by:** Init (Section 2.5)
**Updated by:** Orchestrator — marker block content refreshed after
Phase 2 ARCHITECT (tech stack confirmed), Phase 3 PREPARE (build
commands known), and Phase 9 DEPLOY (deployment config known).

### Important: Marker Block — Never Overwrite User Content

If a `CLAUDE.md` already exists, the orchestrator **MUST NOT overwrite
it**. Instead, it appends its sections inside a marker block at the end
of the file. The markers allow the orchestrator to find and update its
own sections without touching user content.

```markdown
<!-- site-builder:start -->
<!-- site-builder:end -->
```

If no `CLAUDE.md` exists, generate the full file with the marker block.

### Template (Full Generation)

When no `CLAUDE.md` exists:

```markdown
# CLAUDE.md

## Project Overview

**<Project Name>** — <one-line description from project brief or repo>.

<!-- site-builder:start -->

## Tech Stack

<framework, language, CSS approach, key libraries — summarized>

<!-- auto:build-commands -->
## Build & Development Commands

```bash
<install command>     # install dependencies
<dev command>         # start dev server
<build command>       # build for production
<preview command>     # preview production build
```
<!-- /auto:build-commands -->

## Git Workflow

1. Work on `local-dev` branch
2. Commit using Conventional Commits: `<type>(<scope>): <summary>`
3. Create PRs targeting `<target branch>` (demo or prod, depending on
   build mode)

## Architecture Reference

When you need to understand the project:

1. **Read CONTEXT.md** — domain model, data flow, conventions
2. **Read ARCHITECTURE.md** — directory structure, patterns, entry points
3. **Read BRAND.md** — design tokens, typography, component patterns
4. **Read `.site-builder/project-brief.md`** — business requirements
5. **Read `.site-builder/site-architecture.md`** — technical decisions
6. **Read source files** — only when the above don't answer your question

## Site Builder Pipeline State

Pipeline artifacts are in `.site-builder/`. Key files:
- `status.md` — current pipeline phase and configuration
- `project-brief.md` — Phase 1 DISCOVER output
- `site-architecture.md` — Phase 2 ARCHITECT output
- `design-system.md` — Phase 4 DESIGN output
- `content/` — Phase 5 CONTENT output (per-page content files)
- `audit-reports/` — Phase 7 AUDIT output

<!-- site-builder:end -->
```

### Template (Append to Existing)

When `CLAUDE.md` already exists, append only the marker block:

```markdown

<!-- site-builder:start -->

## Tech Stack

<same content as above, starting from Tech Stack>

<!-- site-builder:end -->
```

### Marker Block Rules

1. **Finding the block:** Search for `<!-- site-builder:start -->` and
   `<!-- site-builder:end -->`.
2. **Updating:** Replace everything between the markers (exclusive of
   the markers themselves).
3. **Never touch content outside the markers.** That belongs to the user.
4. **Preserve nested auto-markers.** When replacing content between the
   site-builder markers, the orchestrator must preserve any nested
   `<!-- auto:* -->` / `<!-- /auto:* -->` blocks and their content. Replace
   only the text outside auto-markers within the site-builder block.
5. **Blank line before start marker** and after end marker for clean
   rendering.

**Note on `auto:build-commands`:** Unlike other `auto:*` markers (which
are owned by the pre-commit script / Layer 2), `auto:build-commands` in
CLAUDE.md is owned by the developer-agent gate (Layer 1). It exists
solely so its content survives site-builder marker-block replacement —
the pre-commit script never patches CLAUDE.md. See
`reference/doc-refresh.md` Section 4 for the full ownership boundary.

---

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

---

## File Creation Order

During Init, docs are created in this order:

1. `CONTEXT.md` — domain model (populated with whatever is known from
   existing project files; enriched later by Phase 1 DISCOVER)
2. `ARCHITECTURE.md` — directory structure and patterns (populated from
   current project state; enriched after Phase 3 PREPARE scaffold)
3. `BRAND.md` — design tokens (populated from existing CSS/Tailwind config
   or placeholders; enriched by Phase 4 DESIGN)
4. `CLAUDE.md` — last, because it references the other docs

This order ensures each file can reference files created before it.

---

## Population at Init Time vs. Pipeline Enrichment

At init time, the project may be empty (greenfield) or have an existing
codebase. The orchestrator populates whatever it can from what's on disk:

| Project state | CONTEXT.md | ARCHITECTURE.md | BRAND.md | CLAUDE.md |
|---|---|---|---|---|
| Empty (only `.git/`) | Placeholder sections | Placeholder sections | Placeholder tokens | Skeleton with marker block |
| Existing codebase | Entities from file names, data flow from routes | Full directory listing, deps from package.json, build commands | Tokens from CSS/Tailwind config | Populated tech stack and commands |

In both cases, the pipeline enriches these docs as it progresses:
- Phase 1 DISCOVER → CONTEXT.md (entities, glossary, data flow)
- Phase 2 ARCHITECT → CONTEXT.md (conventions, decisions), CLAUDE.md (tech stack confirmed)
- Phase 3 PREPARE → ARCHITECTURE.md (directory structure, patterns, entry points), CLAUDE.md (build commands)
- Phase 4 DESIGN → BRAND.md (all design tokens and component patterns from design-system.md)
- Phase 6 DEVELOP → ARCHITECTURE.md (finalized component tree, routes)
- Phase 9 DEPLOY → CLAUDE.md (deployment info)
