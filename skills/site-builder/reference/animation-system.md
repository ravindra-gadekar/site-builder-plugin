# Animation System

Industry-adaptive animation system with 3 tiers. The designer-agent selects the tier based on industry vertical and can override based on client preference or competitive analysis.

## Tiers

### Tier 1 — Subtle

**Industries:** Manufacturing, Legal, Healthcare, Finance, Government

Allowed animations:
- Scroll-triggered fade-in on sections (opacity 0→1, translateY 20px→0)
- Smooth hover transitions on buttons/cards (150ms ease-out)
- Counter/number animations on statistics sections
- Gentle image reveals (scale 1.02→1 on scroll)

**Not allowed:** Parallax, typing effects, animated backgrounds.

### Tier 2 — Moderate

**Industries:** B2B SaaS, Professional Services, Education, Real Estate, E-commerce, Restaurant/Hospitality, Automotive, Construction, Fitness/Wellness, Nonprofit

Everything from Tier 1, plus:
- Staggered card entrances (100ms delay between siblings)
- Section divider animations (line grows from center)
- Testimonial carousel slide transitions
- Button hover micro-interactions (subtle scale + shadow shift)
- Parallax on hero background image (subtle, 0.3 factor)
- Image hover zoom on product/portfolio cards

### Tier 3 — Creative

**Industries:** Creative Agency, Tech Startup, Photography/Portfolio, Entertainment/Media, Fashion/Lifestyle

Everything from Tiers 1-2, plus:
- Hero text entrance animations (word-by-word or line-by-line)
- Animated gradient backgrounds or mesh gradients
- Scroll-linked progress indicators
- Creative section transitions (diagonal clip-path reveals, horizontal scroll sections)
- Magnetic cursor effects on CTAs
- Lottie/SVG icon animations
- Text reveal effects (blur→clear, clip-path wipe)

## Industry → Tier Mapping

| Industry | Tier |
|---|---|
| Manufacturing / Industrial | 1 |
| Legal / Accounting | 1 |
| Healthcare / Medical | 1 |
| Finance / Insurance | 1 |
| Government / Public Sector | 1 |
| B2B SaaS / Software | 2 |
| Professional Services | 2 |
| Education / Training | 2 |
| Real Estate | 2 |
| E-commerce / Retail | 2 |
| Restaurant / Hospitality | 2 |
| Automotive | 2 |
| Construction / Trades | 2 |
| Fitness / Wellness | 2 |
| Nonprofit | 2 |
| Creative Agency / Design | 3 |
| Tech Startup | 3 |
| Photography / Portfolio | 3 |
| Entertainment / Media | 3 |
| Fashion / Lifestyle | 3 |

The designer-agent can override the default tier based on client preference or competitive analysis.

**Note:** The animation mapping covers 20 industry entries while `industry-layouts.md` covers 15. The 5 animation-only entries (Government, Photography/Portfolio, Entertainment, Fashion, Tech Startup) share layout patterns with related industries (e.g., Photography uses Creative Agency layout) but have distinct animation needs. The designer-agent cross-references both files.

## Implementation Approach

CSS-only, no external libraries.

### Components

1. **`animations.css`** (~3KB) — shared CSS utility classes:
   - `.reveal`, `.reveal-fade-up`, `.reveal-fade-in`, `.reveal-slide-left`, `.reveal-slide-right`, `.reveal-scale`, `.reveal-blur`
   - `.stagger-children`, `.hover-lift`, `.hover-glow`, `.hover-scale`, `.counter-animate`
   - Tier 3 extras: `.text-reveal`, `.gradient-shift`, `.parallax-bg`

2. **`animation-controller.js`** (~2KB) — vanilla JS handling three concerns:
   - IntersectionObserver for `.reveal-*` class scroll triggers
   - Counter animation for `.counter-animate` elements (reads target from `data-count` attribute, increments over 1.5s with easeOutCubic)
   - Stagger delay calculation for `.stagger-children` containers

3. **Framework wrappers** — each initializes the controller the right way for its framework.

### Non-Negotiable

`@media (prefers-reduced-motion: reduce)` disables all animations. No exceptions.

### Design-System Integration

All design-system-dependent values use CSS custom properties. The developer-agent sets variables in the project's design tokens — functional code (click handlers, IntersectionObserver, preload logic) is never modified.

### Designer-Agent Output

The designer-agent specifies per-section animation assignments in `design-system.md`:

```
## Animation Assignments

Animation Tier: 2 (Moderate)

Hero: .reveal-fade-up (headline), .reveal-fade-in (image), delay 200ms
Products grid: .stagger-children .reveal-fade-up
Stats section: .counter-animate
Testimonials: .reveal-fade-in
CTA: .reveal-fade-up
```
