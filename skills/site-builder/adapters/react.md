# React SPA Framework Adapter

## When to Use
Only when a single-page application is specifically required. NOT recommended for marketing/SEO-focused sites — use Astro or Next.js instead.

## Project Scaffold

```bash
npm create vite@latest . -- --template react-ts
npm install -D tailwindcss @tailwindcss/vite
npm install react-router-dom react-helmet-async
npm install agentation -D
```

## Folder Structure

```
src/
├── components/
│   ├── ui/
│   ├── sections/
│   └── layout/
├── pages/
│   ├── Home.tsx
│   ├── About.tsx
│   ├── Contact.tsx
│   ├── Services.tsx
│   ├── ServiceDetail.tsx
│   └── Blog.tsx
├── router/
│   └── index.tsx            # Route definitions
├── data/
│   └── site.ts              # Site metadata
├── hooks/
│   └── useSEO.ts            # SEO helper hook
└── styles/
    └── index.css
public/
├── robots.txt
├── sitemap.xml              # Must be pre-generated (no server)
└── images/
```

## Component Patterns

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
      <Link to={ctaHref} className="mt-8 inline-block btn-primary">{ctaText}</Link>
    </section>
  )
}
```

## SEO Limitations

**SPAs have significant SEO limitations:**
- Content rendered client-side — search engines may not index properly
- No server-side rendering — AI crawlers may miss content
- Meta tags require `react-helmet-async` and careful management
- Sitemap must be manually generated and maintained

**Mitigations:**
- Use `react-helmet-async` for per-page meta tags
- Pre-render critical pages with a build-time renderer if possible
- Generate static `sitemap.xml` during build
- Ensure JSON-LD is in the initial HTML (not dynamically injected)

## Routing
- React Router v6: `<Routes>` and `<Route>` components
- Use `<Link>` for internal navigation
- Code splitting with `React.lazy()` and `<Suspense>`

## Build & Preview
```bash
npm run dev      # Dev server at localhost:5173
npm run build    # Production build to dist/
npm run preview  # Preview built site
```

## Agentation (Dev Feedback Tool)

Agentation provides visual feedback for AI coding agents. It is installed as a dev dependency and only renders in development mode.

**Add to `src/App.tsx`** (inside the root fragment, after all other components):
```tsx
import { Agentation } from 'agentation'

// In the JSX:
{import.meta.env.DEV && <Agentation />}
```

## Contact Form
- Client-side form with Formspree or external API
- No server-side API routes available (SPA-only)

## Sitemap Configuration

React SPAs don't have built-in sitemap generation. Create a build-time script that generates `sitemap.xml` from route definitions and content dates.

**Setup:**

1. Create `scripts/generate-sitemap.mjs`
2. Add to build command: `"build": "vite build && node scripts/generate-sitemap.mjs"`
3. Read route definitions and content dates from the filesystem
4. Follow the rules and code pattern in `skills/site-builder/reference/sitemap-indexnow.md` Section D (React SPA)

**Output:** `dist/sitemap.xml`

**Key detail:** Since React SPAs are client-rendered, search engines may not discover all routes via crawling alone. A complete, accurate sitemap is especially important for React SPA projects.

**Git-lastmod and RSS feed:** see `reference/sitemap-indexnow.md` Sections F-G (Phase 11 only — not during Phase 6 DEVELOP).
