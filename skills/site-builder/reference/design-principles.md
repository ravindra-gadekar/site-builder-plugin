# Design Principles — Anti-AI-Look Guidelines

## Core Principle

Websites built by this pipeline must look human-designed. AI-generated websites share telltale patterns that users and clients recognize immediately. This document defines what to avoid and what to aim for.

## Red Flags — Patterns That Scream "AI Made This"

### Visual Red Flags
- **Generic gradient backgrounds** — especially blue-to-purple or teal-to-blue hero sections
- **Uniform rounded cards with drop shadows** — same border-radius, same shadow on every card
- **Stock-photo-heavy hero sections** — generic business people shaking hands, laptop on desk
- **Symmetrical everything** — perfectly balanced layouts with no visual tension
- **Overuse of icons** — every feature gets a generic icon in a circle
- **Rainbow accent colors** — each section uses a different color for no reason
- **Cookie-cutter testimonials** — round avatar, name, title, quote — identical layout every time

### Structural Red Flags
- **Same section height everywhere** — uniform padding creates monotony
- **No visual hierarchy** — every element competes equally for attention
- **Template-feeling navigation** — centered logo, evenly spaced links, standard hamburger
- **Generic CTA language** — "Get Started," "Learn More," "Contact Us" with no specificity
- **Footer kitchen sink** — every possible link dumped into a 4-column footer

### Content Red Flags
- **Corporate buzzword soup** — "innovative solutions," "cutting-edge technology," "leveraging synergies"
- **Perfect parallelism** — every bullet point starts with a verb, same sentence length
- **No personality** — could apply to any business in any industry
- **Suspiciously comprehensive** — covers every possible angle with no clear focus

## What Good Looks Like

### Layout
- **Intentional asymmetry** — break the grid occasionally, use varied column ratios (60/40, 70/30)
- **Purposeful whitespace** — not uniform padding, but breathing room where the eye needs rest
- **Varied section heights** — some sections tight, others generous, based on content needs
- **Visual focal points** — one thing per section demands attention first

### Typography
- **Editorial hierarchy** — large display headlines, contrasting body text, clear size jumps
- **Font personality** — the typeface says something about the brand (serious serif, friendly rounded, sharp geometric)
- **Restraint** — max 2 font families, 3-4 weights, consistent scale

### Color
- **Intentional palette** — 1 primary, 1-2 accents, neutrals. Not a rainbow.
- **Meaningful color use** — color indicates something (action, category, emphasis), not decoration
- **Contrast for readability** — not just WCAG compliance, but comfortable reading

### Imagery
- **Specific to the business** — real photos of real work, or illustrations that match the brand
- **Consistent style** — if using illustrations, same style throughout. If photos, same treatment.
- **Purposeful placement** — images support the message, not fill space

### Copy
- **Specific claims** — "served 200+ clients in Maharashtra" not "trusted by many"
- **Natural voice** — reads like a person wrote it for this specific business
- **Varied sentence structure** — mix of short punchy statements and longer explanations
- **Industry-specific language** — uses terms the audience actually uses

## Validation Checklist

The designer agent runs this checklist. Any "yes" answer requires a fix:

1. Could this design work for any business if you swapped the logo? → Too generic
2. Are all cards/sections the same height with the same padding? → Too uniform
3. Does the color palette use more than 3 hues? → Too many colors
4. Is every section symmetrically balanced? → Too safe
5. Could the copy apply to a competitor? → Not specific enough
6. Are there more than 2 generic stock photos? → Needs custom imagery
7. Does navigation look like a Bootstrap/Tailwind template? → Needs personality
8. Is the hero section a gradient with centered text? → AI pattern

## Detection Rules

