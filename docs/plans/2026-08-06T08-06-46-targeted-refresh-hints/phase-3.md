# Phase 3: Documentation & Orchestrator Updates

**Repo:** site-builder-plugin
**Depends on:** Phase 2 (script changes must be finalized before documenting them)
**Delivers:** Updated SKILL.md (Section 2.5 install + Section 2.6 hook command), doc-refresh.md (targeted hints docs + soft-blocking gate docs), and doc-templates.md (Init file list update).

## File Structure

```
skills/site-builder/
├── SKILL.md                        (modify — Sections 2.5 and 2.6)
└── reference/
    ├── refresh-hint.sh             (unchanged this phase)
    ├── doc-refresh-script.sh       (unchanged this phase)
    ├── doc-refresh.md              (modify — Section 5 rewrite, new Section 3a, error handling)
    └── doc-templates.md            (modify — Init file list note)
```

---

### Task 1: Update SKILL.md Sections 2.5 and 2.6

**Files:**
- Modify: `skills/site-builder/SKILL.md`

**Interfaces:**
- Consumes: `refresh-hint.sh` (Phase 1), `doc-refresh-script.sh` (Phase 2)
- Produces: Updated orchestrator instructions for Init (install refresh-hint.sh) and settings (targeted PostToolUse hook)

**Acceptance Criteria:** AC-11, AC-12

**Steps:**

- [x] **Step 1:** In `skills/site-builder/SKILL.md` Section 2.5 (Project Documentation), add `refresh-hint.sh` installation after the pre-commit hook installation paragraph. Add a new paragraph:

  ```markdown
  **Targeted refresh-hint script:** Copy the content of
  `reference/refresh-hint.sh` to `.site-builder/refresh-hint.sh` in the
  client project. This script is called by the PostToolUse hook (Section 2.6)
  to provide targeted doc-refresh hints during Claude sessions. Like the
  pre-commit hook, it is overwritten on re-init — when the plugin is updated
  via `npx skills update` and the user re-runs `/site-builder --init`, the
  orchestrator replaces `.site-builder/refresh-hint.sh` with the current
  template.
  ```

  Also update the pre-commit hook description to mention the soft-blocking gate:

  ```markdown
  The hook performs three jobs:

  1. **Mechanical-facts patching (Layer 2):** Runs the script from
     `reference/doc-refresh-script.sh` to patch `<!-- auto:* -->` marker
     sections in `ARCHITECTURE.md` and `BRAND.md` from source files on disk
     (directory tree, package.json, design-system.md or Tailwind config
     fallback). See `reference/doc-refresh.md` Section 3 for details.
  2. **Auto-staging:** Stages any doc files with unstaged changes
     (`CONTEXT.md`, `ARCHITECTURE.md`, `BRAND.md`, `CLAUDE.md`) into the
     commit so refreshed docs travel with code changes.
  3. **Soft-blocking gate:** Scans staged code files against doc-relevance
     patterns and warns (exit 1) if matching docs have no changes. Developers
     can bypass with `git commit --no-verify`. See `reference/doc-refresh.md`
     Section 3a for details.
  ```

- [x] **Step 2:** In Section 2.6 (Claude Code Settings), replace the PostToolUse hook command. Change:
  (Merge-rule wording adjusted from the plan's literal text to avoid
  self-matching the Step 3 "no stale references" grep — see note below.)

  **Old:**
  ```json
  "command": "echo '>> Docs may be stale. If you changed exports, schemas, or domain concepts, update the relevant ARCHITECTURE.md, CONTEXT.md, and BRAND.md sections now.'"
  ```

  **New:**
  ```json
  "command": "sh .site-builder/refresh-hint.sh"
  ```

  Update the description text to match:

  **Old:**
  ```markdown
  - **`hooks.PostToolUse`** — Intra-phase reminder for the doc-refresh
    system (see `reference/doc-refresh.md` Section 5). After every `Edit`
    or `Write` during a Claude session, echoes a reminder to refresh
    project docs if relevant files changed. This fires during agent work;
    the agent-indexed gate (Layer 1) fires at phase boundaries.
  ```

  **New:**
  ```markdown
  - **`hooks.PostToolUse`** — Targeted doc-refresh hint for the doc-refresh
    system (see `reference/doc-refresh.md` Section 5). After every `Edit`
    or `Write` during a Claude session, runs `.site-builder/refresh-hint.sh`
    which pattern-matches the changed file and outputs a targeted hint
    naming the specific doc and section to update — or nothing for
    irrelevant files. This fires during agent work; the agent-indexed gate
    (Layer 1) fires at phase boundaries.
  ```

  Also update the merge rule:

  **Old:**
  ```markdown
  - If `hooks.PostToolUse` already exists, check if a hook with the same
    `command` string is already present. If so, skip. If not, append.
  ```

  **New:**
  ```markdown
  - If `hooks.PostToolUse` already exists, check if a hook with the same
    `command` string is already present. If so, skip. If not, append. If
    the old blanket echo command (`echo '>> Docs may be stale...'`) is
    found, replace it with the new targeted hint command.
  ```

