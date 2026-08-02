# Doc Refresh Mechanism

How CONTEXT.md, ARCHITECTURE.md, and CLAUDE.md stay in sync with code
changes throughout the site-builder pipeline and beyond.

---

## Two-Layer Refresh System

| Layer | Trigger | What it does |
|---|---|---|
| **Layer 1: Pipeline-phase refresh** | Orchestrator completes a phase | Updates the specific docs that phase affects |
| **Layer 2: Pre-commit hook** | Every `git commit` | Auto-stages already-refreshed docs into the commit |

Layer 1 keeps docs fresh. Layer 2 ensures they ship with the code.

---

## Layer 1: Pipeline-Phase Refresh

The orchestrator updates docs at specific pipeline boundaries. This is
not a hook — it is explicit orchestrator logic at the end of each phase.

### Refresh Mapping

| After phase | Docs refreshed | What changes |
|---|---|---|
| Phase 1 DISCOVER | `CONTEXT.md` | Entities, glossary, data flow from project brief |
| Phase 2 ARCHITECT | `CONTEXT.md`, `CLAUDE.md` | Conventions, decisions; tech stack confirmed |
| Phase 3 PREPARE | `ARCHITECTURE.md`, `CLAUDE.md` | Directory structure, patterns, entry points; build commands |
| Phase 6 DEVELOP | `ARCHITECTURE.md` | Finalized component tree, routes, dependencies |
| Phase 9 DEPLOY | `CLAUDE.md` | Deployment target, CI/CD info |

### Refresh Procedure

For each doc listed in the mapping:

1. Read the current file contents in full.
2. Identify the sections that the phase's output affects (see table
   above — e.g., Phase 1 DISCOVER affects CONTEXT.md's Entities,
   Glossary, and Data Flow sections).
3. Update only those sections with data from the phase output (e.g.,
   `.site-builder/project-brief.md` for Phase 1).
4. For CLAUDE.md: only modify content inside the `<!-- site-builder:start
   -->` / `<!-- site-builder:end -->` marker block. Never touch content
   outside the markers.
5. Write the updated file.

This is surgical — the refresh replaces specific section content, not
the entire document. Manual edits outside the affected sections (and
outside CLAUDE.md's marker block) are preserved.

---

## Layer 2: Pre-commit Hook (Auto-staging)

A POSIX `sh` script installed in `.git/hooks/pre-commit` during Init.
Its only job is to stage already-refreshed doc files into the current
commit so they travel with the code changes that prompted the refresh.

### Hook Script

```sh
# >>> site-builder:docs (do not edit this block) >>>
# Site Builder — auto-stage refreshed project docs
for f in CONTEXT.md ARCHITECTURE.md CLAUDE.md; do
  if [ -f "$f" ] && git diff --name-only | grep -qx "$f"; then
    git add "$f"
  fi
done
# <<< site-builder:docs <<<
```

### Behavior

| Condition | Action |
|---|---|
| Doc file has unstaged changes (`git diff`) | `git add` it into the commit |
| Doc file is unchanged | Skip silently |
| Doc file doesn't exist | Skip silently |

The hook **never refreshes or regenerates docs** — it only stages files
that were already updated by Layer 1 or by manual editing. All
intelligence lives in the orchestrator, not in scripts.

### Hook Installation

Installed during Init (Section 2.5), after doc generation. The script is
wrapped in its own marker block (`site-builder:docs`) so it coexists with
other hooks:

- If `.git/hooks/pre-commit` doesn't exist: create it with `#!/bin/sh`
  shebang, then append the marker block.
- If it exists but has no `site-builder:docs` marker: append the marker
  block at the end.
- If it exists and already has the marker: replace the existing marker
  block content.
- If the gitignore setup (Section 2 of Init, see `reference/gitignore.md`)
  also installed a pre-commit hook with its own marker block
  (`site-builder:gitignore`), both coexist — each marker block is
  independent.

Make the hook executable: `chmod +x .git/hooks/pre-commit` (no-op on
Windows, required on macOS/Linux).

### POSIX Compliance

The hook uses only POSIX `sh` syntax — no bash arrays, `[[ ]]`, or
herestrings. This ensures it runs under `dash`, `ash`, and `busybox sh`,
not just `bash`.

---

## Manual Refresh

If docs feel stale or the user wants to force-update everything, the
orchestrator can re-run the Init doc generation logic (Section 2.5) at
any time. This re-scans the project and updates all three docs, but
still uses the non-destructive procedures:

- CONTEXT.md and ARCHITECTURE.md: sections are replaced with current
  data, but document structure and any manual additions are preserved.
- CLAUDE.md: only the marker block is replaced. User content outside
  the markers is untouched.

---

## Key Principle

The pre-commit hook never refreshes docs — it only stages them. All
intelligence lives in the orchestrator (Claude), not in scripts. This
means:

- Commits made outside a Claude session may have stale docs (the hook
  stages whatever state the docs are in, but nobody refreshed them).
- On the next pipeline run or manual refresh, docs catch up.
- This is acceptable — the hook is a convenience, not a guarantee.
