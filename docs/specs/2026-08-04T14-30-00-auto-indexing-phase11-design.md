# Auto-Indexing (Phase 11) — Design Spec

**Created:** 2026-08-04T14:30:00
**Status:** Draft
**Author:** AI + Ravindra Gadekar

## Overview

Add a new Phase 11 (AUTO-INDEXING) to the site-builder pipeline, owned by a dedicated 15th agent (`seo-indexing-agent`), dispatched immediately after Phase 10 (analytics-agent). Phase 11 runs a single interactive session that configures three capabilities in the client project:

1. **Git-derived sitemap `lastmod`** — patches each framework adapter's sitemap config to resolve per-page `lastmod` dates from git commit history (primary), with frontmatter `updatedDate`/`publishDate` overriding when newer. Uses `execFileSync('git', ['log', '-1', '--format=%aI', '--', filePath])` (argument array, no shell — immune to command injection via filenames). Omits `lastmod` entirely when neither source exists (better than a fabricated date). All resolution happens at build time; frameworks with request-time sitemap generation (e.g. Next.js SSR `app/sitemap.ts`) use a pre-built `_lastmod.json` manifest.

2. **IndexNow search-engine ping** — verifies/creates the IndexNow key file (`public/<key>.txt`, committed directly) and a post-deploy CI/CD step with inline shell commands (no separate script file — everything lives in the workflow YAML, matching the reference project pattern). The CI step extracts URLs from the built sitemap XML and POSTs them to `api.indexnow.org` using `curl`/`jq`. Covers Bing, Yandex, Seznam, Naver. No WebSub/PubSubHubbub Google ping (deprecated/ineffective); Google indexing relies on accurate `lastmod` + `robots.txt` sitemap reference + the existing manual GSC submission reminder from Phase 10.

3. **RSS/Atom feed generation** — scaffolds a blog/content-collection feed (`feed.xml`) per adapter, reusing the same git-primary date resolver, and includes the feed URL in the IndexNow ping payload.

### Why a new phase and agent

- The user explicitly wants a distinct, separately-skippable step after analytics setup, not logic buried inside Phase 6/9.
- A dedicated agent (`seo-indexing-agent`) keeps the one-agent-per-phase convention intact.
- Requires a `pipeline_version` bump (v3→v4) with a resume-transition rule so existing in-progress builds pick up Phase 11 without re-running earlier phases.

### Scope

Phase 11 assumes a single-site repository. For monorepo projects with multiple sites (e.g. `apps/marketing/` + `apps/docs/`), each site requires its own Phase 11 run scoped to its subdirectory. Monorepo multi-site support is out of scope for this design.

### What this is NOT

- Not a Google indexing API integration (Indexing API is restricted to JobPosting/BroadcastEvent content; GSC Sitemaps API requires GCP service-account credentials — both out of scope).
- Not a change to Phase 6 (developer-agent) or Phase 9 (deploy-agent) instructions — Phase 11 patches their output, not their agent definitions.

## Architecture

**New agent:** `agents/seo-indexing-agent.md` — the plugin's 15th specialized agent, dispatched by the orchestrator as Phase 11: AUTO-INDEXING, immediately after Phase 10 (analytics-agent) completes.

**Reference doc changes:** `skills/site-builder/reference/sitemap-indexnow.md` gains two new sections:

- **Section F — Git-Derived Lastmod Resolver**: per-adapter code for resolving a page's `lastmod` via `execFileSync('git', ['log', '-1', '--format=%aI', '--', filePath])` (argument array, never `execSync` with string interpolation — prevents command injection via filenames). Frontmatter `updatedDate`/`publishDate` overrides when newer than the git date. All resolution happens at build time; for frameworks with request-time sitemap generation (Next.js SSR `app/sitemap.ts`), a `_lastmod.json` manifest is generated during `npm run build` and read by the sitemap route. Includes a per-adapter URL-to-source-file mapping table (see below) and recommends batch `git log` for performance optimization on large sites.
- **Section G — RSS/Atom Feed Generation**: per-adapter feed setup for blog/content collections (Astro: `@astrojs/rss`; Next.js: custom route or script; Vue/Nuxt: `@nuxtjs/feed` or custom; React SPA: custom script), reusing the same date resolver from Section F.

