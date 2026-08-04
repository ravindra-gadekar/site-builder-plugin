# Site Builder Agents

A Claude Code skills plugin that installs a team of 15 specialized AI agents and a master orchestrator into any client website project. Handles the complete website design lifecycle — from business analysis through deployment.

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
/site-builder [--init] [--auto] [--parallel]
```

| Flag | Effect |
|------|--------|
| *(none)* | Full interactive pipeline — asks everything, auto-running Init first if not yet complete |
| `--init` | Runs Init only (git check, `.gitignore` setup, MCP configuration), then exits. Does not start the pipeline. |
| `--auto` | Modifier — skips optional prompts (optional MCP setup, demo scope wording, framework elaboration). Never skips approval gates. |
| `--parallel` | Modifier — dispatches read-only agents simultaneously wherever a phase supports it. |

Flags are composable, e.g. `/site-builder --auto --parallel`. `--init` takes priority — if combined with `--auto`/`--parallel`, only Init runs; re-run `/site-builder [--auto] [--parallel]` afterward to start the pipeline. Unknown flags are ignored with a log notice, never a hard failure.

The orchestrator detects your project state and guides you through the pipeline.

## Prerequisites

| Requirement | Status | Purpose |
|------------|--------|---------|
| Git initialized | **Required** | Version control for generated code |
| context7 MCP | **Required** | Developer agent fetches current framework docs |
| GitHub MCP | **Required** (when remote exists) | Phase-boundary PR creation; auto-configured during Init |
| Image generation MCP | Recommended | Content agent generates images (otherwise produces briefs) |
| Analytics MCP | Optional | Centralized analytics connector management |

## Build Modes

Choose a mode when starting the pipeline (`/site-builder`, after Init):

| Mode | PR target | Pages | Use case |
|------|-----------|-------|----------|
| **Demo** | `demo` (created lazily on the first phase-boundary PR) | Partial or full | Client previews, prospecting unknown clients |
| **Prod** | `DEPLOY_BRANCH` (or default branch if none) | All pages | Direct to production |

### How it works

- All pipeline work happens on a single branch, `local-dev` — the orchestrator never checks out `demo`, `prod`, or any other branch.
- **Demo** — phase-boundary PRs target `demo`, created lazily the first time one is needed (not upfront). Production is never touched until you say "make it prod," which promotes via a PR from `demo` to `DEPLOY_BRANCH` after verifying every demo PR is already merged.
- **Prod** — phase-boundary PRs target `DEPLOY_BRANCH` directly. Use when you're confident and ready to go live.
- **Both modes** use the same flow: commit on `local-dev` → push to `feature/<name>` → PR to the mode's base branch → squash merge. `local-dev` itself is never reset and never pushed. Never push directly to the base branch.

### Branch detection

The orchestrator detects both the **default branch** (GitHub base) and the **CI/CD deploy branch** (what triggers production deployment). They may be different — e.g., `develop` as default and `production` as deploy. The default branch is treated as the "golden" branch — only post-production tested, bug-free code goes there.

## What It Does

### 11-Phase Pipeline

```
Phase 1: DISCOVER       → Business analysis, competitor research, codebase inventory, document extraction
Phase 2: ARCHITECT      → Tech stack confirmation, site map, URL structure, components
Phase 3: PREPARE        → Clean old files, scaffold new project, set up .gitignore
Phase 4: DESIGN         → Visual identity, design tokens, wireframes, anti-AI-look validation
Phase 5: CONTENT        → Page copy, meta tags, image planning (real assets first)
Phase 6: DEVELOP        → Working website code (chunked: pages → SEO → performance → analytics scaffolding)
Phase 7: AUDIT          → 6 parallel quality checks with fix loop (max 3 cycles)
Phase 8: INTEGRATE      → Social media setup (all optional/skippable)
Phase 9: DEPLOY         → Hosting-agnostic CI/CD pipeline + staging deployment
Phase 10: ANALYTICS     → Real credentials injected, tracking verified on the live URL
Phase 11: AUTO-INDEXING → Git-derived sitemap lastmod, inline IndexNow CI notification, RSS/Atom feed
```

### Approval Gates

6 user approval gates (Discover, Architect, Design, Deploy, Analytics, Auto-Indexing) and 1 quality gate (all 6 audits must pass).

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

When migrating to a new framework, the Phase 3 PREPARE phase handles cleanup and scaffolding. Working on `local-dev` (with phase-boundary PRs, never a direct push) keeps original code safe on the production branch. Reference old files via `git show` during migration. If it fails, the orchestrator can discard the unpushed `local-dev` commits and start fresh — production is untouched either way.

## 15 Agents

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

### Indexing
| # | Agent | Model | Role |
|---|-------|-------|------|
| 15 | seo-indexing-agent | Sonnet | Git-derived sitemap lastmod, inline IndexNow CI notification, RSS/Atom feed |

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

All git operations are centralized in the orchestrator, adopting the
Fullstack Dev `/git` skill's conventions (commit format, `<type>/<name>`
branch naming, universal stash safety). Agents produce files — they never
commit, push, or create PRs. Remote name is detected dynamically (not
hardcoded to `origin`). Everything happens on a single branch, `local-dev`
— the orchestrator never checks out `demo`, `prod`, or any other branch.

**With remote:** Commits happen per sub-task locally on `local-dev`. PRs
happen at phase boundaries (~7-9 PRs per build, not per-commit). Squash
merge keeps clean phase-level commits on the base branch. `local-dev`
itself is never reset — the next phase boundary just pushes the next batch
of commits to a new feature branch.

```
1. Orchestrator commits locally on local-dev
2. At phase boundary: push to feature branch (git push REMOTE_NAME local-dev:feature/<phase-name>)
3. Create PR targeting the mode's base branch (demo/DEPLOY_BRANCH)
4. Squash merge PR
5. local-dev is untouched -- next phase boundary pushes the next batch
```

**Branch mapping:**

- Demo mode: PR target = `demo` (created lazily on the first phase-boundary PR — never during Init or Branch Setup)
- Prod mode: PR target = `DEPLOY_BRANCH`

No direct pushes to any base branch, ever.

**Without remote:** Commits happen locally with no push or PR. If a remote is added later, accumulated commits are pushed at the next phase boundary.

### Promotion (demo → production)

When user says "make it prod": the orchestrator first verifies every
phase-boundary PR targeting `demo` is already merged (offering to
auto-merge any that are still open), then:
- **With remote:** PR from `demo` → `DEPLOY_BRANCH` (goes live)
- **Without remote:** nothing to promote remotely — mode simply flips to `prod` for future phase-boundary work
- Post-production testing
- After confirmed stable → sync `DEPLOY_BRANCH` → `DEFAULT_BRANCH` (golden branch updated)

Prod mode has no promotion step — code is already live via phase-boundary PRs targeting `DEPLOY_BRANCH` directly.

### Prod mode sync

If `DEPLOY_BRANCH` differs from `DEFAULT_BRANCH`, the orchestrator periodically asks if post-production testing passed and offers to sync tested code back to the default branch via PR.

## Project Structure

### Plugin repo structure

```
site-builder-plugin/
├── agents/                          # 15 specialist agents
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
│   ├── deploy-agent.md
│   └── seo-indexing-agent.md
└── skills/
    └── site-builder/
        ├── SKILL.md                 # Master orchestrator
        ├── reference/               # Shared knowledge
        │   ├── phases.md
        │   ├── quality-gates.md
        │   ├── design-principles.md
        │   ├── audit-standards.md
        │   ├── handoff-checklist.md
        │   ├── gitignore.md         # Self-contained .gitignore generation
        │   ├── doc-templates.md     # CLAUDE.md/CONTEXT.md/ARCHITECTURE.md templates
        │   └── doc-refresh.md       # Two-layer doc refresh (pipeline + pre-commit hook)
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
