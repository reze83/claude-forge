#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

main() {
  local input session_id source_name model script_dir forge_dir version hooks_file active_hooks context_json

  input="$(cat 2>/dev/null || true)"
  session_id="$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null || printf 'unknown')"
  source_name="$(printf '%s' "$input" | jq -r '.source // "unknown"' 2>/dev/null || printf 'unknown')"
  model="$(printf '%s' "$input" | jq -r '.model // "unknown"' 2>/dev/null || printf 'unknown')"

  log_event "${HOME}/.claude/session-log.txt" \
    "session_start session_id=$session_id source=$source_name model=$model"

  script_dir="$(cd "$(dirname "$0")" && pwd)"
  forge_dir="$(cd "$script_dir/.." && pwd 2>/dev/null || printf '%s' "$script_dir")"
  version="unknown"
  if [[ -f "$forge_dir/VERSION" ]]; then
    version="$(sed -n '1p' "$forge_dir/VERSION" 2>/dev/null || printf 'unknown')"
    printf 'claude-forge version: %s\n' "$version" >&2 || true
  fi

  hooks_file="$script_dir/hooks.json"
  active_hooks="none"
  if [[ -f "$hooks_file" ]]; then
    active_hooks="$(jq -r '.hooks | keys | join(", ")' "$hooks_file" 2>/dev/null || printf 'unknown')"
  fi

  # Persist forge-specific env vars for the session via CLAUDE_ENV_FILE
  if [[ -n "${CLAUDE_ENV_FILE:-}" ]]; then
    printf 'export CLAUDE_FORGE_VERSION="%s"\n' "$version" >>"$CLAUDE_ENV_FILE"
    printf 'export CLAUDE_FORGE_ACTIVE_HOOKS="%s"\n' "$active_hooks" >>"$CLAUDE_ENV_FILE"
  fi

  context_json="$(jq -cn --arg version "$version" --arg active_hooks "$active_hooks" '{forgeVersion:$version,activeHooks:$active_hooks}' 2>/dev/null || printf '{"forgeVersion":"unknown","activeHooks":"unknown"}')"
  printf '{"additionalContext":%s}\n' "$context_json"

  exit 0
}

main "$@"
