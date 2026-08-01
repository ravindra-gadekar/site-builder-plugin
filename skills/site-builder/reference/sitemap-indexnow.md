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

### Ping Script (Phase 9 -- deploy-agent)

Create `scripts/ping-indexnow.mjs`:

```js
#!/usr/bin/env node
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const SITE = 'https://<site-domain>';
const KEY = '<generated-key>';
const SITEMAP_PATH = resolve('<output-dir>/sitemap-0.xml'); // see table below

// Handle both single sitemap and sitemap index files
let urls = [];
const xml = readFileSync(SITEMAP_PATH, 'utf-8');
if (xml.includes('<sitemapindex')) {
  // Sitemap index — read each referenced sitemap file
  const sitemapLocs = [...xml.matchAll(/<loc>([^<]+)<\/loc>/g)].map(m => m[1]);
  for (const loc of sitemapLocs) {
    const filename = loc.split('/').pop();
    const filepath = resolve(SITEMAP_PATH, '..', filename);
    try {
      const sub = readFileSync(filepath, 'utf-8');
      urls.push(...[...sub.matchAll(/<loc>([^<]+)<\/loc>/g)].map(m => m[1]));
    } catch { /* sitemap file not found locally */ }
  }
} else {
  urls = [...xml.matchAll(/<loc>([^<]+)<\/loc>/g)].map(m => m[1]);
}

if (urls.length === 0) {
  console.log('No URLs found in sitemap — skipping IndexNow ping');
  process.exit(0);
}

console.log(`Found ${urls.length} URLs in sitemap`);

// IndexNow batch limit: 10,000 URLs per request
const BATCH_SIZE = 10000;
for (let i = 0; i < urls.length; i += BATCH_SIZE) {
  const batch = urls.slice(i, i + BATCH_SIZE);
  const payload = {
    host: new URL(SITE).hostname,
    key: KEY,
    keyLocation: `${SITE}/${KEY}.txt`,
    urlList: batch,
  };

  try {
    const res = await fetch('https://api.indexnow.org/indexnow', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=utf-8' },
      body: JSON.stringify(payload),
    });
    console.log(`IndexNow batch ${Math.floor(i / BATCH_SIZE) + 1}: ${res.status} ${res.statusText}`);
    if (res.status === 429) {
      console.warn('Rate limited — reduce submission frequency');
    }
  } catch (err) {
    console.error('IndexNow failed:', err.message);
  }
}

// NOTE: This script submits ALL sitemap URLs on every deploy. For small sites
// (< 100 pages) with infrequent deploys, this is fine. If rate limiting (429)
// becomes an issue, add change detection: diff the current sitemap against a
// cached copy from the previous deploy and submit only changed/new URLs.

// Google does not participate in IndexNow.
// Google discovery relies on accurate lastmod dates + natural crawling.
// Google deprecated its sitemap ping endpoint in June 2023.
```

**Framework-specific sitemap output paths:**

| Framework | Sitemap Path |
|-----------|-------------|
| Astro | `dist/sitemap-0.xml` or `dist/sitemap-index.xml` |
| Next.js | `public/sitemap-0.xml` or `.next/server/app/sitemap.xml` |
| Nuxt | `.output/public/sitemap.xml` |
| React SPA | `dist/sitemap.xml` |

The deploy-agent must detect the correct path based on the framework in `status.md` -> Build Configuration -> Framework.

### CI/CD Integration (Phase 9 -- deploy-agent)

**GitHub Actions** -- add after the deploy step:
```yaml
- name: Notify search engines via IndexNow
  run: node scripts/ping-indexnow.mjs
```

**Vercel** -- add as a post-build command in `vercel.json` or a deploy hook.

**Netlify** -- add as a `[[plugins]]` entry or post-processing command in `netlify.toml`.

### Important Notes

- **Participating engines:** Bing, Yandex, Seznam, Naver, Yep, Internet Archive, AmazonBot (7 total)
- **Google does NOT participate** -- Google relies on accurate `lastmod` + natural crawling
- **Max 10,000 URLs per POST** -- script handles batching
- **Don't resubmit unchanged URLs** repeatedly -- triggers rate limiting (HTTP 429)
- **Requires Node.js >= 18** for native `fetch` and ES modules
- **Key file encoding:** UTF-8, contains ONLY the key string
