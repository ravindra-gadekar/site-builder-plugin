# Legacy Config Reference

Reference lookup table for the discovery-agent (detection) and deploy-agent (translation). This file is read by agents during the pipeline — it is NOT executed as code.

---

## 1. Source Tech Stack Detection

Expand detection beyond `package.json`:

| Indicator File | Detected Stack | Priority |
|---|---|---|
| `package.json` | Node.js ecosystem (existing detection — check `dependencies` for framework) | Highest |
| `composer.json` or `wp-config.php` | PHP / WordPress | High |
| `Gemfile` | Ruby / Jekyll | Medium (detect only, not deeply parsed) |
| `requirements.txt` / `pyproject.toml` | Python / Django | Medium (detect only, not deeply parsed) |
| `go.mod` (with `gohugoio/hugo` in content) | Hugo | Medium (detect only, not deeply parsed) |
| No package manager file + `.html` files in root or `public/` | Plain HTML/CSS/JS | Lowest (fallback) |

**Detection order:** Check top-down. Stop at first match. A repo can have BOTH `package.json` AND `.html` files — the package manager file wins.

**Plain HTML/CSS heuristic:** Only classify as "Plain HTML/CSS/JS" when:
- No `package.json`, `composer.json`, `Gemfile`, `requirements.txt`, `pyproject.toml`, or `go.mod` exists
- At least one `.html` file exists in the root OR in a `public/`, `www/`, `htdocs/`, or `html/` directory
- This is the fallback — everything else takes priority

---

## 2. Server Config Detection Patterns

### 2.1 Files to Scan

| Config File | Server Type | Scan Method |
|---|---|---|
| `.htaccess` | Apache | **Recursive** — check root and ALL subdirectories. Each file's directory path is recorded. |
| `web.config` | IIS | Root only |
| `nginx.conf` / `default.conf` / `conf.d/*.conf` | Nginx | Root + `nginx/` + `conf/` directories |
| `Dockerfile` | Container | Root + any subdirectory |
| `docker-compose.yml` / `docker-compose.yaml` | Multi-container | Root only |
| `.env` / `.env.example` / `.env.local` / `.env.production` | Any | Root only |

### 2.2 .htaccess Rule Categories

When parsing `.htaccess`, categorize each directive:

| Category | Directives | Action on Migration |
|---|---|---|
| **Redirects** | `RewriteRule ... [R=301]`, `Redirect 301`, `RedirectMatch` | Translate to framework/platform config |
| **Headers** | `Header set`, `Header append`, `Header always set` | Translate to framework/platform headers |
| **CORS** | `Header set Access-Control-Allow-Origin` and related | Translate — update origin if domain changes |
| **Caching** | `ExpiresByType`, `Header set Cache-Control`, `FileETag` | Translate or use framework defaults |
| **Security** | `Options -Indexes`, `ServerSignature Off`, `Header set X-Frame-Options` | Translate — preserve security posture |
| **Clean URLs** | `RewriteRule ^([^\.]+)$ $1.html`, trailing slash rules | Usually not needed (framework handles routing) |
| **Error Pages** | `ErrorDocument 404`, `ErrorDocument 500` | Map to framework error pages |
| **PHP-specific** | `php_value`, `php_flag`, `AddHandler php` | **Drop** — no PHP runtime in new stack. Flag as "dropped on migration" |
| **Auth** | `AuthType`, `AuthUserFile`, `Require` | Flag for manual review — needs different auth approach |
| **Other** | `ForceType`, `AddType`, `SetEnv`, `SetEnvIf` | Flag for manual review |

### 2.3 web.config Rule Categories

| Category | XML Elements | Action on Migration |
|---|---|---|
| **Redirects** | `<rewrite><rules><rule>` with `<action type="Redirect">` | Translate |
| **Headers** | `<httpProtocol><customHeaders><add>` | Translate |
| **Default docs** | `<defaultDocument><files>` | Usually not needed |
| **MIME types** | `<staticContent><mimeMap>` | Usually not needed |
| **URL rewrite** | `<rewrite><rules><rule>` with `<action type="Rewrite">` | Translate if meaningful |

