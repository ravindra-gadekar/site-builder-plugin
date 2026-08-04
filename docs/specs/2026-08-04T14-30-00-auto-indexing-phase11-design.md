# Auto-Indexing (Phase 11) — Design Spec

**Created:** 2026-08-04T14:30:00
**Status:** Draft
**Author:** AI + Ravindra Gadekar

## Overview

Add a new Phase 11 (AUTO-INDEXING) to the site-builder pipeline, owned by a dedicated 15th agent (`seo-indexing-agent`), dispatched immediately after Phase 10 (analytics-agent). Phase 11 runs a single interactive session that configures three capabilities in the client project:

1. **Git-derived sitemap `lastmod`** — patches each framework adapter's sitemap config to resolve per-page `lastmod` dates from `git log -1 --format=%aI -- <file>` (primary), falling back to frontmatter `updatedDate`/`publishDate` only when newer. Omits `lastmod` entirely when neither source exists (better than a fabricated date).

2. **IndexNow search-engine ping** — verifies/creates the IndexNow key file (`public/<key>.txt`, committed directly), the ping script (`scripts/ping-indexnow.mjs`), and the post-deploy CI step in `.github/workflows/deploy.yml`. Covers Bing, Yandex, Seznam, Naver. No WebSub/PubSubHubbub Google ping (deprecated/ineffective); Google indexing relies on accurate `lastmod` + `robots.txt` sitemap reference + the existing manual GSC submission reminder from Phase 10.

3. **RSS/Atom feed generation** — scaffolds a blog/content-collection feed (`feed.xml`) per adapter, reusing the same git-primary date resolver, and includes the feed URL in the IndexNow ping payload.

### Why a new phase and agent

- The user explicitly wants a distinct, separately-skippable step after analytics setup, not logic buried inside Phase 6/9.
- A dedicated agent (`seo-indexing-agent`) keeps the one-agent-per-phase convention intact.
- Requires a `pipeline_version` bump (v3→v4) with a resume-transition rule so existing in-progress builds pick up Phase 11 without re-running earlier phases.

### What this is NOT

- Not a Google indexing API integration (Indexing API is restricted to JobPosting/BroadcastEvent content; GSC Sitemaps API requires GCP service-account credentials — both out of scope).
- Not a change to Phase 6 (developer-agent) or Phase 9 (deploy-agent) instructions — Phase 11 patches their output, not their agent definitions.

## Architecture

**New agent:** `agents/seo-indexing-agent.md` — the plugin's 15th specialized agent, dispatched by the orchestrator as Phase 11: AUTO-INDEXING, immediately after Phase 10 (analytics-agent) completes.

**Reference doc changes:** `skills/site-builder/reference/sitemap-indexnow.md` gains two new sections:
- **Section F — Git-Derived Lastmod Resolver**: per-adapter code for resolving a page's `lastmod` via `git log -1 --format=%aI -- <file>`, with existing frontmatter/`pageLastmod` values used only when newer than the git date.
- **Section G — RSS/Atom Feed Generation**: per-adapter feed setup for blog/content collections (Astro: `@astrojs/rss`; Next.js: custom route or script; Vue/Nuxt: `@nuxtjs/feed` or custom; React SPA: custom script), reusing the same date resolver from Section F.

Section A (lastmod rules) updated to state git-primary/fallback precedence explicitly. No changes needed to Section E (IndexNow) — the existing key-generation/ping-script/CI-wiring design already matches the "commit the key directly" decision.

**What Phase 11 does at runtime:**
1. Detects current state via `.site-builder/status.md` + reads each adapter's existing sitemap config (idempotent — same detect/diff/approve pattern deploy-agent uses for CI/CD).
2. Patches the adapter's sitemap `serialize`/`transform` function (written by developer-agent in Phase 6) to call the new git-lastmod resolver.
3. Verifies the IndexNow key file + `scripts/ping-indexnow.mjs` + CI step exist (created in Phase 6/Phase 9); if retrofitting onto a project that predates this feature, Phase 11 creates them itself.
4. Scaffolds the RSS/Atom feed per adapter, and extends the CI post-deploy step to include feed URLs in the IndexNow ping payload.
5. Verifies the sitemap is correctly referenced in `robots.txt` and confirms in its final report that the client still needs the one-time manual GSC sitemap submission (already documented by Phase 10).

