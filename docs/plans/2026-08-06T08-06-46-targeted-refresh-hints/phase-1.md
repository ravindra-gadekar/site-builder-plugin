# Phase 1: Targeted Refresh-Hint Script

**Repo:** site-builder-plugin
**Depends on:** None
**Delivers:** New `skills/site-builder/reference/refresh-hint.sh` — a POSIX sh template that reads PostToolUse JSON from stdin, extracts `file_path`, and outputs a targeted hint naming the specific doc and section when the changed file matches a doc-relevant pattern. Silent for non-matching files.

## File Structure

```
skills/site-builder/reference/
├── refresh-hint.sh          (create)
├── doc-refresh-script.sh    (unchanged this phase)
├── doc-refresh.md           (unchanged this phase)
└── doc-templates.md         (unchanged this phase)
```

---

### Task 1: Create `refresh-hint.sh`

**Files:**
- Create: `skills/site-builder/reference/refresh-hint.sh`

**Interfaces:**
- Consumes: PostToolUse JSON from stdin — `{"tool_name": "Edit|Write", "file_path": "<absolute-path>"}`
- Produces: Targeted hint text to stdout (one line naming the doc and section), or no output for non-matching files

**Acceptance Criteria:** AC-1, AC-2, AC-3, AC-18

**Steps:**

- [ ] **Step 1:** Create `skills/site-builder/reference/refresh-hint.sh` with the following structure:

  ```sh
  #!/bin/sh
  # Site Builder — targeted refresh hint (PostToolUse)
  # Reads PostToolUse JSON from stdin, extracts file_path, outputs a
  # targeted hint naming the specific doc and section — or nothing for
  # irrelevant files.

  # Read JSON from stdin (single line)
  read -r json 2>/dev/null || exit 0

  # Extract file_path (POSIX sed — no grep -P/-o)
  file_path=$(echo "$json" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  [ -z "$file_path" ] && exit 0

  # Strip CWD prefix for repo-relative path
  rel_path="${file_path#$PWD/}"

  # Pattern match — order matters (case stops at first match).
  # More specific path patterns before broad extension patterns.
  case "$rel_path" in
    */schema/*|*.model.*|*/content/config.*)
      echo ">> Update CONTEXT.md (domain model section) — schema/model file changed: $rel_path" ;;
    *.css|*.scss|*.tsx|tailwind.config.*|*/tailwind.config.*)
      echo ">> Update BRAND.md (colors/tokens section) — design-token-relevant file changed: $rel_path" ;;
    package.json|*/package.json|*config.*)
      echo ">> Update ARCHITECTURE.md and CLAUDE.md (deps, build commands) — config file changed: $rel_path" ;;
    *.ts|*.js|*/src/pages/*|*/src/app/*|*/app/pages/*)
      echo ">> Update ARCHITECTURE.md (directory structure, routes) — structural file changed: $rel_path" ;;
    *) ;;
  esac

  exit 0
  ```

  **Pattern ordering rationale:** The `case` statement evaluates top-to-bottom and stops at the first match. Specific path patterns (`*/schema/*`, `*/content/config.*`) come before broad extension patterns (`*.ts`, `*.js`) so that `src/schema/user.ts` produces a CONTEXT.md hint, not an ARCHITECTURE.md hint. Similarly, `tailwind.config.*` is in the BRAND.md group (before `*config.*` in the ARCHITECTURE.md group) so Tailwind config edits produce a BRAND.md hint.

  **Root-level matching (AC-18):** `package.json` is listed alongside `*/package.json` because POSIX `*/` requires a directory prefix — bare `package.json` would not match `*/package.json` alone. Likewise `tailwind.config.*` (root) and `*/tailwind.config.*` (nested) are both present.

  **TSX in BRAND.md group:** Per the spec, `.tsx` files are in the BRAND.md group (not ARCHITECTURE.md with `.ts`) because TSX files typically contain styled components with design tokens.

- [ ] **Step 2:** Verify the script parses without errors:
  ```sh
  sh -n skills/site-builder/reference/refresh-hint.sh
  ```
  Expected: no output, exit 0.

- [ ] **Step 3:** Commit: `feat(reference): add targeted refresh-hint PostToolUse script`

---

### Task 2: Verify Refresh-Hint Patterns

**Files:**
- Verify: `skills/site-builder/reference/refresh-hint.sh`

**Interfaces:**
- Consumes: `refresh-hint.sh` (created in Task 1)

**Acceptance Criteria:** AC-1, AC-2, AC-3, AC-18

**Steps:**

- [ ] **Step 1:** Verify POSIX compliance — no bash-only syntax:
  ```sh
  # Must find NONE of these:
  grep -n '\[\[' skills/site-builder/reference/refresh-hint.sh
  grep -n '<<<' skills/site-builder/reference/refresh-hint.sh
  grep -n 'declare \|local -[aAirn]' skills/site-builder/reference/refresh-hint.sh
  ```
  All three greps must return no matches.

- [ ] **Step 2:** Verify pattern matching with mock JSON — each test pipes mock JSON to the script and checks stdout:

  | Input `file_path` | Expected output contains | AC |
  |---|---|---|
  | `src/styles/global.css` | `BRAND.md` | AC-2 |
  | `src/components/Button.tsx` | `BRAND.md` | AC-2 |
  | `tailwind.config.js` | `BRAND.md` | AC-2, AC-18 |
  | `packages/ui/tailwind.config.ts` | `BRAND.md` | AC-18 |
  | `src/app/page.ts` | `ARCHITECTURE.md` | AC-2 |
  | `src/pages/about.js` | `ARCHITECTURE.md` | AC-2 |
  | `package.json` | `ARCHITECTURE.md and CLAUDE.md` | AC-2 |
  | `apps/web/package.json` | `ARCHITECTURE.md and CLAUDE.md` | AC-2 |
  | `vite.config.ts` | `ARCHITECTURE.md and CLAUDE.md` | AC-2 |
  | `src/schema/user.ts` | `CONTEXT.md` | AC-2 |
  | `lib/order.model.ts` | `CONTEXT.md` | AC-2 |
  | `src/content/config.ts` | `CONTEXT.md` | AC-2 |
  | `README.md` | (empty — no output) | AC-3 |
  | `docs/guide.md` | (empty — no output) | AC-3 |

  Run each as:
  ```sh
  echo '{"tool_name":"Edit","file_path":"<value>"}' | sh skills/site-builder/reference/refresh-hint.sh
  ```

- [ ] **Step 3:** Verify empty/missing `file_path` produces no output:
  ```sh
  echo '{}' | sh skills/site-builder/reference/refresh-hint.sh
  # Expected: no output, exit 0

  echo '{"tool_name":"Edit"}' | sh skills/site-builder/reference/refresh-hint.sh
  # Expected: no output, exit 0
  ```

- [ ] **Step 4:** If any test fails, fix the script and re-run `sh -n` + failed tests. Commit fix: `fix(reference): correct refresh-hint pattern matching`

---

## Phase 1 Complete

After this phase, `skills/site-builder/reference/refresh-hint.sh` exists as a valid POSIX sh script that outputs targeted doc-refresh hints for pattern-matched files and is silent for everything else.

**Next:** `phase-2.md`