### 2.4 nginx.conf Rule Categories

| Category | Directives | Action on Migration |
|---|---|---|
| **Redirects** | `return 301`, `rewrite ... permanent` | Translate |
| **Headers** | `add_header` | Translate |
| **Proxy** | `proxy_pass`, `proxy_set_header` | Relevant for SSR — flag for review |
| **Caching** | `expires`, `add_header Cache-Control` | Translate |
| **SSL** | `ssl_certificate`, `ssl_protocols` | Platform handles — not needed |
| **Rate limiting** | `limit_req_zone`, `limit_req` | Flag for manual review |

---

## 3. Hosting Type Inference

| Config Fingerprint | Inferred Hosting | Node.js Support |
|---|---|---|
| `.htaccess` + no Docker + PHP files | Shared hosting (cPanel/Apache) | No (static files only) |
| `web.config` + `.aspx`/`.cshtml` | IIS / Windows hosting | No (unless Node configured) |
| `Dockerfile` that builds web app (contains `npm run build`, serves on port) **AND** CI/CD has Docker build+push+deploy steps | Containerized (VPS/cloud) | Yes |
| `docker-compose.yml` with only database/cache services (mongo, postgres, redis) and no web service | Infrastructure-only Docker — hosting type unknown | Unknown — ask user |
| `vercel.json` | Vercel | Yes |
| `netlify.toml` | Netlify | Yes |
| `fly.toml` | Fly.io | Yes |
| None of the above | Unknown — ask user | Unknown |

### 3.1 Docker Disambiguation

Docker files alone do NOT confirm containerized hosting. Use this two-step check:

**Step 1: Is the Dockerfile for the web app?**
- YES indicators: contains `npm run build` or `npm start`, `EXPOSE` with common web ports (80, 443, 3000, 8080), `COPY` of source code
- NO indicators: only installs database/cache software, is a test environment, contains only `python` or `ruby` commands for non-web services

**Step 2: Does CI/CD deploy via Docker?**
- YES indicators: pushes to ECR/GCR/Docker Hub, deploys to ECS/EKS/Cloud Run/Fargate, runs `docker build` in deploy job
- NO indicators: CI/CD deploys via FTP, rsync, `scp`, or platform CLI (Vercel, Netlify, Firebase)

**Resolution:**
- Step 1 YES + Step 2 YES → Containerized hosting confirmed
- Step 1 YES + Step 2 NO → Docker is likely dev-only. Ask user.
- Step 1 NO → Infrastructure-only Docker. Hosting type still unknown.
- No CI/CD found → Cannot confirm. Ask user: "Found Docker files but unclear if production uses containers. Is your site deployed via Docker/containers, or is Docker used for local development only?"

---

## 4. Config Translation Tables

### 4.1 .htaccess → Framework/Platform (when hosting CHANGES)

| .htaccess Rule Type | Astro (`astro.config.mjs`) | Next.js (`next.config.js`) | Vercel (`vercel.json`) | Netlify (`netlify.toml` / `_redirects`) |
|---|---|---|---|---|
| `RewriteRule ^old$ /new [R=301,L]` | `redirects: {'/old': '/new'}` | `async redirects() { return [{source: '/old', destination: '/new', permanent: true}] }` | `{"redirects": [{"source": "/old", "destination": "/new", "permanent": true}]}` | `/old /new 301` in `_redirects` |
| `RewriteRule` (clean URLs) | Built-in (file-based routing) | Built-in (file-based routing) | Built-in | Built-in |
| `Header set X-Frame-Options DENY` | Via adapter headers config | `async headers() { return [{source: '/(.*)', headers: [{key: 'X-Frame-Options', value: 'DENY'}]}] }` | `{"headers": [{"source": "/(.*)", "headers": [{"key": "X-Frame-Options", "value": "DENY"}]}]}` | `[[headers]]\n  for = "/*"\n  [headers.values]\n    X-Frame-Options = "DENY"` |
| `ExpiresByType` (caching) | Framework defaults usually sufficient | Custom `headers()` function | `headers[]` in vercel.json | `[[headers]]` in netlify.toml |
| `ErrorDocument 404 /404.html` | `src/pages/404.astro` | `app/not-found.tsx` | Automatic from framework | Automatic from framework |
| `Options -Indexes` | Not needed (no directory listing in static hosting) | Not needed | Not needed | Not needed |
| `ForceType` / `AddType` | Handled by build tool | Handled by build tool | Platform handles | Platform handles |

