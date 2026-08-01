# Image Optimization

Strict image optimization checklist for the developer-agent. Every rule is a hard requirement — no exceptions unless explicitly noted.

## Rule 1: Never Use `public/` for Optimizable Images

All images go in `src/assets/` (or framework equivalent) so the build pipeline processes them.

**Exceptions (stay in `public/`):**
- Favicons
- OG images (must be a fixed URL for social crawlers)

## Rule 2: Use Framework Image Components Exclusively

Never use raw `<img>` tags. Use the framework's optimized image component:

| Framework | Component | Import |
|---|---|---|
| Astro | `<Image />` | `import { Image } from 'astro:assets'` |
| Next.js | `<Image />` | `import Image from 'next/image'` |
| Vue/Nuxt | `<NuxtImg>` | `@nuxt/image` module |
| React SPA | `<picture>` | Manual WebP/AVIF sources + sharp build script |

These components auto-generate srcset, convert to WebP, and set dimensions.

## Rule 3: Context-Aware Responsive `sizes` Attribute

Select the correct `sizes` template based on the section layout from the wireframe:

| Context | `sizes` value |
|---|---|
| Full-bleed hero / banner | `100vw` |
| 2-column (text + image) | `(max-width: 1024px) 100vw, 50vw` |
| 3-column grid | `(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw` |
| 4-column product grid | `(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 25vw` |
| Thumbnail / logo | `(max-width: 640px) 48px, 64px` |
| Sidebar image | `(max-width: 1024px) 100vw, 30vw` |

Three standard srcset breakpoints: 640w (mobile), 1024w (tablet), 1440w (desktop).

## Rule 4: Loading Strategy by Position

| Position | Attributes |
|---|---|
| Above-the-fold (hero, logo, first visible section) | `loading="eager"` + `fetchpriority="high"` |
| Below-the-fold (everything else) | `loading="lazy"` + `decoding="async"` |

## Rule 5: Explicit Dimensions on Every Image

`width` and `height` attributes are required on every image to prevent CLS. Framework image components handle this automatically when source dimensions are known — verify they are set in the rendered output.

## Rule 6: Format Priority

AVIF > WebP > original.

Use `<Picture />` component when the framework supports multi-format sources (Astro's `<Picture />` does this natively). For frameworks without a Picture component, the image component's built-in format conversion is sufficient.

## Rule 7: Client Asset Conversion

Images extracted from client documents must be processed before use:

1. Move from `.site-builder/assets/extracted/` to `src/assets/`
2. Rename to semantic, URL-friendly names (e.g., `product-wire-harness.jpg` not `doc-p3-img2.jpg`)
3. Convert to WebP via sharp or the framework's image pipeline
4. Resize to appropriate dimensions:
   - Max 1920px width for full-bleed hero/banner images
   - Max 800px width for content images
   - Preserve aspect ratio

## Rule 8: Video Poster Images

Video poster images follow all the same rules (1-7 above). They must be optimized, properly sized, and served through the framework's image pipeline.
