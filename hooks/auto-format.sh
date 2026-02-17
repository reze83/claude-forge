#!/usr/bin/env bash
set -euo pipefail
# PostToolUse Hook — Auto-Formatting
# Formats files after Edit/Write with the appropriate formatter.
# Missing formatter = no error (exit 0).
# Compatible: Bash 3.2+ (macOS) and Bash 4+

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

INPUT=$(cat 2>/dev/null || true)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || FILE_PATH=""
[[ -z "$FILE_PATH" ]] && exit 0
[[ -f "$FILE_PATH" ]] || exit 0

debug "auto-format: formatting $FILE_PATH"

# Find prettier safely: project-local first (resolved from file's directory),
# then global. Avoids CWD-dependent relative path issue.
find_prettier() {
  local file_dir
  file_dir="$(dirname "$FILE_PATH")"
  # Walk up from file directory to find project-local prettier
  local dir="$file_dir"
  while [[ "$dir" != "/" ]]; do
    if [[ -x "$dir/node_modules/.bin/prettier" ]]; then
      printf '%s' "$dir/node_modules/.bin/prettier"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  # Fall back to global prettier
  if command -v prettier >/dev/null 2>&1; then
    printf '%s' "prettier"
    return 0
  fi
  return 1
}

format_result=0

case "$FILE_PATH" in
  # JavaScript/TypeScript/Web (Prettier)
  *.js | *.jsx | *.ts | *.tsx | *.json | *.css | *.scss | *.html | *.md | *.yaml | *.yml)
    PRETTIER_CMD=$(find_prettier) || true
    if [[ -n "$PRETTIER_CMD" ]]; then
      "$PRETTIER_CMD" --write "$FILE_PATH" 2>/dev/null || format_result=$?
    fi
    ;;
  # Python (ruff)
  *.py)
    if command -v ruff >/dev/null 2>&1; then
      ruff format "$FILE_PATH" 2>/dev/null || format_result=$?
    fi
    ;;
  # Rust (rustfmt)
  *.rs)
    if command -v rustfmt >/dev/null 2>&1; then
      rustfmt "$FILE_PATH" 2>/dev/null || format_result=$?
    fi
    ;;
  # Go (gofmt)
  *.go)
    if command -v gofmt >/dev/null 2>&1; then
      gofmt -w "$FILE_PATH" 2>/dev/null || format_result=$?
    fi
    ;;
  # Shell Scripts (shfmt)
  *.sh)
    if command -v shfmt >/dev/null 2>&1; then
      shfmt -w -i 2 -ci "$FILE_PATH" 2>/dev/null || format_result=$?
    fi
    ;;
esac

if [[ "$format_result" -ne 0 ]]; then
  warn "Formatting failed for $FILE_PATH (exit code: $format_result)"
fi

exit 0
