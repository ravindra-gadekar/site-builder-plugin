# Doc Refresh & BRAND.md — Implementation Plan

> **For agentic workers:** Use `/implement --auto docs/plans/2026-08-06T12-00-00-doc-refresh-brand/` to execute this plan
> phase-by-phase, task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the doc-refresh system from phase-indexed footnotes to an agent-indexed checklist gate, add a mechanical-facts pre-commit script with `<!-- auto:* -->` marker ownership, and introduce BRAND.md as a first-class managed document with an Update Mode hard gate.

**Architecture:** Two-layer hybrid refresh: Layer 1 is an agent-indexed gate where the orchestrator verifies judgment-content sections after each agent completes; Layer 2 is a POSIX sh pre-commit script that patches mechanical-fact sections (directory trees, dependency tables, design tokens) inside `<!-- auto:* -->` markers. The two layers never write to the same lines — markers enforce the boundary.

**Tech Stack:** Markdown, POSIX sh
**Repo:** site-builder-plugin (mono-repo, all phases)
**Spec:** `docs/specs/2026-08-04T16-45-00-doc-refresh-brand-design.md`

---

## Global Constraints

- This repo is Markdown-only — no application code, no test framework.
- Layer 2 script must exit 0 on ALL error paths — never block commits on doc-refresh failure.
- Audit agents (6 total) are explicitly excluded from the agent→doc mapping — they are read-only.
- Auto-marker names must be consistent across `doc-templates.md`, `brand-template.md`, and `doc-refresh-script.sh`.
- Section ownership boundary: script writes ONLY inside `<!-- auto:* -->` markers; orchestrator/agents write ONLY outside them.

## Phases

| Phase | Repo | Name | Tasks | Delivers |
|-------|------|------|-------|----------|
| 1 | site-builder-plugin | Foundation — Reference Documents | 3 | New `brand-template.md`, rewritten `doc-refresh.md`, new `doc-refresh-script.sh` |
| 2 | site-builder-plugin | Template, Phases & Checklist Updates | 3 | Updated `doc-templates.md` (auto-markers, BRAND.md, marker rules), `phases.md` (Update Mode gate), `handoff-checklist.md` |
| 3 | site-builder-plugin | Orchestrator — SKILL.md | 2 | Init 2.5/2.6 updates (BRAND.md creation, hook changes), all 11 phase Doc Gate entries, Update Mode gate |
| 4 | site-builder-plugin | Agent Doc-Gate Obligations | 3 | Doc-gate sections in 6 agent files (designer, developer, content, social-integration, analytics, seo-indexing) |

## Execution Order

Phases MUST be executed in order. Each phase depends on the previous phase being complete.
Start with: `docs/plans/2026-08-06T12-00-00-doc-refresh-brand/phase-1.md`
