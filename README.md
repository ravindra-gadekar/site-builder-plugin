# Site Builder Agents

A Claude Code skills plugin that installs a team of 14 specialized AI agents and a master orchestrator into any client website project. Handles the complete website design lifecycle — from business analysis through deployment.

Developed by Ravindra Gadekar.

## Quick Start

### Install

```bash
npx skills add https://github.com/ravindra-gadekar/site-builder-plugin --skill site-builder
```

### Update

```bash
npx skills update site-builder
```

### Run

```
/site-builder
```

The orchestrator detects your project state and guides you through the pipeline.

## Prerequisites

| Requirement | Status | Purpose |
|------------|--------|---------|
| Git initialized | **Required** | Version control for generated code |
| context7 MCP | **Required** | Developer agent fetches current framework docs |
| Image generation MCP | Recommended | Content agent generates images (otherwise produces briefs) |
| Analytics MCP | Optional | Centralized analytics connector management |

## Build Modes

Choose a mode when starting the pipeline:

| Mode | Branch | Pages | Use case |
|------|--------|-------|----------|
| **Demo** | `demo` | Partial or full | Client previews, prospecting unknown clients |
| **Stage** | `stage` | All pages | Full development and testing before production |
| **Prod** | `DEPLOY_BRANCH` | All pages | Direct to production (no safety branch) |

### How it works

- **Demo & Stage** — working branch is created from the default branch, production is never touched. When ready, say "make it prod" to promote.
- **Prod** — code goes directly to the CI/CD deploy branch. Use when you're confident and ready to go live.
- **All modes** use the same git workflow: commit locally → push to `feature/<name>` branch → PR to base → merge → sync. Never push directly to the base branch.

### Branch detection

The orchestrator detects both the **default branch** (GitHub base) and the **CI/CD deploy branch** (what triggers production deployment). They may be different — e.g., `develop` as default and `production` as deploy. The default branch is treated as the "golden" branch — only post-production tested, bug-free code goes there.

## What It Does

### 9-Phase Pipeline

```
Phase 1: DISCOVER    → Business analysis, competitor research, codebase inventory, document extraction
Phase 2: ARCHITECT   → Tech stack confirmation, site map, URL structure, components
Phase 3: PREPARE     → Clean old files, scaffold new project, set up .gitignore
Phase 4: DESIGN      → Visual identity, design tokens, wireframes, anti-AI-look validation
Phase 5: CONTENT     → Page copy, meta tags, image planning (real assets first)
Phase 6: DEVELOP     → Working website code (chunked: pages → SEO → performance)
Phase 7: AUDIT       → 6 parallel quality checks with fix loop (max 3 cycles)
Phase 8: INTEGRATE   → Social media + analytics setup (all optional/skippable)
Phase 9: DEPLOY      → CI/CD pipeline + staging deployment
```

### Approval Gates

4 user approval gates (Discover, Architect, Design, Deploy) and 1 quality gate (all 6 audits must pass).

### Document Parsing & Image Extraction

The discovery agent extracts images and text from client-provided documents:

| Document type | Image extraction | Text extraction |
|---------------|-----------------|-----------------|
| Digital PDF | PyMuPDF extracts embedded images | Read tool reads text |
| Scanned document | Claude vision + Python PIL cropping | Claude reads text from image |
| Direct image files | Copy and catalog | Claude reads any text in image |

Extracted assets are saved to `.site-builder/assets/extracted/` and prioritized over AI-generated images throughout the pipeline.

### Existing Integration Confirmation

When the project has existing code, the discovery agent presents ALL found integrations (CI/CD, analytics, tracking pixels, email configs, maps, chat widgets) to the user for confirmation. Each gets a keep/update/remove/skip decision — nothing is blindly carried forward.

### Optional Integrations

All social profiles, analytics, and tracking setup is skippable. Portfolios and single-page sites don't need Google Business Profile. The user decides what to set up — skipped items can be added later.

### Update Mode

Re-run `/site-builder` on a completed project to make changes. The orchestrator detects what exists and runs only the relevant agents.

### Tech Stack Migration

When migrating to a new framework, the Phase 3 PREPARE phase handles cleanup and scaffolding. The working branch (demo/stage) keeps original code safe on the production branch. Reference old files via `git show` during migration. If it fails, delete the branch and start fresh.

## 14 Agents

### Build Team
| # | Agent | Model | Role |
|---|-------|-------|------|
| 1 | discovery-agent | Sonnet | Business analyst — requirements, competitors, codebase inventory, document extraction |
| 2 | architect-agent | Opus | Technical architect — tech stack, site map, components |
| 3 | designer-agent | Opus | Creative director — design tokens, wireframes, anti-AI-look |
| 4 | content-agent | Opus | Copywriter — page copy, meta content, image planning |
| 5 | developer-agent | Sonnet | Frontend engineer — builds the website |

