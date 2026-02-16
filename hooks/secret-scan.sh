#!/usr/bin/env bash
set -euo pipefail
# PostToolUse Hook — Secret-Scan
# Checks files after Write/Edit for accidentally leaked secrets.
# Must NEVER block (PostToolUse) — warns only via stdout.
# Compatible: Bash 3.2+ (macOS) and Bash 4+ / GNU+BSD coreutils

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[[ -z "$FILE_PATH" ]] && exit 0
[[ -f "$FILE_PATH" ]] || exit 0

# Skip binary files and large files (>1MB)
# Cross-platform file size: macOS stat -f%z, Linux stat -c%s
FILE_SIZE=$(stat -f%z "$FILE_PATH" 2>/dev/null || stat -c%s "$FILE_PATH" 2>/dev/null || echo 0)
[[ "$FILE_SIZE" -gt "$MAX_CONTENT_SIZE" ]] && exit 0

debug "secret-scan: scanning $FILE_PATH ($FILE_SIZE bytes)"

FINDINGS=()

for i in "${!SECRET_PATTERNS[@]}"; do
  if grep -qE "${SECRET_PATTERNS[$i]}" "$FILE_PATH" 2>/dev/null; then
    FINDINGS+=("${SECRET_LABELS[$i]}")
  fi
done

if [[ ${#FINDINGS[@]} -gt 0 ]]; then
  WARN_LIST=$(printf ', %s' "${FINDINGS[@]}")
  WARN_LIST="${WARN_LIST:2}"
  warn "SECRET WARNING: $WARN_LIST found in $FILE_PATH. Please remove!"
fi

exit 0
