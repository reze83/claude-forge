#!/usr/bin/env bash
set -euo pipefail
# SubagentStop Hook — Log subagent completion.
# Fires when a subagent finishes. Can block (exit 2) to prevent subagent stop.
# claude-forge does not block — logging only.

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

main() {
  local input session_id agent_id agent_type stop_hook_active timestamp log_file

  input="$(cat 2>/dev/null || true)"
  session_id="$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null || printf 'unknown')"
  agent_id="$(printf '%s' "$input" | jq -r '.agent_id // "unknown"' 2>/dev/null || printf 'unknown')"
  agent_type="$(printf '%s' "$input" | jq -r '.agent_type // "unknown"' 2>/dev/null || printf 'unknown')"
  stop_hook_active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || printf 'false')"

  log_event "${HOME}/.claude/hooks-debug.log" \
    "subagent_stop session_id=$session_id agent_type=$agent_type agent_id=$agent_id stop_hook_active=$stop_hook_active"

  debug "subagent_stop: agent_type=$agent_type agent_id=$agent_id stop_hook_active=$stop_hook_active"
  exit 0
}

main "$@"
