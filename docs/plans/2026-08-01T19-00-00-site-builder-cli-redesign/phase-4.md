# Phase 4: Agent Updates

**Repo:** site-builder-plugin
**Depends on:** Phase 3 (the orchestrator-side hosting question, Phase 10 ANALYTICS spawn, and Phase 6 analytics-scaffolding expectation must exist before the agents that consume/produce them are updated to match)
**Delivers:** `deploy-agent.md` is hosting-agnostic and receives the hosting choice as orchestrator input instead of asking itself; `developer-agent.md` drops its last `stage`-branch reference and documents the Phase 6 analytics scaffolding step; `analytics-agent.md` reflects its new solo Phase 10 post-deploy role, consuming that scaffolding with live-URL verification.

## File Structure

```
agents/
├── deploy-agent.md       (modify — frontmatter, Section 2 hosting)
├── developer-agent.md    (modify — line 72 stage reference, new analytics scaffolding step)
└── analytics-agent.md    (modify — frontmatter, Inputs, live verification)
```

---

### Task 1: `deploy-agent.md` — hosting-agnostic, receives hosting choice as input

**Files:**
- Modify: `agents/deploy-agent.md`

**Interfaces:**
- Consumes: The hosting platform value the orchestrator now injects (Phase 3 Task 2 of this plan, `### Phase 9: DEPLOY` step 0).
- Produces: No interface other agents in this plan consume — `deploy-agent.md` is a leaf agent definition.

**Acceptance Criteria:** "Deploy phase hosting question is asked by the orchestrator before spawning deploy-agent; hosting choice is passed as input to the agent. deploy-agent.md frontmatter updated to remove 'Vercel/Netlify/AWS' and say 'hosting-agnostic deployment'".

**Steps (Write-and-review):**

1. **Write content.** Change the frontmatter `description` field from:

   ```yaml
   description: "Deployment and CI/CD agent for the site-builder pipeline. Sets up GitHub Actions, deploys to Vercel/Netlify/AWS, configures environments, tests deployment, and documents rollback. Final agent in the pipeline."
   ```

   to:

   ```yaml
   description: "Hosting-agnostic deployment and CI/CD agent for the site-builder pipeline. Sets up GitHub Actions, deploys to whichever platform the orchestrator specifies, configures environments, tests deployment, and documents rollback. Runs before the final Phase 10 ANALYTICS agent."
   ```

   Replace the `### 2. Determine Hosting Platform` section — currently:

   ```markdown
   ### 2. Determine Hosting Platform

   Based on tech stack and user preference:

   | Framework | Recommended hosting | Alternative |
   |-----------|-------------------|-------------|
   | Astro (static) | Vercel or Netlify | GitHub Pages, AWS S3+CloudFront |
   | Astro (SSR) | Vercel | Netlify, AWS Lambda |
   | Next.js | Vercel | AWS, Docker |
   | Vue/Nuxt | Vercel or Netlify | AWS, Docker |
   | React SPA | Vercel, Netlify, or S3 | Any static hosting |

   If the user hasn't specified, recommend Vercel (best DX, free tier, auto-deployments).

   Ask the user which hosting platform they prefer before proceeding.
   ```

   with:

   ```markdown
   ### 2. Hosting Platform (Orchestrator-Provided)

   The orchestrator asks "Where do you want to deploy?" before spawning you
   and passes the answer as an explicit input — you do not ask the user
   yourself. The input is one of: `vercel`, `netlify`, `custom` (VPS, shared
   hosting, IIS, self-managed), or `other` (with a user-provided detail
   string).

   If the input is `custom` or `other` and the target platform isn't covered
   by Sections 3-8 below, adapt the CI/CD and deployment steps to that
   platform's documented deployment method (e.g. rsync/FTP for shared
   hosting, `docker build` + registry push + `docker run`/orchestrator deploy
   for a VPS). Note any manual steps the client must perform in the deploy
   report's Client Instructions section.

   For reference, here's how framework choice interacts with common
   platforms (informational — the platform itself is already decided):

   | Framework | Vercel | Netlify | Custom hosting |
   |-----------|--------|---------|-----------------|
   | Astro (static) | ✅ | ✅ | ✅ (static export) |
   | Astro (SSR) | ✅ | ✅ (adapter) | Requires Node.js runtime — flag if custom hosting is shared/static-only |
   | Next.js | ✅ | ✅ (adapter, limited) | Requires Node.js runtime — flag if custom hosting is shared/static-only |
   | Vue/Nuxt | ✅ | ✅ (adapter) | Requires Node.js runtime for SSR — static export works everywhere |
   | React SPA | ✅ | ✅ | ✅ (static hosting) |
   ```

