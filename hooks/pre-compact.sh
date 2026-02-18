#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

main() {
  local input trigger timestamp

  input="$(cat 2>/dev/null || true)"
  trigger="$(printf '%s' "$input" | jq -r '.trigger // "unknown"' 2>/dev/null || printf 'unknown')"

  timestamp="$(date -Iseconds 2>/dev/null || date)"
  local log_file
  log_file="${HOME}/.claude/hooks-debug.log"
  if mkdir -p "${HOME}/.claude" 2>/dev/null && touch "$log_file" 2>/dev/null; then
    printf '%s pre_compact trigger=%s\n' "$timestamp" "$trigger" >>"$log_file"
  fi

  exit 0
}

main "$@"
