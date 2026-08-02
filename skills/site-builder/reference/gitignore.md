# Gitignore Generation

Self-contained `.gitignore` generation for the site-builder pipeline. The
orchestrator owns this directly — it does not delegate to any external skill.
Both call sites (Init Section 2, and Phase 3 PREPARE Step 4) read this file.

## Pattern Catalog

Categories are additive — merge every category whose **Detect** condition
is met into one file, deduplicated, in the **Category Sort Order** below.

| Category | Detect | Always active | Patterns |
|---|---|---|---|
| Universal | — | Yes | `node_modules/`, `*.log`, `npm-debug.log*`, `.pnpm-store/`, `*.tsbuildinfo` |
| Secrets | — | Yes | `.env`, `.env.local`, `.env.*.local`, `.env.production`, `*.pem`, `credentials.json`, `serviceAccountKey.json`, `.claude/settings.local.json` |
| Build | — | Yes | `dist/`, `build/`, `out/`, `coverage/`, `.nyc_output/` |
| Cache | — | Yes | `.cache/`, `.eslintcache`, `.vite/`, `.turbo/`, `.parcel-cache/` |
| IDE | — | Yes | `.idea/`, `*.iml`, `.vscode/*`, `!.vscode/settings.json`, `!.vscode/tasks.json`, `!.vscode/launch.json`, `!.vscode/extensions.json` |
| macOS | Always include (multi-platform team safety) | Yes | `.DS_Store`, `._*`, `.Spotlight-V100`, `.Trashes` |
| Windows | Always include (multi-platform team safety) | Yes | `Thumbs.db`, `Desktop.ini`, `$RECYCLE.BIN/` |
| Linux | Always include (multi-platform team safety) | Yes | `.fuse_hidden*`, `.directory`, `.Trash-*` |
| Astro | `astro.config.*` exists, or framework choice in `status.md` is `astro` | No | `.astro/` (`dist/` already covered by Build) |
| Next.js | `next.config.*` exists, or framework choice is `nextjs` | No | `.next/`, `next-env.d.ts` (`out/` already covered by Build) |
| Nuxt | `nuxt.config.*` exists, or framework choice is `vue` (this pipeline's Vue adapter scaffolds Nuxt) | No | `.nuxt/`, `.output/` (`dist/` already covered by Build) |
| React (Vite) | `vite.config.*` exists, or framework choice is `react` | No | none beyond Build/Cache — Vite's `dist/` and `.vite/` are already covered |
| Deployment | `vercel.json`, `netlify.toml`, or `firebase.json` present (Phase 9 DEPLOY target) | No | matching one of: `.vercel/`, `.netlify/`, `.firebase/` |
| Site Builder | — | Yes | `.site-builder/`, `.mcp.json`, `*.code-workspace` |
| Skills CLI | `skills-lock.json` exists at the project root (true for every project that installed this plugin via `npx skills add`) | No | `.claude/skills/`, `.agents/`, `skills-lock.json` |

### Category Sort Order

`universal`, `secrets`, framework-specific (astro/nextjs/nuxt/react, in that
order — only the ones that are active), `build`, `cache`, `ide`,
`macos`/`windows`/`linux`, `site-builder`, `deployment`, `skills-cli`.

## Marker Block Format

```gitignore
# >>> site-builder:gitignore (do not edit this block) >>>

# Universal
node_modules/
*.log
...

# Secrets
.env
...

# <<< site-builder:gitignore <<<

# --- User entries below ---
```

- Category headers (`# Category Name`) get one blank line before, none after.
- One pattern per line, no inline comments on pattern lines.
- Empty (inactive) categories are omitted entirely — no header, no patterns.
- Negation patterns (e.g. `!.vscode/settings.json`) stay directly after the
  pattern they negate, in the same category.

## Write Procedure (never destructive)

**Read before touching anything.** Never delete or truncate an existing
`.gitignore` before the new content is fully composed and validated.

```
.gitignore exists?
+-- NO  --> Write a new file: marker block (all active categories) +
|           blank line + "# --- User entries below ---"
|
+-- YES --> Read full current content first
    |
    Contains "site-builder:gitignore" start marker?
    +-- YES --> Replace in place
    |   1. Compose the new marker block in memory from active categories
    |   2. Preserve everything before the start marker verbatim
    |   3. Preserve everything after the end marker verbatim
    |   4. Only then write the file (old content is never lost mid-write —
    |      the replacement is computed fully before the write happens)
    |
    +-- NO  --> Prepend
        1. Keep all existing lines as-is (user's own patterns)
        2. Compose the new marker block from active categories, skipping
           any pattern that already appears verbatim in the existing file
           (avoid confusing duplicates; the user's copy wins)
        3. Write: marker block, blank line, "# --- User entries below ---",
           blank line, then the original content
```

If a category's **Detect** condition can't be evaluated for any reason
(e.g. permission error reading a config file), skip that category only —
never abort the whole generation, and never fall back to deleting the
current file.

## Init-Time vs. PREPARE-Time Runs

**Init (Section 2 of the orchestrator's Init flow)** runs before the
framework is chosen (framework selection happens after Phase 1 DISCOVER
approval). Only the always-active categories plus Skills CLI/Deployment
detection apply — no framework category is active yet.

**Phase 3 PREPARE (Step 4)** re-runs generation after the framework is
selected and scaffolded. The matching framework category (Astro/Next.js/
Nuxt/React) is now detectable from the newly-created config file, so it
merges in on top of what Init already wrote — this is the same "replace in
place" branch above, not a second independent write.

Note: `.site-builder/` is gitignored (Site Builder category) — it holds
pipeline state and intermediate artifacts that are tool output, not client
deliverables. The three project docs (`CONTEXT.md`, `ARCHITECTURE.md`,
`CLAUDE.md`) live at the project root and ARE tracked — they are valuable
documentation regardless of whether the site-builder plugin is installed.
