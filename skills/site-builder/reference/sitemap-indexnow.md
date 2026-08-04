# Sitemap Quality & IndexNow Setup

Shared reference for sitemap configuration and IndexNow auto-notification. Referenced by the developer-agent (Phase 6), seo-audit-agent (Phase 7), and deploy-agent (Phase 9).

Google uses `lastmod` only when it is "consistently and verifiably accurate." Uniform build timestamps train Googlebot to ignore the field entirely. IndexNow provides instant notification to 7 non-Google engines on every deploy.

---

## Section A: Sitemap lastmod Rules

| Rule | Description |
|------|-------------|
| **Never uniform timestamps** | NEVER use `new Date().toISOString()` as `lastmod` for all pages. Google ignores `lastmod` when every page has the same timestamp on every build. |
| **Blog/content pages** | Read `updatedDate` or `publishDate` from frontmatter and use that as `lastmod`. Prefer `updatedDate` when both exist. |
| **Static pages** | Maintain a `pageLastmod` map in the sitemap config with the actual date each page was last meaningfully edited. The developer must set these manually. |
| **Data-driven pages** | Pages generated from data files (services, industries, products): use the date from the data source if available, otherwise use the data file's last modification date. |
| **Category/tag/pagination** | Use the most recent post date in that category, or a fixed date if not computable at config time. |

**What counts as a meaningful edit:** Changes to main content, structured data, or links. NOT: copyright year updates, CSS changes, dependency bumps, build config tweaks.

> **Phase 11 override:** `seo-indexing-agent` overrides these per-page dates
> with git-derived resolution — see Section F.

---

## Section B: Priority Table

| Priority | Page Type | Examples |
|----------|-----------|---------|
| `1.0` | Homepage | `/` |
| `0.9` | Key conversion pages | `/pricing`, `/contact`, main service page, lead-gen tools |
| `0.8` | Service/product/industry pages | `/services/web-design`, `/industries/healthcare` |
| `0.7` | Blog posts, case studies, individual content | `/blog/seo-guide`, `/case-studies/acme` |
| `0.5` | Legal, pagination, category, tag pages | `/privacy`, `/terms`, `/blog/page/2`, `/blog/category/seo` |

**Note:** Google ignores `priority` values. These are set for Bing, Yandex, Seznam, Naver, and other engines that may use them.

---

## Section C: changefreq Defaults

| changefreq | Page Type |
|------------|-----------|
| `weekly` | Blog posts, news, frequently updated content |
| `monthly` | Service pages, product pages, static content pages, homepage |
| `yearly` | Legal pages (terms, privacy policy) |

**Note:** Google ignores `changefreq` values. These are set for non-Google engines.

---

## Section D: Framework-Specific lastmod Implementation

### Astro (`@astrojs/sitemap`)

Use a helper function that reads blog markdown frontmatter at config time via `fs.readdirSync` / `fs.readFileSync` to build a slug-to-date map. Pass the map into the `serialize` callback to set per-URL `lastmod`, `priority`, and `changefreq`.

```js
// astro.config.mjs
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

function getBlogDates() {
  const dir = './src/content/blog';
  const dates = {};
  try {
    for (const file of readdirSync(dir).filter(f => f.endsWith('.md') || f.endsWith('.mdx'))) {
      const content = readFileSync(join(dir, file), 'utf-8');
      const slug = file.replace(/\.mdx?$/, '');
      const updated = content.match(/updatedDate:\s*(\d{4}-\d{2}-\d{2})/);
      const published = content.match(/publishDate:\s*(\d{4}-\d{2}-\d{2})/);
      dates[`/blog/${slug}/`] = updated?.[1] || published?.[1] || null;
    }
  } catch { /* no blog content directory */ }
  return dates;
}

const blogDates = getBlogDates();

// Static page dates — update when page content meaningfully changes
const pageLastmod = {
  '/': '2026-06-15',
  '/about/': '2026-05-20',
  '/contact/': '2026-04-10',
  '/pricing/': '2026-06-01',
  '/privacy/': '2025-12-01',
  '/terms/': '2025-12-01',
};

// Priority map
const priorityMap = {
  '/': 1.0,
  '/pricing/': 0.9, '/contact/': 0.9,
};
function getPriority(url) {
  if (priorityMap[url]) return priorityMap[url];
  if (url.startsWith('/blog/')) return 0.7;
  if (url.startsWith('/services/') || url.startsWith('/industries/')) return 0.8;
  if (['/privacy/', '/terms/'].includes(url)) return 0.5;
  return 0.7;
}

// changefreq map
function getChangefreq(url) {
  if (url.startsWith('/blog/')) return 'weekly';
  if (['/privacy/', '/terms/'].includes(url)) return 'yearly';
  return 'monthly';
}

export default defineConfig({
  integrations: [
    sitemap({
      serialize(item) {
        const path = new URL(item.url).pathname;
        item.lastmod = blogDates[path] || pageLastmod[path] || undefined;
        item.priority = getPriority(path);
        item.changefreq = getChangefreq(path);
        return item;
      },
    }),
  ],
});
```

