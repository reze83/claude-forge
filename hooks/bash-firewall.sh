#!/usr/bin/env bash
set -euo pipefail
# PreToolUse Hook — Bash Firewall
# Reads JSON from stdin, checks command against deny patterns.
# Output: JSON on stdout (exit 0 ensures JSON is processed by Claude Code)
# Compatible: Bash 3.2+ (macOS) and Bash 4+

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

INPUT=$(cat 2>/dev/null || true)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null) || CMD=""

# --- Input normalization (strips absolute paths, prefixes, excess whitespace) ---
normalize_cmd() {
  local cmd="$1"

  # Collapse whitespace and trim
  cmd="$(printf '%s' "$cmd" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"
  [[ -z "$cmd" ]] && {
    printf ''
    return
  }

  # Split into array
  local -a parts
  read -r -a parts <<<"$cmd"

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
  'git\s+push\s+.*(-f\b|--force\b|--force-with-lease)'
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
  '\b(nano|vi|vim|emacs)\s+'
  'pip\s+install\s+.*--break-system-packages'
  '\bmkfs\b'
  '\bdd\s+.*of=/dev/'
  '\b(bash|sh)\s+-c\s+'
  '\$\([^)]*(rm\s+-rf\s+(/|~|\$HOME|\.\.?/)|eval\s+|(bash|sh)\s+-c\s+)'
  '`[^`]*(rm\s+-rf\s+(/|~|\$HOME|\.\.?/)|eval\s+|(bash|sh)\s+-c\s+)`'
  '[<>]\([^)]*(rm\s+-rf\s+(/|~|\$HOME|\.\.?/)|eval\s+|(bash|sh)\s+-c\s+)'
  '\|\s*(/[a-z/]*/)?\.?(bash|sh)(\s|$)'
  '(bash|sh)\s*<<<'
)

DENY_REASONS=(
  "rm -rf / not allowed. Use rm on specific files instead."
  "rm -rf ~ not allowed. Use rm on specific files instead."
  "rm -rf ./ or ../ not allowed. Use rm on specific files instead."
  "rm with separated -r/-f flags on critical paths not allowed. Use rm on specific files."
  "Force-push (--force/--force-with-lease) forbidden. Use: git push origin <branch>"
  "Push via refspec to main/master forbidden. Use feature branch + PR."
  "command/env prefix with rm/eval/bash/sh not allowed. Run commands directly."
  "exec with rm/bash/sh not allowed. Run commands directly."
  "Push to main/master forbidden. Use feature branch + PR."
  "git reset --hard is destructive. Use: git stash or git checkout <file>"
  "git commit --amend changes history. Use: git commit (new commit)"
  "Writing to /etc/ not allowed. Edit config files in project directory."
  "chmod 777/666 insecure. Use: chmod 755 (exec) or chmod 644 (files)"
  "chmod a+rwx too permissive. Use: chmod u+x or specific permissions"
  "eval is a security risk. Run commands directly or use a function."
  "source from /dev/ not allowed"
  "Interactive editors not supported. Use Read/Write/Edit tools instead."
  "pip --break-system-packages not allowed. Use: python -m venv .venv"
  "mkfs formats disks destructively. Not allowed."
  "dd writing to /dev/ is destructive. Not allowed."
  "bash -c / sh -c not allowed. Run commands directly."
  "Dangerous command inside command substitution. Run commands directly."
  "Dangerous command inside backtick substitution. Use $() syntax instead."
  "Dangerous command inside process substitution. Run commands directly."
  "Piping output into bash/sh not allowed. Run commands directly."
  "Herestring into bash/sh not allowed. Run commands directly."
)

# Check both original and normalized command against built-in patterns
# Built-in patterns always use block() — never bypassable via dry-run
for i in "${!DENY_PATTERNS[@]}"; do
  if echo "$CMD" | grep -Eiq "${DENY_PATTERNS[$i]}"; then
    block "${DENY_REASONS[$i]}"
  fi
  if echo "$CMD_NORM" | grep -Eiq "${DENY_PATTERNS[$i]}"; then
    block "${DENY_REASONS[$i]}"
  fi
done

# Check local deny patterns (user overrides from ~/.claude/local-patterns.sh)
# Local patterns use block_or_warn() — supports dry-run for testing custom rules
if [[ ${#LOCAL_DENY_PATTERNS[@]} -gt 0 && ${#LOCAL_DENY_PATTERNS[@]} -eq ${#LOCAL_DENY_REASONS[@]} ]]; then
  for i in "${!LOCAL_DENY_PATTERNS[@]}"; do
    if echo "$CMD" | grep -Eiq "${LOCAL_DENY_PATTERNS[$i]}" 2>/dev/null; then
      block_or_warn "${LOCAL_DENY_REASONS[$i]}"
    fi
    if echo "$CMD_NORM" | grep -Eiq "${LOCAL_DENY_PATTERNS[$i]}" 2>/dev/null; then
      block_or_warn "${LOCAL_DENY_REASONS[$i]}"
    fi
  done
fi

exit 0
