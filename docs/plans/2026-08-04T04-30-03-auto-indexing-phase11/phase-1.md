# Phase 1: Reference Doc Foundation

**Repo:** site-builder-plugin
**Depends on:** None
**Delivers:** `skills/site-builder/reference/sitemap-indexnow.md` with Section E rewritten to the inline-only IndexNow CI pattern, new Section F (git-derived lastmod resolver), new Section G (RSS/Atom feed generation), and a forward-reference appended to Section A. This is the single source of truth every later phase cites by section letter.

## File Structure

```
skills/site-builder/reference/
└── sitemap-indexnow.md   [MODIFY — 4 tasks, same file, sequential edits]
```

### Task 1: Rewrite Section E to the inline-only IndexNow CI pattern

**Files:**
- Modify: `skills/site-builder/reference/sitemap-indexnow.md`

**Interfaces:**
- Consumes: none (Section E already exists in the file; this task rewrites it in place)
- Produces: `sitemap-indexnow.md` Section E (rewritten) — "IndexNow key generation stays as-is; ping mechanism is inline CI shell (`grep`/`jq`/`curl`), no `scripts/ping-indexnow.mjs`". Consumed by Phase 3 Task 1 (`deploy-agent.md` §7b rewrite) and Phase 2 Task 1 (`seo-indexing-agent.md` extends this same inline step with the feed URL).

**Acceptance Criteria:** AC11 (IndexNow key file committed directly, unchanged), AC12 (IndexNow notification entirely inline, no separate script, `grep`/`jq`/`curl`, includes RSS feed URL later), AC13 (no WebSub/PubSubHubbub)

**Steps (Documentation: Write-and-review):**

