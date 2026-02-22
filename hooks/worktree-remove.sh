#!/usr/bin/env bash
set -euo pipefail
# WorktreeRemove Hook — Best-effort worktree cleanup.
# This hook cannot block removal and must always exit 0.

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

main() {
  local input worktree_path session_id cwd hook_event_name
  local project_dir
  local -a remove_cmd

  input="$(cat 2>/dev/null || true)"
  worktree_path="$(printf '%s' "$input" | jq -r '.worktree_path // ""' 2>/dev/null || printf '')"
  session_id="$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null || printf 'unknown')"
  cwd="$(printf '%s' "$input" | jq -r '.cwd // ""' 2>/dev/null || printf '')"
  hook_event_name="$(printf '%s' "$input" | jq -r '.hook_event_name // "WorktreeRemove"' 2>/dev/null || printf 'WorktreeRemove')"

  log_event "${HOME}/.claude/hooks-debug.log" \
    "worktree_remove event=$hook_event_name session_id=$session_id path=$worktree_path cwd=$cwd"
  debug "worktree_remove: event=$hook_event_name session_id=$session_id path=$worktree_path cwd=$cwd"

  if [[ -z "$worktree_path" ]]; then
    log_event "${HOME}/.claude/hooks-debug.log" \
      "worktree_remove_skipped session_id=$session_id reason=missing_worktree_path"
    debug "worktree_remove: skipping cleanup (missing worktree_path)"
    exit 0
  fi

  project_dir="$(cd "$cwd" && pwd 2>/dev/null || printf '%s' "$cwd")"

  if [[ -n "${CLAUDE_FORGE_VCS_WORKTREE_REMOVE_CMD:-}" ]]; then
    read -r -a remove_cmd <<<"${CLAUDE_FORGE_VCS_WORKTREE_REMOVE_CMD}"
    if [[ "${#remove_cmd[@]}" -eq 0 ]]; then
      log_event "${HOME}/.claude/hooks-debug.log" \
        "worktree_remove_failed session_id=$session_id path=$worktree_path reason=invalid_custom_cmd"
      debug "worktree_remove: invalid CLAUDE_FORGE_VCS_WORKTREE_REMOVE_CMD"
      exit 0
    fi

    debug "worktree_remove: using custom command ${CLAUDE_FORGE_VCS_WORKTREE_REMOVE_CMD} for path=$worktree_path"
    if ! "${remove_cmd[@]}" "$worktree_path" >>"${HOME}/.claude/hooks-debug.log" 2>&1; then
      log_event "${HOME}/.claude/hooks-debug.log" \
        "worktree_remove_failed session_id=$session_id path=$worktree_path reason=custom_cmd_failed"
      debug "worktree_remove: custom command failed for path=$worktree_path"
      exit 0
    fi
  else
    debug "worktree_remove: git -C $project_dir worktree remove $worktree_path --force"
    if ! git -C "$project_dir" worktree remove "$worktree_path" --force >>"${HOME}/.claude/hooks-debug.log" 2>&1; then
      log_event "${HOME}/.claude/hooks-debug.log" \
        "worktree_remove_failed session_id=$session_id path=$worktree_path reason=git_worktree_remove_failed"
      debug "worktree_remove: git worktree remove failed for path=$worktree_path"
      exit 0
    fi
  fi

  log_event "${HOME}/.claude/hooks-debug.log" \
    "worktree_remove_success session_id=$session_id path=$worktree_path"
  debug "worktree_remove: cleanup complete for path=$worktree_path"
  exit 0
}

main "$@"