### Next.js (`next-sitemap`)

Use the `transform` function in `next-sitemap.config.js` to set per-URL `lastmod` and `priority`. Read content dates from the filesystem.

```js
// next-sitemap.config.js
const { readdirSync, readFileSync } = require('node:fs');
const { join } = require('node:path');

function getContentDates() {
  const dates = {};
  const contentDir = './content/blog'; // adjust per project
  try {
    for (const file of readdirSync(contentDir).filter(f => f.endsWith('.md') || f.endsWith('.mdx'))) {
      const content = readFileSync(join(contentDir, file), 'utf-8');
      const slug = file.replace(/\.mdx?$/, '');
      const updated = content.match(/updatedDate:\s*(\d{4}-\d{2}-\d{2})/);
      const published = content.match(/publishDate:\s*(\d{4}-\d{2}-\d{2})/);
      dates[`/blog/${slug}`] = updated?.[1] || published?.[1] || null;
    }
  } catch { /* no content dir */ }
  return dates;
}

const contentDates = getContentDates();

const pageLastmod = {
  '/': '2026-06-15',
  '/about': '2026-05-20',
  // ... set actual dates when pages are meaningfully edited
};

module.exports = {
  siteUrl: process.env.SITE_URL || 'https://example.com',
  generateRobotsTxt: false, // robots.txt handled separately
  transform: async (config, path) => {
    const lastmod = contentDates[path] || pageLastmod[path] || undefined;
    let priority = 0.7;
    let changefreq = 'monthly';

    if (path === '/') { priority = 1.0; }
    else if (['/pricing', '/contact'].includes(path)) { priority = 0.9; }
    else if (path.startsWith('/services/') || path.startsWith('/industries/')) { priority = 0.8; }
    else if (path.startsWith('/blog/')) { priority = 0.7; changefreq = 'weekly'; }
    else if (['/privacy', '/terms'].includes(path)) { priority = 0.5; changefreq = 'yearly'; }

    return { loc: path, lastmod, priority, changefreq };
  },
};
```

### Vue/Nuxt (`@nuxtjs/sitemap`)

Configure the `@nuxtjs/sitemap` module in `nuxt.config.ts` with a `urls` function that reads content dates.

```ts
// nuxt.config.ts
import { readdirSync, readFileSync } from 'node:fs';

function getBlogDates() {
  const dates: Array<{ loc: string; lastmod?: string; priority: number; changefreq: string }> = [];
  try {
    for (const file of readdirSync('./content/blog').filter(f => f.endsWith('.md'))) {
      const content = readFileSync(`./content/blog/${file}`, 'utf-8');
      const slug = file.replace('.md', '');
      const updated = content.match(/updatedDate:\s*(\d{4}-\d{2}-\d{2})/);
      const published = content.match(/publishDate:\s*(\d{4}-\d{2}-\d{2})/);
      dates.push({
        loc: `/blog/${slug}`,
        lastmod: updated?.[1] || published?.[1],
        priority: 0.7,
        changefreq: 'weekly',
      });
    }
  } catch { /* no blog content directory */ }
  return dates;
}

const blogUrls = getBlogDates();

const staticUrls = [
  { loc: '/', lastmod: '2026-06-15', priority: 1.0, changefreq: 'monthly' },
  { loc: '/pricing', lastmod: '2026-06-01', priority: 0.9, changefreq: 'monthly' },
  { loc: '/contact', lastmod: '2026-04-10', priority: 0.9, changefreq: 'monthly' },
  { loc: '/privacy', lastmod: '2025-12-01', priority: 0.5, changefreq: 'yearly' },
  { loc: '/terms', lastmod: '2025-12-01', priority: 0.5, changefreq: 'yearly' },
];

export default defineNuxtConfig({
  modules: ['@nuxtjs/sitemap'],
  sitemap: {
    urls: () => [...staticUrls, ...blogUrls],
  },
});
```

