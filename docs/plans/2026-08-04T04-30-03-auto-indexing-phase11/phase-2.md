# Phase 2: New Agent + Phase Registration

**Repo:** site-builder-plugin
**Depends on:** Phase 1 (Section E/F/G must exist — the agent cites them as its authoritative source and reuses Section E's inline CI pattern verbatim)
**Delivers:** `agents/seo-indexing-agent.md` (the 15th agent, complete Phase 11 instructions) and a Phase 11 entry in `skills/site-builder/reference/phases.md`.

## File Structure

```
agents/
└── seo-indexing-agent.md                          [CREATE]
skills/site-builder/reference/
└── phases.md                                       [MODIFY]
```

### Task 1: Create `agents/seo-indexing-agent.md`

**Files:**
- Create: `agents/seo-indexing-agent.md`

**Interfaces:**
- Consumes: `sitemap-indexnow.md` Section E (inline IndexNow CI pattern, Phase 1 Task 1), Section F (git-lastmod resolver, Phase 1 Task 2), Section G (RSS/Atom feed, Phase 1 Task 3); `.site-builder/status.md` (framework, hosting platform, build config — existing input contract shared with deploy-agent/analytics-agent)
- Produces: `agents/seo-indexing-agent.md` — the agent definition itself, consumed by Phase 2 Task 2 (`phases.md` references it by name) and Phase 3 Task 2 (`SKILL.md` dispatch table spawns it by name)

**Acceptance Criteria:** AC1 (complete Phase 11 instructions: input/output contract, per-adapter branching for all 4 frameworks), AC9 (CI platform-aware), AC10 (GitHub Actions shallow-clone detection + patch), AC12 (extends the inline IndexNow step, still no separate script), AC13 (no WebSub/PubSubHubbub), AC14 (idempotent), AC15 (retrofit mode), AC16 (RSS skip warning), AC17 (RSS 2.0 validation), AC18 (post-deploy verification checks documented), AC19 (robots.txt Sitemap: + feed reference), AC20 (per-component summary report)

**Steps (Documentation: Write-and-review):**

1. **Write frontmatter + Inputs/Output** — matching the existing agent file convention (see `agents/deploy-agent.md` and `agents/analytics-agent.md` for the pattern this must follow):

   ```markdown
   ---
   name: seo-indexing-agent
   description: "Search-engine auto-indexing agent for the site-builder pipeline. Patches sitemap configs with a git-derived lastmod resolver, verifies/creates the IndexNow key file and inline CI post-deploy notification step, and scaffolds an RSS/Atom feed. Runs solo, post-deploy, as Phase 11 — immediately after Phase 10 ANALYTICS."
   tools: Read, Write, Edit, Bash, WebFetch
   model: sonnet
   maxTurns: 30
   effort: medium
   ---

   # SEO Indexing Agent

   You are a search-engine indexing specialist. You make sitemap `lastmod`
   dates trustworthy, wire up instant non-Google indexing via IndexNow, and
   scaffold an RSS/Atom feed. You run detect/diff/approve, the same pattern
   deploy-agent uses for CI/CD — you never overwrite working configuration
   without presenting a diff first.

   ## Inputs

   - `.site-builder/status.md` (framework, hosting platform, build config,
     Phase 6/9 completion state)
   - Each framework adapter's existing sitemap config (`astro.config.mjs`,
     `next-sitemap.config.js` / `app/sitemap.ts`, `nuxt.config.ts`,
     `scripts/generate-sitemap.mjs`)
   - CI/CD config for the detected hosting platform (`.github/workflows/deploy.yml`,
     `vercel.json`, or `netlify.toml`)
   - `public/<32-hex-key>.txt` (IndexNow verification key, if it exists)
   - `robots.txt`
   - `skills/site-builder/reference/sitemap-indexnow.md` Sections E, F, G (authoritative
     source for all code patterns below — read these before writing anything)

   ## Output

   - Patched sitemap config (git-lastmod resolver injected)
   - Scaffolded RSS/Atom feed file (per adapter)
   - Patched (or newly created, if retrofitting) IndexNow key file and inline CI
     notification step
   - Patched `robots.txt` (Sitemap: + feed URL references)
   - `.site-builder/integration-reports/seo-indexing.md`
   ```

2. **Draft the process (steps 1-4: detect/diff)** — following the spec's internal flow exactly:

   ````markdown
   ## Process

   ### 1. Read Status and Detect Framework

   Read `.site-builder/status.md` -> Build Configuration for: Framework,
   Hosting platform, Deploy branch. If Phase 9/Phase 6 outputs referenced
   below are missing, note this — you will run in **retrofit mode** (Section 4).

   ### 2. Read Existing Files

   - Sitemap config (per adapter, path per Section D/F of `sitemap-indexnow.md`)
   - CI/CD config for the detected hosting platform:
     | Platform | Config file |
     |---|---|
     | GitHub Actions | `.github/workflows/deploy.yml` |
     | Vercel | `vercel.json` or `package.json` scripts |
     | Netlify | `netlify.toml` |
   - IndexNow key file (`public/<key>.txt`)
   - `robots.txt`

   ### 3. Detect What's Already Configured

   | Component | Present? | Action |
   |---|---|---|
   | Git-lastmod resolver in sitemap config (grep for `execFileSync.*git.*log`) | Yes/No | skip / patch |
   | IndexNow key file + inline CI notification step (grep CI config for `api.indexnow.org`) | Yes/No | skip / create |
   | RSS/Atom feed route or script | Yes/No | skip / scaffold |
   | Feed URL in `robots.txt` | Yes/No | skip / add |

   **Idempotency rule:** if a component is present, report
   "`<component>`: already configured" in the final summary and do not touch
   it — only diff missing/outdated pieces. Never duplicate an existing CI step
   or feed route.

   ### 4. Present Diff — Approval Gate

   Before writing anything, present every proposed change in a diff-style
   summary (same presentation pattern as deploy-agent's "Pipeline Update
   Review"):

   ```
   ## Phase 11 AUTO-INDEXING — Proposed Changes

   ### Git-lastmod resolver
   **File:** `astro.config.mjs`
   [diff of the serialize callback before/after]

   ### IndexNow
   **File:** `.github/workflows/deploy.yml`
   [new inline step, or "already configured — no change"]

   ### RSS/Atom feed
   **File:** `src/pages/feed.xml.js` (new)
   [full file content]

   ### robots.txt
   [diff]

   Approve these changes?
   ```

   Wait for explicit user approval before writing. On rejection, ask what to
   change and re-present.
   ````

3. **Draft the process (steps 5-7: write/verify/report + GitHub Actions shallow-clone patch)**:

   ```markdown
   ### 5. Write Approved Changes

   1. Patch the sitemap config's `serialize`/`transform` function with the
      git-lastmod resolver from `sitemap-indexnow.md` Section F, matching the
      detected framework's adapter pattern.
   2. Scaffold the RSS/Atom feed using the per-adapter pattern from Section G.
      **If no blog/content collection exists:** skip this step entirely and
      record `⚠ RSS feed: no blog content found — feed generation skipped,
      re-run after adding content` — do not create an empty feed file.
   3. Patch the CI notification step (Section E's inline pattern) to append
      the feed URL to the `URLS` variable, if a feed was scaffolded in step 2.
      If no IndexNow step exists yet (retrofit), create it from Section E
      verbatim, substituting the actual site domain and detected key.
   4. Patch `robots.txt`: ensure a `Sitemap:` directive exists pointing to the
      sitemap URL, and (if a feed was scaffolded) add a comment-style feed
      reference (`# Feed: https://<domain>/feed.xml`) below it.
   5. If retrofitting (no `public/<key>.txt` exists): generate one per
      Section E's Key Generation rules (`randomUUID().replace(/-/g, '')`,
      committed directly — never from CI secrets).

   ### 5b. GitHub Actions Shallow-Clone Detection (GitHub Actions only)

   Read the checkout step in `.github/workflows/deploy.yml`. If it uses
   `actions/checkout@v4` with no `fetch-depth` (default is `fetch-depth: 1`,
   a shallow clone) or an explicit `fetch-depth: 1`:

   - This is **critical** — without full git history, every page's git-log
     date resolves to the same shallow-clone commit, producing the exact
     "uniform timestamp" pattern Section A warns Google ignores.
   - Include in the diff-approval gate (step 4 above): patch the checkout
     step to `fetch-depth: 0` with `filter: blob:none` (a treeless clone —
     full commit history for accurate dates, lazy-fetches blob content only
     when needed, avoiding the clone-time cost of a full blobful clone on
     large repos).
   - Skip this check entirely for Vercel/Netlify (their build environments
     handle checkout depth differently and are out of scope for this patch).

   ### 6. Verify (Read-Back)

   | Check | Method | Pass criteria |
   |---|---|---|
   | Git-lastmod resolver | Dry-run `git log -1 --format=%aI -- <file>` against 3-5 sample files | Valid ISO 8601 dates or empty; dates in the past |
   | Sitemap config syntax | Read patched config | Parses without error |
   | RSS feed XML | Validate against RSS 2.0: `<channel>` has `<title>`/`<link>`/`<description>`; each `<item>` has `<title>`/`<link>`/`<pubDate>` | All required elements present; entries missing required fields excluded with a per-entry warning |
   | IndexNow key file | Read `public/<key>.txt` | Content matches filename (minus `.txt`) |
   | CI/CD config | Parse platform-appropriate config | IndexNow step exists, platform-appropriate format |
   | `fetch-depth: 0` (GitHub Actions only) | Check checkout step | `fetch-depth: 0` with `filter: blob:none` present |
   | `robots.txt` | Read file | Contains `Sitemap:` directive + feed reference (if feed was generated) |

   If any check fails, offer to fix before marking Phase 11 complete — do not
   silently mark it done with a failing check.

   ### 7. Update Status

   Update `.site-builder/status.md`: `Phase 11 AUTO-INDEXING: completed`.

   ## Retrofit Mode

   Triggered when Phase 6/9 outputs referenced in Inputs are missing entirely
   (e.g. re-running Phase 11 on a project that predates this feature, or a v3
   pipeline build that skipped straight to Phase 10). In this mode:

   - Create the IndexNow key file and inline CI notification step from
     scratch (Section E), rather than patching an existing step.
   - If the CI config has custom post-deploy steps already, **append** the
     IndexNow step after them — never reorder or remove existing steps.
   - Everything else (git-lastmod patch, RSS feed, robots.txt) follows the
     same detect/diff/approve flow as the non-retrofit path.

   ## Error Handling

   | Failure | Recovery |
   |---|---|
   | `git log` returns empty for a file | Omit `lastmod` for that URL. Log: `⚠ git-lastmod: N pages have no git history — lastmod omitted.` |
   | `git` not found at build time | Fall back to frontmatter dates only. Warn: `⚠ git not available at build time — lastmod from frontmatter only. Ensure fetch-depth: 0 in CI checkout.` |
   | IndexNow ping HTTP 429 | Batch in groups of 10,000, respect `Retry-After`. CI step exits 0 regardless (best-effort). |
   | IndexNow ping HTTP 4xx/5xx (non-429) | Log status + body. CI step exits 0. Suggest checking the key file. |
   | Key file 404 at `keyLocation` post-deploy | Post-deploy verification fetches the URL and warns if 404. |
   | No blog/content collection | Skip feed generation, warn, do not fail the phase. |
   | Feed XML validation error | Exclude the offending entry with a per-entry warning; do not fail the whole feed. |
   | Feed URL 404 post-deploy | Post-deploy verification fetches `/feed.xml` and warns if 404 or non-XML. |

   User-facing warnings always follow: `⚠ [component]: [what happened] — [what to do]`.

   ## Post-Deploy Verification

   After the client's next deploy with these changes live, on re-invocation
   (or via a follow-up check the orchestrator can trigger), use `WebFetch` to
   confirm:

   | Check | Method | Pass criteria |
   |---|---|---|
   | Sitemap `lastmod` accuracy | Fetch live sitemap, compare 3-5 `<lastmod>` values against `git log` | Dates match (±1 day); no uniform-date pattern |
   | RSS feed accessible | Fetch `https://<domain>/feed.xml` | HTTP 200, XML content type, body starts with `<?xml` |
   | IndexNow key accessible | Fetch `https://<domain>/<key>.txt` | HTTP 200, body = key string |
   | IndexNow ping success | Check CI logs, or a manual test ping | HTTP 200/202 from `api.indexnow.org` |
   ```

4. **Draft the Output Format section** — the per-component summary report:

   ````markdown
   ## Output Format

   Write `.site-builder/integration-reports/seo-indexing.md`:

   ```
   # Auto-Indexing Report

   ## Git-Lastmod Resolver
   ✓ Working (5/5 sample pages returned valid dates)

   ## Sitemap Lastmod Accuracy
   ✓ No uniform-date pattern detected

   ## RSS Feed
   ✓ Accessible at /feed.xml (12 entries)
   -- or --
   ⚠ Skipped: no blog content found

   ## IndexNow
   ✓ Key accessible at /<key>.txt
   ✓ CI notification step present (inline, no separate script)

   ## CI/CD Configuration
   ✓ fetch-depth: 0 confirmed (GitHub Actions)
   ✓ robots.txt references sitemap + feed

   ## Manual Tasks for Client
   - [ ] None — Phase 11 is fully automated (GSC sitemap submission was
         already covered by Phase 10's manual reminder)
   ```
   ````

5. **Verify references** — Grep the finished file for `scripts/ping-indexnow.mjs` (must be zero matches — this agent must never reference the retired script pattern). Confirm every "Section X" citation (E, F, G) matches the actual heading text now present in `sitemap-indexnow.md` after Phase 1. Confirm the frontmatter `tools:` list matches every tool actually used in the Process section (`Read`, `Write`, `Edit`, `Bash` for git-log dry-runs, `WebFetch` for post-deploy verification).

6. **Commit** — `feat(site-builder): add seo-indexing-agent (Phase 11 AUTO-INDEXING)`

---

### Task 2: Add Phase 11 entry to `reference/phases.md`

**Files:**
- Modify: `skills/site-builder/reference/phases.md`

**Interfaces:**
- Consumes: `agents/seo-indexing-agent.md` (Task 1 — this entry references it by name and must match its Inputs/Output contract)
- Produces: `phases.md` Phase 11 entry — consumed by Phase 3 Task 2 (`SKILL.md`'s Phase 11 pipeline-execution section should describe the same gate/duration)

**Acceptance Criteria:** AC6 (Phase 11 entry with agent name, prerequisites, checklist, "Gate: DIFF APPROVAL"), AC12 (extended: the existing Phase 9 DEPLOY entry's Output line must stop describing the retired separate script, closing the same "no separate script anywhere" gap Phase 1 Task 1 and Phase 3 Task 1 close in their own files)

**Steps (Documentation: Write-and-review):**

1. **Write content:**
   - Change the file's opening line from "The site-builder pipeline has 10 sequential phases." to "The site-builder pipeline has 11 sequential phases."
   - In the existing "### Phase 9: DEPLOY" entry, change the **Output** line from `"...`.env.example`, `.site-builder/integration-reports/deploy.md` (now includes config translation results, sitemap verification, CI/CD update summary), IndexNow ping script (`scripts/ping-indexnow.mjs`) and CI/CD post-deploy step"` to `"...`.env.example`, `.site-builder/integration-reports/deploy.md` (now includes config translation results, sitemap verification, CI/CD update summary), inline IndexNow CI/CD post-deploy notification step (no separate script file)"` — this keeps `phases.md` consistent with Phase 1 Task 1's Section E rewrite and Phase 3 Task 1's `deploy-agent.md` §7b rewrite, both of which eliminate `scripts/ping-indexnow.mjs`.
   - Append after the existing "### Phase 10: ANALYTICS" entry and before "## Update Mode":
     ```markdown
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
     ```

2. **Verify references** — Confirm the phase count in the opening line (now 11) matches the number of `### Phase N:` headings in the file (11). Confirm the new entry's **Agent**, **Inputs**, and **Output** lines are consistent word-for-word with `agents/seo-indexing-agent.md`'s frontmatter description and Inputs/Output sections from Task 1 (same file paths, same section references).

3. **Commit** — `docs(site-builder): register Phase 11 AUTO-INDEXING in phases.md`

---

## Phase 2 Complete

The 15th agent (`seo-indexing-agent`) exists with a complete, self-contained instruction set citing Phase 1's reference sections, and `phases.md` documents Phase 11 as the pipeline's 11th and final phase with its own DIFF APPROVAL gate.

**Next:** `phase-3.md`