### 4.2 .htaccess → New .htaccess (when hosting STAYS Apache)

When user keeps shared hosting with static-output framework (Astro SSG, React SPA), generate a **new `.htaccess`** in the build output directory:

| Rule Category | Action |
|---|---|
| 301 redirects | Update paths to match new URL structure |
| Security headers (`X-Frame-Options`, `X-Content-Type-Options`, CSP) | Preserve as-is |
| CORS headers | Preserve — update `Access-Control-Allow-Origin` if domain changes |
| Caching (`ExpiresByType`, `Cache-Control`) | Preserve — adjust for new file types |
| Clean URLs / trailing slashes | Update to match framework's routing output |
| Custom error pages (`ErrorDocument`) | Update paths to new error page locations (e.g., `ErrorDocument 404 /404.html`) |
| PHP-specific (`php_value`, `php_flag`) | **Drop** — no PHP runtime |
| Directory listing (`Options -Indexes`) | Preserve |
| Subdirectory `.htaccess` rules | Flag for manual review — subdirectory structure may differ |

### 4.3 web.config Translation

| web.config Rule Type | Translation Target |
|---|---|
| `<rewrite><rules>` with redirect action | Same as .htaccess redirects (Section 4.1) |
| `<httpProtocol><customHeaders>` | Same as .htaccess headers (Section 4.1) |
| `<defaultDocument>` | Not needed (framework handles) |
| `<staticContent><mimeMap>` | Usually not needed (build tool handles) |

### 4.4 nginx.conf Translation

| nginx Rule Type | Translation Target |
|---|---|
| `location` blocks with `return 301` | Framework/platform redirect config (Section 4.1) |
| `add_header` directives | Framework/platform header config (Section 4.1) |
| `proxy_pass` | Relevant for SSR with API routes — flag for review |
| `expires` / `Cache-Control` | Framework/platform caching headers (Section 4.1) |

### 4.5 CI/CD Build Command Mapping

| Framework | Install Command | Build Command | Output Dir | Lint Command |
|---|---|---|---|---|
| Astro | `npm ci` | `astro build` | `dist/` | `astro check` (if configured) |
| Next.js | `npm ci` | `next build` | `.next/` (or `out/` for static export) | `next lint` |
| Nuxt | `npm ci` | `nuxt build` | `.output/` | `nuxt typecheck` |
| React SPA (Vite) | `npm ci` | `vite build` | `dist/` | `eslint .` |

---

## 5. WordPress Plugin Equivalents

When a WordPress site is detected, map common plugins to new-stack equivalents:

| WordPress Plugin | Purpose | New Stack Equivalent |
|---|---|---|
| Yoast SEO / Rank Math | SEO meta, sitemaps, redirects | Framework's built-in SEO (meta tags, sitemap generation) + redirect config |
| Contact Form 7 / WPForms | Contact forms | Formspree, Netlify Forms, or API route form handler |
| WooCommerce | E-commerce | Snipcart, Shopify Storefront API, or custom (flag as major scope) |
| Elementor / WPBakery | Page builder | Not needed — framework IS the builder |
| W3 Total Cache / WP Super Cache | Performance | Framework's built-in static generation + CDN headers |
| Wordfence / Sucuri | Security | Security headers in config + platform WAF |
| Akismet | Spam filtering | Form service spam protection (Formspree, honeypot fields) |
| WPML / Polylang | Multi-language | Framework i18n (Astro i18n, Next.js i18n routing) |
| Advanced Custom Fields | Custom content types | Markdown content files or CMS integration |
| Redirection plugin | Redirect management | Framework/platform redirect config |
| MonsterInsights | Google Analytics | Direct GA4 script or framework integration |
| UpdraftPlus | Backups | Git + hosting platform backups (not needed for code) |

