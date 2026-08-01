# Astro Framework Adapter

## When to Use
Recommended for static marketing sites, blog-heavy sites, SEO-first projects. Zero JavaScript by default — interactive islands only where needed.

## Project Scaffold

```bash
npm create astro@latest . -- --template minimal --typescript strict
npx astro add tailwind
npx astro add sitemap
npx astro add mdx
npx astro add react
npm install agentation -D
```

## Folder Structure

```
src/
├── components/
│   ├── ui/              # Button, Card, Input, etc.
│   ├── sections/        # Hero, FeatureGrid, CTA, etc.
│   └── layout/          # Header, Footer, SEOHead
├── content/
│   ├── config.ts        # Content collection schemas
│   └── blog/            # Blog posts as .md/.mdx
├── layouts/
│   ├── BaseLayout.astro
│   ├── BlogLayout.astro
│   └── LegalLayout.astro
├── pages/
│   ├── index.astro
│   ├── about.astro
│   ├── contact.astro
│   ├── services/
│   │   ├── index.astro
│   │   └── [slug].astro
│   ├── blog/
│   │   ├── index.astro
│   │   └── [...slug].astro
│   └── [legal-pages].astro
├── styles/
│   └── global.css
└── data/
    └── site.ts          # Site metadata, nav links, social URLs
public/
├── robots.txt
├── favicon.svg
└── images/
```

## Component Patterns

**Astro components** (`.astro` files) for static content — no client JS shipped:

```astro
---
// Component script (server-only)
interface Props {
  title: string
  description: string
}
const { title, description } = Astro.props
---

<section class="py-16">
  <h2 class="text-3xl font-bold">{title}</h2>
  <p class="mt-4 text-neutral-600">{description}</p>
</section>
```

**Interactive islands** — use `client:load` or `client:visible` for React/Vue/Svelte components that need JS:

```astro
---
import ContactForm from '../components/ContactForm.tsx'
---

<ContactForm client:visible />
```

## Routing
- File-based routing in `src/pages/`
- Dynamic routes: `[slug].astro` with `getStaticPaths()`
- Content collections: use `getCollection()` for blog posts

## SEO Implementation
- `<SEOHead>` component in layout using `<head>` slot
- Astro `<ViewTransitions />` for smooth page transitions
- `@astrojs/sitemap` integration generates sitemap automatically
- JSON-LD via `<script type="application/ld+json" set:html={JSON.stringify(schema)} />`

## Image Optimization
- Use `astro:assets` — `<Image />` component for automatic WebP/AVIF
- Import images: `import heroImg from '../assets/hero.jpg'`
- Set `width` and `height` for CLS prevention

## Build & Preview
```bash
npm run dev      # Dev server at localhost:4321
npm run build    # Static build to dist/
npm run preview  # Preview built site
```

## Agentation (Dev Feedback Tool)

Agentation provides visual feedback for AI coding agents. It is installed as a dev dependency and only renders in development mode.

**Create `src/components/dev/AgentationOverlay.tsx`:**
```tsx
import { Agentation } from 'agentation'

export default function AgentationOverlay() {
  return <Agentation />
}
```

**Add to `BaseLayout.astro`** (inside `<body>`, after `<slot />`):
```astro
---
import AgentationOverlay from '../components/dev/AgentationOverlay.tsx'
---

{import.meta.env.DEV && <AgentationOverlay client:load />}
```

## Contact Form Options
- Formspree: `<form action="https://formspree.io/f/..." method="POST">`
- Netlify Forms: `<form name="contact" netlify>`
- Custom API: Fetch to external API endpoint with client-side JS island

## Sitemap Configuration

The `@astrojs/sitemap` integration generates the sitemap. Configure it with per-page `lastmod`, `priority`, and `changefreq` using the `serialize` callback.

**Setup:**

1. `npx astro add sitemap` (if not already installed)
2. In `astro.config.mjs`, add a `serialize` callback to the sitemap integration
3. Create a helper function that reads blog frontmatter dates at config time
4. Maintain a `pageLastmod` map for static pages
5. Follow the rules and code pattern in `skills/site-builder/reference/sitemap-indexnow.md` Section D (Astro)

**Output:** `dist/sitemap-0.xml` (or `dist/sitemap-index.xml` if multiple sitemaps)

**Key detail:** Astro's sitemap integration runs at build time and has access to the filesystem, so reading frontmatter dates via `fs` is the correct approach (not a runtime API).
