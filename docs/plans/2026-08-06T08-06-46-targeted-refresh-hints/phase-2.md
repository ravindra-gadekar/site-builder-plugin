# Phase 2: Expanded Doc-Refresh Script

**Repo:** site-builder-plugin
**Depends on:** Phase 1 (refresh-hint.sh exists, but this phase modifies doc-refresh-script.sh independently)
**Delivers:** Expanded `skills/site-builder/reference/doc-refresh-script.sh` with Tailwind config fallback parsing for BRAND.md tokens and a soft-blocking gate that warns (exit 1) when doc-relevant code is staged but matching docs have no changes.

## File Structure

```
skills/site-builder/reference/
├── refresh-hint.sh          (unchanged this phase)
├── doc-refresh-script.sh    (modify — add Tailwind fallback + soft-blocking gate)
├── doc-refresh.md           (unchanged this phase)
└── doc-templates.md         (unchanged this phase)
```

---

### Task 1: Add Tailwind Config Fallback Parsing

**Files:**
- Modify: `skills/site-builder/reference/doc-refresh-script.sh`

**Interfaces:**
- Consumes: `tailwind.config.{ts,js,mjs,cjs}` (client project file, may not exist)
- Consumes: `.site-builder/design-system.md` (client project file, may not exist)
- Consumes: `BRAND.md` auto-markers (`auto:color-tokens`, `auto:font-stack`, `auto:spacing-scale`)
- Produces: Patched BRAND.md auto-marker sections from Tailwind config values (when design-system.md is absent)

**Acceptance Criteria:** AC-4, AC-6, AC-15, AC-16

**Steps:**

- [ ] **Step 1:** In `skills/site-builder/reference/doc-refresh-script.sh`, locate the existing BRAND.md section (line 105-133, the `if [ -f "BRAND.md" ] && [ -f "$DESIGN_SYSTEM" ]` block). After this block, add a new `elif` branch for the Tailwind fallback. The logic:

  ```sh
  # --- BRAND.md: Design Tokens (Tailwind fallback when design-system.md absent) ---
  elif [ -f "BRAND.md" ]; then
    # Tailwind config search order: .ts > .js > .mjs > .cjs (first match wins)
    tw_config=""
    for ext in ts js mjs cjs; do
      if [ -f "tailwind.config.${ext}" ]; then
        tw_config="tailwind.config.${ext}"
        break
      fi
    done

    if [ -n "$tw_config" ]; then
      tw_content=$(tr -d '\r' < "$tw_config" || true)

      # Extract color tokens from theme.extend.colors or theme.colors
      tw_colors=$(echo "$tw_content" | awk '
        /theme\s*:/ { in_theme=1 }
        in_theme && /extend\s*:/ { in_extend=1 }
        in_extend && /colors\s*:/ { in_colors=1; depth=0; next }
        in_theme && !in_extend && /colors\s*:/ { in_fallback_colors=1; depth=0; next }
        (in_colors || in_fallback_colors) && /\{/ { depth++ }
        (in_colors || in_fallback_colors) && /\}/ { depth--; if (depth < 0) { in_colors=0; in_fallback_colors=0 } }
        in_colors && depth >= 0 && /['\''"]?[a-zA-Z]/ {
          gsub(/['\''",{}]/, ""); gsub(/^[ \t]+/, ""); gsub(/[ \t]+$/, "");
          if ($0 != "") print "- " $0
        }
      ' 2>/dev/null || true)

      # If extend.colors was empty, try top-level theme.colors
      if [ -z "$tw_colors" ]; then
        tw_colors=$(echo "$tw_content" | awk '
          /theme\s*:/ { in_theme=1 }
          in_theme && !/extend/ && /colors\s*:/ { in_colors=1; depth=0; next }
          in_colors && /\{/ { depth++ }
          in_colors && /\}/ { depth--; if (depth < 0) { in_colors=0 } }
          in_colors && depth >= 0 && /['\''"]?[a-zA-Z]/ {
            gsub(/['\''",{}]/, ""); gsub(/^[ \t]+/, ""); gsub(/[ \t]+$/, "");
            if ($0 != "") print "- " $0
          }
        ' 2>/dev/null || true)
      fi

      [ -n "$tw_colors" ] && patch_auto_section "BRAND.md" "color-tokens" "$tw_colors"

      # Extract font family from theme.extend.fontFamily or theme.fontFamily
      tw_fonts=$(echo "$tw_content" | awk '
        /theme\s*:/ { in_theme=1 }
        in_theme && /extend\s*:/ { in_extend=1 }
        (in_extend || in_theme) && /fontFamily\s*:/ { in_fonts=1; depth=0; next }
        in_fonts && /\{/ { depth++ }
        in_fonts && /\}/ { depth--; if (depth < 0) { in_fonts=0 } }
        in_fonts && depth >= 0 && /['\''"]?[a-zA-Z]/ {
          gsub(/['\''",{}[\]]/, ""); gsub(/^[ \t]+/, ""); gsub(/[ \t]+$/, "");
          if ($0 != "") print "- " $0
        }
      ' 2>/dev/null || true)

      [ -n "$tw_fonts" ] && patch_auto_section "BRAND.md" "font-stack" "$tw_fonts"

      # Extract spacing from theme.extend.spacing or theme.spacing
      tw_spacing=$(echo "$tw_content" | awk '
        /theme\s*:/ { in_theme=1 }
        in_theme && /extend\s*:/ { in_extend=1 }
        (in_extend || in_theme) && /spacing\s*:/ { in_spacing=1; depth=0; next }
        in_spacing && /\{/ { depth++ }
        in_spacing && /\}/ { depth--; if (depth < 0) { in_spacing=0 } }
        in_spacing && depth >= 0 && /['\''"]?[a-zA-Z0-9]/ {
          gsub(/['\''",{}]/, ""); gsub(/^[ \t]+/, ""); gsub(/[ \t]+$/, "");
          if ($0 != "") print "- " $0
        }
      ' 2>/dev/null || true)

      [ -n "$tw_spacing" ] && patch_auto_section "BRAND.md" "spacing-scale" "$tw_spacing"
    fi
  fi
  ```

  **Key implementation notes:**
  - The `elif` ensures design-system.md takes priority (AC-6) — Tailwind fallback only runs when the existing `if [ -f "$DESIGN_SYSTEM" ]` condition is false.
  - All `tr -d '\r'` for CRLF safety (AC-16).
  - Awk extraction uses `2>/dev/null || true` — empty/partial results skip the marker, never corrupt existing content.
  - JS expressions like `require()` or spread operators produce partial/empty results — this is acceptable per the spec.

