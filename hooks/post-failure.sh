#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

main() {
  local input tool_name tool_input error_text is_interrupt timestamp log_line

  input="$(cat 2>/dev/null || true)"
  tool_name="$(printf '%s' "$input" | jq -r '.tool_name // "unknown"' 2>/dev/null || printf 'unknown')"
  tool_input="$(printf '%s' "$input" | jq -c '.tool_input // {}' 2>/dev/null || printf '{}')"
  error_text="$(printf '%s' "$input" | jq -r '.error // "unknown"' 2>/dev/null || printf 'unknown')"
  is_interrupt="$(printf '%s' "$input" | jq -r '.is_interrupt // false' 2>/dev/null || printf 'false')"

  timestamp="$(date -Iseconds 2>/dev/null || date)"
  local log_file
  log_file="${HOME}/.claude/hooks-debug.log"
  log_line="$(jq -cn --arg ts "$timestamp" --arg tool_name "$tool_name" --arg tool_input "$tool_input" --arg error "$error_text" --arg is_interrupt "$is_interrupt" '{timestamp:$ts,event:"PostToolUseFailure",tool_name:$tool_name,tool_input:$tool_input,error:$error,is_interrupt:$is_interrupt}' 2>/dev/null || printf '{"timestamp":"%s","event":"PostToolUseFailure"}' "$timestamp")"
  if mkdir -p "${HOME}/.claude" 2>/dev/null && touch "$log_file" 2>/dev/null; then
    printf '%s\n' "$log_line" >>"$log_file"
  fi

  printf '{"additionalContext":"Tool execution failed. Check filesystem permissions and verify referenced files exist and are accessible."}\n'
  exit 0
}

main "$@"
