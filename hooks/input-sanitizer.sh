#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

strip_ansi_escape_codes() {
  local command="$1"
  local esc
  esc="$(printf '\033')"
  printf '%s' "$command" | sed -E "s/${esc}\\[[0-9;]*[[:alpha:]]//g"
}

normalize_file_path() {
  local file_path="$1"
  local normalized
  normalized="$(printf '%s' "$file_path" | sed -E 's#://#__CLAUDE_FORGE_PROTO__#g; s#/+#/#g; s#__CLAUDE_FORGE_PROTO__#://#g')"
  if [[ "$normalized" != "/" ]]; then
    normalized="$(printf '%s' "$normalized" | sed -E 's#/*$##')"
  fi
  printf '%s' "$normalized"
}

has_utf8_bom() {
  local text="$1"
  local prefix_hex
  prefix_hex="$(printf '%s' "$text" | head -c 3 | od -An -tx1 2>/dev/null | tr -d ' \n')"
  [[ "$prefix_hex" == "efbbbf" ]]
}

sanitize_content_value() {
  local content="$1"
  if has_utf8_bom "$content"; then
    printf '%s' "$content" | tail -c +4 | tr -d '\r'
  else
    printf '%s' "$content" | tr -d '\r'
  fi
}

build_updated_input() {
  local tool_input_json="$1"
  local field_name="$2"
  local field_value="$3"

  jq -cn \
    --arg tool_input "$tool_input_json" \
    --arg field_name "$field_name" \
    --arg field_value "$field_value" \
    '($tool_input | fromjson) | .[$field_name] = $field_value'
}

sanitize_write_or_edit() {
  local tool_input_json="$1"
  local content_field="$2"
  local file_path content sanitized_file_path sanitized_content updated_input

  file_path="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || printf '')"
  IFS= read -r -d '' content < <(
    printf '%s' "$INPUT" | jq -j --arg field "$content_field" '(.tool_input[$field] // ""), "\u0000"' 2>/dev/null ||
      printf '\0'
  )

  sanitized_file_path="$(normalize_file_path "$file_path")"
  IFS= read -r -d '' sanitized_content < <(
    sanitize_content_value "$content"
    printf '\0'
  )

  if [[ "$sanitized_file_path" == "$file_path" && "$sanitized_content" == "$content" ]]; then
    exit 0
  fi

  updated_input="$(jq -cn \
    --arg tool_input "$tool_input_json" \
    --arg file_path "$sanitized_file_path" \
    --arg content_field "$content_field" \
    --arg content_value "$sanitized_content" \
    '($tool_input | fromjson)
     | .file_path = $file_path
     | .[$content_field] = $content_value')"

  modify_input "$updated_input"
}

INPUT=$(cat 2>/dev/null || true)
TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null) || TOOL_NAME=""
[[ -z "$TOOL_NAME" ]] && exit 0

TOOL_INPUT_JSON=$(printf '%s' "$INPUT" | jq -c '.tool_input // {}' 2>/dev/null || printf '{}')

case "$TOOL_NAME" in
  Bash)
    COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || printf '')
    SANITIZED_COMMAND=$(strip_ansi_escape_codes "$COMMAND")
    [[ "$SANITIZED_COMMAND" == "$COMMAND" ]] && exit 0
    UPDATED_INPUT=$(build_updated_input "$TOOL_INPUT_JSON" "command" "$SANITIZED_COMMAND")
    modify_input "$UPDATED_INPUT"
    ;;
  Write)
    sanitize_write_or_edit "$TOOL_INPUT_JSON" "content"
    ;;
  Edit)
    sanitize_write_or_edit "$TOOL_INPUT_JSON" "new_string"
    ;;
  *)
    exit 0
    ;;
esac
