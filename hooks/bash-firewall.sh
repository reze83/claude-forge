#!/usr/bin/env bash
set -euo pipefail
# PreToolUse Hook — Bash Firewall
# Liest JSON von stdin, prueft command gegen Deny-Patterns.
# Output: JSON auf stdout (modernes Format) + Exit 2 (legacy Fallback)
# Compatible: Bash 3.2+ (macOS) and Bash 4+

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

# --- Deny-Patterns (portable: parallel arrays statt declare -A) ---
DENY_PATTERNS=(
  'rm\s+-rf\s+/'
  'rm\s+-rf\s+(~|\$HOME)'
  'rm\s+-rf\s+(\.|\.\.\/)'
  'git\s+push.*\s+(main|master)(\s|$)'
  'git\s+reset\s+--hard'
  'git\s+commit\s+.*--amend'
  '>\s*/etc/'
  'chmod\s+0?(777|666)'
  'chmod\s+a\+[rwx]'
  '\beval\s+'
  '\bsource\s+/dev/'
  '\bnano\s+'
  '\bvi\s+'
  'pip\s+install\s+.*--break-system-packages'
)

DENY_REASONS=(
  "rm -rf / nicht erlaubt"
  "rm -rf ~ nicht erlaubt"
  "rm -rf ./ oder ../ nicht erlaubt"
  "Push auf main/master verboten. Feature-Branch + PR erstellen."
  "git reset --hard ist destruktiv. git stash verwenden."
  "git commit --amend aendert History. Neuen Commit erstellen."
  "Schreiben nach /etc/ nicht erlaubt"
  "chmod 777/666 unsicher"
  "chmod a+rwx zu permissiv"
  "eval ist ein Sicherheitsrisiko"
  "source aus /dev/ nicht erlaubt"
  "Interaktive Editoren nicht unterstuetzt"
  "Interaktive Editoren nicht unterstuetzt"
  "pip --break-system-packages nicht erlaubt. venv verwenden."
)

for i in "${!DENY_PATTERNS[@]}"; do
  if echo "$CMD" | grep -Eiq "${DENY_PATTERNS[$i]}"; then
    block "${DENY_REASONS[$i]}"
  fi
done

exit 0
