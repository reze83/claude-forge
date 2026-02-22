#!/usr/bin/env bash
# shellcheck disable=SC2034
set -euo pipefail
# hooks/lib.sh — Shared functions for claude-forge hooks
# Sourced by all hook scripts. NOT executed directly.
# Compatible: Bash 3.2+ (macOS) and Bash 4+

# Resolve directory of the calling script (works for symlinks too)
HOOKS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Debug Logging ---
# Set CLAUDE_FORGE_DEBUG=1 to enable hook debug logging
debug() {
  if [[ "${CLAUDE_FORGE_DEBUG:-0}" == "1" ]]; then
    printf '%s [DEBUG] %s\n' "$(date -Iseconds 2>/dev/null || date)" "$1" \
      >>"${HOME}/.claude/hooks-debug.log" 2>/dev/null || true
  fi
}

# --- JSON-safe block function (PreToolUse) ---
# Uses jq for proper JSON escaping to prevent injection
# Exit 0 + JSON: Claude Code reads permissionDecision:"deny" from stdout
# (exit 2 would cause JSON to be ignored — see hooks reference)
block() {
  local reason
  reason=$(printf '%s' "$1" | jq -Rs .)
  debug "BLOCK: $1"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}' "$reason"
  exit 0
}

# --- Dry-run aware block (PreToolUse) ---
# Set CLAUDE_FORGE_DRY_RUN=1 to report violations without blocking.
# Uses warn() in dry-run mode, block() in normal mode.
# Note: Critical hooks use block() directly — not bypassable even in DRY_RUN.
block_or_warn() {
  if [[ "${CLAUDE_FORGE_DRY_RUN:-0}" == "1" ]]; then
    warn "[DRY-RUN] Would block: $1"
    debug "DRY-RUN: $1"
  else
    block "$1"
  fi
}

# --- JSON-safe warn function (PostToolUse) ---
# Uses jq for proper JSON escaping to prevent injection
# systemMessage: shown to user as warning (documented universal field)
warn() {
  local message
  message=$(printf '%s' "$1" | jq -Rs .)
  debug "WARN: $1"
  printf '{"systemMessage":%s}' "$message"
}

# --- Input Modifier (PreToolUse updatedInput) ---
# Outputs hookSpecificOutput with permissionDecision:"allow" and
# the provided updatedInput JSON object, then exits.
# Call ONLY when input actually changed — exit 0 without output = no change.
# Usage: modify_input '{"command": "new_value"}'
modify_input() {
  local updated_json="$1"
  debug "modify_input: $updated_json"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","updatedInput":%s}}' \
    "$updated_json"
  exit 0
}