### React SPA (build-time script)

React SPAs typically don't have built-in sitemap generation. Create a build-time script that generates `sitemap.xml` from route definitions and content dates.

```js
// scripts/generate-sitemap.mjs
import { writeFileSync, readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const SITE = 'https://example.com';

const staticPages = [
  { loc: '/', lastmod: '2026-06-15', priority: 1.0, changefreq: 'monthly' },
  { loc: '/pricing', lastmod: '2026-06-01', priority: 0.9, changefreq: 'monthly' },
  { loc: '/contact', lastmod: '2026-04-10', priority: 0.9, changefreq: 'monthly' },
  { loc: '/privacy', lastmod: '2025-12-01', priority: 0.5, changefreq: 'yearly' },
  { loc: '/terms', lastmod: '2025-12-01', priority: 0.5, changefreq: 'yearly' },
];

// Read blog dates if content directory exists
const blogPages = [];
try {
  const dir = './content/blog';
  for (const file of readdirSync(dir).filter(f => f.endsWith('.md'))) {
    const content = readFileSync(join(dir, file), 'utf-8');
    const slug = file.replace('.md', '');
    const updated = content.match(/updatedDate:\s*(\d{4}-\d{2}-\d{2})/);
    const published = content.match(/publishDate:\s*(\d{4}-\d{2}-\d{2})/);
    blogPages.push({
      loc: `/blog/${slug}`,
      lastmod: updated?.[1] || published?.[1],
      priority: 0.7,
      changefreq: 'weekly',
    });
  }
} catch { /* no blog content */ }

const allPages = [...staticPages, ...blogPages];

const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${allPages.map(p => `  <url>
    <loc>${SITE}${p.loc}</loc>
${p.lastmod ? `    <lastmod>${p.lastmod}</lastmod>\n` : ''}    <priority>${p.priority}</priority>
    <changefreq>${p.changefreq}</changefreq>
  </url>`).join('\n')}
</urlset>`;

writeFileSync('dist/sitemap.xml', xml);
console.log(`Generated sitemap.xml with ${allPages.length} URLs`);
```

Add to `package.json`:
```json
{
  "scripts": {
    "build": "vite build && node scripts/generate-sitemap.mjs"
  }
}
```

---

## Section E: IndexNow Setup

### Key Generation (Phase 6 -- developer-agent)

1. **Check first:** Search `public/` for an existing `.txt` file whose name is a 32-char hex string. If found, skip generation -- the key already exists from a previous build.
2. **If no key exists:** Generate a unique 32-character hex string as the IndexNow API key:
   ```js
   import { randomUUID } from 'node:crypto';
   const key = randomUUID().replace(/-/g, '');
   ```
3. Create verification file at `public/<key>.txt` containing ONLY the key string (no whitespace, no newline)
4. Store the key value in a comment at the top of the verification file for reference

**File naming:** The file MUST be named `<key-value>.txt` (not `indexnow-key.txt`). IndexNow verifies domain ownership by fetching `https://<domain>/<key>.txt`.

**Update mode:** Never regenerate a key if one already exists. Regenerating would break existing IndexNow verification with search engines and leave the old key file orphaned.

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

For sites with >10,000 URLs, split `URL_LIST_JSON` into batches of 10,000 in
a loop -- same logic as the old script, now inline.

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

