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
# rm uses 4 patterns to cover all flag-order and target combinations:
#   [[:alpha:]]* instead of [a-z] — POSIX character class, portable on macOS Bash 3.2+
#   Optional intermediate flags group ([[:space:]]+(--|-flag|--long-flag))* handles
#   `rm -rf -- /`, `rm -rf --no-preserve-root /`, and similar variants.
#   Patterns 1-3: combined flags (-rf or -fr). Pattern 4: separated flags (-r -f or -f -r).
DENY_PATTERNS=(
  # combined flags, root filesystem only (/) — specific project paths allowed
  'rm[[:space:]]+(-[[:alpha:]]*r[[:alpha:]]*f[[:alpha:]]*|-[[:alpha:]]*f[[:alpha:]]*r[[:alpha:]]*)([[:space:]]+(--|-[[:alpha:]]+|--[[:alnum:]-]+))*[[:space:]]+/([[:space:]]|$)'
  # combined flags, system critical directories (depth 1)
  'rm[[:space:]]+(-[[:alpha:]]*r[[:alpha:]]*f[[:alpha:]]*|-[[:alpha:]]*f[[:alpha:]]*r[[:alpha:]]*)([[:space:]]+(--|-[[:alpha:]]+|--[[:alnum:]-]+))*[[:space:]]+/(etc|usr|var|bin|sbin|lib|lib64|boot|sys|proc|dev|opt|srv|run|snap|root)([[:space:]]|$|/[^/[:space:]]*([[:space:]]|$))'
  # combined flags, home directory target (~ or $HOME)
  'rm[[:space:]]+(-[[:alpha:]]*r[[:alpha:]]*f[[:alpha:]]*|-[[:alpha:]]*f[[:alpha:]]*r[[:alpha:]]*)([[:space:]]+(--|-[[:alpha:]]+|--[[:alnum:]-]+))*[[:space:]]+(~|\$HOME)'
  # combined flags, relative target (. or ../)
  'rm[[:space:]]+(-[[:alpha:]]*r[[:alpha:]]*f[[:alpha:]]*|-[[:alpha:]]*f[[:alpha:]]*r[[:alpha:]]*)([[:space:]]+(--|-[[:alpha:]]+|--[[:alnum:]-]+))*[[:space:]]+(\.|\.\.\/)'
  # separated flags (-r -f or -f -r) on critical paths — catches `rm -r -f /`
  'rm[[:space:]]+(-[[:alpha:]]*r[[:alpha:]]*[[:space:]]+-[[:alpha:]]*f[[:alpha:]]*|-[[:alpha:]]*f[[:alpha:]]*[[:space:]]+-[[:alpha:]]*r[[:alpha:]]*)([[:space:]]+(--|-[[:alpha:]]+|--[[:alnum:]-]+))*[[:space:]]+(/|\$HOME|~|\.\.?/)'
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
  'python[0-9.]*\s+-c\s+'
  'node(js)?\s+-e\s+'
  'perl[0-9.]*\s+-e\s+'
  'ruby[0-9.]*\s+-e\s+'
)

DENY_REASONS=(
  "rm -rf / (root) not allowed. Use rm on specific project directories instead."
  "rm -rf on system directory not allowed. Use rm on specific project directories instead."
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
  "python -c not allowed. Use a .py script file instead."
  "node/nodejs -e not allowed. Use a .js script file instead."
  "perl -e not allowed. Use a .pl script file instead."
  "ruby -e not allowed. Use a .rb script file instead."
)

# Check both original and normalized command against built-in patterns
# Built-in patterns always use block() — never bypassable via dry-run
# Performance: build alternation for quick-check (2 grep calls instead of 60)
deny_alt=""
for i in "${!DENY_PATTERNS[@]}"; do
  if [[ -z "$deny_alt" ]]; then
    deny_alt="${DENY_PATTERNS[$i]}"
  else
    deny_alt="${deny_alt}|${DENY_PATTERNS[$i]}"
  fi
done

# Two-pass check: raw CMD first, then normalized CMD_NORM.
# Raw pass catches patterns visible in the original input (e.g. backtick substitutions,
# process substitutions) that normalize_cmd does not fully strip.
# Normalized pass catches patterns that only emerge after prefix removal
# (e.g. `command rm -rf /` → CMD_NORM=`rm -rf /`).
# Both passes are required: normalization can reveal new matches while also
# eliminating some surface-level patterns from the raw form.
if echo "$CMD" | grep -Eiq "$deny_alt"; then
  for i in "${!DENY_PATTERNS[@]}"; do
    if echo "$CMD" | grep -Eiq "${DENY_PATTERNS[$i]}"; then
      block "${DENY_REASONS[$i]}"
    fi
  done
fi
if echo "$CMD_NORM" | grep -Eiq "$deny_alt"; then
  for i in "${!DENY_PATTERNS[@]}"; do
    if echo "$CMD_NORM" | grep -Eiq "${DENY_PATTERNS[$i]}"; then
      block "${DENY_REASONS[$i]}"
    fi
  done
fi

# Check local deny patterns (user overrides from ~/.claude/local-patterns.sh)
# Local patterns use block_or_warn() — supports dry-run for testing custom rules
if [[ ${#LOCAL_DENY_PATTERNS[@]} -gt 0 && ${#LOCAL_DENY_PATTERNS[@]} -eq ${#LOCAL_DENY_REASONS[@]} ]]; then
  local_deny_alt=""
  for i in "${!LOCAL_DENY_PATTERNS[@]}"; do
    if [[ -z "$local_deny_alt" ]]; then
      local_deny_alt="${LOCAL_DENY_PATTERNS[$i]}"
    else
      local_deny_alt="${local_deny_alt}|${LOCAL_DENY_PATTERNS[$i]}"
    fi
  done

  if echo "$CMD" | grep -Eiq "$local_deny_alt" 2>/dev/null; then
    for i in "${!LOCAL_DENY_PATTERNS[@]}"; do
      if echo "$CMD" | grep -Eiq "${LOCAL_DENY_PATTERNS[$i]}" 2>/dev/null; then
        block_or_warn "${LOCAL_DENY_REASONS[$i]}"
      fi
    done
  fi
  if echo "$CMD_NORM" | grep -Eiq "$local_deny_alt" 2>/dev/null; then
    for i in "${!LOCAL_DENY_PATTERNS[@]}"; do
      if echo "$CMD_NORM" | grep -Eiq "${LOCAL_DENY_PATTERNS[$i]}" 2>/dev/null; then
        block_or_warn "${LOCAL_DENY_REASONS[$i]}"
      fi
    done
  fi
fi

exit 0
