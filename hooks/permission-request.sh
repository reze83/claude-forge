#!/usr/bin/env bash
set -euo pipefail
# PermissionRequest Hook — Log permission requests and optionally gate them.
# Fires when Claude requests a new permission (e.g. tool access, network).
# Opt-in gate: CLAUDE_FORGE_PERMISSION_GATE=1 blocks all permission requests.

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

main() {
  local input session_id tool_name permission_type

  input="$(cat 2>/dev/null || true)"
  session_id="$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null || printf 'unknown')"
  tool_name="$(printf '%s' "$input" | jq -r '.tool_name // "unknown"' 2>/dev/null || printf 'unknown')"
  permission_type="$(printf '%s' "$input" | jq -r '.permission_type // "unknown"' 2>/dev/null || printf 'unknown')"

  log_event "${HOME}/.claude/hooks-debug.log" \
    "permission_request type=$permission_type tool=$tool_name session=$session_id"
  debug "permission_request: type=$permission_type tool=$tool_name"

  if [[ "${CLAUDE_FORGE_PERMISSION_GATE:-0}" == "1" ]]; then
    printf 'Permission %s fuer %s geblockt (PERMISSION_GATE=1)\n' "$permission_type" "$tool_name" >&2
    exit 2
  fi

  exit 0
}

main "$@"