- [ ] **Step 2:** Verify the existing BRAND.md patching from `design-system.md` still works unchanged (AC-15). The new code is an `elif` branch — the original `if` block is untouched.

- [ ] **Step 3:** Run syntax check:
  ```sh
  sh -n skills/site-builder/reference/doc-refresh-script.sh
  ```

- [ ] **Step 4:** Commit: `feat(reference): add Tailwind config fallback for BRAND.md token patching`

---

### Task 2: Add Soft-Blocking Gate

**Files:**
- Modify: `skills/site-builder/reference/doc-refresh-script.sh`

**Interfaces:**
- Consumes: `git diff --cached --name-only` (staged files list)
- Consumes: `git diff --name-only` (unstaged changes list)
- Consumes: `git diff --cached --diff-filter=AD` (added/deleted files)
- Produces: Warning messages to stdout + exit 1 when doc-relevant code staged without matching doc changes; exit 0 otherwise

**Acceptance Criteria:** AC-7, AC-8, AC-9, AC-10, AC-15, AC-16, AC-17, AC-19

**Steps:**

- [ ] **Step 1:** In `skills/site-builder/reference/doc-refresh-script.sh`, make three structural changes to enable the soft-blocking gate:

  1. **Remove the final `exit 0`** (currently the last line, line 149). The gate will control the exit code.
  2. **Insert `trap - EXIT`** after the auto-staging loop (after the second `for f in CONTEXT.md CLAUDE.md` loop, before the new gate logic). This clears the safety-net trap so the gate's `exit 1` is not intercepted.
  3. **Keep `set -e` and `trap 'exit 0' EXIT` at the top** — Steps 1-2 (patching + staging) remain protected by the trap (AC-9).

  The structure becomes:
  ```sh
  set -e
  trap 'exit 0' EXIT

  # ... existing patching (Step 1) ...
  # ... existing auto-staging (Step 2) ...

  # --- Step 3: Soft-blocking gate ---
  trap - EXIT
  # gate logic here (can exit 1)
  ```

