#!/usr/bin/env bash
set -euo pipefail
# Stop Hook — Log Claude turn completion and send desktop notification.
# Fires after every Claude response. Can block (decision: "block") to continue.
# claude-forge does not block — notification + logging only.

LOG_DIR="${CLAUDE_LOG_DIR:-$HOME/.claude}"
LOG_FILE="$LOG_DIR/session-log.txt"
TIMESTAMP="$(date -Iseconds 2>/dev/null || date)"

input="$(cat 2>/dev/null || true)"
stop_hook_active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || printf 'false')"

# Skip logging when already looping via stop hook to prevent recursion noise
if [[ "$stop_hook_active" == "true" ]]; then
  exit 0
fi

# Log turn completion
if mkdir -p "$LOG_DIR" 2>/dev/null && touch "$LOG_FILE" 2>/dev/null; then
  printf '%s | claude_stop\n' "$TIMESTAMP" >>"$LOG_FILE" 2>/dev/null || true
fi

# Desktop notification (WSL2 → PowerShell, Linux → notify-send)
if command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -Command "
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    \$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(0)
    \$xml.GetElementsByTagName('text')[0].AppendChild(\$xml.CreateTextNode('Claude hat geantwortet')) | Out-Null
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show([Windows.UI.Notifications.ToastNotification]::new(\$xml))
  " 2>/dev/null || true
elif command -v notify-send >/dev/null 2>&1; then
  notify-send "Claude Code" "Claude hat geantwortet" 2>/dev/null || true
fi

exit 0