# --- JSON context builder (SessionStart) ---
# Builds additionalContext JSON from key-value pairs
# Usage: context "key1" "val1" "key2" "val2"
context() {
  local args=()
  while [[ $# -gt 0 ]]; do
    args+=("--arg" "$1" "$2")
    shift 2
  done
  jq -cn "${args[@]}" '$ARGS.named' 2>/dev/null || printf '{}'
}

# --- Secret Patterns (ERE — no PCRE, Bash 3.2+ compatible) ---
# Parallel arrays (no declare -A for Bash 3.2 compat)
SECRET_PATTERNS=(
  'sk-ant-[a-zA-Z0-9_-]{20,}'
  'sk-[a-zA-Z0-9]{48,}'
  'ghp_[a-zA-Z0-9]{36}'
  'gh[os]_[a-zA-Z0-9]{36,}'
  'ghr_[a-zA-Z0-9]{36,}'
  'AKIA[0-9A-Z]{16}'
  'eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.'
  'PRIVATE KEY'
  'sk_live_[a-zA-Z0-9]{24,}'
  'xox[baprs]-[a-zA-Z0-9-]{10,}'
  'AccountKey=[a-zA-Z0-9+/=]{30,}'
)

SECRET_LABELS=(
  "Anthropic API Key (sk-ant-...)"
  "OpenAI API Key (sk-...)"
  "GitHub PAT (ghp_...)"
  "GitHub OAuth/Server Token (gho_/ghs_...)"
  "GitHub Refresh Token (ghr_...)"
  "AWS Access Key (AKIA...)"
  "JWT Token (eyJ...)"
  "Private Key Block"
  "Stripe Live Key (sk_live_...)"
  "Slack Token (xox...)"
  "Azure Storage Key (AccountKey=...)"
)

# --- Local Patterns (user overrides) ---
# Load additional deny patterns from ~/.claude/local-patterns.sh if present.
# The file must define LOCAL_DENY_PATTERNS=() and LOCAL_DENY_REASONS=() arrays.
# Security: skip if world-writable or group-writable (potential tampering).
LOCAL_DENY_PATTERNS=()
LOCAL_DENY_REASONS=()
_local_patterns_file="${HOME}/.claude/local-patterns.sh"
if [[ -f "$_local_patterns_file" ]]; then
  # Security: skip if writable by group or others (stat -c Linux, stat -f macOS)
  _perms=$(stat -c '%a' "$_local_patterns_file" 2>/dev/null || stat -f '%Lp' "$_local_patterns_file" 2>/dev/null || echo "644")
  _gw=$(((${_perms:-644} / 10 % 10) & 2))
  _ow=$(((${_perms:-644} % 10) & 2))
  if [[ $_gw -ne 0 || $_ow -ne 0 ]]; then
    debug "local-patterns: SKIPPED — writable by group/others (mode $_perms)"
  else
    # shellcheck source=/dev/null
    source "$_local_patterns_file" 2>/dev/null || true
    debug "local-patterns: loaded ${#LOCAL_DENY_PATTERNS[@]} patterns"
  fi
  unset _perms _gw _ow
fi
unset _local_patterns_file

# --- Desktop Notification (WSL2 / Linux) ---
# Sends a Windows Toast notification (WSL2) or notify-send (Linux).
# Runs asynchronously in background to avoid blocking hooks.
# Usage: notify "Message text"
notify() {
  local message="$1"
  (
    trap - EXIT # prevent duplicate metrics trap in subshell
    if command -v powershell.exe >/dev/null 2>&1; then
      powershell.exe -Command "
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        \$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(0)
        \$xml.GetElementsByTagName('text')[0].AppendChild(\$xml.CreateTextNode('$message')) | Out-Null
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show([Windows.UI.Notifications.ToastNotification]::new(\$xml))
      " 2>/dev/null || true
    elif command -v notify-send >/dev/null 2>&1; then
      notify-send "Claude Code" "$message" 2>/dev/null || true
    fi
  ) &
  disown $! 2>/dev/null || true
}

# --- Event Logger ---
# Appends a timestamped log entry to a file. Creates parent dirs if needed.
# Usage: log_event "/path/to/logfile" "message"
log_event() {
  local log_file="$1" message="$2"
  local timestamp
  timestamp="$(date -Iseconds 2>/dev/null || date)"
  mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
  printf '%s %s\n' "$timestamp" "$message" >>"$log_file" 2>/dev/null || true
}

# --- Input Parser ---
# Reads hook JSON input from stdin and sets global variables.
# Sets: HOOK_INPUT, HOOK_TOOL_NAME, HOOK_FILE_PATH
# Usage: parse_input (call once at top of hook script)
parse_input() {
  HOOK_INPUT=$(cat 2>/dev/null || true)
  HOOK_TOOL_NAME=$(printf '%s' "$HOOK_INPUT" | jq -r '.tool_name // ""' 2>/dev/null) || HOOK_TOOL_NAME=""
  HOOK_FILE_PATH=$(printf '%s' "$HOOK_INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""' 2>/dev/null) || HOOK_FILE_PATH=""
}

# --- Constants ---
readonly MAX_CONTENT_SIZE=1048576 # 1MB limit for secret scanning

# --- Hook Metrics (CLAUDE_FORGE_DEBUG=1 only) ---
# Records execution time of each hook that sources lib.sh.
# Uses millisecond-precision via date +%s%N + EXIT trap.
_hook_now_ms() {
  local ns
  ns=$(date +%s%N 2>/dev/null) || ns=""
  if [[ -n "$ns" && "$ns" != *N ]]; then
    printf '%s' "$((ns / 1000000))"
  else
    # macOS fallback: gdate or SECONDS*1000
    ns=$(gdate +%s%N 2>/dev/null) || ns=""
    if [[ -n "$ns" && "$ns" != *N ]]; then
      printf '%s' "$((ns / 1000000))"
    else
      printf '%s' "$((SECONDS * 1000))"
    fi
  fi
}
_HOOK_START_MS=$(_hook_now_ms)
_HOOK_SCRIPT_NAME="${BASH_SOURCE[1]:-unknown}"
_HOOK_SCRIPT_NAME="${_HOOK_SCRIPT_NAME##*/}" # basename only
_hook_metrics_trap() {
  if [[ "${CLAUDE_FORGE_DEBUG:-0}" == "1" ]]; then
    local elapsed=$(($(_hook_now_ms) - _HOOK_START_MS))
    printf '%s [METRIC] %s completed in %dms\n' \
      "$(date -Iseconds 2>/dev/null || date)" "$_HOOK_SCRIPT_NAME" "$elapsed" \
      >>"${HOME}/.claude/hooks-debug.log" 2>/dev/null || true
  fi
}
trap _hook_metrics_trap EXIT