2. **Verify references.** Grep the file for `Vercel/Netlify/AWS` and `Ask the user which hosting platform they prefer` — both absent. Grep for `Final agent in the pipeline` — absent (Phase 10 is now final).
3. **Commit:** `docs(deploy-agent): make hosting-agnostic, receive hosting choice as orchestrator input`

---

### Task 2: `developer-agent.md` — remove stage reference, add analytics scaffolding step

**Files:**
- Modify: `agents/developer-agent.md`

**Interfaces:**
- Consumes: None new.
- Produces: The Phase 6 analytics scaffolding (GA4 snippet, cookie consent banner, conversion event stubs with placeholder env vars) that Task 3 (`analytics-agent.md`) consumes.

**Acceptance Criteria:** "All references to 'stage' mode are removed from... developer-agent.md", "Phase 6 DEVELOP lays down analytics scaffolding code (GA4 snippet, cookie consent banner, conversion event stubs)".

**Steps (Write-and-review):**

1. **Write content.** In `### 1. Project Scaffold`, update the note that references the old pipeline version — replace:

   ```markdown
   > **Note:** In the 9-phase pipeline (v2), scaffolding is handled during **Phase 3 PREPARE**...
   ```

   with:

   ```markdown
   > **Note:** In the 10-phase pipeline (v3), scaffolding is handled during **Phase 3 PREPARE**...
   ```

   In `### 0. Migration Safety (redesign with tech stack change)`, replace the current line:

   ```markdown
   Since all work happens on a `demo` or `stage` branch (or `DEPLOY_BRANCH` in prod mode), the original code is safely preserved on the production branch. No backup folder is needed.
   ```

   with:

   ```markdown
   Since all work happens on `local-dev` (with phase-boundary PRs targeting `demo` or `DEPLOY_BRANCH` depending on mode), the original code is safely preserved on the production branch. No backup folder is needed.
   ```

   After `### 8. SEO Implementation` and before `### 9. URL Redirects (redesign only)`, insert a new section:

   ```markdown
   ### 8b. Analytics Scaffolding

   Lay down tracking infrastructure now, using placeholder environment
   variables — Phase 10 ANALYTICS (post-deploy) collects the real credentials
   and injects them. Do not block on the user having real IDs at this stage.

   - **GA4 snippet:** add the `gtag.js` loading pattern to the site's `<head>`
     (via layout component), framework-appropriate per the adapter file.
     Reference the tracking ID via an environment variable
     (`PUBLIC_GA4_ID` / `NEXT_PUBLIC_GA4_ID`), left as a placeholder. Add a
     matching entry to `.env.example`.
   - **Cookie consent banner:** add a minimal consent banner component with
     Necessary/Analytics/Marketing categories, storing the user's choice in
     `localStorage`. Gate GA4 (and any other tracking scaffolded here) behind
     analytics consent — do not fire before consent.
   - **Conversion event stubs:** wire up (but leave inert until GA4 has a real
     ID) event handlers for: form submission, `tel:` link clicks, primary CTA
     clicks, `mailto:` link clicks.

   This scaffolding must not break `npm run build` even with placeholder
   environment variables unset — guard tracking initialization on the
   presence of a real ID, not just on consent.
   ```

2. **Verify references.** Grep the file for `stage` branch — absent. Grep for `### 8b. Analytics Scaffolding` — exactly one match, positioned between `### 8. SEO Implementation` and `### 9. URL Redirects (redesign only)`.
3. **Commit:** `docs(developer-agent): drop stage branch reference, add Phase 6 analytics scaffolding step`

---

### Task 3: `analytics-agent.md` — Phase 10 solo role, live-URL verification

**Files:**
- Modify: `agents/analytics-agent.md`

