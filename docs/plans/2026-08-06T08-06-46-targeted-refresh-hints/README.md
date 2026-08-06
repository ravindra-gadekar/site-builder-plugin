# Targeted Refresh Hints & Expanded Auto-Patch — Implementation Plan

> **For agentic workers:** Use `/implement --auto docs/plans/2026-08-06T08-06-46-targeted-refresh-hints/` to execute this plan
> phase-by-phase, task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the blanket PostToolUse echo with targeted, file-pattern-based refresh hints and expand the pre-commit script with Tailwind config fallback parsing and a soft-blocking doc-relevance gate.
**Architecture:** New `refresh-hint.sh` template for PostToolUse hooks; expanded `doc-refresh-script.sh` with Tailwind fallback + soft-blocking gate (Step 3). Documentation updates across SKILL.md, doc-refresh.md, and doc-templates.md.
**Tech Stack:** POSIX sh, Markdown
**Repo:** site-builder-plugin (all phases)
**Spec:** `docs/specs/2026-08-06T07-04-11-targeted-refresh-hints-design.md`

## Global Constraints

- All shell scripts must be POSIX sh compliant — no `[[`, no herestrings (`<<<`), no bash arrays, no `local -a`
- All file reads in scripts must pipe through `tr -d '\r'` for CRLF safety (Windows Git Bash)
- Patching (Steps 1-2 of doc-refresh-script.sh) must always exit 0 on error — never block commits on doc-refresh failure
- Only the soft-blocking gate (Step 3) may exit 1, and only for the specific pattern-mismatch condition
- The gitignore hook (`site-builder:gitignore` marker block) must be unaffected
- Layer 1 (agent-indexed checklist gate) is unchanged — judgment content still requires agent/orchestrator verification
- CSS `:root {}` fallback is deferred — not implemented in this plan

## Phases

| Phase | Repo | Name | Tasks | Delivers |
|-------|------|------|-------|----------|
| 1 | site-builder-plugin | Targeted Refresh-Hint Script | 2 | New `reference/refresh-hint.sh` — file-pattern-targeted PostToolUse hint script |
| 2 | site-builder-plugin | Expanded Doc-Refresh Script | 2 | Tailwind config fallback parsing + soft-blocking gate in `reference/doc-refresh-script.sh` |
| 3 | site-builder-plugin | Documentation & Orchestrator Updates | 3 | Updated SKILL.md, doc-refresh.md, doc-templates.md with new script references and behavior docs |

## Execution Order

Phases MUST be executed in order. Each phase depends on the previous phase.
Start with: `docs/plans/2026-08-06T08-06-46-targeted-refresh-hints/phase-1.md`
