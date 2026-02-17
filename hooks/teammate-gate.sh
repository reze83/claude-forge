#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

main() {
  local input teammate_name team_name timestamp

  input="$(cat 2>/dev/null || true)"
  teammate_name="$(printf '%s' "$input" | jq -r '.teammate_name // "unknown"' 2>/dev/null || printf 'unknown')"
  team_name="$(printf '%s' "$input" | jq -r '.team_name // "unknown"' 2>/dev/null || printf 'unknown')"

  timestamp="$(date -Iseconds 2>/dev/null || date)"
  local log_file
  log_file="${HOME}/.claude/hooks-debug.log"
  if mkdir -p "${HOME}/.claude" 2>/dev/null && touch "$log_file" 2>/dev/null; then
    printf '%s teammate_idle teammate=%s team=%s\n' \
      "$timestamp" "$teammate_name" "$team_name" >> "$log_file"
  fi

  if [[ "${CLAUDE_FORGE_TEAMMATE_GATE:-0}" != "1" ]]; then
    exit 0
  fi

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
      printf 'Teammate idle blocked: uncommitted changes detected in current directory.\n' >&2
      exit 2
    fi
  fi

  exit 0
}

main "$@"