> Rules adapted from [Impeccable](https://github.com/pbakaus/impeccable) (Apache 2.0). Rewritten in our format.

**Brand Asset Override:** All detection rules below are advisory. When the designer-agent detects existing brand assets in a client project (colors, fonts extracted from CSS/config files), those assets override conflicting rules. The self-validation step skips rules that conflict with established brand identity. Example: if a client's brand uses Inter, the "overused typeface" rule is suppressed for that project.

### Typography Staleness

| # | Rule | Detect | Fix |
| --- | ------ | -------- | ----- |
| 1 | Overused typeface | Inter, Poppins, Roboto, or Montserrat used as sole font without brand justification | Choose a typeface that reflects the brand personality — serif for authority, rounded sans for friendliness, geometric sans for tech. If the client's existing brand uses one of these fonts, this rule is suppressed. |
| 2 | Flat type hierarchy | Fewer than 3 distinct font sizes in use across the page | Establish a clear type scale with minimum 5 sizes: display (hero), h2, h3, body, small. Size jumps should be noticeable (1.25× minimum ratio). |
| 3 | Inconsistent font weight | Same weight (e.g., 400) used everywhere, or weights vary without pattern | Define a weight system: 700 for headings, 600 for subheadings, 400 for body, 500 for emphasis. Apply consistently. |
| 4 | Body text below 16px on mobile | Base body text renders smaller than 16px on screens ≤768px | Set body text to minimum 16px (1rem) on mobile. Use `clamp()` or responsive sizes that never drop below this floor. |
| 5 | Line height outside range | Body text line height below 1.4 or above 1.7 | Set body text line-height between 1.4–1.6 for optimal readability. Headings can be tighter (1.1–1.3). |

### Contrast & Color

| # | Rule | Detect | Fix |
|---|------|--------|-----|
| 6 | Low text contrast | Text-to-background contrast ratio below WCAG AA 4.5:1 (3:1 for large text ≥24px or bold ≥18.5px) | Adjust text color or background to meet minimum 4.5:1. Use a contrast checker tool. |
| 7 | Palette bloat | More than 5 chromatic colors (excluding neutrals) in the primary palette | Limit to 1 primary + 1-2 accents + semantic colors (success/warning/error). Neutrals are free. |
| 8 | Generic gradient | Purple-to-blue, pink-to-orange, or teal-to-cyan gradient used without brand connection | Derive gradients from the brand's primary/accent colors. If using a gradient, it should feel ownable. |
| 9 | Color-only state indicators | Interactive state changes (hover, active, disabled) communicated only through color | Add a secondary indicator: underline, icon change, opacity shift, border, or scale transform alongside color. |
| 10 | Low interactive/non-interactive contrast | Interactive elements (buttons, links) visually indistinguishable from surrounding non-interactive text | Interactive elements need minimum 2 visual differentiators: color + weight, color + underline, color + border. |

### Spacing Anti-patterns

| # | Rule | Detect | Fix |
|---|------|--------|-----|
| 11 | Cramped padding | Less than 12px padding on interactive elements (buttons, inputs, cards) | Minimum 12px horizontal, 8px vertical on all interactive elements. Prefer 16px+ for comfortable touch targets. |
| 12 | Inconsistent spacing scale | Spacing values don't follow a mathematical ratio or design system scale | Use a consistent spacing scale (4px base: 4, 8, 12, 16, 24, 32, 48, 64). Never use arbitrary pixel values. |
| 13 | Section padding too tight | Desktop section vertical padding below 64px (4rem) | Sections need minimum 64px (py-16) vertical padding on desktop for breathing room. Hero sections should be more generous (96-128px). |
| 14 | Heading level skip | Heading hierarchy jumps levels (h1 → h3, h2 → h4) without intervening level | Maintain strict heading hierarchy. Every h3 should be preceded by an h2, every h2 by an h1 on the page. |

### Motion Anti-patterns

| # | Rule | Detect | Fix |
|---|------|--------|-----|
| 15 | Default/linear timing | Animations use `linear` or browser-default `ease` instead of custom curves | Use purposeful easing: `ease-out` for entrances, `ease-in-out` for state changes, custom cubic-bezier for brand feel. Never `linear` for UI motion. |
| 16 | Overlong micro-interactions | Hover, focus, or toggle animations exceed 500ms duration | Micro-interactions: 150-300ms. Page transitions: 300-500ms. Only scroll-triggered reveals can exceed 500ms. |
| 17 | Purposeless animation | Motion exists purely for decoration with no functional role (doesn't guide attention, indicate state, or reveal content) | Every animation should serve one of: reveal content on scroll, indicate state change, guide user attention, provide feedback. Remove decorative-only motion. |
| 18 | No reduced-motion fallback | Animations lack `prefers-reduced-motion: reduce` media query override | Wrap all animations in `@media (prefers-reduced-motion: no-preference)` or disable via media query. This is non-negotiable. |

### Accessibility Catches

| # | Rule | Detect | Fix |
|---|------|--------|-----|
| 19 | Missing focus states | Interactive elements lack visible focus indicator, or focus ring is invisible against background | Add `focus-visible` ring with minimum 2px width and sufficient contrast. Use outline-offset for spacing. |
| 20 | Small touch targets | Interactive elements (buttons, links, inputs) have tap area below 44×44px | Ensure minimum 44×44px touch target. Use padding to increase tap area without changing visual size if needed. |
| 21 | Skip-to-content absent | Page has no skip-to-content link for keyboard/screen-reader users | Add `<a href="#main-content" class="sr-only focus:not-sr-only">Skip to content</a>` as first focusable element. |
| 22 | Placeholder-only inputs | Form inputs use placeholder text as their only label (no `<label>` element) | Every input needs a visible `<label>` element. Placeholder is supplementary, not a replacement. |

### Component Defaults

| # | Rule | Detect | Fix |
|---|------|--------|-----|
| 23 | Uniform border-radius | Every element uses the same border-radius value (no visual hierarchy through rounding) | Vary radius by component role: buttons (md/lg), cards (lg/xl), badges/pills (full), containers (sm/md). Create a radius scale. |
| 24 | Uniform shadow depth | All elevated elements share identical shadow (no depth hierarchy) | Vary shadow by elevation: subtle for cards (sm), moderate for dropdowns (md), prominent for modals (lg/xl). |
| 25 | Uncustomized framework UI | Default Tailwind UI, shadcn, or framework component appearance used without brand customization | Customize at minimum: colors (match brand), border-radius (match system), font (match typography). Components should feel designed, not installed. |
| 26 | Excessive card nesting | Cards nested inside cards more than 1 level deep | Flatten the visual hierarchy. Use spacing, color, or borders to distinguish content levels instead of nested containers. |
| 27 | No button weight differentiation | Primary and secondary buttons look identical or nearly so | Primary: solid background + white text. Secondary: outline or lighter fill. Ghost/tertiary: text-only. Visual weight must decrease. |

---

## Rule Application

**When rules are checked:**

1. Designer-agent self-validates against the full ruleset (existing validation checklist + detection rules above) before outputting `design-system.md`
2. If validation fails → fix and re-validate (max 2 cycles)
3. After 2 cycles, output `design-system.md` with remaining violations annotated as warnings (not blockers). The orchestrator presents warnings at the approval gate: "Design passed N/27 rules, M advisory warnings: [list]." User decides whether to accept or request revision.
4. Accessibility audit agent references rules #19-22 during AUDIT phase

**Severity:** All 27 rules are advisory, not hard blockers. The goal is consistently high quality with flexibility for justified exceptions.