### 5.1 WordPress Data That Cannot Be Extracted From Files

Flag these to the user — they are stored in the WordPress database, not in files:

- Redirects managed by SEO plugins (Yoast, Rank Math, Redirection plugin)
- Custom field definitions and values (ACF, Meta Box)
- Menu structure and widget assignments
- Permalink structure setting (Settings → Permalinks)
- Plugin-specific settings stored in `wp_options`
- Post/page content (unless exported to XML/JSON)
- User-submitted form data
- WooCommerce products, orders, customers

---

## 6. .env Variable Migration

### 6.1 Security Classification

**Never make public (hard guard):** Variables containing these keywords are NEVER given a public prefix, regardless of user input:
- `KEY` (except `SITE_KEY` — e.g., reCAPTCHA site key IS public)
- `SECRET`
- `PASSWORD`
- `TOKEN`
- `CREDENTIAL`
- `PRIVATE`
- `AUTH`

**Likely public (flag as candidates):** Variables containing:
- `GA`, `ANALYTICS`, `GTM` — analytics tracking IDs
- `SITE_URL`, `APP_URL`, `BASE_URL` — public URLs
- `RECAPTCHA_SITE_KEY` — the site key (not secret key) is always public
- `PUBLIC_` (already prefixed as public)

**Default: private.** All variables are private (no public prefix) unless the user explicitly classifies them as public.

### 6.2 Prefix Translation

Applied ONLY after user classifies each variable:

| Source Convention | Target: Astro Public | Target: Astro Private | Target: Next.js Public | Target: Next.js Private |
|---|---|---|---|---|
| `REACT_APP_*` (CRA) | `PUBLIC_*` | Remove prefix, keep name | `NEXT_PUBLIC_*` | Remove prefix, keep name |
| No prefix (PHP `$_ENV`) | `PUBLIC_*` | Keep as-is | `NEXT_PUBLIC_*` | Keep as-is |
| `VUE_APP_*` (Vue CLI) | `PUBLIC_*` | Remove prefix, keep name | `NEXT_PUBLIC_*` | Remove prefix, keep name |
| `VITE_*` (Vite) | `PUBLIC_*` | Remove prefix, keep name | `NEXT_PUBLIC_*` | Remove prefix, keep name |
| `NEXT_PUBLIC_*` (Next.js) | `PUBLIC_*` | Remove prefix, keep name | Keep as-is | Remove prefix, keep name |
| `PUBLIC_*` (Astro) | Keep as-is | Remove prefix, keep name | `NEXT_PUBLIC_*` | Remove prefix, keep name |
| Generic (no prefix) | Add `PUBLIC_` | Keep as-is | Add `NEXT_PUBLIC_` | Keep as-is |

### 6.3 .env.example Output Format

The deploy-agent generates a new `.env.example`:

```env
# === Server-Side Variables (never exposed to browser) ===
SMTP_HOST=           # Email server hostname
DB_CONNECTION=       # Database connection string
API_SECRET_KEY=      # ⚠️ SECRET — never make public

# === Client-Side Variables (exposed to browser) ===
PUBLIC_GA_ID=        # Google Analytics measurement ID
PUBLIC_SITE_URL=     # Public site URL

# === Needs Classification (ask user) ===
# CONTACT_EMAIL=    # Is this needed in browser? If yes, add PUBLIC_ prefix
```
