# Site Builder CLI Redesign — Implementation Plan

> **For agentic workers:** Use `/implement --auto <path>` to execute this plan
> phase-by-phase, task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign `/site-builder` to support composable `--init`/`--auto`/`--parallel` flags, collapse build modes from three (demo/stage/prod) to two (demo/prod), delegate git and `.gitignore` operations to the Fullstack Dev `/git` and `/gitignore` skills, make deployment hosting-agnostic, and add a new post-deploy Phase 10 ANALYTICS.

**Architecture:** `skills/site-builder/SKILL.md` gains a flag-dispatch layer that routes `$ARGUMENTS` to either an `--init`-only flow or the full pipeline, mirroring the pattern already used by `/project --init` and `/refactor --auto --parallel`. The ~100-line inline "Git Operations Protocol" is replaced by a lightweight protocol that adopts `/git` skill conventions (commit messages, branch naming, universal stash) while still calling `mcp__github__create_pull_request` directly, because PR target branches vary by mode. `.gitignore` generation moves from inline logic to `/gitignore rebuild` delegation. Three supporting agent files (`deploy-agent.md`, `analytics-agent.md`, `developer-agent.md`) and the project's own docs (`README.md`, `CONTEXT.md`, `skills/site-builder/reference/phases.md`) are updated to match.

**Tech Stack:** Markdown-only Claude Code skill/agent definitions (no application code, no build tooling).

**Repo:** `site-builder-plugin` (mono-repo, single repo — all 5 phases target it)
**Spec:** `docs/specs/2026-08-01T18-30-00-site-builder-cli-redesign-design.md`

---

## Global Constraints

- No new agent files are created — only the 3 existing agents affected by this redesign are modified (`deploy-agent.md`, `analytics-agent.md`, `developer-agent.md`).
- `--demo`/`--prod` remain interactive-only questions, never CLI flags (spec Out of Scope).
- Prod → demo reverse promotion is not supported (one-way only).
- Client-project doc-sync automation is explicitly out of scope for this change.
- Every edit that removes "stage" mode must leave no dangling references to a `stage` branch, `Stage mode`, or `pipeline_version: 2` defaults.
- This repo has no automated test suite (Markdown-only plugin) — task verification is grep-based (confirm old text is gone, new text is present) and prose-consistency review, not `npm test`.

## Phases

| Phase | Repo | Name | Tasks | Delivers |
|-------|------|------|-------|----------|
| 1 | site-builder-plugin | Flag Dispatch & Init | 3 | `SKILL.md` opens with a flag-dispatch table routing `--init`/`--auto`/`--parallel`; Init section replaces Prerequisites Check with git/gitignore/MCP setup and a completion flag in `status.md` |
| 2 | site-builder-plugin | Mode Selection & Git Delegation | 4 | Build mode narrowed to demo/prod; branch setup uses `local-dev` only; ~100-line Git Operations Protocol replaced with a `/git`-convention-adopting protocol and explicit branch guard |
| 3 | site-builder-plugin | Pipeline Phases & Status | 5 | Phase 8 INTEGRATE is social-only; hosting-agnostic Phase 9 DEPLOY; new Phase 10 ANALYTICS; Mode Promotion Flow gains a pre-promotion PR-merged check; `status.md` template moves to `pipeline_version: 3`; `phases.md` documents 10 phases |
| 4 | site-builder-plugin | Agent Updates | 3 | `deploy-agent.md` is hosting-agnostic and receives the hosting choice as input; `analytics-agent.md` reflects its new solo Phase 10 role; `developer-agent.md` drops the `stage` branch reference and documents analytics scaffolding vs. Phase 10 credential injection |
| 5 | site-builder-plugin | Docs Cleanup & Verification | 3 | `README.md` and `CONTEXT.md` reflect demo/prod modes and the new git workflow; final grep-based verification confirms zero `stage`-mode references remain across the 8 files named in the spec's acceptance criteria |

## Execution Order

Phases MUST be executed in order. Each phase depends on the previous phase.
Start with: `docs/plans/2026-08-01T19-00-00-site-builder-cli-redesign/phase-1.md`