Section A (lastmod rules) is **NOT** updated — Phase 6/7/9 agents read Section A during their phases, and changing it would alter their behavior. Instead, a forward reference is added at the bottom of Section A: "Phase 11 (seo-indexing-agent) overrides these per-page dates with git-derived resolution — see Section F." The seo-indexing-agent reads Section F as its authoritative source. No changes needed to Section E (IndexNow) — the existing key-generation/ping-script/CI-wiring design already matches the "commit the key directly" decision.

### URL-to-source-file mapping (Section F content)

| Page type | Source file for git date | Notes |
| --- | --- | --- |
| Content collection (blog `.md`/`.mdx`) | The content file itself (e.g. `src/content/blog/my-post.md`) | Git dates are reliable — content changes dominate |
| Static pages (`.astro`, `.tsx`, `.vue`) | The page component file | Prefer manual `pageLastmod` map with git date as fallback — git captures non-content edits (formatting, import reorg) |
| Data-driven dynamic routes (e.g. `/services/[slug]`) | The data source file (JSON/YAML/TS) | Template file's git date used as fallback if data source has no history |
| Category/tag/pagination pages | Most recent content file in the collection | Reflects when the collection last changed |
| Composite pages (layout + component + data) | The primary content source file only | Documented trade-off — layout/component changes don't bump lastmod |

### Content-aware date accuracy

Git commit dates capture ALL changes to a file, including non-content edits (Prettier runs, import reordering, config tweaks). For content collection files (`.md`/`.mdx`), this is acceptable — content changes dominate. For component/page files (`.astro`, `.tsx`, `.vue`), git dates may reflect non-meaningful edits. Section F recommends:

- Content files: git-primary, frontmatter override when newer
- Component/page files: manual `pageLastmod` map primary, git date as fallback when no manual entry exists

This avoids the scenario where a repo-wide formatting run sets every page's `lastmod` to the same date — exactly the "uniform timestamp" pattern Google ignores.

**What Phase 11 does at runtime:**

1. Detects current state via `.site-builder/status.md` + reads each adapter's existing sitemap config (idempotent — same detect/diff/approve pattern deploy-agent uses for CI/CD).
2. Patches the adapter's sitemap `serialize`/`transform` function (written by developer-agent in Phase 6) to call the new git-lastmod resolver.
3. Verifies the IndexNow key file and CI post-deploy notification step exist (created in Phase 6/Phase 9); if retrofitting onto a project that predates this feature, Phase 11 creates them itself.
4. Scaffolds the RSS/Atom feed per adapter, and extends the inline CI post-deploy notification step to include feed URLs in the IndexNow ping payload.
5. Verifies the sitemap is correctly referenced in `robots.txt` and confirms in its final report that the client still needs the one-time manual GSC sitemap submission (already documented by Phase 10).

**Doc updates required:** README.md, CONTEXT.md, and `docs/project/architecture.md` bump "14 agents" to "15 agents" and add `seo-indexing-agent` to roster tables. `skills/site-builder/reference/phases.md` gets a Phase 11 entry with "Gate: DIFF APPROVAL — agent presents all proposed file changes for user sign-off before writing." `SKILL.md`'s phase list, dispatch table, Pipeline Complete section (moves after Phase 11), status tracking template (gains Phase 11 entry), and `pipeline_version` are bumped. Phase boundary PR schedule gains: `| 11. AUTO-INDEXING | feature/auto-indexing | feat: add git-derived lastmod, RSS feed, and IndexNow enhancements |`.

### Resume-transition rules (v3 → v4)

| Scenario | Behavior |
| --- | --- |
| Completed v3 build (all 10 phases done) | Offer Phase 11 as optional upgrade: "This build finished under the 10-phase pipeline. Run the new Phase 11 AUTO-INDEXING?" If accepted, add `Phase 11 AUTO-INDEXING: in-progress` to status.md, bump `pipeline_version` to 4, and dispatch seo-indexing-agent. |
| Mid-run v3 build (some phases incomplete) | Add `Phase 11 AUTO-INDEXING: pending` to status.md, bump `pipeline_version` to 4. Continue from last incomplete phase — Phase 11 runs after Phase 10 completes normally. |
| Fresh build (no status.md) | Starts as v4 pipeline with all 11 phases. No transition needed. |

## Data Flow

### Phase inputs (from earlier phases)

**Phase 6 (DEVELOP) → Phase 11:**

- Sitemap config file (e.g. `astro.config.mjs`, `next-sitemap.config.js`, `nuxt.config.ts`, `scripts/generate-sitemap.mjs`). Phase 11 reads and patches to inject the git-lastmod resolver.
- `public/<32-hex-key>.txt` (IndexNow verification key, committed). Phase 11 verifies existence; creates if missing (retrofit).

