#!/usr/bin/env bash
set -euo pipefail
# PreToolUse Hook — Bash Firewall
# Reads JSON from stdin, checks command against deny patterns.
# Output: JSON on stdout (modern format) + Exit 2 (legacy fallback)
# Compatible: Bash 3.2+ (macOS) and Bash 4+

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# --- Input normalization (strips absolute paths, prefixes, excess whitespace) ---
normalize_cmd() {
  local cmd="$1"

  # Collapse whitespace and trim
  cmd="$(printf '%s' "$cmd" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"
  [[ -z "$cmd" ]] && { printf ''; return; }

  # Split into array
  local -a parts
  read -r -a parts <<< "$cmd"

  # Strip command/exec prefix (shift to actual command)
  local idx=0
  if [[ "${parts[0]}" == "command" || "${parts[0]}" == "exec" ]]; then
    idx=1
  elif [[ "${parts[0]}" == "env" ]]; then
    local i
    for ((i = 1; i < ${#parts[@]}; i++)); do
      if [[ "${parts[$i]}" != *=* ]]; then
        idx=$i
        break
      fi
    done
  fi

  # Strip absolute path from the command itself (/usr/bin/rm -> rm)
  if [[ "$idx" -lt "${#parts[@]}" ]]; then
    if [[ "${parts[$idx]}" == /* && "${parts[$idx]}" != "/" ]]; then
      parts[$idx]="${parts[$idx]##*/}"
    fi
  fi

  printf '%s' "${parts[*]}"
}

CMD_NORM="$(normalize_cmd "$CMD")"

debug "bash-firewall: original='$CMD' normalized='$CMD_NORM'"

# --- Deny patterns (ERE, portable — no PCRE) ---
DENY_PATTERNS=(
  'rm\s+-rf\s+/'
  'rm\s+-rf\s+(~|\$HOME)'
  'rm\s+-rf\s+(\.|\.\.\/)'
  'rm\s+(-[a-z]*r[a-z]*\s+-[a-z]*f[a-z]*|-[a-z]*f[a-z]*\s+-[a-z]*r[a-z]*)\s+(/|\$HOME|~|\.\.?/)'
  'git\s+push\s+(-f|--force)\s+\S+\s+(main|master)'
  'git\s+push\s+\S+\s+\S+:(main|master)'
  '(command|env)\s+(rm|eval|bash|sh)\s'
  'exec\s+(rm|bash|sh)\s'
  'git\s+push.*\s+(main|master)(\s|$)'
  'git\s+reset\s+--hard'
  'git\s+commit\s+.*--amend'
  '>\s*/etc/'
  'chmod\s+0?(777|666)'
  'chmod\s+a\+[rwx]'
  '\beval\s+'
  '\bsource\s+/dev/'
  '\bnano\s+'
  '\bvi\s+'
  'pip\s+install\s+.*--break-system-packages'
  '\b(bash|sh)\s+-c\s+'
  '\$\([^)]*(rm\s+-rf\s+(/|~|\$HOME|\.\.?/)|eval\s+|(bash|sh)\s+-c\s+)'
  '`[^`]*(rm\s+-rf\s+(/|~|\$HOME|\.\.?/)|eval\s+|(bash|sh)\s+-c\s+)`'
  '[<>]\([^)]*(rm\s+-rf\s+(/|~|\$HOME|\.\.?/)|eval\s+|(bash|sh)\s+-c\s+)'
  '\|\s*(/[a-z/]*/)?\.?(bash|sh)(\s|$)'
  '(bash|sh)\s*<<<'
)

DENY_REASONS=(
  "rm -rf / not allowed"
  "rm -rf ~ not allowed"
  "rm -rf ./ or ../ not allowed"
  "rm with separated -r/-f flags on critical paths not allowed"
  "Force-push to main/master forbidden. Use feature branch + PR."
  "Push via refspec to main/master forbidden. Use feature branch + PR."
  "command/env prefix with rm/eval/bash/sh not allowed"
  "exec with rm/bash/sh not allowed"
  "Push to main/master forbidden. Use feature branch + PR."
  "git reset --hard is destructive. Use git stash."
  "git commit --amend changes history. Create a new commit."
  "Writing to /etc/ not allowed"
  "chmod 777/666 insecure"
  "chmod a+rwx too permissive"
  "eval is a security risk"
  "source from /dev/ not allowed"
  "Interactive editors not supported"
  "Interactive editors not supported"
  "pip --break-system-packages not allowed. Use venv."
  "bash -c / sh -c not allowed. Run commands directly."
  "Dangerous command inside command substitution not allowed"
  "Dangerous command inside backtick substitution not allowed"
  "Dangerous command inside process substitution not allowed"
  "Piping output into bash/sh not allowed"
  "Herestring into bash/sh not allowed"
)

# Check both original and normalized command against all patterns
for i in "${!DENY_PATTERNS[@]}"; do
  if echo "$CMD" | grep -Eiq "${DENY_PATTERNS[$i]}"; then
    block "${DENY_REASONS[$i]}"
  fi
  if echo "$CMD_NORM" | grep -Eiq "${DENY_PATTERNS[$i]}"; then
    block "${DENY_REASONS[$i]}"
  fi
done

exit 0