### Important Notes

- **Participating engines:** Bing, Yandex, Seznam, Naver, Yep, Internet Archive, AmazonBot (7 total)
- **Google does NOT participate** -- Google relies on accurate `lastmod` + natural crawling
- **Max 10,000 URLs per POST** -- batch in groups of 10,000 in the inline shell loop if exceeded (see Performance note below)
- **Don't resubmit unchanged URLs** repeatedly -- triggers rate limiting (HTTP 429)
- **Key file encoding:** UTF-8, contains ONLY the key string

---

## Section F: Git-Derived Lastmod Resolver

> **Security requirement:** NEVER use `execSync` with string interpolation
> for git commands -- always use `execFileSync` with an argument array to
> prevent command injection via filenames.

### Core Resolver Logic

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

### URL-to-Source-File Mapping

| Page type | Source file for git date | Example | Notes |
| --- | --- | --- | --- |
| Content collection (blog `.md`/`.mdx`) | The content file itself | `src/content/blog/my-post.md` | Git dates are reliable -- content changes dominate |
| Static pages (`.astro`, `.tsx`, `.vue`) | The page component file | `src/pages/about.astro` | Prefer manual `pageLastmod` map with git date as fallback |
| Data-driven dynamic routes | The data source file (JSON/YAML/TS) | `/services/[slug]` -> `src/data/services.json` | Template file's git date as fallback if data source has no history |
| Category/tag/pagination pages | Most recent content file in the collection | `src/content/blog/*.md` | Reflects when the collection last changed |
| Composite pages | The primary content source file only | e.g. a homepage assembled from multiple partials -- use the hero/primary content file | Documented trade-off |

### Per-Adapter Code

**Astro** (`astro.config.mjs`):

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

**Next.js** (`next-sitemap.config.js` `transform`, and `_lastmod.json` manifest for App Router SSR):

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

**Vue/Nuxt** (`nuxt.config.ts` `urls` function): same `getGitDate` helper, applied per blog/static URL entry before returning the array.

**React SPA** (`scripts/generate-sitemap.mjs`): same `getGitDate` helper called per page before writing `dist/sitemap.xml`.

### Performance

For sites with 200+ pages, sequential `execFileSync` per file adds 10-40s to
builds. Prefer a single batch call: `git log --format='%aI' --name-only`
across the content directory in one subprocess, parsing all dates from the
combined output instead of one `execFileSync` per file.

### Build-Time-Only Requirement

Git-lastmod resolution MUST happen at build time, not request time -- see
the `_lastmod.json` manifest pattern above for Next.js SSR.

---

## Section G: RSS/Atom Feed Generation

### Skip Condition

If no blog/content collection directory exists (or it exists but is empty),
skip feed generation entirely and log:
`⚠ RSS feed: no blog content found — feed generation skipped, re-run after adding content`.

### RSS 2.0 Required-Element Checklist

Validated before writing; entries missing required fields are excluded with
a per-entry warning. `<channel>` must have `<title>`, `<link>`,
`<description>`; each `<item>` must have `<title>`, `<link>`, `<pubDate>`.

### Per-Adapter Feed Code

**Astro** (`@astrojs/rss`, `src/pages/feed.xml.js`):

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

**Next.js** (App Router route, `src/app/feed.xml/route.ts`):

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

**Vue/Nuxt** (`server/routes/feed.xml.ts`, or `@nuxtjs/feed` module config): same
required-field filter, `defineEventHandler` returning the XML string with
`Content-Type: application/xml`.

**React SPA** (build-time, `scripts/generate-feed.mjs`): reads content dates via
the Section F `getGitDate` helper, filters posts missing `title`/`pubDate`,
writes `dist/feed.xml`; add to build command:
`"build": "vite build && node scripts/generate-sitemap.mjs && node scripts/generate-feed.mjs"`.

### IndexNow Payload Integration

The feed URL (`<site>/feed.xml`) is added to the `urlList` in the Section E
inline CI step's `URLS` variable once the feed exists — Phase 11 patches the
CI step to append it (see `seo-indexing-agent.md`).