**Doc updates required:** README.md, CONTEXT.md, and `docs/project/architecture.md` bump "14 agents" to "15 agents" and add `seo-indexing-agent` to roster tables. `skills/site-builder/reference/phases.md` gets a Phase 11 entry. `SKILL.md`'s phase list, dispatch table, and `pipeline_version` are bumped.

## Data Flow

### Phase inputs (from earlier phases)

**Phase 6 (DEVELOP) → Phase 11:**
- Sitemap config file (e.g. `astro.config.mjs`, `next-sitemap.config.js`, `nuxt.config.ts`, `scripts/generate-sitemap.mjs`). Phase 11 reads and patches to inject the git-lastmod resolver.
- `public/<32-hex-key>.txt` (IndexNow verification key, committed). Phase 11 verifies existence; creates if missing (retrofit).

**Phase 9 (DEPLOY) → Phase 11:**
- `scripts/ping-indexnow.mjs` and post-deploy CI step in `.github/workflows/deploy.yml`. Phase 11 verifies existence; patches `ping-indexnow.mjs` to include RSS feed URLs; creates if missing (retrofit).

**Phase 10 (ANALYTICS) → Phase 11:**
- Orchestrator marks Phase 10 complete in `.site-builder/status.md` and dispatches `seo-indexing-agent`.

### Phase 11 internal flow

```
1. Read .site-builder/status.md → detect framework, build tool, deploy target
         │
2. READ existing files:
   ├── Sitemap config (per adapter)
   ├── CI workflow (.github/workflows/deploy.yml)
   ├── IndexNow key file (public/<key>.txt)
   ├── IndexNow ping script (scripts/ping-indexnow.mjs)
   └── robots.txt
         │
3. DETECT what's already configured vs. missing:
   ├── Git-lastmod resolver present in sitemap config? → skip / patch
   ├── IndexNow key + ping script + CI step? → skip / create
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
   ├── Patch scripts/ping-indexnow.mjs to include feed URL
   ├── Patch robots.txt to add Sitemap: + feed reference if missing
   └── Create missing IndexNow files if retrofit
         │
6. VERIFY (read-back):
   ├── Sitemap config contains git-log call
   ├── Feed route/script exists and exports valid XML structure
   ├── CI workflow has post-deploy IndexNow step
   ├── robots.txt references both sitemap and feed
   └── Report: remind user of manual GSC sitemap submission
         │
7. UPDATE .site-builder/status.md → Phase 11 complete
```

### Git-lastmod resolver logic

```
For each page URL:
  1. Map URL → source file path(s)
  2. gitDate = exec(`git log -1 --format=%aI -- <file>`)
  3. frontmatterDate = read updatedDate || publishDate from frontmatter (if content page)
  4. lastmod = max(gitDate, frontmatterDate)  // whichever is newer wins
  5. If neither exists → omit lastmod for that URL
```

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
|---|---|
| `agents/seo-indexing-agent.md` | Phase 11 agent definition |

### Modified files — Reference docs

| File | Change |
|---|---|
| `skills/site-builder/reference/sitemap-indexnow.md` | Add Section F (git-lastmod resolver, per-adapter), Section G (RSS/Atom feed, per-adapter). Update Section A lastmod precedence rule. |
| `skills/site-builder/reference/phases.md` | Add Phase 11 AUTO-INDEXING entry |

### Modified files — Orchestrator

| File | Change |
|---|---|
| `skills/site-builder/SKILL.md` | Phase 11 in phase list + dispatch table, `seo-indexing-agent` in agent spawning pattern, `pipeline_version` bump (v3→v4) with resume-transition rule |

### Modified files — Adapters

