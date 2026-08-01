# Next.js Framework Adapter

## When to Use
When SSR or dynamic features are needed — user auth, API routes, real-time data. Also for React ecosystem preference.

## Project Scaffold

```bash
npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"
npm install agentation -D
```

## Folder Structure

```
src/
├── app/
│   ├── layout.tsx           # Root layout (BaseLayout equivalent)
│   ├── page.tsx             # Homepage
│   ├── about/
│   │   └── page.tsx
│   ├── contact/
│   │   └── page.tsx
│   ├── services/
│   │   ├── page.tsx         # Services index
│   │   └── [slug]/
│   │       └── page.tsx     # Individual service
│   ├── blog/
│   │   ├── page.tsx         # Blog index
│   │   └── [slug]/
│   │       └── page.tsx     # Blog post
│   ├── api/
│   │   └── contact/
│   │       └── route.ts     # Contact form API
│   ├── sitemap.ts           # Dynamic sitemap generation
│   └── robots.ts            # Dynamic robots.txt
├── components/
│   ├── ui/                  # Button, Card, Input, etc.
│   ├── sections/            # Hero, FeatureGrid, CTA, etc.
│   └── layout/              # Header, Footer, SEOHead
├── lib/
│   └── data.ts              # Site metadata, nav links
└── styles/
    └── globals.css
public/
├── images/
└── favicon.ico
```

## Component Patterns

**Server Components** (default) — no "use client" directive:

```tsx
// src/components/sections/Hero.tsx
interface HeroProps {
  title: string
  description: string
  ctaText: string
  ctaHref: string
}

export default function Hero({ title, description, ctaText, ctaHref }: HeroProps) {
  return (
    <section className="py-16">
      <h1 className="text-5xl font-bold">{title}</h1>
      <p className="mt-4 text-neutral-600">{description}</p>
      <a href={ctaHref} className="mt-8 inline-block btn-primary">{ctaText}</a>
    </section>
  )
}
```

**Client Components** — only when interactivity needed (forms, mobile menu, accordion):

```tsx
'use client'

import { useState } from 'react'

export default function MobileMenu() {
  const [isOpen, setIsOpen] = useState(false)
  // ...
}
```

## Routing
- App Router: `app/` directory, `page.tsx` files
- Dynamic routes: `[slug]/page.tsx` with `generateStaticParams()`
- Use `generateStaticParams` for SSG where possible

## SEO Implementation
- Use `Metadata` export or `generateMetadata()` per page:

```tsx
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Page Title | Brand',
  description: '...',
  openGraph: { title: '...', description: '...', images: ['/og-image.jpg'] },
  twitter: { card: 'summary_large_image', title: '...', description: '...' },
  alternates: { canonical: 'https://...' },
}
```

- JSON-LD: render `<script type="application/ld+json">` in page component
- `sitemap.ts` and `robots.ts` as route handlers

## Image Optimization
- Use `next/image` — `<Image />` component for automatic optimization
- Set `width`, `height`, and `alt` props
- Use `priority` prop for above-fold images (disables lazy loading)

## Build & Preview
```bash
npm run dev      # Dev server at localhost:3000
npm run build    # Production build
npm start        # Start production server
```

## Agentation (Dev Feedback Tool)

Agentation provides visual feedback for AI coding agents. It is installed as a dev dependency and only renders in development mode.

**Create `src/components/dev/AgentationOverlay.tsx`:**
```tsx
'use client'

import { Agentation } from 'agentation'

export default function AgentationOverlay() {
  if (process.env.NODE_ENV !== 'development') return null
  return <Agentation />
}
```

**Add to root `src/app/layout.tsx`** (inside `<body>`, after `{children}`):
```tsx
import dynamic from 'next/dynamic'

const AgentationOverlay = dynamic(
  () => import('@/components/dev/AgentationOverlay'),
  { ssr: false }
)

// In the body JSX:
{process.env.NODE_ENV === 'development' && <AgentationOverlay />}
```

## Contact Form
- API route: `app/api/contact/route.ts` with email sending
- Client-side form component with validation
- CSRF protection via header checks

## Sitemap Configuration

Use `next-sitemap` package with a `transform` function in `next-sitemap.config.js` to set per-URL `lastmod`, `priority`, and `changefreq`.

**Setup:**

1. `npm install next-sitemap`
2. Create `next-sitemap.config.js` with a `transform` function
3. Read content dates from the filesystem or a generated manifest
4. Follow the rules and code pattern in `skills/site-builder/reference/sitemap-indexnow.md` Section D (Next.js)

**Alternative (App Router):** Create `app/sitemap.ts` that exports a function returning sitemap entries with per-URL metadata. This is Next.js's built-in approach but requires more manual URL management.

**Output:** `public/sitemap-0.xml` (next-sitemap) or `.next/server/app/sitemap.xml` (built-in)
