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

# --- JSON context builder (Setup/SessionStart) ---
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

# --- Constants ---
readonly MAX_CONTENT_SIZE=1048576 # 1MB limit for secret scanning
