# Pipeline Phases

The site-builder pipeline has 11 sequential phases. Each phase maps to one or more specialist agents. The orchestrator runs phases in order, managing gates between them.

## Phase Definitions

### Phase 1: DISCOVER
- **Agent:** discovery-agent
- **Purpose:** Gather business requirements, analyze competitors, inventory existing codebase, AND perform Environment Inventory (source tech stack detection, server config parsing, sitemap extraction, CI/CD extraction, hosting inference, WordPress-specific detection)
- **Inputs:** Repo code (always), live URL (optional), user documents (optional), interactive interview
- **Output:** `.site-builder/project-brief.md` (now includes `## Environment & Migration Assessment` section with parsed configs, sitemap URLs, CI/CD categorization, and hosting type)
- **Gate:** USER APPROVAL — orchestrator pauses, presents brief (including hosting compatibility warning if applicable), waits for user sign-off
- **Duration estimate:** 15-25 minutes (depends on interview depth and environment complexity)

### Phase 2: ARCHITECT
- **Agent:** architect-agent
- **Purpose:** Technical architecture decisions — tech stack confirmation (now hosting-aware), site map, component tree, integrations, AND cross-check URL redirect map against old sitemap URLs
- **Inputs:** `.site-builder/project-brief.md` (including Environment & Migration Assessment), framework choice from `status.md`, hosting compatibility decision from `status.md`
- **Output:** `.site-builder/site-architecture.md` (includes `## Files to Preserve`, `## Hosting Context`, and orphaned URL warnings if applicable)
- **Gate:** USER APPROVAL — user reviews architecture decisions (including any orphaned URL flags)
- **Duration estimate:** 5-15 minutes

### Phase 3: PREPARE
- **Agent:** developer-agent (narrowed scaffold spawn) + orchestrator (cleanup)
- **Purpose:** Clean old website files (preserving server config files for deploy-agent), scaffold new project with selected framework, set up .gitignore
- **Inputs:** `.site-builder/site-architecture.md` (folder structure, Files to Preserve), framework from `status.md`
- **Output:** Clean working tree with scaffolded project, `.gitignore`, passing `npm run build`. Server config files (`.htaccess`, `web.config`, `nginx.conf`) preserved for deploy-agent translation.
- **Gate:** None (mechanical, already approved via framework choice + architecture)
- **Duration estimate:** 5-10 minutes

### Phase 4: DESIGN
- **Agent:** designer-agent
- **Purpose:** Visual identity — design tokens, component patterns, wireframes, anti-AI-look validation
- **Inputs:** `.site-builder/project-brief.md`, `.site-builder/site-architecture.md`
- **Output:** `.site-builder/design-system.md`
- **Gate:** USER APPROVAL — user reviews visual direction
- **Duration estimate:** 10-20 minutes

### Phase 5: CONTENT
- **Agent:** content-agent
- **Purpose:** Write all page copy, meta content, image briefs, content strategy
- **Inputs:** `.site-builder/project-brief.md`, `.site-builder/site-architecture.md`, `.site-builder/design-system.md`
- **Output:** `.site-builder/content-plan.md`, `.site-builder/content/*.md` (one file per page)
- **Gate:** None (flows directly into DEVELOP)
- **Duration estimate:** 15-30 minutes

### Phase 6: DEVELOP
- **Agent:** developer-agent
- **Purpose:** Build the working website — scaffold, components, pages, SEO, performance
- **Inputs:** `.site-builder/site-architecture.md`, `.site-builder/design-system.md`, `.site-builder/content/*.md`, framework adapter
- **Output:** Working website code in repo root
- **Gate:** None (flows directly into AUDIT)
- **Duration estimate:** 30-60 minutes

### Phase 7: AUDIT (parallel)
- **Agents:** seo-audit-agent, technical-audit-agent, content-quality-agent, ai-search-agent, schema-audit-agent, accessibility-audit-agent
- **Purpose:** Quality assurance — 6 independent audits run simultaneously
- **Inputs:** Built website code
- **Output:** `.site-builder/audit-reports/*.md` (one per audit)
- **Gate:** QUALITY GATE — ALL 6 audits must pass. Failed checks route to content-agent or developer-agent for fixes. Maximum 3 audit cycles. If issues remain after 3 rounds, present to user for manual resolution.
- **Fix sequence (per cycle):**
  1. All 6 audits run in parallel (read-only)
  2. Collect failures, group by responsible agent
  3. content-agent fixes content issues first
  4. developer-agent fixes code issues second
  5. Re-audit (parallel again)
