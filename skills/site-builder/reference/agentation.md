# Agentation Integration Guide

Visual feedback tool for AI coding agents. Lets users click elements on the running website, annotate them with notes, and generate structured output (CSS selectors, element paths, bounding boxes) that AI agents use to locate and fix the exact code.

**Install as dev dependency in every project.** Never ship to production.

## Installation

```bash
npm install agentation -D
```

Requires React 18+ as a peer dependency. For non-React frameworks, React and ReactDOM are installed as dev dependencies alongside agentation.

## Framework Integration

### Astro

Astro needs React integration to render the agentation component as a client island.

**Scaffold commands (add to existing):**
```bash
npx astro add react
npm install agentation -D
```

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

### Next.js

Already React-based. Use dynamic import to avoid SSR issues.

**Scaffold commands (add to existing):**
```bash
npm install agentation -D
```

**Create `src/components/dev/AgentationOverlay.tsx`:**
```tsx
'use client'

import { Agentation } from 'agentation'

export default function AgentationOverlay() {
  if (process.env.NODE_ENV !== 'development') return null
  return <Agentation />
}
```

**Add to root `layout.tsx`** (inside `<body>`, after `{children}`):
```tsx
import dynamic from 'next/dynamic'

const AgentationOverlay = dynamic(
  () => import('@/components/dev/AgentationOverlay'),
  { ssr: false }
)

// In the JSX:
{process.env.NODE_ENV === 'development' && <AgentationOverlay />}
```

### Vue / Nuxt

Uses a client-only Nuxt plugin that dynamically imports React and mounts agentation to a separate DOM node. React is only loaded in development.

**Scaffold commands (add to existing):**
```bash
npm install agentation react@^18 react-dom@^18 -D
```

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

No layout changes needed — the plugin auto-mounts to the DOM in dev mode.

### React SPA (Vite)

Already React-based. Simplest integration.

**Scaffold commands (add to existing):**
```bash
npm install agentation -D
```

**Add to `src/App.tsx`** (after all other components, inside the root fragment):
```tsx
import { Agentation } from 'agentation'

// In the JSX:
{import.meta.env.DEV && <Agentation />}
```

## Agent Sync via MCP (Optional)

For real-time two-way communication between the browser toolbar and AI agents (eliminates copy-paste), configure the agentation MCP server in `.mcp.json`:

```json
{
  "mcpServers": {
    "agentation": {
      "command": "npx",
      "args": ["-y", "agentation-mcp", "server"]
    }
  }
}
```

Then connect the React component to the server:

```tsx
<Agentation endpoint="http://localhost:4747" />
```

Verify with: `npx agentation-mcp doctor`

## Dev-Only Rules

- The `<Agentation />` component MUST only render in development mode
- Use framework-specific dev checks: `import.meta.env.DEV` (Astro/Vite), `process.env.NODE_ENV` (Next.js), `import.meta.dev` (Nuxt)
- Never include agentation in production builds
- The component renders a toolbar in the bottom-right corner — no layout impact
