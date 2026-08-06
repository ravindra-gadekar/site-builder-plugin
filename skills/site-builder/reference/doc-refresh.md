# Doc Refresh Mechanism

How `CONTEXT.md`, `ARCHITECTURE.md`, `BRAND.md`, and `CLAUDE.md` stay in
sync with code changes throughout the site-builder pipeline and beyond.

---

## Overview

Two layers keep client-project docs current:

| Layer | Trigger | What it does |
|---|---|---|
| **Layer 1: Agent-indexed checklist gate** | Orchestrator completes a phase or Update Mode agent run | Verifies judgment-content sections in mapped docs match the agent's output |
| **Layer 2: Mechanical-facts pre-commit script** | Every `git commit` | Patches mechanical sections inside `<!-- auto:* -->` markers from source files on disk |

---

## Layer 1: Agent-Indexed Checklist Gate

### Agent → Doc Mapping

This is the authoritative table for the entire system.

| Agent | Docs it must refresh | Sections affected |
|---|---|---|
| discovery-agent | `CONTEXT.md` | Entities, Glossary, Data Flow |
| architect-agent | `CONTEXT.md`, `CLAUDE.md` | Conventions, Decisions; Tech Stack |
| developer-agent | `ARCHITECTURE.md`, `CLAUDE.md`, `BRAND.md` | Directory Structure, Patterns, Entry Points, Dependencies; Build & Dev commands (CLAUDE.md marker block); verify BRAND.md tokens match design-system.md (Phase 6 only — not Phase 3, when design-system.md does not yet exist) |
| designer-agent | `BRAND.md` (primary owner) | All sections (colors, typography, spacing, component patterns) |
| content-agent | `CONTEXT.md` | Glossary (new terms from content) |
| deploy-agent | `CLAUDE.md` | Deployment target, CI/CD |
| analytics-agent | `CLAUDE.md` | Analytics config reference |
| seo-indexing-agent | `CLAUDE.md` | Indexing config reference |
| social-integration-agent | `ARCHITECTURE.md` | Integrations |

### Gate Enforcement Procedure

After every agent completes:

