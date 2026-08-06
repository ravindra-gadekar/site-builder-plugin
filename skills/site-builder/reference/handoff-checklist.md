# Deployment Readiness Handoff Checklist

Final checklist before the deploy agent sets up CI/CD and pushes to production. The orchestrator runs this at the transition from INTEGRATE → DEPLOY.

## Pre-Deploy Checks

### Build
- [ ] Project builds without errors (`npm run build` or equivalent)
- [ ] No TypeScript/ESLint errors or warnings
- [ ] Build output size is reasonable (< 5MB total for static sites)

### Content Completeness
- [ ] All pages from site map are implemented
- [ ] No placeholder text ("Lorem ipsum," "TODO," "Coming soon" unless intentional)
- [ ] All image slots either filled with real/generated images or have documented briefs
- [ ] Legal pages marked "needs legal review" have disclaimer banner

### SEO
- [ ] sitemap.xml generated and accurate
- [ ] Sitemap has per-page lastmod dates (not uniform build timestamps)
- [ ] IndexNow verification key file present in public directory
- [ ] robots.txt present and correct
- [ ] All pages have unique title + meta description
- [ ] Canonical URLs set on all pages
- [ ] OG/Twitter Card meta on all pages
- [ ] JSON-LD schemas valid

### Performance
- [ ] All images optimized (WebP/AVIF, sized correctly, lazy-loaded)
- [ ] No render-blocking resources
- [ ] CSS purged of unused styles
- [ ] JavaScript tree-shaken and code-split

### Accessibility
- [ ] Keyboard navigation works throughout
- [ ] Screen reader tested (landmarks, headings, alt text)
- [ ] Color contrast passes WCAG AA
- [ ] Focus indicators visible
- [ ] Skip navigation link present

### Integrations
- [ ] Analytics tracking code installed (or setup instructions documented)
- [ ] Social media links verified
- [ ] Contact form functional
- [ ] Cookie consent configured (if analytics installed)

### Security
- [ ] HTTPS enforced
- [ ] Security headers configured (CSP, X-Frame-Options, HSTS)
- [ ] No sensitive data in client-side code
- [ ] Environment variables documented (no secrets in repo)

### Deployment
- [ ] CI/CD pipeline configured
- [ ] IndexNow ping script included in post-deploy CI/CD step
- [ ] Staging environment tested
- [ ] Rollback procedure documented
- [ ] Environment variables listed and documented
- [ ] DNS/domain instructions provided (if applicable)

### Documentation
- [ ] BRAND.md present in project root and populated with design tokens (not placeholder text)
- [ ] All `<!-- auto:* -->` marker sections in ARCHITECTURE.md populated with current data (directory tree, dependencies, build commands)
- [ ] All `<!-- auto:* -->` marker sections in BRAND.md populated with current data (color tokens, font stack, spacing scale) — skip if before Phase 4 DESIGN
- [ ] CONTEXT.md entities and glossary reflect the built website
- [ ] CLAUDE.md marker block contains current tech stack, build commands, and deployment info

## Client Handoff Package

The deploy agent produces this package for the client:

1. **Staging URL** — live preview of the built site
2. **Deployment docs** — how the pipeline works, how to trigger deploys
3. **Content briefs** — image briefs for any AI-generated placeholder images
4. **Manual tasks** — anything that needs client action (analytics verification, legal review, DNS changes)
5. **Maintenance guide** — how to update content, add blog posts, modify pages