### Audit Squad (run in parallel)
| # | Agent | Model | Checks |
|---|-------|-------|--------|
| 6 | seo-audit-agent | Haiku | Titles, meta, headings, links, sitemap, robots, canonicals |
| 7 | technical-audit-agent | Haiku | Performance, images, mobile, security, code quality |
| 8 | content-quality-agent | Haiku | E-E-A-T, readability, depth, uniqueness, AI detection |
| 9 | ai-search-agent | Haiku | llms.txt, citability, FAQ format, brand signals |
| 10 | schema-audit-agent | Haiku | JSON-LD validation, required schemas, rich results |
| 11 | accessibility-audit-agent | Haiku | WCAG 2.1 AA — contrast, keyboard, ARIA, forms |

### Integration Team
| # | Agent | Model | Role |
|---|-------|-------|------|
| 12 | social-integration-agent | Sonnet | Social profile linking, share buttons, OG meta |
| 13 | analytics-agent | Sonnet | GA4, GSC, Bing Webmaster, tracking events, consent |
| 14 | deploy-agent | Sonnet | CI/CD pipeline, staging deploy, rollback plan |

## Framework Support

Framework-agnostic with adapter files for:
- **Astro** — recommended for static marketing sites (default)
- **Next.js** — when SSR or dynamic features needed
- **Vue/Nuxt** — for Vue ecosystem preference
- **React SPA** — only when specifically required

## Supported Website Types (v1)

Business and marketing sites: homepage, about, services, contact, blog, case studies, legal pages.

**Planned for later:** e-commerce, portfolios, SaaS landing pages, multi-language.

## Git Workflow

All git operations are centralized in the orchestrator. Agents produce files — they never commit, push, or create PRs. Remote name is detected dynamically (not hardcoded to `origin`).

**With remote:** Commits happen per sub-task locally on the working branch (`demo`/`stage`/`prod`). PRs happen at phase boundaries (~7-9 PRs per build, not per-commit). Squash merge keeps clean phase-level commits on the base branch.

```
1. Orchestrator commits locally on the working branch (demo/stage/prod)
2. At phase boundary: push to feature branch (git push REMOTE_NAME HEAD:feature/<phase-name>)
3. Create PR targeting the base branch (demo/stage/DEPLOY_BRANCH)
4. Squash merge PR
5. Sync local: git reset --hard REMOTE_NAME/<base-branch>
```

**Branch mapping:**

- Demo mode: working branch = `demo`, PR target = `demo`
- Stage mode: working branch = `stage`, PR target = `stage`
- Prod mode: working branch = `prod`, PR target = `DEPLOY_BRANCH`

No direct pushes to any base branch, ever.

**Without remote:** Commits happen locally with no push or PR. If a remote is added later, accumulated commits are pushed at the next phase boundary.

### Promotion (demo/stage → production)

When user says "make it prod":
- **With remote:** PR from working branch → `DEPLOY_BRANCH` (goes live)
- **Without remote:** Local merge of working branch into `DEFAULT_BRANCH`
- Post-production testing
- After confirmed stable → sync `DEPLOY_BRANCH` → `DEFAULT_BRANCH` (golden branch updated)

### Prod mode sync

If `DEPLOY_BRANCH` differs from `DEFAULT_BRANCH`, the orchestrator periodically asks if post-production testing passed and offers to sync tested code back to the default branch via PR.

## Project Structure

### Plugin repo structure

```
site-builder-plugin/
├── agents/                          # 14 specialist agents
│   ├── discovery-agent.md
│   ├── architect-agent.md
│   ├── designer-agent.md
│   ├── content-agent.md
│   ├── developer-agent.md
│   ├── seo-audit-agent.md
│   ├── technical-audit-agent.md
│   ├── content-quality-agent.md
│   ├── ai-search-agent.md
│   ├── schema-audit-agent.md
│   ├── accessibility-audit-agent.md
│   ├── social-integration-agent.md
│   ├── analytics-agent.md
│   └── deploy-agent.md
└── skills/
    └── site-builder/
        ├── SKILL.md                 # Master orchestrator
        ├── reference/               # Shared knowledge
        │   ├── phases.md
        │   ├── quality-gates.md
        │   ├── design-principles.md
        │   ├── audit-standards.md
        │   └── handoff-checklist.md
        └── adapters/                # Framework-specific patterns
            ├── astro.md
            ├── nextjs.md
            ├── vue.md
            └── react.md
```

After installation via `npx skills add`, agents are available as agent types and the `/site-builder` skill is registered.

### Working directory (created per project)

```
.site-builder/                       # Project data (not overwritten by plugin updates)
├── project-brief.md                 # Discovery output
├── site-architecture.md             # Architect output
├── design-system.md                 # Designer output
├── content-plan.md                  # Content strategy
├── content/                         # Per-page content files
├── assets/
│   └── extracted/                   # Images & text extracted from documents
├── audit-reports/                   # 6 audit reports
├── integration-reports/             # Social, analytics, deploy reports
└── status.md                        # Pipeline state for resumability
```

## License

MIT — Ravindra Gadekar 2026
