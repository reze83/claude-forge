#!/usr/bin/env bash
set -euo pipefail
# WorktreeCreate Hook — Create a new worktree and return its path.
# This hook replaces default worktree creation behavior.

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

main() {
  local input name session_id cwd hook_event_name
  local project_dir worktree_dir worktree_parent worktree_path
  local -a worktree_cmd

  input="$(cat 2>/dev/null || true)"
  name="$(printf '%s' "$input" | jq -r '.name // ""' 2>/dev/null || printf '')"
  session_id="$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null || printf 'unknown')"
  cwd="$(printf '%s' "$input" | jq -r '.cwd // ""' 2>/dev/null || printf '')"
  hook_event_name="$(printf '%s' "$input" | jq -r '.hook_event_name // "WorktreeCreate"' 2>/dev/null || printf 'WorktreeCreate')"

  log_event "${HOME}/.claude/hooks-debug.log" \
    "worktree_create event=$hook_event_name session_id=$session_id name=$name cwd=$cwd"
  debug "worktree_create: event=$hook_event_name session_id=$session_id name=$name cwd=$cwd"

  if [[ -z "$name" || -z "$cwd" ]]; then
    printf 'worktree-create: missing required input fields (name/cwd)\n' >&2
    log_event "${HOME}/.claude/hooks-debug.log" \
      "worktree_create_failed session_id=$session_id reason=missing_input"
    exit 1
  fi

  project_dir="$(cd "$cwd" && pwd 2>/dev/null || printf '%s' "$cwd")"

  if [[ -n "${CLAUDE_FORGE_VCS_WORKTREE_CMD:-}" ]]; then
    read -r -a worktree_cmd <<<"${CLAUDE_FORGE_VCS_WORKTREE_CMD}"
    if [[ "${#worktree_cmd[@]}" -eq 0 ]]; then
      printf 'worktree-create: CLAUDE_FORGE_VCS_WORKTREE_CMD is invalid\n' >&2
      log_event "${HOME}/.claude/hooks-debug.log" \
        "worktree_create_failed session_id=$session_id name=$name reason=invalid_custom_cmd"
      exit 1
    fi

    debug "worktree_create: using custom command ${CLAUDE_FORGE_VCS_WORKTREE_CMD} for name=$name"
    if ! worktree_path="$("${worktree_cmd[@]}" "$name" 2>>"${HOME}/.claude/hooks-debug.log")"; then
      printf 'worktree-create: custom command failed for name=%s\n' "$name" >&2
      log_event "${HOME}/.claude/hooks-debug.log" \
        "worktree_create_failed session_id=$session_id name=$name reason=custom_cmd_failed"
      exit 1
    fi
  else
    worktree_dir="$project_dir/.claude/worktrees/$name"
    worktree_parent="$(dirname "$worktree_dir")"
    mkdir -p "$worktree_parent"

    debug "worktree_create: git -C $project_dir worktree add $worktree_dir -b worktree/$name"
    if ! git -C "$project_dir" worktree add "$worktree_dir" -b "worktree/$name" >/dev/null 2>>"${HOME}/.claude/hooks-debug.log"; then
      printf 'worktree-create: failed to create worktree at %s\n' "$worktree_dir" >&2
      log_event "${HOME}/.claude/hooks-debug.log" \
        "worktree_create_failed session_id=$session_id name=$name path=$worktree_dir reason=git_worktree_add_failed"
      exit 1
    fi

    worktree_path="$(cd "$worktree_dir" && pwd 2>/dev/null || printf '%s' "$worktree_dir")"
  fi

  if [[ -z "$worktree_path" ]]; then
    printf 'worktree-create: empty worktree path returned\n' >&2
    log_event "${HOME}/.claude/hooks-debug.log" \
      "worktree_create_failed session_id=$session_id name=$name reason=empty_worktree_path"
    exit 1
  fi

  if [[ "$worktree_path" != /* ]]; then
    worktree_path="$project_dir/$worktree_path"
  fi

  log_event "${HOME}/.claude/hooks-debug.log" \
    "worktree_create_success session_id=$session_id name=$name path=$worktree_path"
  debug "worktree_create: created path=$worktree_path"
  printf '%s\n' "$worktree_path"
  exit 0
}

main "$@"
