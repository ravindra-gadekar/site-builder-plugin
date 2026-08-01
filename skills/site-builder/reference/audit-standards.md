# Audit Standards

Specific thresholds and check definitions for each of the 6 audit agents. Referenced by the orchestrator when evaluating audit pass/fail status.

## SEO Audit Standards

| Check | Pass | Fail |
|-------|------|------|
| Title tags | Unique per page, 30-60 chars, primary keyword present | Missing, duplicate, too long/short, no keyword |
| Meta descriptions | Unique per page, 120-160 chars, includes CTA | Missing, duplicate, too long/short |
| H1 tags | Exactly one per page, contains primary keyword | Missing, multiple H1s, no keyword |
| Heading hierarchy | Logical H1→H2→H3 (no skipped levels) | H3 before H2, skipped heading levels |
| Internal links | Every page reachable within 3 clicks from homepage | Orphan pages, broken internal links |
| URL structure | Clean, semantic, lowercase, hyphens | Query params, underscores, uppercase, IDs |
| Image alt text | Descriptive alt on all content images, empty alt on decorative | Missing alt, generic "image1.jpg" |
| Sitemap.xml | Valid XML, includes all indexable pages, no 404s | Missing, invalid XML, includes noindex pages |
| Robots.txt | Present, allows important pages, blocks admin/assets | Missing, blocks indexable content |
| Canonical URLs | Present on all pages, self-referencing | Missing, pointing to wrong URLs |
| Favicon | Present in 3 sizes (16×16, 32×32, apple-touch-icon) | Missing favicon |
| Title descriptiveness | Descriptive, specific to page content | Generic ("Home", "Welcome", "Untitled") |
| Charset | `<meta charset="UTF-8">` declared | Missing charset declaration |
| Social/OG tags | og:title, og:description, og:image, og:url, og:type on all pages | Missing OG tags |
| OG image size | 1200×630 dimensions | Wrong dimensions or missing |
| Twitter Card | twitter:card, twitter:title, twitter:description on all pages | Missing Twitter Card meta |
| Legal pages | Privacy policy + terms of service linked | Missing legal pages |
| Internal links | All internal hrefs match actual pages (file existence) | Broken internal link to non-existent page |
| Anchor text | Descriptive anchor text | "click here", "here", "read more" |
| Author meta tag | `<meta name="author">` present sitewide | Missing author meta tag |
| Robots.txt AI bots | AI bot sections have ONLY `Allow: /`, no Disallow rules | AI bot sections mix Allow + Disallow (causes false block flags) |
| Identical lastmod | `<lastmod>` values are not a uniform build timestamp (identical to the second) | All URLs share the same lastmod timestamp to the second (build-time anti-pattern = FAIL). All same date-only on greenfield = WARNING. |
| Missing lastmod | Every `<url>` has a `<lastmod>` element | Any URL missing `<lastmod>` |
| Missing priority | `<priority>` values present | No priority values set (WARNING, not FAIL) |
| IndexNow key file | 32-char hex `.txt` file in public/ with matching content | Missing IndexNow key file |
| IndexNow key format | Key filename = content, 32 hex chars, no extra whitespace | Filename/content mismatch, wrong format |

## Technical Audit Standards

| Check | Pass | Fail |
|-------|------|------|
| LCP (Largest Contentful Paint) | ≤ 2.5s | > 2.5s |
| CLS (Cumulative Layout Shift) | ≤ 0.1 | > 0.1 |
| INP (Interaction to Next Paint) | ≤ 200ms | > 200ms |
| Total page weight | ≤ 1.5MB initial load | > 3MB |
| Image format | WebP or AVIF with fallbacks | Unoptimized PNG/JPG > 200KB |
| Lazy loading | Images below fold use loading="lazy" | All images eager-loaded |
| Render-blocking | No render-blocking JS/CSS in critical path | Blocking resources > 100KB |
| Mobile viewport | `<meta name="viewport">` present, no horizontal scroll | Missing viewport, horizontal overflow |
| Touch targets | ≥ 44x44px interactive elements | < 44px tap targets |
| Broken links | Zero 404s from internal links | Any broken internal link |
| HTTPS | All resources served over HTTPS | Mixed content warnings |
| Security headers | CSP, X-Frame-Options, HSTS present | Missing critical security headers |
| HTML validity | Valid HTML5, no parse errors | Unclosed tags, invalid nesting |
| Meta CSP | Meta CSP tag present or documented as server-header-only | No CSP at all |
| rel=noopener | All `target="_blank"` links have `rel="noopener"` | Missing noopener on external links |
| No inline handlers | Zero onclick/onload/onmouseover HTML attributes | Inline event handlers found |
| Font-display | `font-display: swap` on all @font-face | Missing font-display |
| Framework images | All images use framework image components | Raw `<img>` from `public/` |
| srcset | Content images have srcset with correct sizes | Missing srcset on content images |
| Video facade | YouTube/Vimeo use facade pattern (no bare iframes) | Bare `<iframe>` embed |
| Video preload | Self-hosted video has preload="none" (unless autoplay) | preload="auto" on non-autoplay video |
| Video poster | All videos have poster images | Video without poster |

