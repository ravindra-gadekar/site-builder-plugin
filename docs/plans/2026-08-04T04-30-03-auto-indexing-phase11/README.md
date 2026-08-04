# Auto-Indexing (Phase 11) — Implementation Plan

> **For agentic workers:** Use `/implement --auto <path>` to execute this plan
> phase-by-phase, task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a new Phase 11 (AUTO-INDEXING) to the site-builder pipeline, owned by a dedicated 15th agent (`seo-indexing-agent`), that configures git-derived sitemap `lastmod`, an inline-CI IndexNow ping, and RSS/Atom feed generation in client projects — dispatched immediately after Phase 10 (analytics-agent).

**Architecture:** `agents/seo-indexing-agent.md` is a new detect/diff/approve agent (same pattern as deploy-agent's CI/CD assessment) that patches each framework adapter's sitemap config with a git-log-based `lastmod` resolver, verifies/creates the IndexNow key file and an **inline-only** CI/CD post-deploy notification step (no separate script file, anywhere in the pipeline), and scaffolds a per-adapter RSS/Atom feed. `reference/sitemap-indexnow.md` gains Section F (git-lastmod resolver) and Section G (RSS/Atom feed), and Section E (IndexNow) is rewritten from the old separate-script pattern to the inline `grep`/`jq`/`curl` pattern — `deploy-agent.md` §7b is updated to match, so Phase 9 itself never creates `scripts/ping-indexnow.mjs`.

**Tech Stack:** Markdown (Claude Code agent/skill definitions) — no application code in this repo. Generated code snippets target Node.js `execFileSync`, framework sitemap configs (Astro/Next.js/Nuxt/React SPA), and GitHub Actions/Vercel/Netlify CI YAML.

**Repo:** `site-builder-plugin` (single repo, all 5 phases target it)
**Spec:** `docs/specs/2026-08-04T14-30-00-auto-indexing-phase11-design.md`

---

## Global Constraints

- NEVER use `execSync` with string interpolation for git commands — always `execFileSync('git', [...])` with an argument array (command injection prevention via filenames).
- No separate `scripts/ping-indexnow.mjs` file anywhere in the pipeline's output — IndexNow notification is 100% inline in the CI/CD workflow YAML (`grep`/`jq`/`curl`), confirmed with the user mid-plan-generation.
- `reference/sitemap-indexnow.md` Section A (lastmod rules) is read-only in this plan — only a forward reference to Section F is appended at its bottom.
- `agents/developer-agent.md` and `agents/analytics-agent.md` are NOT modified — Phase 6/10 scaffolding stays as-is; Phase 11 patches their output, not their instructions.
- Google never receives a WebSub/PubSubHubbub ping — relies on accurate `lastmod` + `robots.txt` + the existing manual GSC reminder from Phase 10.
- All new/patched CI logic must be idempotent — re-running Phase 11 on an already-configured project only diffs missing/outdated pieces, never duplicates steps.

## Phases

| Phase | Repo | Name | Tasks | Delivers |
|-------|------|------|-------|----------|
| 1 | site-builder-plugin | Reference Doc Foundation | 4 | `sitemap-indexnow.md`: Section E rewritten to inline-only IndexNow CI pattern; new Section F (git-lastmod resolver); new Section G (RSS/Atom feed); Section A forward-reference |
| 2 | site-builder-plugin | New Agent + Phase Registration | 2 | `agents/seo-indexing-agent.md` (full Phase 11 instructions); `phases.md` Phase 11 entry |
| 3 | site-builder-plugin | Orchestrator + Deploy Agent Sync | 3 | `deploy-agent.md` §7b rewritten to match Section E; `SKILL.md` Phase 11 dispatch + Pipeline Complete move; `pipeline_version` v3→v4 + resume rules + status tracking + PR schedule |
| 4 | site-builder-plugin | Adapter Cross-References | 2 | One-line Section F/G pointer added to `astro.md`, `nextjs.md`, `vue.md`, `react.md` |
| 5 | site-builder-plugin | Documentation Consistency | 4 | `README.md`, `CONTEXT.md`, `docs/project/architecture.md`, `ARCHITECTURE.md`, `CLAUDE.md` bumped 14→15 agents |

## Execution Order

Phases MUST be executed in order — each phase's content is referenced by the next (Section F/G before the agent that cites them; the agent before phases.md/SKILL.md reference it by name; adapters cross-reference Sections F/G; doc counts are bumped last, once the 15th agent file actually exists).

Start with: `docs/plans/2026-08-04T04-30-03-auto-indexing-phase11/phase-1.md`

## Notes from Plan Generation

- **Spec inconsistency resolved:** the spec originally listed `agents/deploy-agent.md` and `sitemap-indexnow.md` Section E as unchanged, while the acceptance criteria required an inline-only IndexNow CI step (no `scripts/ping-indexnow.mjs`). Both files' current content still document the separate-script pattern. Per user decision, this plan fixes it at the source (Phase 1 Task 1 + Phase 3 Task 1) rather than having Phase 11 migrate a pre-existing script at runtime.
- **Scope addition beyond the spec's literal file list:** `ARCHITECTURE.md` (root) and `CLAUDE.md` also contain stale "14 agents" mentions the spec didn't call out. Phase 5 Task 4 fixes both for consistency, confirmed with the user.
- **Deliberately left stale:** `.fullstack-dev/config.json`'s `description` field also says "14 specialized AI agents." Unlike the files above, this is a `/project`-skill-managed generated config, not a hand-maintained doc — it's left alone here and will self-correct on the next `/project --init`/refresh run, consistent with how `CLAUDE.md`'s auto-refreshed marker block is treated in Phase 5 Task 4.
- **Grill-gate review (plan-reviewer-agent):** found 2 Critical gaps, both now fixed — Phase 1 Task 1 originally missed rewriting the adjacent "CI/CD Integration" subsection of Section E (still referenced the retired script), and no task updated `phases.md`'s existing Phase 9 DEPLOY entry, which also described the retired script. Phase 2 Task 2 now folds in that `phases.md` fix. Also fixed: stale "Important Notes" bullets in Section E (Phase 1 Task 1), an empty `disallowedTools:` frontmatter key in the agent draft (Phase 2 Task 1), a mislabeled "verbatim" table (Phase 1 Task 2), and a README pipeline-diagram alignment note (Phase 5 Task 1).