**Phase 9 (DEPLOY) → Phase 11:**

- Post-deploy CI/CD notification step (inline shell commands in the workflow YAML — no separate script file). Phase 11 detects the hosting platform from `status.md` and reads the appropriate config: GitHub Actions (`.github/workflows/deploy.yml`), Vercel (`vercel.json` or `package.json` scripts), or Netlify (`netlify.toml` / `[[plugins]]`).
- Phase 11 verifies the notification step exists and includes RSS feed URLs; creates or patches if missing (retrofit).

**Phase 10 (ANALYTICS) → Phase 11:**

- Orchestrator marks Phase 10 complete in `.site-builder/status.md` and dispatches `seo-indexing-agent`.

### Phase 11 internal flow

```text
1. Read .site-builder/status.md → detect framework, build tool, deploy target
         │
2. READ existing files:
   ├── Sitemap config (per adapter)
   ├── CI/CD config (GitHub Actions .yml / vercel.json / netlify.toml — per hosting platform)
   ├── IndexNow key file (public/<key>.txt)
   ├── CI/CD post-deploy notification step (inline in workflow YAML)
   └── robots.txt
         │
3. DETECT what's already configured vs. missing:
   ├── Git-lastmod resolver present in sitemap config? → skip / patch
   ├── IndexNow key + CI notification step? → skip / create
   ├── RSS/Atom feed route/script? → skip / scaffold
   └── Feed URL in robots.txt? → skip / add
         │
4. PRESENT diff of all proposed changes → approval gate
         │
5. WRITE approved changes:
   ├── Patch sitemap config with git-lastmod resolver function
   ├── Scaffold RSS/Atom feed (per-adapter):
   │   ├── Astro: src/pages/feed.xml.js using @astrojs/rss
   │   ├── Next.js: src/app/feed.xml/route.ts or pages/api/feed.ts
   │   ├── Vue/Nuxt: server/routes/feed.xml.ts or nuxt.config.ts feed module
   │   └── React SPA: scripts/generate-feed.mjs (build-time)
   ├── Patch CI notification step to include feed URL in IndexNow payload
   ├── Patch robots.txt to add Sitemap: + feed reference if missing
   └── Create missing IndexNow files if retrofit
         │
6. VERIFY (read-back):
   ├── Sitemap config contains git-log call
   ├── Feed route/script exists and exports valid XML structure
   ├── CI/CD config has post-deploy IndexNow step (platform-appropriate)
   ├── robots.txt references both sitemap and feed URL
   └── Report: remind user of manual GSC sitemap submission
         │
7. UPDATE .site-builder/status.md → Phase 11 complete
```

### Git-lastmod resolver logic

```text
For each page URL:
  1. Map URL → primary source file (see URL-to-source-file mapping table above)
  2. gitDate = execFileSync('git', ['log', '-1', '--format=%aI', '--', filePath])
     // argument array — no shell, immune to command injection via filenames
     // NEVER use execSync with string interpolation for git commands
  3. For content files (.md/.mdx):
       frontmatterDate = read updatedDate || publishDate from frontmatter
       lastmod = max(gitDate, frontmatterDate)  // frontmatter overrides when newer
  4. For component/page files (.astro/.tsx/.vue):
       manualDate = read from pageLastmod map (if maintained)
       lastmod = manualDate || gitDate  // manual map primary, git fallback
  5. If neither source exists → omit lastmod for that URL
```

**Build-time resolution requirement:** Git-lastmod resolution MUST happen at build time, not request time. For frameworks with request-time sitemap generation (Next.js SSR `app/sitemap.ts` running in serverless environments without `git`), generate a `_lastmod.json` manifest during `npm run build` and read it from the sitemap route.

**Performance note:** For sites with 200+ pages, sequential `execFileSync` per file adds 10-40s to builds. Section F recommends an optional batch resolver: `git log --format='%aI' --name-only` across directories in a single subprocess, parsing all dates from one call.

### IndexNow ping payload (after Phase 11)

```json
{
  "host": "<site-domain>",
  "key": "<committed-32-hex-key>",
  "keyLocation": "https://<site-domain>/<key>.txt",
  "urlList": [
    "...all sitemap URLs...",
    "https://<site-domain>/feed.xml"
  ]
}
```

## Per-Repo Changes

All changes are in `site-builder-plugin` (mono-repo).

### New files

| File | Purpose |
| --- | --- |
| `agents/seo-indexing-agent.md` | Phase 11 agent definition |

