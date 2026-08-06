# BRAND.md Template

**Location:** Project root (`BRAND.md`)
**Purpose:** Design tokens extracted from the site-builder design system —
colors, typography, spacing, and component patterns. Single source of truth
for visual identity outside `.site-builder/`.
**Created by:** Init (Section 2.5), after `ARCHITECTURE.md`, before `CLAUDE.md`
**Updated by:** designer-agent (primary owner, Phase 4 DESIGN), developer-agent
(secondary/verify-only, Phase 6 DEVELOP — only when `.site-builder/design-system.md`
exists), pre-commit script (mechanical token sections only)

---

## Template

```markdown
# BRAND.md

## Brand Direction

<2-3 sentence design philosophy from design-system.md>

## Design Tokens

### Colors

<!-- auto:color-tokens -->
| Token | Value | Usage |
|---|---|---|
| Primary | <hex> | <where used> |
| Secondary | <hex> | <where used> |
| Accent | <hex> | <where used> |
| Background | <hex> | <where used> |
| Surface | <hex> | <where used> |
| Text Primary | <hex> | <where used> |
| Text Secondary | <hex> | <where used> |
<!-- /auto:color-tokens -->

### Typography

<!-- auto:font-stack -->
| Role | Family | Weight | Size |
|---|---|---|---|
| Heading | <font> | <weight> | <scale> |
| Body | <font> | <weight> | <scale> |
| UI | <font> | <weight> | <scale> |
<!-- /auto:font-stack -->

### Spacing

<!-- auto:spacing-scale -->
| Token | Value | Usage |
|---|---|---|
| xs | <value> | <usage> |
| sm | <value> | <usage> |
| md | <value> | <usage> |
| lg | <value> | <usage> |
| xl | <value> | <usage> |
<!-- /auto:spacing-scale -->

### Shadows

<shadow definitions — not auto-managed>

### Border Radius

<border-radius scale — not auto-managed>

### Transitions

<transition presets — not auto-managed>

## Component Patterns

### Navigation
<nav pattern description>

### Hero
<hero pattern description>

### Cards
<card pattern description>

### Buttons
<button styles and states>

### Footer
<footer pattern description>

## Dark Mode (if applicable)

<dark mode token mappings>
```

---

## Population Rules

- **Existing codebase (CSS/Tailwind config present):** Extract color values
  from `tailwind.config.*` `theme.extend.colors`, font families from
  `theme.extend.fontFamily`, spacing from `theme.extend.spacing`. If raw CSS:
  parse custom properties from `:root {}`. Populate the token tables with
  extracted values. Component Patterns section left as placeholders.
- **Greenfield project (no config):** All token table cells use
  `<placeholder>` text. Brand Direction says "Pending Phase 4 DESIGN".
  Component Patterns section left as placeholders.
- **After Phase 4 DESIGN:** designer-agent populates ALL sections from
  `.site-builder/design-system.md`. This is the primary population event.
- **After Phase 6 DEVELOP:** developer-agent verifies that BRAND.md tokens
  still match design-system.md (tokens may have been adjusted during
  implementation). Verify-only — do not overwrite designer-agent content
  unless values diverged.

---

## Auto-Marker Reference

| Marker | Section | Source |
|---|---|---|
| `auto:color-tokens` | Colors table | `.site-builder/design-system.md` ### Colors |
| `auto:font-stack` | Typography table | `.site-builder/design-system.md` ### Typography |
| `auto:spacing-scale` | Spacing table | `.site-builder/design-system.md` ### Spacing |

These three sections are patched by the pre-commit script
(`reference/doc-refresh-script.sh`, Layer 2). All other sections (Brand
Direction, Shadows, Border Radius, Transitions, Component Patterns, Dark
Mode) are judgment content managed by the designer-agent gate (Layer 1) only.
See `reference/doc-refresh.md` for the full ownership boundary.
