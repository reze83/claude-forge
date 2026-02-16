#!/usr/bin/env bash
set -euo pipefail
# PreToolUse Hook — Secret-Scan (Pre-Write/Edit)
# Scannt .tool_input.content (Write) / .tool_input.new_string (Edit)
# BEVOR die Datei geschrieben wird. Blockt bei High-Confidence Secrets.
# Compatible: Bash 3.2+ (macOS) and Bash 4+

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')

# Only scan Write and Edit operations
case "$TOOL_NAME" in
  Write) CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // ""') ;;
  Edit)  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // ""') ;;
  *)     exit 0 ;;
esac

[[ -z "$CONTENT" ]] && exit 0

# Allowlist: skip if pragma comment present
if echo "$CONTENT" | grep -qE '(#|//) pragma: allowlist secret'; then
  exit 0
fi

# --- Moderne Hook-Output-Funktion ---
block() {
  local reason="$1"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$reason"
  exit 2
}

# --- Secret-Patterns (ERE, kein PCRE) ---
if echo "$CONTENT" | grep -qE 'sk-ant-[a-zA-Z0-9_-]{20,}'; then
  block "SECRET BLOCKED: Anthropic API Key (sk-ant-...) im Content erkannt"
fi

if echo "$CONTENT" | grep -qE 'sk-[a-zA-Z0-9]{48,}'; then
  block "SECRET BLOCKED: OpenAI API Key (sk-...) im Content erkannt"
fi

if echo "$CONTENT" | grep -qE 'ghp_[a-zA-Z0-9]{36}'; then
  block "SECRET BLOCKED: GitHub Token (ghp_...) im Content erkannt"
fi

if echo "$CONTENT" | grep -qE 'AKIA[0-9A-Z]{16}'; then
  block "SECRET BLOCKED: AWS Access Key (AKIA...) im Content erkannt"
fi

if echo "$CONTENT" | grep -qE 'eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.'; then
  block "SECRET BLOCKED: JWT Token (eyJ...) im Content erkannt"
fi

if echo "$CONTENT" | grep -q 'PRIVATE KEY'; then
  block "SECRET BLOCKED: Private Key Block im Content erkannt"
fi

exit 0
