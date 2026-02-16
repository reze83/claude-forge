#!/usr/bin/env bash
set -euo pipefail
# PreToolUse Hook — Secret-Scan (Pre-Write/Edit)
# Scans .tool_input.content (Write) / .tool_input.new_string (Edit)
# BEFORE the file is written. Blocks on high-confidence secrets.
# Compatible: Bash 3.2+ (macOS) and Bash 4+

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')

# Only scan Write and Edit operations
case "$TOOL_NAME" in
  Write) CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // ""') ;;
  Edit)  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // ""') ;;
  *)     exit 0 ;;
esac

[[ -z "$CONTENT" ]] && exit 0

# Content size limit: skip overly large content to prevent DoS
CONTENT_SIZE=${#CONTENT}
if [[ "$CONTENT_SIZE" -gt "$MAX_CONTENT_SIZE" ]]; then
  debug "secret-scan-pre: content too large ($CONTENT_SIZE bytes), truncating to $MAX_CONTENT_SIZE"
  CONTENT="${CONTENT:0:$MAX_CONTENT_SIZE}"
fi

debug "secret-scan-pre: scanning $CONTENT_SIZE bytes for tool=$TOOL_NAME"

# Scan line by line — pragma only applies to the line it appears on
while IFS= read -r line; do
  # Skip lines with pragma allowlist
  if printf '%s' "$line" | grep -qE '(#|//) pragma: allowlist secret'; then
    continue
  fi

  # Check each secret pattern
  for i in "${!SECRET_PATTERNS[@]}"; do
    if printf '%s' "$line" | grep -qE "${SECRET_PATTERNS[$i]}"; then
      block "SECRET BLOCKED: ${SECRET_LABELS[$i]} detected in content"
    fi
  done
done <<< "$CONTENT"

exit 0
