#!/usr/bin/env bash
set -euo pipefail
# PreToolUse Hook — Geschuetzte Dateien
# Blockiert Read/Write/Edit auf sensible Dateien.
# Output: JSON auf stdout (modernes Format) + Exit 2 (legacy Fallback)

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[[ -z "$FILE_PATH" ]] && exit 0

# --- Moderne Hook-Output-Funktion ---
block() {
  local reason="$1"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$reason"
  exit 2
}

PATTERNS=(".env" ".env." "secrets/" ".ssh/" ".aws/" ".gnupg/" ".git/" ".npmrc" ".netrc")
EXTENSIONS=(".pem" ".key" ".p12" ".pfx" ".keystore")

# package-lock.json: Only block Write/Edit, allow Read
if [[ "$FILE_PATH" == *"package-lock.json"* ]]; then
  if [[ "$TOOL_NAME" == "Write" || "$TOOL_NAME" == "Edit" ]]; then
    block "'$FILE_PATH' ist geschuetzt (package-lock.json: nur Read erlaubt)"
  fi
fi

for p in "${PATTERNS[@]}"; do
  [[ "$FILE_PATH" == *"$p"* ]] && block "'$FILE_PATH' ist geschuetzt (Muster: '$p')"
done

for e in "${EXTENSIONS[@]}"; do
  [[ "$FILE_PATH" == *"$e" ]] && block "'$FILE_PATH' ist geschuetzt (Endung: '$e')"
done

exit 0
