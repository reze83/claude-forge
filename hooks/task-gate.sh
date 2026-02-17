#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

main() {
  local input task_id task_subject task_description forge_dir

  input="$(cat 2>/dev/null || true)"
  task_id="$(printf '%s' "$input" | jq -r '.task_id // "unknown"' 2>/dev/null || printf 'unknown')"
  task_subject="$(printf '%s' "$input" | jq -r '.task_subject // "unknown"' 2>/dev/null || printf 'unknown')"
  task_description="$(printf '%s' "$input" | jq -r '.task_description // "unknown"' 2>/dev/null || printf 'unknown')"

  debug "TaskCompleted task_id=$task_id task_subject=$task_subject task_description=$task_description"

  if [[ "${CLAUDE_FORGE_TASK_GATE:-0}" != "1" ]]; then
    exit 0
  fi

  forge_dir="${CLAUDE_FORGE_DIR:-${HOME}/.claude/claude-forge}"
  # Sanitize path — reject shell metacharacters to prevent command injection
  if [[ "$forge_dir" =~ [;\|\&\$\`] ]]; then
    printf 'Task gate failed: invalid characters in forge directory path\n' >&2
    exit 2
  fi
  if [[ ! -d "$forge_dir" ]]; then
    printf 'Task gate failed: forge directory not found: %s\n' "$forge_dir" >&2
    exit 2
  fi

  if ! (cd "$forge_dir" && bash tests/test-hooks.sh); then
    printf 'Task gate blocked: hook tests failed in %s\n' "$forge_dir" >&2
    exit 2
  fi

  exit 0
}

main "$@"
