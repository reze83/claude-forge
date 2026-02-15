#!/usr/bin/env bash
set -euo pipefail
# PostToolUse Hook — Secret-Scan
# Prueft Dateien nach Write/Edit auf versehentlich eingefuegte Secrets.
# Darf NIEMALS blocken (PostToolUse) → warnt nur via stdout.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[[ -z "$FILE_PATH" ]] && exit 0
[[ -f "$FILE_PATH" ]] || exit 0

# Skip binary files and large files (>1MB)
MAX_SIZE=1048576
FILE_SIZE=$(stat -c%s "$FILE_PATH" 2>/dev/null || echo 0)
[[ "$FILE_SIZE" -gt "$MAX_SIZE" ]] && exit 0

FINDINGS=()

# Anthropic API Key
if grep -qP 'sk-ant-[a-zA-Z0-9_-]{20,}' "$FILE_PATH" 2>/dev/null; then
  FINDINGS+=("Anthropic API Key (sk-ant-...)")
fi

# OpenAI API Key
if grep -qP 'sk-[a-zA-Z0-9]{48,}' "$FILE_PATH" 2>/dev/null; then
  FINDINGS+=("OpenAI API Key (sk-...)")
fi

# GitHub Token
if grep -qP 'ghp_[a-zA-Z0-9]{36}' "$FILE_PATH" 2>/dev/null; then
  FINDINGS+=("GitHub Token (ghp_...)")
fi

# AWS Access Key
if grep -qP 'AKIA[0-9A-Z]{16}' "$FILE_PATH" 2>/dev/null; then
  FINDINGS+=("AWS Access Key (AKIA...)")
fi

# JWT Token
if grep -qP 'eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.' "$FILE_PATH" 2>/dev/null; then
  FINDINGS+=("JWT Token (eyJ...)")
fi

# Private Key Block
if grep -q 'PRIVATE KEY' "$FILE_PATH" 2>/dev/null; then
  FINDINGS+=("Private Key Block")
fi

if [[ ${#FINDINGS[@]} -gt 0 ]]; then
  WARN_LIST=$(printf ', %s' "${FINDINGS[@]}")
  WARN_LIST="${WARN_LIST:2}"
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","notification":"SECRET WARNING: %s gefunden in %s. Bitte entfernen!"}}' "$WARN_LIST" "$FILE_PATH"
fi

exit 0
