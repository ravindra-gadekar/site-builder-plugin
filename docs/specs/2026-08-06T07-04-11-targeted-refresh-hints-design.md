# Targeted Refresh Hints & Expanded Auto-Patch — Design Spec

**Created:** 2026-08-06T07:04:11Z
**Status:** Draft
**Author:** AI + Ravindra Gadekar

## Overview

Replace the site-builder plugin's blanket PostToolUse echo ("Docs may be stale...") with a targeted, file-pattern-based `refresh-hint.sh` script that only fires when the changed file actually affects documentation, naming the specific doc and section. Expand the pre-commit script (`doc-refresh-script.sh`) to parse `tailwind.config.*` and CSS custom properties as a fallback source for BRAND.md tokens when `.site-builder/design-system.md` doesn't exist. Add a soft-blocking gate that warns and exits 1 (with `--no-verify` bypass) when doc-relevant code is staged but the matching doc has no changes.

This builds on the existing two-layer doc-refresh system (PR #14) without replacing it — Layer 1 (agent-indexed checklist gate) is unchanged, Layer 2 (mechanical-facts pre-commit script) is expanded.

**Prior art:** The fullstack-dev plugin's `refresh-hint.sh` pattern (static template, file-pattern matching, silent on irrelevant files). Site-builder adopts the PostToolUse targeting approach but keeps its own auto-marker content-patching system, which fullstack-dev does not have.

---

## Architecture

The feature modifies two template files that the site-builder orchestrator installs into client projects during Init (Section 2.5), plus the SKILL.md instructions that describe the installation:

**Component 1: `refresh-hint.sh` (new template)**
- Location: `skills/site-builder/reference/refresh-hint.sh`
- Installed to: Client project root as `.site-builder/refresh-hint.sh`
- Called by: PostToolUse hook in `.claude/settings.json` (`sh .site-builder/refresh-hint.sh`)
- Function: Reads PostToolUse JSON from stdin, extracts `file_path`, pattern-matches against doc-relevant file types, outputs a targeted hint naming the specific doc and section — or nothing for irrelevant files

**Component 2: `doc-refresh-script.sh` (expanded)**
- Location: `skills/site-builder/reference/doc-refresh-script.sh` (existing)
- Installed to: `.git/hooks/pre-commit` inside the `site-builder:docs` marker block (existing)
- Expanded with:
  - **Tailwind/CSS fallback parsing** for BRAND.md tokens when `.site-builder/design-system.md` doesn't exist
  - **Soft-blocking gate** that checks staged code files against doc-relevance patterns and warns (exit 1 + bypass message) if matching docs have no changes

**Component 3: `SKILL.md` updates**
- Section 2.5: Install `refresh-hint.sh` alongside the pre-commit hook; update hook description
- Section 2.6: Replace blanket echo command with `sh .site-builder/refresh-hint.sh`; update description to reference the targeted hint system

**Component 4: `doc-refresh.md` updates**
- Section 5 (Intra-Phase Reminder): Rewrite to describe the targeted refresh-hint system
- New Section 3a: Document the soft-blocking gate behavior and bypass
- Error Handling: Add soft-blocking gate failure/bypass entries

**Script structure for soft-blocking gate:**
The existing `doc-refresh-script.sh` uses `set -e` + `trap 'exit 0' EXIT` to
guarantee exit 0 on any error, and ends with `exit 0`. To make Step 3's
`exit 1` effective, the implementation must: (1) remove the final `exit 0`,
(2) insert `trap - EXIT` before Step 3 to clear the safety-net trap, (3)
append the gate logic after the trap reset. This ensures Steps 1-2 are
still protected by the trap while Step 3 can exit 1 intentionally.

**Pattern set distinction (hints vs. gate):**
The refresh-hint.sh patterns are intentionally broader than the soft-blocking
gate patterns. Hints are advisory — they nudge on any plausibly-relevant edit
(including `.tsx` for BRAND.md, blanket `.ts/.js` for ARCHITECTURE.md). The
gate is enforcement — it only blocks on structurally significant changes
(route files, config files, design tokens) to avoid false-positive fatigue
that would train developers to always use `--no-verify`.

**Update path for refresh-hint.sh:**
`refresh-hint.sh` is overwritten on re-init (same lifecycle as the pre-commit
hook content). When the plugin is updated via `npx skills update` and the
user re-runs `/site-builder --init`, the orchestrator replaces
`.site-builder/refresh-hint.sh` with the current template.

**Boundaries:**
- Layer 1 (agent-indexed checklist gate) is unchanged — judgment content still requires agent/orchestrator verification
- Layer 2 (mechanical-facts script) is expanded, not replaced — existing auto-marker patching is preserved
- The gitignore hook (`site-builder:gitignore` marker block) is untouched

---

## Data Flow

### PostToolUse Hint Flow (during Claude sessions)

```
Developer/Agent edits a file via Edit/Write tool
  -> PostToolUse hook fires
  -> sh .site-builder/refresh-hint.sh
  -> Script reads JSON from stdin, extracts file_path
  -> Strip CWD prefix -> repo-relative path
  -> Pattern match:
     *.css|*.scss|*.tsx|tailwind.config.*|*/tailwind.config.*
       -> "Update BRAND.md (colors/tokens section)"
     *.ts|*.js|*/src/pages/*|*/src/app/*|*/app/pages/*
       -> "Update ARCHITECTURE.md (directory structure, routes)"
     */package.json|*config.*
       -> "Update ARCHITECTURE.md and CLAUDE.md (deps, build commands)"
     */schema/*|*.model.*|*/content/config.*
       -> "Update CONTEXT.md (domain model section)"
     No match -> silent (no output)
```

### Pre-Commit Flow (every git commit)

```
git commit triggered
  -> .git/hooks/pre-commit runs (site-builder:docs block)

  Step 1: Mechanical-facts patching (existing, expanded)
    -> Patch ARCHITECTURE.md auto-markers from find/package.json
    -> Patch BRAND.md auto-markers:
        .site-builder/design-system.md exists?
        +-- YES -> parse Colors/Typography/Spacing (current behavior)
        +-- NO  -> fallback: parse tailwind.config.* or CSS :root {}
                   (new -- covers pre-Phase-4 and direct-edit cases)
    -> Stage patched files (ARCHITECTURE.md, BRAND.md)

  Step 2: Auto-stage Layer 1 docs (existing)
    -> Stage CONTEXT.md, CLAUDE.md if they have unstaged changes

  Step 3: Soft-blocking gate (new)
    -> Reset trap: trap - EXIT (so exit 1 is not intercepted)
    -> Scan staged code files (git diff --cached --name-only) against
       narrowed enforcement patterns:
       *.css|*.scss|tailwind.config.* staged BUT BRAND.md has no changes
       (neither staged nor unstaged)
         -> warn: ">> WARNING: BRAND.md may need updating -- staged files
                    match design-token patterns (*.css, *.scss, tailwind.config.*)"
       src/pages/*|src/app/*|app/pages/* staged OR files added/deleted
       (git diff --cached --diff-filter=AD) BUT ARCHITECTURE.md has no changes
         -> warn: ">> WARNING: ARCHITECTURE.md may need updating -- staged
                    files match route/structure patterns"
       package.json staged BUT ARCHITECTURE.md has no changes
         -> warn: ">> WARNING: ARCHITECTURE.md build/deps may need updating
                    -- package.json was changed"
    -> Any warnings?
       +-- YES -> print all warnings (aggregate, don't stop at first)
                  print "Refresh the listed docs, or run 'git commit
                         --no-verify' to skip."
                  -> exit 1
       +-- NO  -> exit 0

    Note: "has no changes" means not in git diff --name-only (unstaged)
    AND not in git diff --cached --name-only (staged). A doc with ANY
    changes (staged or unstaged) passes the gate -- unstaged changes
    suggest the developer is aware the doc needs updating.
    
    Note: the gate uses NARROWER patterns than refresh-hint.sh (no blanket
    *.ts|*.js) to avoid false-positive fatigue. See Architecture section
    for rationale.
```

**Key invariant:** Step 1 (patching) runs before Step 3 (gate). So if the auto-patcher already refreshed and staged BRAND.md from a Tailwind config change, the gate won't fire — it only catches gaps the mechanical patcher can't cover (judgment content like component patterns, route descriptions).

### Tailwind Config Parsing Specification

When `.site-builder/design-system.md` is absent, the script searches for
Tailwind config files in this order: `tailwind.config.ts` >
`tailwind.config.js` > `tailwind.config.mjs` > `tailwind.config.cjs`.
First match wins.

Extraction targets (awk/sed, same CRLF-safe pipeline as existing script):

| Auto-marker | Config key paths (checked in order, first non-empty wins) |
|---|---|
| `auto:color-tokens` | `theme.extend.colors`, then `theme.colors` |
| `auto:font-stack` | `theme.extend.fontFamily`, then `theme.fontFamily` |
| `auto:spacing-scale` | `theme.extend.spacing`, then `theme.spacing` |

The parser extracts key-value pairs from JavaScript object literals using
awk (same approach as the existing `package.json` parser). JS expressions
like `require()` or spread operators produce partial/empty results — the
script patches with whatever it gets, and empty results skip the marker
(never corrupt existing content).

**Tailwind v4 note:** Tailwind CSS v4 eliminated `tailwind.config.*` in
favor of CSS-native `@theme` directives. Projects using Tailwind v4 will
have no config file — the fallback silently skips, and the pipeline's
Phase 4 DESIGN creates `design-system.md` as the primary source. This is
a known limitation, not a bug.

### CSS `:root {}` Fallback — Deferred

Parsing CSS `:root {}` custom properties (AC-5 in the original spec) is
deferred to a follow-up. The Tailwind fallback alone covers the primary
gap (pre-Phase-4 projects with Tailwind). The CSS fallback adds parsing
complexity for an edge case (projects with custom properties but no
Tailwind and no design-system.md). If needed later, the file search order
would be: `src/styles/global.css`, `src/globals.css`, `app/globals.css`,
then `find . -name '*.css' -path '*/styles/*' | head -1`.

---

## File Changes

| File | Action | What changes |
|---|---|---|
| `reference/refresh-hint.sh` | **Create** | New static POSIX sh template — file-pattern-targeted PostToolUse hint script |
| `reference/doc-refresh-script.sh` | **Modify** | Add Tailwind/CSS fallback parsing for BRAND.md tokens; add soft-blocking gate (Step 3) after patching and auto-staging |
| `reference/doc-refresh.md` | **Modify** | Rewrite Section 5 (Intra-Phase Reminder) for targeted hints; add Section 3a (Soft-Blocking Gate); update Error Handling tables |
| `reference/doc-templates.md` | **Modify** | Add note that `.site-builder/refresh-hint.sh` is created during Init alongside the docs |
| `SKILL.md` | **Modify** | Section 2.5: add `refresh-hint.sh` installation step, expand pre-commit hook description with soft-blocking behavior. Section 2.6: replace blanket echo command with `sh .site-builder/refresh-hint.sh`, update hook description |

**Files NOT touched:**
- `reference/brand-template.md` — no template changes, just new source parsing
- `reference/phases.md` — Update Mode gate unchanged
- `reference/handoff-checklist.md` — existing doc checks still apply
- `agents/*.md` — agent doc-gate obligations unchanged
- Gitignore hook — separate marker block, unaffected

---

## Error Handling

### Refresh-hint.sh failures

| Failure | Recovery |
|---|---|
| PostToolUse JSON missing `file_path` field | Script exits 0 silently — no hint, no error |
| Script not found (`.site-builder/refresh-hint.sh` missing) | Shell prints "No such file" to stderr; PostToolUse hook returns non-zero but Claude session continues unaffected |
| Script syntax error | Same as above — hook fails but session continues. Fix on next `npx skills update` + re-init |
| File path doesn't match any pattern | Silent — no output. This is correct behavior, not a failure |

### Soft-blocking gate failures

| Failure | Recovery |
|---|---|
| Gate fires (code staged, doc not staged) | Print specific warnings naming which docs are stale. Print: `"Refresh the listed docs, or run 'git commit --no-verify' to skip."` Exit 1. |
| False positive (doc was refreshed but in a different commit) | Developer uses `--no-verify` to bypass. Gate message makes this clear. |
| Gate logic itself errors (script bug in Step 3) | The EXIT trap is already cleared (`trap - EXIT`) before Step 3, so a bug here would cause a non-zero exit and block the commit. Developers use `--no-verify` to bypass. This is acceptable — a gate bug is rare and the bypass is documented. |

### Tailwind/CSS fallback parsing failures

| Failure | Recovery |
|---|---|
| `tailwind.config.*` missing and no CSS `:root {}` found | Skip BRAND.md token patching entirely (same as current behavior when `design-system.md` is missing). Exit 0. |
| Tailwind config uses JS expressions instead of string literals (e.g., `colors: require('./colors')`) | Awk/sed extraction gets partial or empty results. Patch with whatever was extracted; empty result -> skip that marker. Never corrupt existing content. |
| Both `design-system.md` AND `tailwind.config.*` exist | `design-system.md` wins (checked first). Tailwind fallback only runs when design-system.md is absent. |

### Key principles

- **Patching (Step 1) and staging (Step 2) always exit 0** on error — they never block commits. This is the existing guarantee, preserved.
- **Only the soft-blocking gate (Step 3) can exit 1**, and only when it detects a real pattern mismatch. A `--no-verify` bypass is always available.
- Before Step 3, the script executes `trap - EXIT` to clear the safety-net trap and removes the final `exit 0`. This allows the gate's `exit 1` to propagate. Steps 1-2 remain protected by the trap during their execution.

---

## Testing Strategy

Since this is a Markdown-only repo with no test framework, testing is structural verification.

### refresh-hint.sh verification

| What to test | How |
|---|---|
| Script parses without errors | `sh -n skills/site-builder/reference/refresh-hint.sh` |
| CSS file triggers BRAND.md hint | Echo mock JSON with `file_path: "src/styles/global.css"`, pipe to script, confirm output mentions BRAND.md |
| TypeScript file triggers ARCHITECTURE.md hint | Echo mock JSON with `file_path: "src/app/page.tsx"`, confirm output mentions ARCHITECTURE.md |
| package.json triggers ARCHITECTURE.md/CLAUDE.md hint | Echo mock JSON with `file_path: "package.json"`, confirm output mentions both docs |
| Schema file triggers CONTEXT.md hint | Echo mock JSON with `file_path: "src/schema/user.ts"`, confirm output mentions CONTEXT.md |
| Irrelevant file produces no output | Echo mock JSON with `file_path: "README.md"`, confirm empty output |
| Missing file_path in JSON produces no output | Echo `{}`, confirm empty output and exit 0 |
| POSIX compliance | Grep for `[[`, herestrings, bash arrays — must find none |

### Expanded doc-refresh-script.sh verification

| What to test | How |
|---|---|
| Existing auto-marker patching still works | Same scratch-file test as Phase 1 Task 3 — create sample ARCHITECTURE.md with markers, run script, confirm content replaced and surrounding text untouched |
| Tailwind fallback: parses tailwind.config.js colors | Create scratch `tailwind.config.js` with `theme.extend.colors` block + BRAND.md with `auto:color-tokens` markers, remove `design-system.md`, run script, confirm tokens extracted |
| Tailwind fallback: design-system.md takes priority | Create both files, run script, confirm BRAND.md tokens come from design-system.md (not tailwind.config) |
| Tailwind fallback: no config exists -> skip gracefully | Empty scratch dir with just BRAND.md markers, run script, confirm exit 0 and markers untouched |
| Soft-blocking gate: warns when code staged but doc not | In scratch git repo, stage a `.css` file without staging BRAND.md, run script, confirm exit 1 + warning message |
| Soft-blocking gate: silent when doc already staged | Stage both `.css` file and BRAND.md, run script, confirm exit 0 |
| Soft-blocking gate: doesn't fire when no code matches patterns | Stage only `README.md`, confirm exit 0 |
| Soft-blocking gate: doc with unstaged changes passes gate | Stage a `.css` file, leave BRAND.md with unstaged edits (not staged), confirm exit 0 (gate sees changes exist) |
| Trap reset: gate exit 1 not intercepted by EXIT trap | Run FULL script (not Step 3 in isolation) with a `.css` file staged and BRAND.md unchanged, confirm exit code is 1 (not 0) |
| Tailwind fallback: parses theme.extend.colors | Create scratch `tailwind.config.js` with `theme: { extend: { colors: { primary: '#ff0000' } } }` + BRAND.md markers, confirm `#ff0000` appears in patched output |
| Script exits 0 in empty directory | Run in empty scratch dir, confirm exit 0 |

### SKILL.md / doc-refresh.md verification

| What to test | How |
|---|---|
| No stale references to blanket echo | `grep -c "echo.*Docs may be stale" skills/site-builder/SKILL.md` -> 0 |
| refresh-hint.sh referenced in Section 2.5 and 2.6 | `grep "refresh-hint" skills/site-builder/SKILL.md` -> present |
| Soft-blocking gate documented | `grep "soft-block\|--no-verify" skills/site-builder/reference/doc-refresh.md` -> present |

---

## Acceptance Criteria

- [ ] **AC-1:** `refresh-hint.sh` exists at `skills/site-builder/reference/refresh-hint.sh` as a valid POSIX sh script (`sh -n` passes, no bash-only syntax)
- [ ] **AC-2:** `refresh-hint.sh` outputs a targeted hint naming the specific doc and section when the changed file matches a doc-relevant pattern (CSS/SCSS/TSX -> BRAND.md, TS/JS/pages -> ARCHITECTURE.md, package.json/config -> ARCHITECTURE.md+CLAUDE.md, schema/model -> CONTEXT.md)
- [ ] **AC-3:** `refresh-hint.sh` produces no output for files that don't match any pattern (silent, not a generic echo)
- [ ] **AC-4:** `doc-refresh-script.sh` parses `tailwind.config.*` color/font/spacing values as a fallback source for BRAND.md auto-markers when `.site-builder/design-system.md` does not exist
- [ ] **AC-5:** ~~CSS `:root {}` fallback~~ **Deferred** to follow-up. Tailwind fallback covers the primary gap. When neither `design-system.md` nor `tailwind.config.*` exists, BRAND.md token patching is skipped (existing behavior)
- [ ] **AC-6:** When both `design-system.md` and `tailwind.config.*` exist, `design-system.md` takes priority — Tailwind fallback does not run
- [ ] **AC-7:** Soft-blocking gate exits 1 with specific warning messages when doc-relevant code files are staged but the corresponding doc has no changes (neither staged via `git diff --cached` nor unstaged via `git diff`). A doc with ANY changes passes the gate
- [ ] **AC-8:** Soft-blocking gate message includes `git commit --no-verify` bypass instruction
- [ ] **AC-9:** Patching (Step 1) and auto-staging (Step 2) always exit 0 on error — the existing "never block commits on doc-refresh failure" guarantee is preserved for mechanical patching
- [ ] **AC-10:** Only the soft-blocking gate (Step 3) can exit 1, and only for the specific pattern-mismatch condition
- [ ] **AC-11:** SKILL.md Section 2.5 describes installing `refresh-hint.sh` to `.site-builder/refresh-hint.sh` during Init
- [ ] **AC-12:** SKILL.md Section 2.6 PostToolUse hook command is `sh .site-builder/refresh-hint.sh` (not the old blanket echo)
- [ ] **AC-13:** `doc-refresh.md` Section 5 describes the targeted refresh-hint system (not the old "Intra-phase reminder" label with generic echo)
- [ ] **AC-14:** `doc-refresh.md` documents the soft-blocking gate behavior, bypass mechanism, and error handling
- [ ] **AC-15:** All existing auto-marker patching (directory structure, dependencies, build-dev, color-tokens, font-stack, spacing-scale) continues to work unchanged
- [ ] **AC-16:** CRLF safety preserved — all new file reads pipe through `tr -d '\r'`
- [ ] **AC-17:** Gitignore hook (`site-builder:gitignore` marker block) is unaffected
- [ ] **AC-18:** `refresh-hint.sh` matches root-level `tailwind.config.*` (not just `*/tailwind.config.*`) — both patterns present in the case statement
- [ ] **AC-19:** Soft-blocking gate evaluates ALL pattern rules and aggregates ALL warnings before exiting 1 (developer sees complete picture, not one-at-a-time)

---

## Modified files

| File | Change |
|---|---|
| `skills/site-builder/reference/refresh-hint.sh` | Create — new PostToolUse hint script template |
| `skills/site-builder/reference/doc-refresh-script.sh` | Modify — Tailwind/CSS fallback + soft-blocking gate |
| `skills/site-builder/reference/doc-refresh.md` | Modify — targeted hints docs + soft-blocking gate docs |
| `skills/site-builder/reference/doc-templates.md` | Modify — note refresh-hint.sh in Init file list |
| `skills/site-builder/SKILL.md` | Modify — Section 2.5 install + Section 2.6 hook command |