- [ ] **Step 2:** Add the soft-blocking gate logic after `trap - EXIT`:

  ```sh
  # --- Step 3: Soft-blocking doc-relevance gate ---
  # Narrower patterns than refresh-hint.sh — enforcement, not advisory.
  # Only blocks on structurally significant changes to avoid false-positive
  # fatigue that would train developers to always use --no-verify.

  gate_warnings=""

  # Get staged files list (once, reused by all checks)
  staged_files=$(git diff --cached --name-only 2>/dev/null || true)
  [ -z "$staged_files" ] && exit 0

  # Helper: check if a doc has ANY changes (staged or unstaged)
  doc_has_changes() {
    _doc="$1"
    [ -f "$_doc" ] || return 1
    git diff --name-only 2>/dev/null | grep -qx "$_doc" && return 0
    git diff --cached --name-only 2>/dev/null | grep -qx "$_doc" && return 0
    return 1
  }

  # Check 1: Design-token files staged, BRAND.md unchanged
  if echo "$staged_files" | grep -qE '\.(css|scss)$' || \
     echo "$staged_files" | grep -q 'tailwind\.config\.'; then
    if ! doc_has_changes "BRAND.md"; then
      gate_warnings="${gate_warnings}>> WARNING: BRAND.md may need updating — staged files match design-token patterns (*.css, *.scss, tailwind.config.*)
  "
    fi
  fi

  # Check 2: Route/structure files staged OR files added/deleted, ARCHITECTURE.md unchanged
  route_match=""
  if echo "$staged_files" | grep -qE '(^|/)src/pages/|src/app/|app/pages/'; then
    route_match="yes"
  fi
  added_deleted=$(git diff --cached --diff-filter=AD --name-only 2>/dev/null || true)
  if [ -n "$route_match" ] || [ -n "$added_deleted" ]; then
    if ! doc_has_changes "ARCHITECTURE.md"; then
      gate_warnings="${gate_warnings}>> WARNING: ARCHITECTURE.md may need updating — staged files match route/structure patterns
  "
    fi
  fi

  # Check 3: package.json staged, ARCHITECTURE.md unchanged
  if echo "$staged_files" | grep -qx 'package.json'; then
    if ! doc_has_changes "ARCHITECTURE.md"; then
      gate_warnings="${gate_warnings}>> WARNING: ARCHITECTURE.md build/deps may need updating — package.json was changed
  "
    fi
  fi

  # Aggregate and exit (AC-19: all warnings shown, not one-at-a-time)
  if [ -n "$gate_warnings" ]; then
    printf '%s' "$gate_warnings"
    echo "Refresh the listed docs, or run 'git commit --no-verify' to skip."
    exit 1
  fi

  exit 0
  ```

  **Key implementation notes:**
  - Gate uses NARROWER patterns than refresh-hint.sh — no blanket `*.ts`/`*.js`, no `*.tsx`, no `*config.*` (AC-7 spec rationale).
  - `doc_has_changes` checks BOTH staged and unstaged — a doc with ANY changes passes the gate (AC-7).
  - All warnings are aggregated before exiting (AC-19) — developer sees the complete picture.
  - Exit 1 only from the gate, never from patching/staging (AC-9, AC-10).
  - Bypass instruction included in output (AC-8).
  - The gitignore hook runs in its own marker block and is unaffected (AC-17).

- [ ] **Step 3:** Run syntax check:
  ```sh
  sh -n skills/site-builder/reference/doc-refresh-script.sh
  ```

- [ ] **Step 4:** Verify the full script structure:
  - Lines 1-9: `set -e`, `trap 'exit 0' EXIT`, helper function — unchanged
  - Lines ~10-133: Step 1 patching (ARCHITECTURE.md + BRAND.md) — unchanged (AC-15)
  - Lines ~134-147: Step 2 auto-staging — unchanged
  - New line: `trap - EXIT` — clears safety trap
  - New lines: Step 3 gate logic — can exit 1

- [ ] **Step 5:** Commit: `feat(reference): add soft-blocking doc-relevance gate to pre-commit script`

---

## Phase 2 Complete

After this phase, `skills/site-builder/reference/doc-refresh-script.sh` contains:
- All existing mechanical-facts patching (unchanged, AC-15)
- Tailwind config fallback for BRAND.md tokens when design-system.md is absent (AC-4, AC-6)
- Soft-blocking gate that warns and exits 1 when doc-relevant code is staged without matching doc changes (AC-7, AC-8, AC-9, AC-10, AC-19)

**Next:** `phase-3.md`
