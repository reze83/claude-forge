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

# is_transient_error <stderr_output> <exit_code> [timeout_value]
# Returns 0 if the error is transient and worth retrying, 1 otherwise.
# Transient: connection errors, DNS failures, HTTP 502/503/504, short timeouts.
# NOT transient: auth failures, rate limits, invalid prompts.
is_transient_error() {
  local stderr="${1-}"
  local exit_code="${2-}"
  local timeout_value="${3-}"

  # Never retry auth/rate-limit errors
  if printf '%s\n' "$stderr" | grep -qiE '(auth(entication)? (failed|failure)|unauthorized|forbidden|access denied|invalid (api key|token|credentials|prompt)|rate[ -]?limit|too many requests|(^|[^0-9])429([^0-9]|$))'; then
    return 1
  fi

  # Timeout: only retry if timeout was short (< 60s)
  if [[ "$exit_code" == "124" ]]; then
    if [[ "$timeout_value" =~ ^[0-9]+$ ]] && ((timeout_value < 60)); then
      return 0
    fi
    return 1
  fi

  # Connection/DNS/HTTP 5xx errors
  if printf '%s\n' "$stderr" | grep -qiE '(connection refused|connection reset|dns resolution failure|temporary failure in name resolution|name or service not known|could not resolve host|http[^0-9]*(502|503|504)|(^|[^0-9])(502|503|504)([^0-9]|$))'; then
    return 0
  fi

  return 1
}
