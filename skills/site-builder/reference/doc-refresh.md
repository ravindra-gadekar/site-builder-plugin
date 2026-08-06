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

## Soft-Blocking Doc-Relevance Gate

Step 3 of the pre-commit script (after mechanical-facts patching and
auto-staging) scans staged code files against doc-relevance patterns
and warns (exit 1) if matching docs have no changes.

### Gate Patterns (Enforcement — Narrower Than Hints)

| Staged file pattern | Required doc | Warning if doc unchanged |
|---|---|---|
| `*.css`, `*.scss`, `tailwind.config.*` | BRAND.md | Design-token patterns detected |
| `src/pages/*`, `src/app/*`, `app/pages/*`, or files added/deleted | ARCHITECTURE.md | Route/structure patterns detected |
| `package.json` | ARCHITECTURE.md | Build/deps changed |

These patterns are intentionally narrower than `refresh-hint.sh` — no
blanket `*.ts`/`*.js`, no `*.tsx`, no `*config.*`. Hints are advisory;
the gate is enforcement. Broad gate patterns cause false-positive fatigue
that trains developers to always use `--no-verify`, defeating the purpose.

### Gate Behavior

- **"Has no changes"** means the doc is not in `git diff --name-only`
  (unstaged) AND not in `git diff --cached --name-only` (staged). A doc
  with ANY changes (staged or unstaged) passes the gate — unstaged
  changes suggest the developer is aware the doc needs updating.
- **All warnings are aggregated** before exiting 1 — the developer sees
  the complete picture, not one-at-a-time messages.
- **Bypass:** `git commit --no-verify` skips the entire pre-commit hook,
  including the gate. The gate message includes this instruction.
- **Interaction with patching:** Step 1 (patching) runs before Step 3
  (gate). If the auto-patcher already refreshed and staged BRAND.md from
  a Tailwind config change, the gate won't fire — it only catches gaps
  the mechanical patcher can't cover.

### Trap Reset

Before Step 3, the script executes `trap - EXIT` to clear the safety-net
trap that protects Steps 1-2. This allows the gate's `exit 1` to
propagate. Steps 1-2 remain protected by `trap 'exit 0' EXIT` during
their execution — they always exit 0 on error.

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

## Targeted Refresh Hints (PostToolUse Hook)

The PostToolUse hook runs `.site-builder/refresh-hint.sh` after every
`Edit` or `Write` during a Claude session. The script reads the
PostToolUse JSON from stdin, extracts the `file_path`, and
pattern-matches it against doc-relevant file types:

| File pattern | Hint target |
|---|---|
| `*.css`, `*.scss`, `*.tsx`, `tailwind.config.*` | BRAND.md (colors/tokens section) |
| `*.ts`, `*.js`, `*/src/pages/*`, `*/src/app/*` | ARCHITECTURE.md (directory structure, routes) |
| `package.json`, `*config.*` | ARCHITECTURE.md + CLAUDE.md (deps, build commands) |
| `*/schema/*`, `*.model.*`, `*/content/config.*` | CONTEXT.md (domain model section) |

Files that don't match any pattern produce no output — no generic echo,
no noise for irrelevant edits.

The hint script is installed to `.site-builder/refresh-hint.sh` during
Init (Section 2.5) and overwritten on re-init (same lifecycle as the
pre-commit hook content). The template lives at
`reference/refresh-hint.sh`.

**Label:** "Targeted refresh hints" (the prior generic-nudge label is
retired — the old blanket echo is replaced by pattern-targeted output).

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
| Tailwind config missing (no `tailwind.config.*` and no `design-system.md`) | Skip BRAND.md token patching entirely. Exit 0. |
| Tailwind config uses JS expressions (e.g., `require()`) | Partial/empty extraction results. Patch with whatever was extracted; empty result skips the marker. Never corrupt existing content. |

### Soft-blocking gate failures

| Failure | Recovery |
|---|---|
| Gate fires (code staged, doc not staged) | Print specific warnings naming which docs are stale. Print bypass instruction (`git commit --no-verify`). Exit 1. |
| False positive (doc was refreshed but in a different commit) | Developer uses `--no-verify` to bypass. Gate message makes this clear. |
| Gate logic itself errors (script bug in Step 3) | The EXIT trap is already cleared before Step 3, so a bug here causes a non-zero exit and blocks the commit. Developers use `--no-verify` to bypass. This is acceptable — a gate bug is rare and the bypass is documented. |

### Update Mode gate failures

| Failure | Recovery |
|---|---|
| Gate blocks deploy, user wants to ship anyway | Orchestrator offers: "Doc refresh incomplete for [list]. Deploy anyway, or let me finish the refresh first?" User can override. |
| No agents ran (manual change outside pipeline) | Skip step 4, proceed to deploy. Layer 2 still patches mechanical facts on commit. |

### Key principle

Layer 2 patching (Steps 1-2) never blocks commits on doc-refresh failure.
It exits 0 on every error path. Only the soft-blocking gate (Step 3) can
exit 1, and only when it detects a real pattern mismatch between staged
code and unchanged docs. A `--no-verify` bypass is always available.

---

## Hook Installation

- Installed during Init (Section 2.5), after doc generation.
- The pre-commit hook now contains BOTH the auto-staging logic (for docs
  refreshed by Layer 1) AND the mechanical-facts patching script (Layer 2).
- Both use the `site-builder:docs` marker block in `.git/hooks/pre-commit`.
- Coexists with the gitignore hook's `site-builder:gitignore` marker block.
- Installation rules: create if absent, append if no marker, replace if
  marker exists.