### Modified files — Reference docs

| File | Change |
| --- | --- |
| `skills/site-builder/reference/sitemap-indexnow.md` | Add Section F (git-lastmod resolver, per-adapter), Section G (RSS/Atom feed, per-adapter). Add forward reference at bottom of Section A: "Phase 11 overrides — see Section F." Section A rules themselves unchanged. |
| `skills/site-builder/reference/phases.md` | Add Phase 11 AUTO-INDEXING entry |

### Modified files — Orchestrator

| File | Change |
| --- | --- |
| `skills/site-builder/SKILL.md` | Phase 11 in phase list + dispatch table, `seo-indexing-agent` in agent spawning pattern, `pipeline_version` bump (v3→v4) with resume-transition rules (see Architecture section), Pipeline Complete section moves after Phase 11, status tracking template gains `Phase 11 AUTO-INDEXING: [pending/in-progress/complete]` entry, Phase 11 Progress checklist added, Phase boundary PR schedule entry added: `feature/auto-indexing` / `feat: add git-derived lastmod, RSS feed, and IndexNow enhancements` |

### Modified files — Adapters

| File | Change |
| --- | --- |
| `skills/site-builder/adapters/astro.md` | One-line cross-reference under Sitemap Configuration: "Git-lastmod and RSS feed: see `reference/sitemap-indexnow.md` Sections F-G (Phase 11 only — not during Phase 6 DEVELOP)" |
| `skills/site-builder/adapters/nextjs.md` | Same one-line cross-reference |
| `skills/site-builder/adapters/vue.md` | Same one-line cross-reference |
| `skills/site-builder/adapters/react.md` | Same one-line cross-reference |

### Modified files — Documentation

| File | Change |
| --- | --- |
| `README.md` | 14 → 15 agents, add `seo-indexing-agent` to roster |
| `CONTEXT.md` | Agent count + Entities table |
| `docs/project/architecture.md` | Agent count in System Overview |

### Files NOT changed

| File | Reason |
| --- | --- |
| `agents/deploy-agent.md` | Phase 9 IndexNow scaffolding (§7b) stays as-is — Phase 11 patches its output |
| `agents/analytics-agent.md` | Phase 10 unchanged — already documents IndexNow ownership and manual GSC submission |
| `agents/developer-agent.md` | Phase 6 sitemap scaffolding unchanged — Phase 11 patches the generated code |
| `templates/` | No new templates — per-adapter code is inline in adapter docs and sitemap-indexnow.md |

## Error Handling

### Git history unavailable

| Failure | Cause | Recovery |
| --- | --- | --- |
| `git log` returns empty for a file | Untracked, newly created, or shallow clone | Omit `lastmod` for that URL. Log: "X pages have no git history — lastmod omitted." |
| `git` command not found | Containerized build without git | Fall back to frontmatter dates only. Warning: "git not available at build time — lastmod from frontmatter only. Ensure `fetch-depth: 0` in CI checkout." |
| Shallow clone in CI | Default `actions/checkout` (`fetch-depth: 1`) | Detect and patch to `fetch-depth: 0` with `filter: blob:none` (treeless clone — full commit history for accurate git dates, but lazy-fetches file content only when needed, avoiding prohibitive clone times for large repos) via diff-approval gate. Critical — without full history, all pages get the same date. |

### IndexNow ping failures

| Failure | Cause | Recovery |
| --- | --- | --- |
| HTTP 429 | Rate limit (>10k URLs or too frequent) | Batch in groups of 10,000, respect `Retry-After`. CI step exits 0 (deploy succeeded; notification is best-effort). |
| HTTP 4xx/5xx (non-429) | Malformed payload, invalid key, service outage | Log status code and body. CI step exits 0. Agent suggests checking key file. |
| Key file 404 at `keyLocation` | Not deployed, wrong path, CDN cache | Verification step fetches the URL post-deploy and warns if 404. Suggests checking build output includes `public/<key>.txt`. |

### RSS/Atom feed failures

| Failure | Cause | Recovery |
| --- | --- | --- |
| No blog/content collection found | Project has no blog posts yet | Skip feed generation entirely. Warning: "No content collection — RSS feed skipped. Re-run Phase 11 after adding content." |
| Feed XML validation error | Malformed dates, missing required fields | Validate against RSS 2.0 required elements before writing. Exclude entries missing required fields with a per-entry warning. |
| Feed URL 404 after deploy | Route not built, wrong path | Verification fetches `https://<domain>/feed.xml` and warns if 404 or non-XML response. |