1. **Write content** — Replace BOTH the "### Ping Script (Phase 9 -- deploy-agent)" subsection (the `scripts/ping-indexnow.mjs` Node script block) AND the immediately-following "### CI/CD Integration (Phase 9 -- deploy-agent)" subsection (the one with `run: node scripts/ping-indexnow.mjs` for GitHub Actions, and the Vercel/Netlify bullets) with a single combined "### Inline CI Notification (Phase 9 -- deploy-agent)" subsection — the new subsection folds the old CI/CD Integration subsection's per-platform wiring directly into the new inline pattern, so there is exactly one subsection covering "what to add to the CI config," not two adjacent ones. New content:

   ````markdown
   ### Inline CI Notification (Phase 9 -- deploy-agent)

   No separate script file is created. The post-deploy notification step lives
   entirely inline in the CI/CD workflow config, using `grep`/`jq`/`curl`.

   **GitHub Actions** -- add after the deploy step in `.github/workflows/deploy.yml`:

   ```yaml
   - name: Notify search engines via IndexNow
     run: |
       SITE="https://<site-domain>"
       SITEMAP_PATH="<output-dir>/sitemap-0.xml"   # see path table below
       KEY_FILE=$(find public -maxdepth 1 -regextype posix-extended -iregex '.*/[a-f0-9]{32}\.txt' | head -1)
       KEY=$(basename "$KEY_FILE" .txt)
       URLS=$(grep -oE '<loc>[^<]+</loc>' "$SITEMAP_PATH" | sed -E 's#</?loc>##g')
       if [ -z "$URLS" ]; then
         echo "No URLs found in sitemap -- skipping IndexNow ping"
         exit 0
       fi
       URL_LIST_JSON=$(printf '%s\n' "$URLS" | jq -R . | jq -s .)
       HOST=$(echo "$SITE" | sed -E 's#https?://##')
       PAYLOAD=$(jq -n --arg host "$HOST" --arg key "$KEY" \
         --arg keyLocation "$SITE/$KEY.txt" --argjson urlList "$URL_LIST_JSON" \
         '{host: $host, key: $key, keyLocation: $keyLocation, urlList: $urlList}')
       STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST https://api.indexnow.org/indexnow \
         -H "Content-Type: application/json; charset=utf-8" -d "$PAYLOAD")
       echo "IndexNow ping: HTTP $STATUS"
       exit 0   # best-effort -- never fail the deploy on a notification error
   ```

   **Vercel** -- add the same `grep`/`jq`/`curl` sequence as a post-build command in
   `vercel.json` (`"buildCommand"` chain) or a deploy hook script invoked from there
   (still no persisted `.mjs` file in the repo -- the shell block is inlined into the
   hook's command string).

   **Netlify** -- add the same sequence as a `run` command in a `[[plugins]]` entry's
   `onSuccess` lifecycle in `netlify.toml`, or as a post-processing command.

   **Framework-specific sitemap output paths:**

   | Framework | Sitemap Path |
   |-----------|-------------|
   | Astro | `dist/sitemap-0.xml` or `dist/sitemap-index.xml` |
   | Next.js | `public/sitemap-0.xml` or `.next/server/app/sitemap.xml` |
   | Nuxt | `.output/public/sitemap.xml` |
   | React SPA | `dist/sitemap.xml` |

   The deploy-agent must detect the correct path based on the framework in
   `status.md` -> Build Configuration -> Framework, and substitute it for
   `<output-dir>/sitemap-0.xml` above.
   ````

2. **Reword the stale "Important Notes" bullets** — the existing "Important Notes" subsection at the end of Section E has two bullets written for the retired Node.js script: `"Max 10,000 URLs per POST -- script handles batching"` and `"Requires Node.js >= 18 for native fetch and ES modules"`. Reword both for the inline CI step: `"Max 10,000 URLs per POST -- batch in groups of 10,000 in the inline shell loop if exceeded (see Performance note below)"` and drop the Node.js-version bullet entirely (the inline step only needs `curl`/`jq`/`grep`, all standard on GitHub Actions/Vercel/Netlify runners — no Node.js version requirement applies).

3. **Verify references** — Grep the file for any remaining mentions of `scripts/ping-indexnow.mjs` or `ping-indexnow.mjs` outside of a "no longer used" historical note; there must be zero, including in the now-merged CI/CD Integration content (step 1) and the Important Notes subsection (step 2). Confirm the "Important Notes" subsection still lists the 7 participating engines and the 10,000-URL batch limit, now worded for the inline step (add a one-line batching caveat to the inline step itself: "For sites with >10,000 URLs, split `URL_LIST_JSON` into batches of 10,000 in a loop — same logic as the old script, now inline").

4. **Commit** — `docs(site-builder): rewrite IndexNow Section E to inline-only CI pattern`

---

### Task 2: Add Section F — Git-Derived Lastmod Resolver

**Files:**
- Modify: `skills/site-builder/reference/sitemap-indexnow.md`

**Interfaces:**
- Consumes: Section D (existing, framework-specific `lastmod` implementation patterns) — Section F extends these with git-log resolution, does not replace them
- Produces: `sitemap-indexnow.md` Section F (heading `## Section F: Git-Derived Lastmod Resolver`) — consumed by Phase 2 Task 1 (`seo-indexing-agent.md` cites Section F as its authoritative resolver source) and Phase 4 Tasks 1-2 (adapter cross-reference lines point here)

**Acceptance Criteria:** AC2 (Section F documents `execFileSync` resolver, per-adapter snippets, URL-to-source-file mapping, content-aware strategy, `_lastmod.json` manifest, omits `lastmod` when neither source exists), AC3 (security note)

**Steps (Documentation: Write-and-review):**

1. **Write content** — Insert a new `## Section F: Git-Derived Lastmod Resolver` heading immediately after Section E (before the file's end), with:

   a. **Security note** (first, prominent):
      ```markdown
      > **Security requirement:** NEVER use `execSync` with string interpolation
      > for git commands -- always use `execFileSync` with an argument array to
      > prevent command injection via filenames.
      ```

   b. **Core resolver logic** (shared pseudocode, matches the spec's Git-lastmod resolver logic section):
      ```js
      import { execFileSync } from 'node:child_process';

      function getGitDate(filePath) {
        try {
          const out = execFileSync(
            'git', ['log', '-1', '--format=%aI', '--', filePath],
            { encoding: 'utf-8' }
          ).trim();
          return out || null; // empty = untracked/no history
        } catch {
          return null; // git unavailable at build time
        }
      }
      ```

   c. **URL-to-source-file mapping table** (condensed from the spec — the spec's version includes example file paths per row, e.g. `src/content/blog/my-post.md`, `/services/[slug]`, and longer Notes-column rationale; reproduce those examples inline when writing the actual table into the file, not just the condensed version below):
      | Page type | Source file for git date | Notes |
      | --- | --- | --- |
      | Content collection (blog `.md`/`.mdx`) | The content file itself | Git dates are reliable — content changes dominate |
      | Static pages (`.astro`, `.tsx`, `.vue`) | The page component file | Prefer manual `pageLastmod` map with git date as fallback |
      | Data-driven dynamic routes | The data source file (JSON/YAML/TS) | Template file's git date as fallback if data source has no history |
      | Category/tag/pagination pages | Most recent content file in the collection | Reflects when the collection last changed |
      | Composite pages | The primary content source file only | Documented trade-off |

   d. **Per-adapter code** (extend each Section D example with the resolver):
      - Astro (`astro.config.mjs`):
        ```js
        import { execFileSync } from 'node:child_process';
        import { readdirSync, readFileSync } from 'node:fs';
        import { join } from 'node:path';

        function getGitDate(filePath) {
          try {
            return execFileSync('git', ['log', '-1', '--format=%aI', '--', filePath], { encoding: 'utf-8' }).trim() || null;
          } catch { return null; }
        }

        function getBlogDates() {
          const dir = './src/content/blog';
          const dates = {};
          try {
            for (const file of readdirSync(dir).filter(f => f.endsWith('.md') || f.endsWith('.mdx'))) {
              const filePath = join(dir, file);
              const content = readFileSync(filePath, 'utf-8');
              const slug = file.replace(/\.mdx?$/, '');
              const frontmatterDate = content.match(/updatedDate:\s*(\d{4}-\d{2}-\d{2})/)?.[1]
                || content.match(/publishDate:\s*(\d{4}-\d{2}-\d{2})/)?.[1] || null;
              const gitDate = getGitDate(filePath);
              // frontmatter overrides when newer than the git date
              dates[`/blog/${slug}/`] = (frontmatterDate && (!gitDate || frontmatterDate > gitDate.slice(0, 10)))
                ? frontmatterDate
                : gitDate; // may be null -- omit lastmod for that URL
            }
          } catch { /* no blog content directory */ }
          return dates;
        }

        // Static/component pages: manual pageLastmod map is primary, git date is fallback
        const pageLastmod = { '/': '2026-06-15' /* ...maintained manually... */ };
        function getStaticLastmod(url, sourceFile) {
          return pageLastmod[url] || getGitDate(sourceFile) || undefined;
        }
        ```
      - Next.js (`next-sitemap.config.js` `transform`, and `_lastmod.json` manifest for App Router SSR):
        ```js
        // scripts/generate-lastmod-manifest.mjs -- build-time, for app/sitemap.ts (SSR, no git at request time)
        import { execFileSync } from 'node:child_process';
        import { writeFileSync, readdirSync, readFileSync } from 'node:fs';

        function getGitDate(filePath) {
          try {
            return execFileSync('git', ['log', '-1', '--format=%aI', '--', filePath], { encoding: 'utf-8' }).trim() || null;
          } catch { return null; }
        }

        const manifest = {}; // url -> ISO date | null, populated per the mapping table above
        writeFileSync('_lastmod.json', JSON.stringify(manifest, null, 2));
        ```
        ```ts
        // app/sitemap.ts
        import manifest from '../_lastmod.json';
        export default function sitemap(): MetadataRoute.Sitemap {
          return routes.map(r => ({ url: r.url, lastModified: manifest[r.url] ?? undefined }));
        }
        ```
      - Vue/Nuxt (`nuxt.config.ts` `urls` function): same `getGitDate` helper, applied per blog/static URL entry before returning the array.
      - React SPA (`scripts/generate-sitemap.mjs`): same `getGitDate` helper called per page before writing `dist/sitemap.xml`.

   e. **Performance note** (batch resolver, from the spec):
      ```markdown
      **Performance:** for sites with 200+ pages, sequential `execFileSync` per
      file adds 10-40s to builds. Prefer a single batch call:
      `git log --format='%aI' --name-only` across the content directory in one
      subprocess, parsing all dates from the combined output instead of one
      `execFileSync` per file.
      ```

   f. **Build-time-only requirement** (from the spec): "Git-lastmod resolution MUST happen at build time, not request time — see the `_lastmod.json` manifest pattern above for Next.js SSR."

2. **Verify references** — Confirm the new Section F heading uses `## Section F:` (H2, matches Section A-E's heading level) and appears before Section G (added in Task 3). Confirm every code block has matching opening/closing triple-backticks (no unterminated fences).

3. **Commit** — `docs(site-builder): add Section F git-derived lastmod resolver`

---

### Task 3: Add Section G — RSS/Atom Feed Generation

**Files:**
- Modify: `skills/site-builder/reference/sitemap-indexnow.md`

**Interfaces:**
- Consumes: Section F's `getGitDate` helper (reused for feed `pubDate`/`updated` values)
- Produces: `sitemap-indexnow.md` Section G (heading `## Section G: RSS/Atom Feed Generation`) — consumed by Phase 2 Task 1 and Phase 4 Tasks 1-2

**Acceptance Criteria:** AC4 (RSS/Atom feed docs for all 4 adapters), AC16 (skip with warning when no content collection), AC17 (RSS 2.0 required-element validation)

**Steps (Documentation: Write-and-review):**

1. **Write content** — Insert `## Section G: RSS/Atom Feed Generation` after Section F, with:

   a. **Skip condition** (from the spec): "If no blog/content collection directory exists (or it exists but is empty), skip feed generation entirely and log: `⚠ RSS feed: no blog content found — feed generation skipped, re-run after adding content`."

   b. **RSS 2.0 required-element checklist** (validated before writing, entries missing required fields excluded with a per-entry warning): `<channel>` must have `<title>`, `<link>`, `<description>`; each `<item>` must have `<title>`, `<link>`, `<pubDate>`.

   c. **Per-adapter code:**
      - Astro (`@astrojs/rss`, `src/pages/feed.xml.js`):
        ```js
        import rss from '@astrojs/rss';
        import { getCollection } from 'astro:content';

        export async function GET(context) {
          const posts = await getCollection('blog');
          const valid = posts.filter(p => p.data.title && p.data.pubDate);
          return rss({
            title: 'Site Name Blog',
            description: 'Latest posts',
            site: context.site,
            items: valid.map(p => ({
              title: p.data.title,
              pubDate: p.data.updatedDate ?? p.data.publishDate,
              description: p.data.description,
              link: `/blog/${p.slug}/`,
            })),
          });
        }
        ```
      - Next.js (App Router route, `src/app/feed.xml/route.ts`):
        ```ts
        import { NextResponse } from 'next/server';

        export async function GET() {
          const posts = getBlogPosts().filter(p => p.title && p.pubDate);
          const items = posts.map(p => `
            <item>
              <title>${p.title}</title>
              <link>https://example.com/blog/${p.slug}</link>
              <pubDate>${new Date(p.pubDate).toUTCString()}</pubDate>
            </item>`).join('');
          const xml = `<?xml version="1.0" encoding="UTF-8"?>
          <rss version="2.0"><channel>
            <title>Site Name Blog</title>
            <link>https://example.com</link>
            <description>Latest posts</description>
            ${items}
          </channel></rss>`;
          return new NextResponse(xml, { headers: { 'Content-Type': 'application/xml' } });
        }
        ```
      - Vue/Nuxt (`server/routes/feed.xml.ts`, or `@nuxtjs/feed` module config): same required-field filter, `defineEventHandler` returning the XML string with `Content-Type: application/xml`.
      - React SPA (build-time, `scripts/generate-feed.mjs`): reads content dates via the Section F `getGitDate` helper, filters posts missing `title`/`pubDate`, writes `dist/feed.xml`; add to build command: `"build": "vite build && node scripts/generate-sitemap.mjs && node scripts/generate-feed.mjs"`.

   d. **IndexNow payload integration note**: "The feed URL (`<site>/feed.xml`) is added to the `urlList` in the Section E inline CI step's `URLS` variable once the feed exists — Phase 11 patches the CI step to append it (see `seo-indexing-agent.md`)."

2. **Verify references** — Confirm each per-adapter snippet's output content-type is `application/xml` (not `text/xml`, matches RSS 2.0 convention already used by `@astrojs/rss`). Confirm the skip-condition warning text matches the spec's exact wording verbatim (`⚠ RSS feed: no blog content found — feed generation skipped, re-run after adding content`), since the seo-indexing-agent (Phase 2) will reproduce it in its summary report format.

3. **Commit** — `docs(site-builder): add Section G RSS/Atom feed generation`

---

### Task 4: Add Section A forward-reference

**Files:**
- Modify: `skills/site-builder/reference/sitemap-indexnow.md`

**Interfaces:**
- Consumes: Section F (must exist — this task adds a pointer to it)
- Produces: One-line forward reference at the bottom of Section A — no new consumers, this is a leaf documentation pointer

**Acceptance Criteria:** AC5 (Section A itself NOT modified beyond the forward reference)

**Steps (Documentation: Write-and-review):**

1. **Write content** — At the very bottom of Section A (after the "What counts as a meaningful edit" line, before the `---` separator that starts Section B), append:
   ```markdown
   > **Phase 11 override:** `seo-indexing-agent` overrides these per-page dates
   > with git-derived resolution — see Section F.
   ```

2. **Verify references** — Diff-check that no other line in Section A (the rule table, the "meaningful edit" definition) was touched — only the new blockquote line was added. This directly satisfies AC5's "Section A is NOT modified" requirement.

3. **Commit** — `docs(site-builder): add Phase 11 forward-reference to Section A`

---

## Phase 1 Complete

`sitemap-indexnow.md` now documents the full Phase 11 IndexNow/lastmod/feed design: Section E is inline-only (no separate script), Section F gives every adapter a git-derived `lastmod` resolver with a security-hardened `execFileSync` pattern, Section G gives every adapter an RSS/Atom feed generator, and Section A points forward to Section F without being altered itself.

**Next:** `phase-2.md`
