#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

# --- Helpers ---

has_command() {
  command -v "$1" >/dev/null 2>&1
}

check_node_version() {
  local version major
  version="$(node --version 2>/dev/null || true)"
  version="${version#v}"
  major="${version%%.*}"
  if [[ -n "$major" ]] && [[ "$major" -ge 20 ]]; then
    return 0
  fi
  return 1
}

check_python_version() {
  local version major minor
  version="$(python3 --version 2>/dev/null | sed 's/Python //' || true)"
  major="${version%%.*}"
  minor="${version#*.}"
  minor="${minor%%.*}"
  if [[ -n "$major" ]] && [[ -n "$minor" ]] &&
    [[ "$major" -gt 3 || ("$major" -eq 3 && "$minor" -ge 10) ]]; then
    return 0
  fi
  return 1
}

# --- Main ---

main() {
  local script_dir forge_dir version
  local dep_status="ok" dep_missing="" symlink_status="ok" symlink_broken=""

  # Drain stdin (hook receives JSON on stdin)
  cat >/dev/null 2>&1 || true

  script_dir="$(cd "$(dirname "$0")" && pwd)"
  forge_dir="$(cd "$script_dir/.." && pwd 2>/dev/null || printf '%s' "$script_dir")"

  # --- Version ---
  version="unknown"
  if [[ -f "$forge_dir/VERSION" ]]; then
    version="$(sed -n '1p' "$forge_dir/VERSION" 2>/dev/null || printf 'unknown')"
  fi

  # --- Dependency checks ---
  local deps=("git" "jq" "node" "python3")
  for dep in "${deps[@]}"; do
    if ! has_command "$dep"; then
      dep_status="missing"
      dep_missing="${dep_missing:+${dep_missing}, }${dep}"
    fi
  done

  if has_command node && ! check_node_version; then
    dep_status="outdated"
    dep_missing="${dep_missing:+${dep_missing}, }node<20"
  fi

  if has_command python3 && ! check_python_version; then
    dep_status="outdated"
    dep_missing="${dep_missing:+${dep_missing}, }python3<3.10"
  fi

  # --- Link health (hardlinks + symlinks) ---
  local link_dirs=("hooks" "rules" "commands")
  for dir in "${link_dirs[@]}"; do
    local target="$HOME/.claude/$dir"
    if [[ ! -d "$target" ]]; then
      symlink_status="missing"
      symlink_broken="${symlink_broken:+${symlink_broken}, }${dir}"
    elif [[ -z "$(ls -A "$target" 2>/dev/null)" ]]; then
      symlink_status="broken"
      symlink_broken="${symlink_broken:+${symlink_broken}, }${dir}"
    fi
  done

  # --- Output ---
  local context_json
  context_json="$(
    context \
      "forgeVersion" "$version" \
      "dependencies" "$dep_status" \
      "symlinkHealth" "$symlink_status" \
      "depMissing" "$dep_missing" \
      "symlinkBroken" "$symlink_broken"
  )"
  printf '{"additionalContext":%s}\n' "$context_json"

  exit 0
}

main "$@"
