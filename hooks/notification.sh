#!/usr/bin/env bash
set -euo pipefail
# Notification Hook — Forward Claude Code notifications to desktop.
# Fires when Claude Code generates a notification (task done, errors, etc.).
# Cannot block — always exit 0.

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

main() {
  local input message title

  input="$(cat 2>/dev/null || true)"
  message="$(printf '%s' "$input" | jq -r '.message // ""' 2>/dev/null || printf '')"
  title="$(printf '%s' "$input" | jq -r '.title // "Claude Code"' 2>/dev/null || printf 'Claude Code')"

  if [[ -n "$message" ]]; then
    notify "$title: $message"
  fi

  log_event "${HOME}/.claude/hooks-debug.log" "notification title=$title msg=$message"
  exit 0
}

main "$@"