**Interfaces:**
- Consumes: The live deployment URL (from Phase 3 Task 2's Phase 10 spawn prompt) and the Phase 6 analytics scaffolding Task 2 (`developer-agent.md`) just added.
- Produces: The verification results in `.site-builder/integration-reports/analytics.md` that Phase 3 Task 2's Phase 10 approval gate presents to the user.

**Acceptance Criteria:** "`analytics-agent.md` frontmatter updated: description changed from 'Phase 7 parallel with social-integration-agent' to reflect Phase 10 solo post-deploy role", "Phase 10 ANALYTICS (new) runs after deploy: reuses existing `analytics-agent` with narrowed scope... Phase 10 asks user for real credentials..., injects them, and verifies tracking fires on the deployed URL".

**Steps (Write-and-review):**

1. **Write content.** Change the frontmatter `description` field from:

   ```yaml
   description: "Analytics and tracking agent for the site-builder pipeline. Sets up GA4, GSC, Bing Webmaster, tracking events, and privacy compliance. Runs in parallel with social-integration-agent during Phase 7."
   ```

   to:

   ```yaml
   description: "Analytics and tracking agent for the site-builder pipeline. Connects real credentials to the GA4/GSC/Bing/tracking scaffolding already laid down in Phase 6 DEVELOP, and verifies tracking fires on the live deployed URL. Runs solo, post-deploy, as Phase 10 — the final phase of the pipeline."
   ```

   Add `WebFetch` to the frontmatter `tools` line (needed for live-URL verification) — change:

   ```yaml
   tools: Read, Write, Edit
   disallowedTools: Bash
   ```

   to:

   ```yaml
   tools: Read, Write, Edit, WebFetch
   disallowedTools: Bash
   ```

   In the `## Inputs` list, add a line after the existing `.site-builder/site-architecture.md` entry:

   ```markdown
   - Live deployment URL (from Phase 9 DEPLOY's report — this is what distinguishes Phase 10 from a pre-deploy run)
   ```

   Immediately after the `## Process` heading and before `### 1. Ask Connection Method`, insert:

   ```markdown
   ### 0. Context: You're Running Post-Deploy

   You are always invoked as Phase 10, after the site is already live. Phase 6
   DEVELOP already scaffolded tracking snippets, the cookie consent banner,
   and conversion event stubs into the codebase — placeholder environment
   variables only, no real IDs. Your job here is narrower than a from-scratch
   setup: collect the real credentials for whatever was scaffolded, inject
   them, and confirm they actually work on the live URL. If Phase 6's
   scaffolding is missing entirely for a platform the user wants (e.g. they
   decide to add Clarity now, having skipped it during DEVELOP), you can still
   add it fresh — the sections below cover both cases.
   ```

   After the existing `## Cookie Consent` section (the last content section
   before `## Output Format`), add:

   ```markdown
   ## 7. Live Verification

   For every platform marked "Installed" (not skipped, not "not needed"):

   1. Use `WebFetch` to fetch the live deployment URL.
   2. Confirm the platform's tracking script/tag appears in the rendered HTML
      with the *real* credential injected — not the placeholder. For example,
      for GA4 confirm the `gtag('config', 'G-XXXXXXX')` call uses the actual
      measurement ID the user provided, not `PUBLIC_GA4_ID` literally.
   3. If a script only loads after cookie consent (per the Cookie Consent
      section above), verify the *scaffolding* is correct (consent gate
      present, correct script src) rather than a fired network request —
      `WebFetch` reads the static/rendered HTML, it cannot simulate a user
      clicking "accept" or observe a `dataLayer` push.
   4. Record per-platform: `✅ Verified on live URL` / `⚠️ Scaffolded but
      injected ID not found — check environment variable name` / `ℹ️ Requires
      manual client verification (e.g. GSC, Bing ownership)`.

   Report any `⚠️` results to the user before the pipeline's Phase 10
   approval gate — do not silently mark verification as passed.
   ```

2. **Verify references.** Grep the file for `Phase 7` — absent (Phase 7 was AUDIT, not INTEGRATE, and analytics no longer runs there at all). Grep for `## 7. Live Verification` and `### 0. Context: You're Running Post-Deploy` — each present exactly once. Confirm `tools: Read, Write, Edit, WebFetch` in frontmatter.
3. **Commit:** `docs(analytics-agent): reflect Phase 10 solo post-deploy role with live verification`

---

## Phase 4 Complete

All three affected agent files now match the redesigned pipeline: `deploy-agent.md` is hosting-agnostic and input-driven, `developer-agent.md` scaffolds analytics infrastructure in Phase 6 without a stale `stage` branch reference, and `analytics-agent.md` documents its new solo post-deploy role consuming that scaffolding with live verification.

**Next:** `phase-5.md`