- **Duration estimate:** 10-20 minutes per cycle

### Phase 8: INTEGRATE
- **Agent:** social-integration-agent
- **Purpose:** Connect social media presence — icons, share buttons, OG meta, schema sameAs links
- **Inputs:** Built website code, `.site-builder/project-brief.md`
- **Output:** Updated website code, `.site-builder/integration-reports/social-integration.md`
- **Gate:** None (flows into DEPLOY)
- **Duration estimate:** 5-10 minutes

### Phase 9: DEPLOY
- **Agent:** deploy-agent
- **Purpose:** Orchestrator asks "Where do you want to deploy?" (hosting-agnostic — Vercel, Netlify, custom hosting, or other) before spawning the agent; deploy-agent then performs config translation (server rules → framework/platform config), .env variable migration, CI/CD pipeline in-place update (asking to keep or reconfigure any existing pipeline), sitemap verification, staging deployment, production readiness
- **Inputs:** Built website code, `.site-builder/site-architecture.md`, `.site-builder/project-brief.md` (Environment & Migration Assessment), `status.md` (hosting decision), `reference/legacy-configs.md` (translation tables)
- **Output:** Translated configs, updated CI/CD pipeline, `.env.example`, `.site-builder/integration-reports/deploy.md` (now includes config translation results, sitemap verification, CI/CD update summary), inline IndexNow CI/CD post-deploy notification step (no separate script file)
- **Gate:** CONFIG TRANSLATION REVIEW (within agent) + USER APPROVAL (after deployment)
- **Duration estimate:** 20-40 minutes (longer for complex migrations with many rules)

### Phase 10: ANALYTICS
- **Agent:** analytics-agent
- **Purpose:** Connect real analytics credentials to the scaffolding Phase 6 DEVELOP already laid down, and verify tracking fires on the live deployed URL
- **Inputs:** Live deployment URL (from Phase 9 DEPLOY), analytics scaffolding code (GA4 snippet, cookie consent banner, conversion event stubs from Phase 6), `.site-builder/site-architecture.md`
- **Output:** Injected credentials in environment configuration, `.site-builder/integration-reports/analytics.md` updated with live verification results
- **Gate:** USER APPROVAL — orchestrator presents verification results, user approves or provides corrected credentials to retry
- **Duration estimate:** 5-15 minutes

### Phase 11: AUTO-INDEXING
- **Agent:** seo-indexing-agent
- **Purpose:** Configure git-derived sitemap `lastmod`, verify/create the IndexNow key file and inline CI post-deploy notification step, and scaffold an RSS/Atom feed
- **Inputs:** `.site-builder/status.md` (framework, hosting platform), each adapter's sitemap config, CI/CD config for the detected hosting platform, `public/<key>.txt` (if present), `robots.txt`, `skills/site-builder/reference/sitemap-indexnow.md` Sections E-G
- **Output:** Patched sitemap config, scaffolded RSS/Atom feed, patched/created IndexNow key + inline CI notification step, patched `robots.txt`, `.site-builder/integration-reports/seo-indexing.md`
- **Gate:** DIFF APPROVAL — agent presents all proposed file changes for user sign-off before writing
- **Duration estimate:** 10-20 minutes

**Prerequisites:** Phase 10 ANALYTICS complete (live deployment URL exists). Runs even if Phase 6/9 predate this feature — see `agents/seo-indexing-agent.md` Retrofit Mode.

**Checklist (mirrors the agent's Verify step):**
- [ ] Git-lastmod resolver patched into sitemap config
- [ ] IndexNow key file verified/created
- [ ] IndexNow inline CI notification step verified/created (feed URL included if a feed exists)
- [ ] RSS/Atom feed scaffolded (or explicitly skipped with a warning — no content collection)
- [ ] `robots.txt` references sitemap + feed
- [ ] GitHub Actions `fetch-depth: 0` + `filter: blob:none` confirmed (GitHub Actions only)

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
