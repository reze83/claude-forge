#!/usr/bin/env bash
set -euo pipefail
# PostToolUse Hook — Auto-Formatting
# Formatiert Dateien nach Edit/Write mit dem passenden Formatter.
# Fehlender Formatter = kein Fehler (exit 0).

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[[ -z "$FILE_PATH" ]] && exit 0
[[ -f "$FILE_PATH" ]] || exit 0

case "$FILE_PATH" in
  # JavaScript/TypeScript/Web (Prettier)
  *.js|*.jsx|*.ts|*.tsx|*.json|*.css|*.scss|*.html|*.md|*.yaml|*.yml)
    if [[ -x "node_modules/.bin/prettier" ]]; then
      node_modules/.bin/prettier --write "$FILE_PATH" 2>/dev/null || true
    elif command -v prettier >/dev/null 2>&1; then
      prettier --write "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  # Python (ruff)
  *.py)
    if command -v ruff >/dev/null 2>&1; then
      ruff format "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  # Rust (rustfmt)
  *.rs)
    if command -v rustfmt >/dev/null 2>&1; then
      rustfmt "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  # Go (gofmt)
  *.go)
    if command -v gofmt >/dev/null 2>&1; then
      gofmt -w "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  # Shell Scripts (shfmt)
  *.sh)
    if command -v shfmt >/dev/null 2>&1; then
      shfmt -w -i 2 -ci "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
esac

exit 0
