#!/usr/bin/env bash
set -euo pipefail
# SessionEnd Hook — Session end notification + log
# Sends desktop notification and logs timestamp.
# SessionEnd fires once when session terminates (not on every Claude response).
# Must NEVER block — always exit 0.

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

LOG_FILE="${CLAUDE_LOG_DIR:-$HOME/.claude}/session-log.txt"
MAX_LOG_LINES=1000
MSG="Claude Code Session beendet"

# Drain stdin (not needed for SessionEnd)
cat >/dev/null 2>&1 || true

log_event "$LOG_FILE" "$MSG"

# Atomic log rotation using mkdir as portable lock (no flock needed)
LOCK_DIR="${LOG_FILE}.lock"
if mkdir "$LOCK_DIR" 2>/dev/null; then
  if [[ -f "$LOG_FILE" ]]; then
    LINE_COUNT=$(wc -l <"$LOG_FILE" 2>/dev/null || printf '0')
    if [[ "$LINE_COUNT" -gt "$MAX_LOG_LINES" ]]; then
      tail -n "$MAX_LOG_LINES" "$LOG_FILE" >"$LOG_FILE.tmp" 2>/dev/null &&
        mv "$LOG_FILE.tmp" "$LOG_FILE" 2>/dev/null || true
    fi
  fi
  rmdir "$LOCK_DIR" 2>/dev/null || true
fi

notify "$MSG"

exit 0
