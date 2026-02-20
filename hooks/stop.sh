#!/usr/bin/env bash
set -euo pipefail
# Stop Hook — Log Claude turn completion and send desktop notification.
# Fires after every Claude response. Can block (decision: "block") to continue.
# claude-forge does not block — notification + logging only.

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

LOG_FILE="${CLAUDE_LOG_DIR:-$HOME/.claude}/session-log.txt"

input="$(cat 2>/dev/null || true)"
stop_hook_active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || printf 'false')"

# Skip logging when already looping via stop hook to prevent recursion noise
if [[ "$stop_hook_active" == "true" ]]; then
  exit 0
fi

log_event "$LOG_FILE" "claude_stop"
notify "Claude hat geantwortet"

exit 0
