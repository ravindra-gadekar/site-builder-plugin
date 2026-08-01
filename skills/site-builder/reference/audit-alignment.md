# Audit Alignment

Maps the marketing audit system's 12 categories (100+ checks) to the site-builder plugin's 6 audit agents. This is the single source of truth for what each agent checks and how scores are calculated.

## Scoring Reference (from Marketing Audit)

- Overall score = weighted average of 12 categories (total weight = 100)
- Grade: A+(≥95, zero fails), A(≥90), B+(≥85), B(≥80), C+(≥75), C(≥70), D(≥60), F(<60)

| Category | Weight |
|---|---|
| SEO | 15 |
| Performance | 15 |
| Accessibility | 10 |
| Mobile | 10 |
| Security | 10 |
| AEO | 10 |
| GEO | 8 |
| Content | 7 |
| Links | 5 |
| Structured Data | 4 |
| Social | 3 |
| Brand | 3 |

## Agent → Category Mapping

| Plugin Audit Agent | Marketing Audit Categories Covered |
|---|---|
| seo-audit-agent | SEO(15) + Social/OG(3) + Brand(3) + Links(5) — build-time checks only |
| technical-audit-agent | Performance(15) code-level + Mobile(10) code-level + Security(10) code-level |
| content-quality-agent | Content/E-E-A-T(7) — page-type-aware checks |
| ai-search-agent | AEO(10) + GEO(8) |
| schema-audit-agent | Structured Data(4) |
| accessibility-audit-agent | Accessibility(10) |

## AEO Check Ownership Boundary (No Overlap)

Two agents cover AEO-adjacent territory. Ownership is strictly separated:

- **content-quality-agent** owns **content form**: short paragraphs, readability, author byline, dates, clear definitions
- **ai-search-agent** owns **AI discoverability**: crawler access, Q&A headings, schema types, llms.txt, entity clarity, freshness signals

## Build-Time vs Post-Deploy Classification

Every check is marked `[build]` or `[deploy]` throughout this file.

### Build-time enforceable `[build]`
- SEO meta tags, heading hierarchy, URL structure
- Content quality, readability, word counts
- Schema markup (JSON-LD)
- Accessibility patterns (contrast, landmarks, labels)
- Image optimization (format, dimensions, lazy loading)
- Animation accessibility (prefers-reduced-motion)
- OG/Twitter Card tags
- Brand elements (favicon, legal pages)
- Link inventory (anchor text, internal link file existence)
- AEO/GEO patterns (llms.txt, Q&A structure, entity clarity)

### Post-deploy measurable `[deploy]`
- PSI scores (LCP, CLS, TBT, FCP, Speed Index, TTFB)
- Security headers (HSTS, CSP server headers, X-Frame-Options)
- SSL certificate validity
- Broken external links (HTTP HEAD requests)
- 404 page validation (requires fetching nonexistent URL)
- Mobile vs desktop performance gap

## Key Threshold Alignments

| Signal | Threshold | Classification |
|---|---|---|
| Content depth (blog/articles) | 600+ words | `[build]` |
| Content depth (service/product) | 400+ words | `[build]` |
| Content depth (contact/legal) | No minimum | `[build]` |
| Readability (Flesch-Kincaid) | ≤ grade 8 pass, ≤ 12 warning, > 12 fail | `[build]` |
| LCP patterns | Code must produce ≤ 2.5s | `[build]` code-level, `[deploy]` measured |
| CLS patterns | Code must produce ≤ 0.1 | `[build]` code-level, `[deploy]` measured |
| OG image dimensions | 1200×630 target | `[build]` |
| Favicon | 16×16, 32×32, apple-touch-icon sizes required | `[build]` |
| Touch targets | ≥ 48×48px | `[build]` |
| Color contrast (normal text) | ≥ 4.5:1 | `[build]` |
| Color contrast (large text) | ≥ 3:1 | `[build]` |

## Fix Routing for New Check Categories

| Issue Type | Route To | Examples |
|---|---|---|
| Security (code-level) | developer-agent | Meta CSP, rel=noopener, no inline handlers |
| Social/OG | developer-agent | Meta tags in HTML head |
| Brand (code) | developer-agent | Favicon sizes, legal page links |
| Brand (content) | content-agent | Legal page text |
| Links (anchor text) | content-agent | Descriptive anchor text |
| Links (file existence) | developer-agent | Internal link href matches actual page |
| Mobile (code) | developer-agent | Viewport meta, font sizes, touch targets |

## Two-Tier Quality Gate

### Tier 1 — Build-time gate (blocking)

The existing quality gate in Phase 7. The plugin won't proceed to deploy until these pass.

- All 6 audit agents must pass on `[build]` checks
- Target: zero `fail` checks on all build-time-enforceable validations
- Max-3-fix-cycles rule remains — if audits don't pass after 3 cycles, report remaining issues to user

### Tier 2 — Post-deploy validation (advisory)

After deployment, the deploy-agent performs or instructs the user to perform:
- Run the marketing audit API against the live URL for actual PSI-based scores
- Run external broken link detection (HTTP HEAD requests)
- Validate security headers are set correctly by hosting provider
- Validate custom 404 page renders correctly
- Check mobile vs desktop performance gap

If any category scores below B+ (85), the deploy-agent outputs specific remediation steps. This tier is informational — it doesn't block deployment since server-side factors may need separate fixes.
