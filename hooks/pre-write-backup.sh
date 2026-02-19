#!/usr/bin/env bash
set -euo pipefail
# PreToolUse Hook — Pre-Write Backup
# If CLAUDE_FORGE_BACKUP=1, creates a .bak copy before Write/Edit.
# Never blocks — only warns on failure.
# Compatible: Bash 3.2+ (macOS) and Bash 4+

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

# Opt-in only (like task-gate)
[[ "${CLAUDE_FORGE_BACKUP:-0}" != "1" ]] && exit 0

INPUT=$(cat 2>/dev/null || true)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null) || TOOL_NAME=""
[[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]] && exit 0

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || FILE_PATH=""
[[ -z "$FILE_PATH" ]] && exit 0

debug "pre-write-backup: tool=$TOOL_NAME path=$FILE_PATH"

# Skip temp files and node_modules
case "$FILE_PATH" in
  /tmp/*) exit 0 ;;
  */node_modules/*) exit 0 ;;
esac

# Only backup existing files (new files need no backup)
[[ -f "$FILE_PATH" ]] || exit 0

if ! cp "$FILE_PATH" "${FILE_PATH}.bak" 2>/dev/null; then
  warn "Backup failed for '$FILE_PATH' (cp to '${FILE_PATH}.bak')"
fi

exit 0
