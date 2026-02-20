#!/usr/bin/env bash
set -euo pipefail
# tests/bench-hooks.sh — Benchmark all claude-forge hooks
#
# Usage: bash tests/bench-hooks.sh
#   BENCH_ITERATIONS=100 bash tests/bench-hooks.sh
#
# Measures avg/min/max execution time (ms) for each hook.
# Default: 50 iterations per hook (override via BENCH_ITERATIONS).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOKS_DIR="$SCRIPT_DIR/../hooks"
ITERATIONS="${BENCH_ITERATIONS:-50}"

printf "claude-forge hook benchmark (%d iterations)\n\n" "$ITERATIONS"
printf "%-25s %8s %8s %8s\n" "Hook" "Avg(ms)" "Min(ms)" "Max(ms)"
printf "%-25s %8s %8s %8s\n" "-------------------------" "--------" "--------" "--------"

bench() {
  local hook="$1" input="$2"
  local script="$HOOKS_DIR/$hook"
  local total=0 min=999999 max=0

  for ((i = 0; i < ITERATIONS; i++)); do
    start=$(date +%s%N)
    printf '%s' "$input" | bash "$script" >/dev/null 2>&1 || true
    end=$(date +%s%N)
    elapsed=$(((end - start) / 1000000))
    total=$((total + elapsed))
    ((elapsed < min)) && min=$elapsed
    ((elapsed > max)) && max=$elapsed
  done

  avg=$((total / ITERATIONS))
  printf "%-25s %8d %8d %8d\n" "$hook" "$avg" "$min" "$max"
}

bench bash-firewall.sh '{"tool_name":"Bash","tool_input":{"command":"git status"}}'
bench protect-files.sh '{"tool_name":"Read","tool_input":{"file_path":"/home/c/src/index.ts"}}'
bench secret-scan-pre.sh '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.ts","content":"const x = 42;"}}'
bench auto-format.sh '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.ts"}}'
bench url-allowlist.sh '{"tool_name":"WebFetch","tool_input":{"url":"https://github.com"}}'
bench smithery-context.sh '{"tool_name":"UserPromptSubmit","tool_input":{"prompt":"hello"}}'
bench session-start.sh '{"tool_name":"SessionStart","tool_input":{}}'
bench setup.sh '{"tool_name":"Setup","tool_input":{}}'
bench post-failure.sh '{"tool_name":"PostToolUseFailure","tool_input":{"error":"some error"}}'
bench pre-compact.sh '{"tool_name":"PreCompact","tool_input":{"trigger":"manual"}}'
bench secret-scan.sh '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.ts"}}'
bench stop.sh '{"tool_name":"Stop","tool_input":{}}'
bench pre-write-backup.sh '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.ts","content":"x"}}'
bench session-logger.sh '{"tool_name":"Stop","tool_input":{}}'
bench task-gate.sh '{"tool_name":"TaskCompleted","tool_input":{}}'
bench teammate-gate.sh '{"tool_name":"TeammateIdle","tool_input":{}}'
bench subagent-start.sh '{"tool_name":"SubagentStart","tool_input":{"subagent_id":"test"}}'
bench subagent-stop.sh '{"tool_name":"SubagentStop","tool_input":{"subagent_id":"test"}}'
