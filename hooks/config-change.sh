#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

LOG_FILE="${CLAUDE_LOG_DIR:-$HOME/.claude}/config-changes.log"

main() {
  local input config_source session_id file_path message

  input="$(cat 2>/dev/null || true)"
  config_source="$(printf '%s' "$input" | jq -r '.source // "unknown"' 2>/dev/null || printf 'unknown')"
  session_id="$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null || printf 'unknown')"
  file_path="$(printf '%s' "$input" | jq -r '.file_path // ""' 2>/dev/null || printf '')"

  message="config_change source=$config_source session=$session_id"
  if [[ -n "$file_path" ]]; then
    message="$message file=$file_path"
  fi

  log_event "$LOG_FILE" "$message"

  # policy_settings cannot be blocked per Claude Code docs
  if [[ "$config_source" == "policy_settings" ]]; then
    exit 0
  fi

  if [[ "${CLAUDE_FORGE_CONFIG_LOCK:-0}" == "1" ]]; then
    local reason
    reason="$(printf 'Config change blocked (CLAUDE_FORGE_CONFIG_LOCK=1): source=%s' "$config_source")"
    printf '{"decision":"block","reason":%s}' "$(printf '%s' "$reason" | jq -Rs .)"
    exit 0
  fi

  exit 0
}

main "$@"
