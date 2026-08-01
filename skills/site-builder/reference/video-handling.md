# Video Handling

Two video component patterns for the developer-agent. **Video handling is conditional** — only activated when the content-agent identifies video content in client materials. If no videos exist, no video templates are copied and no video audit checks run.

## Pattern 1 — YouTube/Vimeo Facade

A performance-first embed that loads zero bytes from YouTube/Vimeo until the user clicks play.

**How it works:**
1. Render a `<button>` wrapping a poster `<img>` + play icon SVG overlay
2. Poster image follows all rules in `image-optimization.md`
3. On click: replace button with actual `<iframe>`
4. On hover/pointerover: `preconnect` to youtube.com or vimeo.com
5. `aspect-ratio: 16/9` (or client-specified)
6. Explicit `width` and `height` to prevent CLS
7. `aria-label="Play video: [video title]"` for accessibility

**Savings:** ~500KB per YouTube embed, ~300KB per Vimeo embed.

## Pattern 2 — Self-Hosted HTML5 Video

For MP4/WebM files hosted alongside the site.

**How it works:**
1. `<video>` with `preload="none"` — zero bytes until interaction
2. Poster image via `poster` attribute (WebP, optimized)
3. Custom play button overlay (same SVG icon as facade for consistency)
4. On click: set `preload="auto"`, call `.play()`
5. On pointerover: upgrade to `preload="metadata"` (~50KB)
6. Controls shown after play starts
7. `playsinline` for iOS
8. Explicit dimensions on container

## Autoplay Background Videos (Muted Ambient Loops)

For decorative background videos:

- `autoplay muted loop playsinline`
- `preload="auto"` acceptable
- Max 5MB file size
- Max 15 seconds duration
- No audio track
- Static image fallback for `prefers-reduced-motion` (use the poster image)

## Poster Image Acquisition

| Video Source | Poster Strategy |
|---|---|
| YouTube | Auto-fetch `maxresdefault.jpg` (fallback `hqdefault.jpg`) via thumbnail URL. Developer-agent downloads at build time, converts to WebP, stores in `src/assets/`. |
| Vimeo | Auto-fetch via Vimeo oEmbed API (`https://vimeo.com/api/oembed.json?url={URL}`). Same conversion pipeline. |
| Self-hosted (MP4/WebM) | Content-agent flags `poster-needed`. If ffmpeg available, developer-agent extracts first frame or client-specified timestamp. Otherwise, use `real-asset-needed` marker with placeholder. |
| Client-provided poster | Use directly, apply image optimization rules. |

## Component Templates

Reusable component templates are in `templates/video/`:

| File | Framework | Pattern |
|---|---|---|
| `astro-video-facade.astro` | Astro | YouTube/Vimeo facade |
| `astro-video-player.astro` | Astro | Self-hosted HTML5 |
| `nextjs-video-facade.tsx` | Next.js | YouTube/Vimeo facade |
| `nextjs-video-player.tsx` | Next.js | Self-hosted HTML5 |
| `vue-video-facade.vue` | Vue/Nuxt | YouTube/Vimeo facade |
| `vue-video-player.vue` | Vue/Nuxt | Self-hosted HTML5 |
| `react-video-facade.tsx` | React SPA | YouTube/Vimeo facade |
| `react-video-player.tsx` | React SPA | Self-hosted HTML5 |

The developer-agent copies the appropriate framework template into the project's component directory. Templates use CSS custom properties for styling — functional code is never modified.

### Component Props

| Prop | Type | Default | Description |
|---|---|---|---|
| `src` | string | required | Video URL (YouTube/Vimeo URL or file path) |
| `poster` | string | required | Poster image path |
| `title` | string | required | Video title (used for aria-label) |
| `aspectRatio` | string | `"16/9"` | CSS aspect-ratio value |
| `autoplay` | boolean | `false` | Enable autoplay (muted ambient loop mode) |

### CSS Custom Properties

```css
.video-facade {
  border-radius: var(--video-border-radius, 0.5rem);
  --play-btn-bg: var(--color-primary, #f97316);
  --play-btn-size: var(--video-play-size, 4rem);
}
```