### Idempotency / re-run safety

| Scenario | Behavior |
| --- | --- |
| Re-run on already-configured project | Detects existing components via `status.md` + file reads. Reports "already configured" per piece. Only diffs for missing/outdated pieces. |
| Run on project that skipped Phase 6/9 | Retrofit mode — creates IndexNow key, CI notification step from scratch. |
| Existing CI has custom post-deploy steps | Appends IndexNow step after existing steps, never reorders/removes. Diff-approval gate before writing. |

### User-facing error format

```text
⚠ [component]: [what happened] — [what to do]
```

Examples:

- `⚠ git-lastmod: 3 pages have no git history — lastmod omitted for those URLs`
- `⚠ IndexNow: ping returned HTTP 403 — verify public/<key>.txt is deployed and accessible`
- `⚠ RSS feed: no blog content found — feed generation skipped, re-run after adding posts`
- `⚠ CI: checkout step uses shallow clone — patching to fetch-depth: 0 for accurate git dates`

## Testing Strategy

This repo is Markdown-only — no test runner. Testing applies to what the agent produces in client projects. Phase 11's verification step is the test suite.

### Build-time verification (during Phase 11)

| Check | Method | Pass criteria |
| --- | --- | --- |
| Git-lastmod resolver | Dry-run against 3-5 sample files: `git log -1 --format=%aI -- <file>` | Valid ISO 8601 dates or empty; dates in the past |
| Sitemap config syntax | Read patched config, check for parse errors | File parses without error |
| RSS feed XML | Validate against RSS 2.0 required elements: `<channel>`, `<title>`, `<link>`, `<description>`, `<item>` with `<title>`, `<link>`, `<pubDate>` | Valid XML, all required elements present |
| IndexNow key file | Read `public/<key>.txt`, confirm content = key | Content matches filename (minus .txt) |
| CI/CD config | Parse platform-appropriate config (GitHub Actions `.yml` / `vercel.json` / `netlify.toml`), check IndexNow post-deploy step | Valid config; IndexNow step exists in platform-appropriate format |
| `fetch-depth: 0` (GitHub Actions only) | Check CI checkout step | `fetch-depth: 0` with `filter: blob:none` present |
| `robots.txt` references | Read robots.txt | Contains `Sitemap:` directive pointing to sitemap URL, and feed URL reference (when RSS feed was generated) |

### Post-deploy verification (after first deploy with Phase 11 changes)

| Check | Method | Pass criteria |
| --- | --- | --- |
| Sitemap `lastmod` accuracy | Fetch live `sitemap-0.xml`, compare 3-5 `<lastmod>` values against `git log` | Dates match (±1 day); no uniform-date pattern |
| RSS feed accessible | Fetch `https://<domain>/feed.xml` | HTTP 200, XML content type, body starts with `<?xml` |
| IndexNow key accessible | Fetch `https://<domain>/<key>.txt` | HTTP 200, body = key string |
| IndexNow ping success | Check CI logs or manual test ping | HTTP 200 or 202 from api.indexnow.org |

### Agent summary report format

```text
✓ Git-lastmod resolver: working (5/5 sample pages returned valid dates)
✓ Sitemap lastmod: accurate (no uniform-date pattern detected)
✓ RSS feed: accessible at /feed.xml (12 entries)
✓ IndexNow key: accessible at /<key>.txt
✓ CI workflow: fetch-depth: 0 confirmed, IndexNow step present
✓ robots.txt: sitemap + feed referenced
⚠ 2 pages have no git history — lastmod omitted
```

Failures block Phase 11 completion — the agent offers to fix each issue before marking the phase complete.

## Acceptance Criteria

