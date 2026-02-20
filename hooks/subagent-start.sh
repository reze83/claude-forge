#!/usr/bin/env bash
set -euo pipefail
# SubagentStart Hook — Log subagent spawn and inject context.
# Fires when Claude spawns a subagent (Explore, Plan, Bash, custom).
# Cannot block — always exit 0.

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

main() {
  local input session_id agent_id agent_type timestamp log_file

  input="$(cat 2>/dev/null || true)"
  session_id="$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null || printf 'unknown')"
  agent_id="$(printf '%s' "$input" | jq -r '.agent_id // "unknown"' 2>/dev/null || printf 'unknown')"
  agent_type="$(printf '%s' "$input" | jq -r '.agent_type // "unknown"' 2>/dev/null || printf 'unknown')"

  log_event "${HOME}/.claude/hooks-debug.log" \
    "subagent_start session_id=$session_id agent_type=$agent_type agent_id=$agent_id"

  debug "subagent_start: agent_type=$agent_type agent_id=$agent_id"
  exit 0
}

main "$@"
