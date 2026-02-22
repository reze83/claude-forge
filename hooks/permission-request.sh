#!/usr/bin/env bash
set -euo pipefail
# PermissionRequest Hook — Log permission requests and optionally gate them.
# Fires when a permission dialog appears (e.g. tool access, network).
# Input fields: tool_name, tool_input, permission_suggestions (per Claude Code docs).
# Opt-in gate: CLAUDE_FORGE_PERMISSION_GATE=1 blocks all permission requests.

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

main() {
  local input session_id tool_name tool_input_summary

  input="$(cat 2>/dev/null || true)"
  session_id="$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null || printf 'unknown')"
  tool_name="$(printf '%s' "$input" | jq -r '.tool_name // "unknown"' 2>/dev/null || printf 'unknown')"
  tool_input_summary="$(printf '%s' "$input" | jq -c '.tool_input // {}' 2>/dev/null || printf '{}')"

  log_event "${HOME}/.claude/hooks-debug.log" \
    "permission_request tool=$tool_name input=$tool_input_summary session=$session_id"
  debug "permission_request: tool=$tool_name input=$tool_input_summary"

  if [[ "${CLAUDE_FORGE_PERMISSION_GATE:-0}" == "1" ]]; then
    printf 'Permission fuer %s geblockt (PERMISSION_GATE=1)\n' "$tool_name" >&2
    exit 2
  fi

  exit 0
}

main "$@"
