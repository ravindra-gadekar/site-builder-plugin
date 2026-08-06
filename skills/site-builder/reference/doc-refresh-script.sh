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

exit 0
