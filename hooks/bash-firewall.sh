#!/usr/bin/env bash
set -euo pipefail
# PreToolUse Hook — Bash Firewall
# Liest JSON von stdin, prueft command gegen Deny-Patterns.
# Output: JSON auf stdout (modernes Format) + Exit 2 (legacy Fallback)

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# --- Moderne Hook-Output-Funktion ---
block() {
  local reason="$1"
  # JSON-Output (offiziell empfohlen seit 2026)
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$reason"
  # Exit 2 als Fallback fuer aeltere Versionen
  exit 2
}

declare -A DENY=(
  ['rm\s+-rf\s+/']="rm -rf / nicht erlaubt"
  ['rm\s+-rf\s+(~|\$HOME)']="rm -rf ~ nicht erlaubt"
  ['rm\s+-rf\s+(\.|\.\./)']="rm -rf ./ oder ../ nicht erlaubt"
  ['git\s+push.*\s+(main|master)(\s|$)']="Push auf main/master verboten. Feature-Branch + PR erstellen."
  ['git\s+reset\s+--hard']="git reset --hard ist destruktiv. git stash verwenden."
  ['git\s+commit\s+.*--amend']="git commit --amend aendert History. Neuen Commit erstellen."
  ['>\s*/etc/']="Schreiben nach /etc/ nicht erlaubt"
  ['chmod\s+0?(777|666)']="chmod 777/666 unsicher"
  ['chmod\s+a\+[rwx]']="chmod a+rwx zu permissiv"
  ['\beval\s+']="eval ist ein Sicherheitsrisiko"
  ['\bsource\s+/dev/']="source aus /dev/ nicht erlaubt"
  ['\bnano\s+']="Interaktive Editoren nicht unterstuetzt"
  ['\bvi\s+']="Interaktive Editoren nicht unterstuetzt"
  ['pip\s+install\s+.*--break-system-packages']="pip --break-system-packages nicht erlaubt. venv verwenden."
)

for pat in "${!DENY[@]}"; do
  if echo "$CMD" | grep -Eiq "$pat"; then
    block "${DENY[$pat]}"
  fi
done

exit 0