## Content Quality Standards

| Check | Pass | Fail |
|-------|------|------|
| Blog word count | ≥ 600 words | < 600 words on blog/article pages |
| Service page word count | ≥ 400 words | < 400 words on service/product pages |
| Contact/legal word count | No minimum | N/A (always passes) |
| Readability | Flesch-Kincaid ≤ grade 8 (blog/service), ≤ grade 10 (legal) | > grade 12 |
| Author byline | Present on blog/article pages | Missing on blog/article pages |
| Publication date | Present on blog/article pages | Missing on blog/article pages |
| Paragraph length | ≤ 4 sentences per paragraph | > 4 sentences consistently |
| Duplicate content | < 20% overlap between pages | > 40% overlap between any two pages |
| Brand voice | Consistent tone across all pages | Jarring shifts between formal/casual |
| AI detection | Passes AI-content checklist | Formulaic paragraphs, buzzword soup |
| CTA presence | Clear CTA on every page | Pages with no call-to-action |
| Spelling/grammar | Zero errors | Any spelling or grammar mistakes |
| E-E-A-T signals | Experience, expertise, authority, trust markers present | No author info, no credentials, no trust signals |

## AI Search Readiness Standards

| Check | Pass | Fail |
|-------|------|------|
| llms.txt | Present in root, correctly formatted, `<link>` tag in `<head>` pointing to it | Missing file, malformed, or no `<link>` discovery tag |
| Citable passages | Self-contained statements with data/credentials | Vague claims without specifics |
| FAQ format | Q&A structure with clear answers | Poorly formatted FAQ sections |
| Brand clarity | Business name, expertise, service area stated clearly | Brand identity unclear or buried |
| Structured citations | Claims backed by numbers, credentials, or references | Unsupported assertions |
| Snippet readiness | Lists, tables, definitions, how-to steps present | No structured content for extraction |

## Schema Audit Standards

| Check | Pass | Fail |
|-------|------|------|
| Organization schema | Present on homepage with name, legalName, url, description, logo, founder, address, contactPoint, sameAs, knowsAbout, foundingDate | Missing or thin (only name/url/description) |
| BreadcrumbList | Present on all non-homepage pages | Missing on inner pages |
| FAQ schema | Present where FAQ content exists | FAQ content without schema |
| Article/BlogPosting | Present on blog posts with author, date, image | Blog posts without schema |
| LocalBusiness | Present if local business detected | Local business without local schema |
| JSON-LD validity | Valid syntax, no console errors | Parse errors, duplicate schemas |
| Rich result eligibility | Passes Google Rich Results Test | Fails validation |
| @context validation | Uses `https://schema.org` | Uses `http://schema.org` or missing @context |
| Breadcrumb enforcement | BreadcrumbList on ALL non-homepage pages | Missing on any inner page |
| VideoObject | Present when video elements exist | Video present without VideoObject schema |

## Accessibility Audit Standards

| Check | Pass | Fail |
|-------|------|------|
| Color contrast (normal text) | ≥ 4.5:1 ratio | < 4.5:1 |
| Color contrast (large text) | ≥ 3:1 ratio | < 3:1 |
| Keyboard navigation | All interactive elements focusable and operable | Elements unreachable by keyboard |
| Focus indicators | Visible focus styles on all interactive elements | Default outline removed with no replacement |
| Image alt text | All content images have meaningful alt text | Missing or generic alt attributes |
| Decorative images | Marked with `alt=""` or `role="presentation"` | Decorative images with descriptive alt |
| Form labels | All inputs have associated `<label>` elements | Inputs without labels |
| Error messages | Programmatically associated with inputs | Visual-only error indicators |
| Landmarks | `<main>`, `<nav>`, `<header>`, `<footer>` present | No semantic landmarks |
| Skip navigation | "Skip to content" link present | Missing skip link |
| Motion | Respects `prefers-reduced-motion` | Animations ignore preference |
| Touch targets | ≥ 48×48px interactive elements | < 48px tap targets |
