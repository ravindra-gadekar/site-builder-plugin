# Vue / Nuxt Framework Adapter

## When to Use
When the client team uses Vue or when Nuxt's hybrid SSR/SSG capabilities are preferred.

## Project Scaffold

```bash
npx nuxi@latest init .
npx nuxi module add @nuxtjs/tailwindcss
npx nuxi module add @nuxtjs/seo
npm install agentation react@^18 react-dom@^18 -D
```

## Folder Structure

```
app/
├── components/
│   ├── ui/                  # Button, Card, Input, etc.
│   ├── sections/            # Hero, FeatureGrid, CTA, etc.
│   └── layout/              # Header, Footer
├── layouts/
│   ├── default.vue          # BaseLayout
│   ├── blog.vue             # BlogLayout
│   └── legal.vue            # LegalLayout
├── pages/
│   ├── index.vue            # Homepage
│   ├── about.vue
│   ├── contact.vue
│   ├── services/
│   │   ├── index.vue
│   │   └── [slug].vue
│   └── blog/
│       ├── index.vue
│       └── [slug].vue
├── composables/
│   └── useSiteData.ts       # Site metadata, nav links
└── assets/
    └── css/
        └── main.css
public/
├── robots.txt
├── images/
└── favicon.ico
server/
├── api/
│   └── contact.post.ts      # Contact form handler
└── routes/
    └── sitemap.xml.ts        # Dynamic sitemap
```

## Component Patterns

```vue
<!-- components/sections/Hero.vue -->
<script setup lang="ts">
defineProps<{
  title: string
  description: string
  ctaText: string
  ctaHref: string
}>()
</script>

<template>
  <section class="py-16">
    <h1 class="text-5xl font-bold">{{ title }}</h1>
    <p class="mt-4 text-neutral-600">{{ description }}</p>
    <NuxtLink :to="ctaHref" class="mt-8 inline-block btn-primary">
      {{ ctaText }}
    </NuxtLink>
  </section>
</template>
```

## SEO Implementation
- Use `useSeoMeta()` composable per page
- `@nuxtjs/seo` module handles sitemap, robots, OG images
- JSON-LD via `useSchemaOrg()` from `nuxt-schema-org`

## Image Optimization
- Use `<NuxtImg>` component from `@nuxt/image`
- Automatic format negotiation and lazy loading
- Set `width`, `height`, and `alt` props

## Agentation (Dev Feedback Tool)

Agentation provides visual feedback for AI coding agents. Since it is a React component, Vue/Nuxt projects use a client-only plugin that dynamically imports React and mounts agentation to a separate DOM node. React is only loaded in development.

**Create `plugins/agentation.client.ts`:**
```ts
import { defineNuxtPlugin } from '#app'

export default defineNuxtPlugin(async () => {
  if (!import.meta.dev) return

  const { createElement } = await import('react')
  const { createRoot } = await import('react-dom/client')
  const { Agentation } = await import('agentation')

  const container = document.createElement('div')
  container.id = 'agentation-root'
  document.body.appendChild(container)
  createRoot(container).render(createElement(Agentation))
})
```

No layout changes needed — the plugin auto-mounts in dev mode.

## Build & Preview
```bash
npm run dev      # Dev server at localhost:3000
npm run build    # Production build
npm run preview  # Preview production build
```

## Sitemap Configuration

The `@nuxtjs/sitemap` module (included via `@nuxtjs/seo`) generates the sitemap. Configure it with a `urls` function in `nuxt.config.ts`.

**Setup:**

1. Module is already installed via `@nuxtjs/seo` — no additional install needed
2. Add `sitemap` config block to `nuxt.config.ts` with a `urls` function
3. Read content dates at build time from the content directory
4. Follow the rules and code pattern in `skills/site-builder/reference/sitemap-indexnow.md` Section D (Nuxt)

**Output:** `.output/public/sitemap.xml`

**Key detail:** Nuxt's sitemap module auto-discovers routes but requires explicit `urls` entries for custom `lastmod`/`priority`/`changefreq` values.

**Git-lastmod and RSS feed:** see `reference/sitemap-indexnow.md` Sections F-G (Phase 11 only — not during Phase 6 DEVELOP).