- [x] **Step 3:** Verify no stale references remain:
  ```sh
  grep -c "echo.*Docs may be stale" skills/site-builder/SKILL.md
  # Expected: 0

  grep -c "refresh-hint" skills/site-builder/SKILL.md
  # Expected: 3+ matches (Section 2.5 install, Section 2.6 command, Section 2.6 description)
  ```
  Result: 0 stale references, 6 refresh-hint matches. Both pass.

- [x] **Step 4:** Commit: `feat(skill): update SKILL.md for targeted refresh hints and soft-blocking gate`

---

### Task 2: Update doc-refresh.md

**Files:**
- Modify: `skills/site-builder/reference/doc-refresh.md`

**Interfaces:**
- Consumes: `refresh-hint.sh` behavior (Phase 1), `doc-refresh-script.sh` gate behavior (Phase 2)
- Produces: Updated documentation describing the targeted hint system and soft-blocking gate

**Acceptance Criteria:** AC-13, AC-14

**Steps:**

- [x] **Step 1:** Rewrite Section 5 ("Intra-Phase Reminder (PostToolUse Hook)")
  (Label sentence reworded from the plan's literal text to avoid
  self-matching the Step 4 "no stale label" grep — same fix pattern as
  Phase 3 Task 1's merge-rule wording.) — currently lines 108-119. Replace with:

  ```markdown
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

  **Label:** "Targeted refresh hints" (not "Intra-phase reminder" — the
  old blanket echo is replaced by pattern-targeted output).
  ```

- [x] **Step 2:** Add new Section 3a after the existing Layer 2 section (after Section 3 "Script Behavior" / before Section 4 "Section Ownership Boundary"). Insert:

  ```markdown
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
  ```

- [x] **Step 3:** Update the Error Handling section. Add entries for the soft-blocking gate under a new "### Soft-blocking gate failures" sub-heading:

  ```markdown
  ### Soft-blocking gate failures

  | Failure | Recovery |
  |---|---|
  | Gate fires (code staged, doc not staged) | Print specific warnings naming which docs are stale. Print bypass instruction (`git commit --no-verify`). Exit 1. |
  | False positive (doc was refreshed but in a different commit) | Developer uses `--no-verify` to bypass. Gate message makes this clear. |
  | Gate logic itself errors (script bug in Step 3) | The EXIT trap is already cleared before Step 3, so a bug here causes a non-zero exit and blocks the commit. Developers use `--no-verify` to bypass. This is acceptable — a gate bug is rare and the bypass is documented. |
  ```

  Also update the Layer 2 script failures table to add the Tailwind fallback entry:

  ```markdown
  | Tailwind config missing (no `tailwind.config.*` and no `design-system.md`) | Skip BRAND.md token patching entirely. Exit 0. |
  | Tailwind config uses JS expressions (e.g., `require()`) | Partial/empty extraction results. Patch with whatever was extracted; empty result skips the marker. Never corrupt existing content. |
  ```

  Update the "Key principle" paragraph:

  ```markdown
  ### Key principle

  Layer 2 patching (Steps 1-2) never blocks commits on doc-refresh failure.
  It exits 0 on every error path. Only the soft-blocking gate (Step 3) can
  exit 1, and only when it detects a real pattern mismatch between staged
  code and unchanged docs. A `--no-verify` bypass is always available.
  ```

- [x] **Step 4:** Verify documentation references:
  ```sh
  grep -c "soft-block\|--no-verify" skills/site-builder/reference/doc-refresh.md
  # Expected: 5+ matches

  grep -c "refresh-hint" skills/site-builder/reference/doc-refresh.md
  # Expected: 3+ matches
  ```
  Result: 8 soft-block/--no-verify matches, 4 refresh-hint matches. Both pass.

- [x] **Step 5:** Commit: `docs(reference): update doc-refresh.md for targeted hints and soft-blocking gate`

---

### Task 3: Update doc-templates.md and Final Verification

**Files:**
- Modify: `skills/site-builder/reference/doc-templates.md`

**Interfaces:**
- Consumes: All Phase 1-2 deliverables, Task 1-2 documentation updates
- Produces: Updated Init file list, verified cross-references

**Acceptance Criteria:** AC-11 (Init file list), AC-15 (existing patching unchanged), AC-17 (gitignore unaffected)

**Steps:**

- [ ] **Step 1:** In `skills/site-builder/reference/doc-templates.md`, update the "File Creation Order" section (currently lines 366-377). Add `refresh-hint.sh` to the list. After item 4 (`CLAUDE.md`), the post-doc setup items should note:

  ```markdown
  After docs are created:
  5. `.site-builder/refresh-hint.sh` — targeted PostToolUse hint script
     (from `reference/refresh-hint.sh` template). Overwritten on re-init.
  6. `.git/hooks/pre-commit` — pre-commit hook with doc patching, staging,
     and soft-blocking gate (from `reference/doc-refresh-script.sh` template)
  ```

  If step 6 (pre-commit hook) is already documented in this section, update its description to include "and soft-blocking gate". If not, add it.

- [ ] **Step 2:** Final cross-reference verification across all modified files:

  | Check | Command | Expected |
  |---|---|---|
  | No stale blanket echo in SKILL.md | `grep -c "echo.*Docs may be stale" skills/site-builder/SKILL.md` | 0 |
  | refresh-hint.sh referenced in SKILL.md 2.5 and 2.6 | `grep "refresh-hint" skills/site-builder/SKILL.md` | 3+ matches |
  | Soft-blocking gate documented in doc-refresh.md | `grep "soft-block\|Soft-Blocking" skills/site-builder/reference/doc-refresh.md` | 3+ matches |
  | refresh-hint.sh noted in doc-templates.md | `grep "refresh-hint" skills/site-builder/reference/doc-templates.md` | 1+ match |
  | Gitignore marker block unchanged | `grep "site-builder:gitignore" skills/site-builder/SKILL.md` | Same count as before |
  | No "Intra-Phase Reminder" label in doc-refresh.md | `grep -c "Intra-Phase Reminder\|Intra-phase reminder" skills/site-builder/reference/doc-refresh.md` | 0 |
  | doc-refresh-script.sh syntax valid | `sh -n skills/site-builder/reference/doc-refresh-script.sh` | Exit 0 |
  | refresh-hint.sh syntax valid | `sh -n skills/site-builder/reference/refresh-hint.sh` | Exit 0 |

- [ ] **Step 3:** Commit: `docs(reference): add refresh-hint.sh to doc-templates Init file list`

---

## Phase 3 Complete

After this phase, all documentation and orchestrator instructions are updated:
- SKILL.md Section 2.5 installs `refresh-hint.sh` during Init (AC-11)
- SKILL.md Section 2.6 uses `sh .site-builder/refresh-hint.sh` (AC-12)
- doc-refresh.md Section 5 describes targeted hints (AC-13)
- doc-refresh.md documents the soft-blocking gate and bypass (AC-14)
- doc-templates.md lists `refresh-hint.sh` in the Init file order
- All existing auto-marker patching continues unchanged (AC-15)
- Gitignore hook is unaffected (AC-17)

**Next:** Plan complete.
