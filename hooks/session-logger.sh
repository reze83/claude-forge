#!/usr/bin/env bash
set -euo pipefail
# Stop Hook — Session-Ende Benachrichtigung + Log
# Sendet Desktop-Notification und loggt Zeitstempel.
# Darf NIEMALS blocken → immer exit 0.

LOG_DIR="${CLAUDE_LOG_DIR:-$HOME/.claude}"
LOG_FILE="$LOG_DIR/session-log.txt"
MAX_LOG_LINES=1000
TIMESTAMP="$(date -Iseconds)"
MSG="Claude Code Session beendet"

# Log schreiben
echo "$TIMESTAMP | $MSG" >> "$LOG_FILE" 2>/dev/null || true

# Log rotation: keep last MAX_LOG_LINES lines
if [[ -f "$LOG_FILE" ]]; then
  LINE_COUNT=$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)
  if [[ "$LINE_COUNT" -gt "$MAX_LOG_LINES" ]]; then
    tail -n "$MAX_LOG_LINES" "$LOG_FILE" > "$LOG_FILE.tmp" 2>/dev/null && mv "$LOG_FILE.tmp" "$LOG_FILE" 2>/dev/null || true
  fi
fi

# Desktop-Notification (WSL2 → PowerShell, Linux → notify-send)
if command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -Command "
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    \$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(0)
    \$xml.GetElementsByTagName('text')[0].AppendChild(\$xml.CreateTextNode('Task abgeschlossen')) | Out-Null
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show([Windows.UI.Notifications.ToastNotification]::new(\$xml))
  " 2>/dev/null || true
elif command -v notify-send >/dev/null 2>&1; then
  notify-send "Claude Code" "$MSG" 2>/dev/null || true
fi

exit 0
