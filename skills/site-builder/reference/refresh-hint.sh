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