- [ ] `agents/seo-indexing-agent.md` exists with complete Phase 11 instructions: input contract (status.md fields required, including hosting platform), output contract (files created/patched, status.md updates), per-adapter branching for all 4 frameworks (Astro, Next.js, Vue/Nuxt, React SPA)
- [ ] `skills/site-builder/reference/sitemap-indexnow.md` Section F documents the git-derived lastmod resolver using `execFileSync('git', ['log', '-1', '--format=%aI', '--', filePath])` (argument array, never `execSync` with string interpolation — security requirement). Includes per-adapter code snippets, URL-to-source-file mapping table, content-aware date strategy (git-primary for `.md`/`.mdx`; manual `pageLastmod` map primary with git fallback for component files), and `_lastmod.json` build-time manifest pattern for Next.js SSR. Omits `lastmod` entirely when neither source exists.
- [ ] `skills/site-builder/reference/sitemap-indexnow.md` Section F includes a security note: "NEVER use `execSync` with string interpolation for git commands — always use `execFileSync` with an argument array to prevent command injection via filenames"
- [ ] `skills/site-builder/reference/sitemap-indexnow.md` Section G documents RSS/Atom feed generation for blog/content collections across all 4 adapters: Astro (`@astrojs/rss`), Next.js (App Router route or build script), Vue/Nuxt (`@nuxtjs/feed` or custom server route), React SPA (build-time `scripts/generate-feed.mjs`)
- [ ] `skills/site-builder/reference/sitemap-indexnow.md` Section A is NOT modified — only a forward reference added at the bottom: "Phase 11 (seo-indexing-agent) overrides these per-page dates with git-derived resolution — see Section F"
- [ ] `skills/site-builder/reference/phases.md` contains a Phase 11 AUTO-INDEXING entry with agent name, prerequisites, checklist, and "Gate: DIFF APPROVAL — agent presents all proposed file changes for user sign-off before writing"
- [ ] `skills/site-builder/SKILL.md` updated: Phase 11 in phase list + dispatch table, `seo-indexing-agent` in agent spawning pattern, `pipeline_version` bumped (v3→v4) with concrete resume-transition rules (completed v3 → optional upgrade offer; mid-run v3 → add Phase 11 pending), Pipeline Complete section moved after Phase 11, status tracking template gains Phase 11 entry, Phase boundary PR schedule entry added (`feature/auto-indexing`)
- [ ] All 4 adapter files (`astro.md`, `nextjs.md`, `vue.md`, `react.md`) have a one-line cross-reference under Sitemap Configuration: "Git-lastmod and RSS feed: see `reference/sitemap-indexnow.md` Sections F-G (Phase 11 only — not during Phase 6 DEVELOP)". No full subsections — all implementation details live in sitemap-indexnow.md Sections F/G only.
- [ ] Phase 11 is CI platform-aware: detects hosting platform from `status.md` and reads/writes the appropriate config (GitHub Actions `.github/workflows/deploy.yml`, Vercel `vercel.json` / `package.json` scripts, Netlify `netlify.toml`). Verification checks are platform-specific.
- [ ] For GitHub Actions: Phase 11 detects shallow clones (`fetch-depth: 1` or default) and patches to `fetch-depth: 0` with `filter: blob:none` (treeless clone — full history for accurate dates without downloading all blobs) via diff-approval gate
- [ ] IndexNow key file committed directly to `public/<key>.txt` (not from CI secrets)
- [ ] IndexNow notification is handled entirely inline in the CI/CD workflow YAML (no separate `scripts/ping-indexnow.mjs` file). CI step extracts URLs from built sitemap XML using `grep`/`jq`, includes RSS feed URL, and POSTs to `api.indexnow.org` using `curl`. Pattern matches the reference project's inline approach.
- [ ] No WebSub/PubSubHubbub ping step generated — Google relies on accurate `lastmod` + `robots.txt` sitemap reference + existing manual GSC submission reminder from Phase 10
- [ ] Phase 11 fully idempotent: re-run detects already-configured components via `status.md` + file reads, only presents diffs for missing/outdated pieces, never duplicates existing CI steps or feed routes
- [ ] Phase 11 works in retrofit mode: creates IndexNow key, CI notification step, and feed from scratch if Phase 6/9 output is missing
- [ ] RSS feed generation skipped with clear warning when no blog/content collection exists
- [ ] Feed XML validated against RSS 2.0 required elements before writing; entries missing required fields excluded with per-entry warning
- [ ] Post-deploy verification checks documented: live sitemap lastmod accuracy (no uniform-date pattern), feed accessibility (`/feed.xml` returns valid XML), IndexNow key accessibility, CI platform-specific post-deploy step presence
- [ ] `robots.txt` contains both `Sitemap:` directive and feed URL reference after Phase 11 runs (when RSS feed was generated)
- [ ] `seo-indexing-agent` produces a summary report with per-component pass/fail status covering: git-lastmod resolver, sitemap lastmod accuracy, RSS feed accessibility, IndexNow key accessibility, CI/CD configuration, and robots.txt references
- [ ] README.md, CONTEXT.md, and `docs/project/architecture.md` updated from "14 agents" to "15 agents" with `seo-indexing-agent` in roster tables
