#!/usr/bin/env bash
set -euo pipefail
# UserPromptSubmit Hook — Smithery Context Injector
# Reads connected Smithery servers and injects them as additionalContext.
# Uses TTL-based cache to avoid slow `smithery mcp list` on every prompt.
# Compatible: Bash 3.2+

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

# Cache config (env-overridable for tests)
_SMITHERY_CACHE_FILE="${SMITHERY_CACHE_FILE:-${XDG_RUNTIME_DIR:-/tmp}/claude-forge-smithery-cache.json}"
_SMITHERY_CACHE_TTL="${SMITHERY_CACHE_TTL:-60}"

# Portable mtime in epoch seconds
_smithery_mtime() {
  stat -c '%Y' "$1" 2>/dev/null || stat -f '%m' "$1" 2>/dev/null || printf '0'
}

# Check if cache file exists and is within TTL
_smithery_cache_valid() {
  [[ -f "$_SMITHERY_CACHE_FILE" ]] || return 1
  local now mtime age
  now=$(date +%s)
  mtime=$(_smithery_mtime "$_SMITHERY_CACHE_FILE")
  age=$((now - mtime))
  [[ "$age" -lt "$_SMITHERY_CACHE_TTL" ]]
}

main() {
  # Drain stdin (prompt input not needed)
  cat >/dev/null 2>&1 || true

  # Check smithery CLI — exit gracefully if not installed
  command -v smithery >/dev/null 2>&1 || exit 0

  # Try cache first, fall back to CLI
  local servers_json
  if _smithery_cache_valid; then
    servers_json=$(cat "$_SMITHERY_CACHE_FILE" 2>/dev/null) || servers_json=""
  fi

  if [[ -z "${servers_json:-}" ]]; then
    servers_json=$(smithery mcp list 2>/dev/null) || exit 0
    [[ -z "$servers_json" ]] && exit 0
    # Atomic write: tmp file + mv
    local cache_dir
    cache_dir=$(dirname "$_SMITHERY_CACHE_FILE")
    mkdir -p "$cache_dir" 2>/dev/null || true
    printf '%s' "$servers_json" >"${_SMITHERY_CACHE_FILE}.tmp" 2>/dev/null &&
      mv "${_SMITHERY_CACHE_FILE}.tmp" "$_SMITHERY_CACHE_FILE" 2>/dev/null || true
  fi

  local count
  count=$(printf '%s' "$servers_json" | jq '.total // 0' 2>/dev/null) || exit 0
  [[ "$count" -eq 0 ]] && exit 0

  # Extract only connected servers (name + id)
  local names ids
  names=$(printf '%s' "$servers_json" |
    jq -r '[.servers[] | select(.status=="connected") | .name] | join(", ")' 2>/dev/null) || exit 0
  ids=$(printf '%s' "$servers_json" |
    jq -r '[.servers[] | select(.status=="connected") | .id] | join(", ")' 2>/dev/null) || exit 0

  [[ -z "$names" ]] && exit 0

  # Check if Sequential Thinking is registered as native MCP server
  local has_st="false"
  local mcp_json="$HOME/.claude/.mcp.json"
  if [[ -f "$mcp_json" ]] && jq -e '."sequential-thinking"' "$mcp_json" >/dev/null 2>&1; then
    has_st="true"
  fi
  # Also check project-scope .mcp.json (mcpServers wrapper)
  if [[ "$has_st" == "false" && -f ".mcp.json" ]] && jq -e '.["sequential-thinking"] // .mcpServers["sequential-thinking"]' ".mcp.json" >/dev/null 2>&1; then
    has_st="true"
  fi

  local ctx
  ctx=$(context "smithery_connected" "$names" "smithery_ids" "$ids" "sequential_thinking_mcp" "$has_st")
  printf '{"additionalContext":%s}\n' "$ctx"
}

main "$@"
