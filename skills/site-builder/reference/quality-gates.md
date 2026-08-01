# Quality Gates

## User Approval Gates

Four phases require explicit user approval before the pipeline continues.

### Gate: DISCOVER → ARCHITECT
- **Trigger:** discovery-agent completes `project-brief.md`
- **Presented to user:** Business summary, competitor analysis highlights, page inventory, codebase inventory
- **User actions:** Approve / Request changes / Add information
- **On changes:** discovery-agent re-runs with updated inputs

### Gate: ARCHITECT → DESIGN
- **Trigger:** architect-agent completes `site-architecture.md`
- **Presented to user:** Tech stack recommendation, site map, URL structure, component tree
- **User actions:** Approve / Change tech stack / Modify site map / Add pages
- **On changes:** architect-agent re-runs affected sections

### Gate: DESIGN → CONTENT
- **Trigger:** designer-agent completes `design-system.md`
- **Presented to user:** Color palette, typography, component patterns, wireframes
- **User actions:** Approve / Adjust colors / Change fonts / Modify layout
- **On changes:** designer-agent re-runs affected sections

### Gate: DEPLOY (final)
- **Trigger:** deploy-agent completes CI/CD setup and staging deployment
- **Presented to user:** Staging URL, deployment pipeline summary, environment details
- **User actions:** Approve for production / Request changes / Hold
- **On changes:** deploy-agent adjusts pipeline configuration

## Quality Gate: Audit Pass

The quality gate operates in two tiers:

### Tier 1 — Build-Time Gate (Blocking)

The existing quality gate in Phase 7. The plugin won't proceed to deploy until these pass.

**Criteria:** ALL 6 audit agents must report PASS on build-time-enforceable checks. A single FAIL blocks the pipeline.

### Pass/Fail Definition Per Audit

| Audit | PASS condition | FAIL triggers |
|-------|---------------|---------------|
| SEO | All checks pass OR only INFO-level findings | Missing title tags, duplicate H1s, broken sitemap, missing canonical URLs, missing OG tags, missing favicon, broken internal links, identical lastmod timestamps (build-time anti-pattern), missing IndexNow key file |
| Technical | Code-level patterns within thresholds, no critical issues | Raw `<img>` from public/, missing srcset, lazy-loaded LCP images, missing font-display, bare YouTube iframes, missing noopener, inline event handlers |
| Content Quality | Page-type thresholds met, consistent voice | Blog pages under 600 words, service pages under 400 words, missing bylines on blog posts, readability > grade 12 |
| AI Search | AEO + GEO checks adequate | Missing llms.txt, no citable passages, blocked AI crawlers, no Q&A headings |
| Schema | Required schemas present and valid | Missing Organization/LocalBusiness, invalid @context, missing BreadcrumbList on inner pages |
| Accessibility | WCAG 2.1 AA compliance | Contrast below 4.5:1, missing alt text, no keyboard nav, touch targets < 48px, prefers-reduced-motion not functional |

### Tier 2 — Post-Deploy Validation (Advisory)

After deployment, the deploy-agent performs or instructs the user to perform:

- Run the marketing audit API against the live URL for actual PSI-based scores
- Run external broken link detection (HTTP HEAD requests)
- Validate security headers are set correctly by hosting provider (HSTS, CSP server headers, X-Frame-Options)
- Validate custom 404 page renders correctly
- Check mobile vs desktop performance gap
- Validate SSL certificate

If any category scores below B+ (85), the deploy-agent outputs specific remediation steps. This tier is informational — it doesn't block deployment since server-side factors may need separate fixes.

### Audit Loop Rules

1. **Maximum 3 cycles.** After 3 rounds, present remaining issues to user.
2. **Fixes are sequential** to avoid file conflicts: content-agent first, then developer-agent.
3. **Only re-audit failed checks** — passed checks from previous cycle carry forward.
4. **Each cycle re-runs all 6 audits in parallel** (read-only) to catch regressions from fixes.
5. **All audit agents use sequential checklist execution format** — checks run in numbered order, status reported immediately after each, no skipping, no batching.

### Routing Rules

| Issue type | Routed to |
|-----------|-----------|
| Copy, meta descriptions, heading text, readability, CTAs, FAQ formatting | content-agent |
| HTML structure, CSS, schema markup, image optimization, performance, accessibility | developer-agent |
| Both content and code | content-agent first, then developer-agent |