| File | Change |
|---|---|
| `skills/site-builder/adapters/astro.md` | "Git-Lastmod Resolver" + "RSS Feed" subsections |
| `skills/site-builder/adapters/nextjs.md` | "Git-Lastmod Resolver" + "RSS Feed" subsections |
| `skills/site-builder/adapters/vue.md` | "Git-Lastmod Resolver" + "RSS Feed" subsections |
| `skills/site-builder/adapters/react.md` | "Git-Lastmod Resolver" + "RSS Feed" subsections |

### Modified files — Documentation

| File | Change |
|---|---|
| `README.md` | 14 → 15 agents, add `seo-indexing-agent` to roster |
| `CONTEXT.md` | Agent count + Entities table |
| `docs/project/architecture.md` | Agent count in System Overview |

### Files NOT changed

| File | Reason |
|---|---|
| `agents/deploy-agent.md` | Phase 9 IndexNow scaffolding (§7b) stays as-is — Phase 11 patches its output |
| `agents/analytics-agent.md` | Phase 10 unchanged — already documents IndexNow ownership and manual GSC submission |
| `agents/developer-agent.md` | Phase 6 sitemap scaffolding unchanged — Phase 11 patches the generated code |
| `templates/` | No new templates — per-adapter code is inline in adapter docs and sitemap-indexnow.md |

## Error Handling

### Git history unavailable

| Failure | Cause | Recovery |
|---|---|---|
| `git log` returns empty for a file | Untracked, newly created, or shallow clone | Omit `lastmod` for that URL. Log: "X pages have no git history — lastmod omitted." |
| `git` command not found | Containerized build without git | Fall back to frontmatter dates only. Warning: "git not available at build time — lastmod from frontmatter only. Ensure `fetch-depth: 0` in CI checkout." |
| Shallow clone in CI | Default `actions/checkout` (`fetch-depth: 1`) | Detect and patch to `fetch-depth: 0` via diff-approval gate. Critical — without full history, all pages get the same date. |

### IndexNow ping failures

| Failure | Cause | Recovery |
|---|---|---|
| HTTP 429 | Rate limit (>10k URLs or too frequent) | Batch in groups of 10,000, respect `Retry-After`. CI step exits 0 (deploy succeeded; notification is best-effort). |
| HTTP 4xx/5xx (non-429) | Malformed payload, invalid key, service outage | Log status code and body. CI step exits 0. Agent suggests checking key file. |
| Key file 404 at `keyLocation` | Not deployed, wrong path, CDN cache | Verification step fetches the URL post-deploy and warns if 404. Suggests checking build output includes `public/<key>.txt`. |

### RSS/Atom feed failures

| Failure | Cause | Recovery |
|---|---|---|
| No blog/content collection found | Project has no blog posts yet | Skip feed generation entirely. Warning: "No content collection — RSS feed skipped. Re-run Phase 11 after adding content." |
| Feed XML validation error | Malformed dates, missing required fields | Validate against RSS 2.0 required elements before writing. Exclude entries missing required fields with a per-entry warning. |
| Feed URL 404 after deploy | Route not built, wrong path | Verification fetches `https://<domain>/feed.xml` and warns if 404 or non-XML response. |

### Idempotency / re-run safety

| Scenario | Behavior |
|---|---|
| Re-run on already-configured project | Detects existing components via `status.md` + file reads. Reports "already configured" per piece. Only diffs for missing/outdated pieces. |
| Run on project that skipped Phase 6/9 | Retrofit mode — creates IndexNow key, ping script, CI step from scratch. |
| Existing CI has custom post-deploy steps | Appends IndexNow step after existing steps, never reorders/removes. Diff-approval gate before writing. |

### User-facing error format