1. Read each doc listed for that agent.
2. Verify the relevant sections reflect the agent's output.
3. State what was checked (e.g., "ARCHITECTURE.md directory tree updated to
   reflect new `/api` route") before proceeding.

This is the same "must state what you checked" pattern as Phase 7's audit
quality gate.

### Audit Agents Excluded By Design

The 6 audit agents (seo-audit, technical-audit, content-quality, ai-search,
schema-audit, accessibility-audit) are absent from the mapping
intentionally — they are read-only analyzers whose findings are acted on by
content-agent and developer-agent, which ARE in the mapping. Do not add
doc-gate obligations to audit agents during implementation.

---

## Layer 2: Mechanical-Facts Pre-Commit Script

A POSIX `sh` script template at `reference/doc-refresh-script.sh`, installed
into `.git/hooks/pre-commit` during Init.

### What It Patches

| Doc | Sections handled by script | Auto-marker name | Source |
|---|---|---|---|
| `ARCHITECTURE.md` | Directory Structure | `auto:directory-structure` | `find . -maxdepth 2` excluding node_modules/.git/gitignored |
| `ARCHITECTURE.md` | Dependencies | `auto:dependencies` | `package.json` dependencies + devDependencies |
| `ARCHITECTURE.md` | Build & Dev | `auto:build-dev` | `package.json` scripts |
| `BRAND.md` | Color tokens | `auto:color-tokens` | `.site-builder/design-system.md` color token blocks |
| `BRAND.md` | Font stack | `auto:font-stack` | `.site-builder/design-system.md` typography section |
| `BRAND.md` | Spacing scale | `auto:spacing-scale` | `.site-builder/design-system.md` spacing section |

### What It Does NOT Patch

Agent/phase counts in `CLAUDE.md` (those are plugin-repo values, not client
-project values). CLAUDE.md's Build & Dev commands are refreshed by the
developer-agent gate (Layer 1), not the script.

### Script Behavior

Reads source files, extracts mechanical values, patches only content
between `<!-- auto:X -->` / `<!-- /auto:X -->` markers using sed/awk. Exits
0 on every error path.

**CRLF handling:** preprocesses input with `tr -d '\r'` before sed/awk
pattern matching.

---

## Section Ownership Boundary

Each auto-managed section is wrapped in `<!-- auto:* -->` markers.

- The script (Layer 2) only writes inside these markers.
- The agent gate (Layer 1) only writes outside them.
- Neither touches the other's territory.

**Exception — `auto:build-commands` in CLAUDE.md:** This marker exists
solely so its content survives site-builder marker-block replacement
(the nested-marker preservation rule). It is owned by the developer-agent
gate (Layer 1), NOT the pre-commit script. The script never patches
CLAUDE.md. This is the only `auto:*` marker where Layer 1 writes inside
the markers rather than outside them.

---

## Intra-Phase Reminder (PostToolUse Hook)

The PostToolUse hook (`echo 'Docs may be stale...'`) is retained as an
intra-phase nudge. It fires during agent work; the gate fires at phase
boundaries. Different scope, both useful.

The echo message mentions BRAND.md alongside ARCHITECTURE.md and
CONTEXT.md.

**Label:** "Intra-phase reminder" (not "Layer 1" — that label now belongs
to the gate).

---

## Nested Marker Rule for CLAUDE.md

Auto-markers can appear inside the `<!-- site-builder:start -->` /
`<!-- site-builder:end -->` block. When replacing site-builder marker block
content, the orchestrator must preserve nested `<!-- auto:* -->` blocks and
their content. The orchestrator replaces only the text outside auto-markers
within the site-builder block.

---

## Staleness Windows

| Scenario | How long docs can be stale | Why acceptable |
|---|---|---|
| Mid-phase (agent still running) | Minutes | Agent hasn't finished producing the data yet |
| Between phase boundary and next commit | Until next commit | Layer 2 catches mechanical facts; Layer 1 already caught judgment facts at boundary |
| Outside a Claude session (manual code edits) | Until next commit | Layer 2 script still fires — mechanical facts stay fresh. Judgment sections may drift, caught on next pipeline run |
| Update Mode | Zero after Doc Refresh Gate | Hard gate blocks deploy until docs verified |

---

## Error Handling

### Layer 1 Gate failures

| Failure | Recovery |
|---|---|
| Orchestrator skips gate (context pressure) | Layer 2 catches mechanical facts. Judgment sections stay stale until next agent run. |
| Doc file doesn't exist when gate fires | Gate creates it from template. Log: "Created missing [doc] from template." |
| Agent's `.site-builder/` output file is missing (phase skipped) | Skip refresh for that doc. Log: "No [file] found — skipping [doc] refresh." Do not create a doc with empty content. |
| Orchestrator states "checked" without actually updating (hallucinated compliance) | No programmatic defense. Mitigated by: (a) requiring the orchestrator to name what specifically changed; (b) Layer 2 catching the mechanical subset independently. |

### Layer 2 Script failures

| Failure | Recovery |
|---|---|
| Source file missing (`.site-builder/design-system.md`, `package.json`) | Skip that section's patching. Exit 0 — never block the commit. |
| Source file malformed (unparseable JSON) | Skip section. Log to stderr. Exit 0. |
| Auto-markers missing from doc file | Skip that section. Never write outside markers. Exit 0. |
| Script syntax error (bug in shipped template) | Pre-commit hook fails, `git commit` aborts. User can `git commit --no-verify` to bypass. |
| Windows without Git Bash sh | `.git/hooks/pre-commit` runs under Git Bash's sh. If unavailable, commit proceeds without hook. |

### Update Mode gate failures

| Failure | Recovery |
|---|---|
| Gate blocks deploy, user wants to ship anyway | Orchestrator offers: "Doc refresh incomplete for [list]. Deploy anyway, or let me finish the refresh first?" User can override. |
| No agents ran (manual change outside pipeline) | Skip step 4, proceed to deploy. Layer 2 still patches mechanical facts on commit. |

### Key principle

Layer 2 never blocks commits on doc-refresh failure. It exits 0 on every
error path. A broken refresh script must never prevent a user from
committing their actual code.

---

## Hook Installation

- Installed during Init (Section 2.5), after doc generation.
- The pre-commit hook now contains BOTH the auto-staging logic (for docs
  refreshed by Layer 1) AND the mechanical-facts patching script (Layer 2).
- Both use the `site-builder:docs` marker block in `.git/hooks/pre-commit`.
- Coexists with the gitignore hook's `site-builder:gitignore` marker block.
- Installation rules: create if absent, append if no marker, replace if
  marker exists.
