#!/usr/bin/env bash
set -euo pipefail
# PreToolUse Hook — Protected Files
# Blocks Read/Write/Edit/Glob/Grep on sensitive files.
# Output: JSON on stdout (exit 0 ensures JSON is processed by Claude Code)
# Compatible: Bash 3.2+ (macOS) and Bash 4+

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')

# Extract file_path from tool_input (Read/Write/Edit use file_path, Glob/Grep use path)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')
[[ -z "$FILE_PATH" ]] && exit 0

debug "protect-files: tool=$TOOL_NAME path=$FILE_PATH"

# Case-insensitive comparison (Bash 3.2+ compatible)
FILE_PATH_LOWER=$(printf '%s' "$FILE_PATH" | tr '[:upper:]' '[:lower:]')

PATTERNS=(".env" ".env." "secrets/" ".ssh/" ".aws/" ".gnupg/" ".git/" ".npmrc" ".netrc")
EXTENSIONS=(".pem" ".key" ".p12" ".pfx" ".keystore")

# Allowlist: safe .env template files (check before blocking)
ALLOWLIST=(".env.example" ".env.sample" ".env.template")
for a in "${ALLOWLIST[@]}"; do
  [[ "$FILE_PATH_LOWER" == *"$a" ]] && exit 0
done

# Hook-Tampering protection: block Write/Edit on hook config
HOOK_PROTECTED=("hooks.json" "hooks/" "settings.json" "settings.local.json")
if [[ "$TOOL_NAME" == "Write" || "$TOOL_NAME" == "Edit" ]]; then
  for hp in "${HOOK_PROTECTED[@]}"; do
    [[ "$FILE_PATH_LOWER" == *".claude/$hp"* ]] && block "'$FILE_PATH' is protected (hook configuration)"
  done
fi

# package-lock.json: Only block Write/Edit, allow Read/Glob/Grep
if [[ "$FILE_PATH_LOWER" == *"package-lock.json"* ]]; then
  if [[ "$TOOL_NAME" == "Write" || "$TOOL_NAME" == "Edit" ]]; then
    block "'$FILE_PATH' is protected (package-lock.json: read-only)"
  fi
fi

for p in "${PATTERNS[@]}"; do
  [[ "$FILE_PATH_LOWER" == *"$p"* ]] && block "'$FILE_PATH' is protected (pattern: '$p')"
done

for e in "${EXTENSIONS[@]}"; do
  [[ "$FILE_PATH_LOWER" == *"$e" ]] && block "'$FILE_PATH' is protected (extension: '$e')"
done

exit 0
