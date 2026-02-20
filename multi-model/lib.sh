#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Multi-Model Shared Functions
# Sourced by codex-wrapper.sh and available for command scripts.
# ============================================================

# render_template <template-file> [key=value ...]
# Reads a template file, substitutes {{key}} placeholders with values,
# warns about unsubstituted placeholders on stderr,
# prints the rendered result to stdout.
# Returns 1 if template file is missing.
render_template() {
  local template_file="$1"
  if [[ -z "$template_file" || ! -f "$template_file" ]]; then
    printf 'render_template: file not found: %s\n' "${template_file:-""}" >&2
    return 1
  fi
  shift || true

  local -a sed_args=()
  local kv key value key_esc value_esc

  for kv in "$@"; do
    case "$kv" in
      *=*)
        key="${kv%%=*}"
        value="${kv#*=}"
        ;;
      *) continue ;;
    esac

    # Escape sed special chars: use | as delimiter to avoid escaping /
    key_esc="$(printf '%s' "$key" | sed 's/[][\\.^$*|]/\\&/g')"
    value_esc="$(printf '%s' "$value" | sed 's/[\\&|]/\\&/g')"
    sed_args+=(-e "s|{{${key_esc}}}|${value_esc}|g")
  done

  local rendered
  if [[ ${#sed_args[@]} -gt 0 ]]; then
    rendered="$(sed "${sed_args[@]}" "$template_file")"
  else
    rendered="$(cat "$template_file")"
  fi

  # Warn about unsubstituted placeholders
  local ph
  printf '%s' "$rendered" |
    grep -oE '\{\{[^{}]+\}\}' 2>/dev/null |
    sort -u |
    while IFS= read -r ph; do
      [[ -n "$ph" ]] && printf 'warning: unsubstituted placeholder %s\n' "$ph" >&2
    done

  printf '%s\n' "$rendered"
}
