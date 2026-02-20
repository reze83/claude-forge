#!/usr/bin/env bash
set -euo pipefail
# UserPromptSubmit Hook — Smithery Context Injector
# Reads connected Smithery servers and injects them as additionalContext.
# No network call — reads only local Smithery configuration.
# Compatible: Bash 3.2+

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

main() {
  # Drain stdin (prompt input not needed)
  cat >/dev/null 2>&1 || true

  # Check smithery CLI — exit gracefully if not installed
  command -v smithery >/dev/null 2>&1 || exit 0

  # Query connected servers from local config (no network)
  local servers_json
  servers_json=$(smithery mcp list 2>/dev/null) || exit 0
  [[ -z "$servers_json" ]] && exit 0

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
