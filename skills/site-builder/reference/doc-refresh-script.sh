#!/bin/sh
# Site Builder — mechanical-facts doc refresh (pre-commit)
# Patches ARCHITECTURE.md and BRAND.md auto-marker sections from source files.
# Exits 0 on ALL error paths — never blocks a commit.

# --- CRLF safety (Windows Git Bash) ---
# All file reads are piped through tr -d '\r' before sed/awk processing.

set -e
trap 'exit 0' EXIT

# --- Helper: patch content between auto-markers ---
# Usage: patch_auto_section <file> <marker-name> <new-content>
# If file or markers are missing, skip silently.
patch_auto_section() {
  _file="$1"
  _marker="$2"
  _content="$3"
  _open="<!-- auto:${_marker} -->"
  _close="<!-- /auto:${_marker} -->"

  [ -f "$_file" ] || return 0

  # Check markers exist (CRLF-safe)
  tr -d '\r' < "$_file" | grep -q "$_open" || return 0
  tr -d '\r' < "$_file" | grep -q "$_close" || return 0

  # Replace content between markers using awk (CRLF-safe)
  # NOTE: awk vars use mstart/mend, not open/close — close() is a gawk builtin
  # and using it as a -v variable name fails with "cannot use gawk builtin
  # `close' as variable name" under gawk.
  _tmp="${_file}.tmp.$$"
  tr -d '\r' < "$_file" | awk -v mstart="$_open" -v mend="$_close" -v content="$_content" '
    $0 == mstart { print; printf "%s\n", content; skip=1; next }
    $0 == mend { skip=0 }
    !skip { print }
  ' > "$_tmp"

  mv "$_tmp" "$_file"
}

# --- ARCHITECTURE.md: Directory Structure ---
if [ -f "ARCHITECTURE.md" ]; then
  dir_tree=$(find . -maxdepth 2 \
    -not -path './.git*' \
    -not -path './node_modules*' \
    -not -path './.site-builder*' \
    -not -name '*.tmp' \
    2>/dev/null | sort | head -80 || true)

  if [ -n "$dir_tree" ]; then
    # Format as indented tree (simplified)
    formatted=$(echo "$dir_tree" | sed 's|^\./||' | sed 's|[^/]*/|  |g' || true)
    patch_auto_section "ARCHITECTURE.md" "directory-structure" "\`\`\`
${formatted}
\`\`\`"
  fi
fi

# --- ARCHITECTURE.md: Dependencies ---
if [ -f "ARCHITECTURE.md" ] && [ -f "package.json" ]; then
  deps=$(tr -d '\r' < package.json | awk '
    /"dependencies"/ { in_deps=1; next }
    /"devDependencies"/ { in_devdeps=1; next }
    in_deps && /\}/ { in_deps=0 }
    in_devdeps && /\}/ { in_devdeps=0 }
    in_deps && /"[^"]+":/ {
      gsub(/[",]/, ""); gsub(/^[ \t]+/, "");
      split($0, a, ": "); deps_list = deps_list "| " a[1] " | " a[2] " |\n"
    }
    in_devdeps && /"[^"]+":/ {
      gsub(/[",]/, ""); gsub(/^[ \t]+/, "");
      split($0, a, ": "); devdeps_list = devdeps_list "| " a[1] " | " a[2] " |\n"
    }
    END {
      if (deps_list) { printf "### Runtime\n\n| Package | Version |\n|---|---|\n%s\n", deps_list }
      if (devdeps_list) { printf "### Dev\n\n| Package | Version |\n|---|---|\n%s\n", devdeps_list }
    }
  ' 2>/dev/null || true)

  if [ -n "$deps" ]; then
    patch_auto_section "ARCHITECTURE.md" "dependencies" "$deps"
  fi
fi

# --- ARCHITECTURE.md: Build & Dev ---
if [ -f "ARCHITECTURE.md" ] && [ -f "package.json" ]; then
  build_cmds=$(tr -d '\r' < package.json | awk '
    /"scripts"/ { in_scripts=1; next }
    in_scripts && /\}/ { in_scripts=0 }
    in_scripts && /"[^"]+":/ {
      gsub(/[",]/, ""); gsub(/^[ \t]+/, "");
      split($0, a, ": ");
      printf "npm run %s  # %s\n", a[1], a[2]
    }
  ' 2>/dev/null || true)

  if [ -n "$build_cmds" ]; then
    patch_auto_section "ARCHITECTURE.md" "build-dev" "\`\`\`bash
${build_cmds}
\`\`\`"
  fi
fi

# --- BRAND.md: Design Tokens (from .site-builder/design-system.md) ---
DESIGN_SYSTEM=".site-builder/design-system.md"
if [ -f "BRAND.md" ] && [ -f "$DESIGN_SYSTEM" ]; then
  ds_content=$(tr -d '\r' < "$DESIGN_SYSTEM" || true)

  # Extract color tokens (lines between ### Colors and next ###)
  colors=$(echo "$ds_content" | awk '
    /^### Colors/ { found=1; next }
    found && /^###/ { exit }
    found { print }
  ' || true)
  [ -n "$colors" ] && patch_auto_section "BRAND.md" "color-tokens" "$colors"

  # Extract font stack (lines between ### Typography and next ###)
  fonts=$(echo "$ds_content" | awk '
    /^### Typography/ { found=1; next }
    found && /^###/ { exit }
    found { print }
  ' || true)
  [ -n "$fonts" ] && patch_auto_section "BRAND.md" "font-stack" "$fonts"

  # Extract spacing scale (lines between ### Spacing and next ###)
  spacing=$(echo "$ds_content" | awk '
    /^### Spacing/ { found=1; next }
    found && /^###/ { exit }
    found { print }
  ' || true)
  [ -n "$spacing" ] && patch_auto_section "BRAND.md" "spacing-scale" "$spacing"

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

# --- Stage patched docs ---
for f in ARCHITECTURE.md BRAND.md; do
  if [ -f "$f" ] && git diff --name-only 2>/dev/null | grep -qx "$f"; then
    git add "$f"
  fi
done

# Also auto-stage Layer 1 refreshed docs (CONTEXT.md, CLAUDE.md)
for f in CONTEXT.md CLAUDE.md; do
  if [ -f "$f" ] && git diff --name-only 2>/dev/null | grep -qx "$f"; then
    git add "$f"
  fi
done

# --- Step 3: Soft-blocking doc-relevance gate ---
# Narrower patterns than refresh-hint.sh — enforcement, not advisory.
# Only blocks on structurally significant changes to avoid false-positive
# fatigue that would train developers to always use --no-verify.
trap - EXIT

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
