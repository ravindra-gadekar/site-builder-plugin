# Phase 4: Adapter Cross-References

**Repo:** site-builder-plugin
**Depends on:** Phase 1 (Sections F/G must exist — these are one-line pointers to them, not new content)
**Delivers:** All 4 framework adapters (`astro.md`, `nextjs.md`, `vue.md`, `react.md`) carry a one-line cross-reference under "Sitemap Configuration" pointing to `sitemap-indexnow.md` Sections F-G, with an explicit "Phase 11 only" note so Phase 6 DEVELOP doesn't pick up git-lastmod/RSS logic prematurely.

## File Structure

```
skills/site-builder/adapters/
├── astro.md      [MODIFY — 1 line]
├── nextjs.md      [MODIFY — 1 line]
├── vue.md         [MODIFY — 1 line]
└── react.md       [MODIFY — 1 line]
```

### Task 1: Cross-reference in `astro.md` and `nextjs.md`

**Files:**
- Modify: `skills/site-builder/adapters/astro.md`
- Modify: `skills/site-builder/adapters/nextjs.md`

**Interfaces:**
- Consumes: `sitemap-indexnow.md` Sections F, G (Phase 1 Tasks 2-3)
- Produces: One-line cross-reference in each file — no downstream plan consumers (leaf documentation pointers)

**Acceptance Criteria:** AC8 (one-line cross-reference under Sitemap Configuration, no full subsections, exact wording)

**Steps (Documentation: Write-and-review):**

1. **Write content** — In `astro.md`, under the existing `## Sitemap Configuration` section (the one ending with "**Key detail:** Astro's sitemap integration runs at build time..."), append a new line:

   ```markdown
   **Git-lastmod and RSS feed:** see `reference/sitemap-indexnow.md` Sections F-G (Phase 11 only — not during Phase 6 DEVELOP).
   ```

   In `nextjs.md`, under the existing `## Sitemap Configuration` section (ending with "**Output:** `public/sitemap-0.xml` (next-sitemap) or `.next/server/app/sitemap.xml` (built-in)"), append the same line verbatim.

2. **Verify references** — Confirm neither file gained any new subsection headings (`### ...`) related to git-lastmod or RSS — only the single line was added, per AC8's "No full subsections — all implementation details live in sitemap-indexnow.md Sections F/G only." Confirm the line text is byte-identical across both files (and will match Task 2's files below), so a future grep for this exact sentence finds all 4 adapters consistently.

3. **Commit** — `docs(site-builder): cross-reference Sections F-G from astro and nextjs adapters`

---

### Task 2: Cross-reference in `vue.md` and `react.md`

**Files:**
- Modify: `skills/site-builder/adapters/vue.md`
- Modify: `skills/site-builder/adapters/react.md`

**Interfaces:**
- Consumes: `sitemap-indexnow.md` Sections F, G (Phase 1 Tasks 2-3); same cross-reference sentence as Task 1 (for consistency)
- Produces: One-line cross-reference in each file — no downstream plan consumers

**Acceptance Criteria:** AC8 (one-line cross-reference under Sitemap Configuration, no full subsections, exact wording)

**Steps (Documentation: Write-and-review):**

1. **Write content** — In `vue.md`, under the existing `## Sitemap Configuration` section (ending with "**Key detail:** Nuxt's sitemap module auto-discovers routes but requires explicit `urls` entries..."), append:

   ```markdown
   **Git-lastmod and RSS feed:** see `reference/sitemap-indexnow.md` Sections F-G (Phase 11 only — not during Phase 6 DEVELOP).
   ```

   In `react.md`, under the existing `## Sitemap Configuration` section (ending with "**Key detail:** Since React SPAs are client-rendered, search engines may not discover all routes via crawling alone..."), append the same line verbatim.

2. **Verify references** — Confirm the sentence in both files is byte-identical to the one added in Task 1's `astro.md`/`nextjs.md` (same exact wording across all 4 adapters — this satisfies AC8's implicit consistency requirement). Confirm no full subsections were added.

3. **Commit** — `docs(site-builder): cross-reference Sections F-G from vue and react adapters`

---

## Phase 4 Complete

All 4 framework adapters point to the single authoritative source (`sitemap-indexnow.md` Sections F-G) for git-lastmod and RSS feed implementation, with an explicit Phase-11-only scope note — no duplicated implementation detail across adapter files.

**Next:** `phase-5.md`