```
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
|---|---|---|
| Git-lastmod resolver | Dry-run against 3-5 sample files: `git log -1 --format=%aI -- <file>` | Valid ISO 8601 dates or empty; dates in the past |
| Sitemap config syntax | Read patched config, check for parse errors | File parses without error |
| RSS feed XML | Validate against RSS 2.0 required elements: `<channel>`, `<title>`, `<link>`, `<description>`, `<item>` with `<title>`, `<link>`, `<pubDate>` | Valid XML, all required elements present |
| IndexNow key file | Read `public/<key>.txt`, confirm content = key | Content matches filename (minus .txt) |
| CI workflow YAML | Parse `.github/workflows/deploy.yml`, check IndexNow step | Valid YAML; `run: node scripts/ping-indexnow.mjs` step exists |
| `fetch-depth: 0` | Check CI checkout step | `fetch-depth: 0` present |
| `robots.txt` references | Read robots.txt | Contains `Sitemap:` directive and optionally feed URL |

### Post-deploy verification (after first deploy with Phase 11 changes)

| Check | Method | Pass criteria |
|---|---|---|
| Sitemap `lastmod` accuracy | Fetch live `sitemap-0.xml`, compare 3-5 `<lastmod>` values against `git log` | Dates match (±1 day); no uniform-date pattern |
| RSS feed accessible | Fetch `https://<domain>/feed.xml` | HTTP 200, XML content type, body starts with `<?xml` |
| IndexNow key accessible | Fetch `https://<domain>/<key>.txt` | HTTP 200, body = key string |
| IndexNow ping success | Check CI logs or manual test ping | HTTP 200 or 202 from api.indexnow.org |

### Agent summary report format

```
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

- [ ] `agents/seo-indexing-agent.md` exists with complete Phase 11 instructions: input contract (status.md fields required), output contract (files created/patched, status.md updates), per-adapter branching for all 4 frameworks (Astro, Next.js, Vue/Nuxt, React SPA)
- [ ] `skills/site-builder/reference/sitemap-indexnow.md` Section F documents the git-derived lastmod resolver with per-adapter code snippets that use `git log -1 --format=%aI -- <file>` as primary source and frontmatter `updatedDate`/`publishDate` as fallback (whichever is newer wins); omits `lastmod` entirely when neither source exists
- [ ] `skills/site-builder/reference/sitemap-indexnow.md` Section G documents RSS/Atom feed generation for blog/content collections across all 4 adapters: Astro (`@astrojs/rss`), Next.js (App Router route or build script), Vue/Nuxt (`@nuxtjs/feed` or custom server route), React SPA (build-time `scripts/generate-feed.mjs`)
- [ ] `skills/site-builder/reference/sitemap-indexnow.md` Section A updated to state git-primary/frontmatter-fallback as the canonical lastmod precedence rule
- [ ] `skills/site-builder/reference/phases.md` contains a Phase 11 AUTO-INDEXING entry with agent name, prerequisites, and checklist
- [ ] `skills/site-builder/SKILL.md` updated: Phase 11 in the phase list and dispatch table, `seo-indexing-agent` in the agent spawning pattern, `pipeline_version` bumped with resume-transition rule
- [ ] All 4 adapter files (`astro.md`, `nextjs.md`, `vue.md`, `react.md`) have "Git-Lastmod Resolver" and "RSS Feed" subsections
- [ ] Phase 11 agent detects shallow clones (`fetch-depth: 1` or default) in CI checkout step and patches to `fetch-depth: 0` via diff-approval gate
- [ ] IndexNow key file committed directly to `public/<key>.txt` (not from CI secrets)
- [ ] `scripts/ping-indexnow.mjs` patched to include RSS feed URL in IndexNow `urlList` payload
- [ ] No WebSub/PubSubHubbub ping step generated — Google relies on accurate `lastmod` + `robots.txt` sitemap reference + existing manual GSC submission reminder from Phase 10
- [ ] Phase 11 fully idempotent: re-run detects already-configured components, only diffs for missing/outdated pieces
- [ ] Phase 11 works in retrofit mode: creates IndexNow key, ping script, CI step, and feed from scratch if Phase 6/9 output is missing
- [ ] RSS feed generation skipped with clear warning when no blog/content collection exists
- [ ] Feed XML validated against RSS 2.0 required elements before writing; entries missing required fields excluded with per-entry warning
- [ ] Post-deploy verification checks documented: live sitemap lastmod accuracy, feed accessibility, IndexNow key accessibility, CI `fetch-depth: 0` presence
- [ ] README.md, CONTEXT.md, and `docs/project/architecture.md` updated from "14 agents" to "15 agents" with `seo-indexing-agent` in roster tables
