#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Codex CLI Wrapper fuer Claude Code (v0.104+)
# Aufgerufen von multi-* Commands via Bash.
#
# Usage: codex-wrapper.sh --sandbox <mode> --prompt "<prompt>" [options]
#   --sandbox:      read | write | full (default: write)
#   --prompt:       Die Aufgabe fuer Codex
#   --model:        OpenAI-Modell (default: gpt-5.3-codex)
#   --context-file: Datei-Inhalt an Prompt prependen (wiederholbar)
#   --template:     Template-Datei rendern statt --prompt (key=value args)
#   --no-retry:     Kein automatischer Retry bei transienten Fehlern
#
# Output: JSON auf stdout
#   { "status": "success|error", "output": "...", "model": "<model>" }
# ============================================================

SANDBOX="write"
PROMPT=""
MODEL="gpt-5.3-codex"
REASONING="xhigh"
TIMEOUT=${CLAUDE_FORGE_CODEX_TIMEOUT:-240}
WORKDIR="$(pwd)"
CONTEXT_FILES=()
TEMPLATE=""
NO_RETRY=0

readonly MAX_CONTEXT_BYTES=50000
readonly RETRY_DELAY=5
readonly MIN_TIMEOUT=30
readonly MAX_TIMEOUT=1800

# --- Source shared library ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

# --- Pre-Checks ---
if ! command -v jq >/dev/null 2>&1; then
  echo '{"status":"error","output":"jq nicht installiert. apt install jq","model":"'"$MODEL"'"}'
  exit 0
fi

# --- Argumente ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-retry)
      NO_RETRY=1
      shift
      ;;
    --sandbox | --prompt | --workdir | --timeout | --model | --context-file | --template)
      if [[ $# -lt 2 ]]; then
        echo "{\"status\":\"error\",\"output\":\"Missing value for $1\",\"model\":\"$MODEL\"}"
        exit 0
      fi
      ;;&
    --sandbox)
      SANDBOX="$2"
      shift 2
      ;;
    --prompt)
      PROMPT="$2"
      shift 2
      ;;
    --workdir)
      WORKDIR="$2"
      shift 2
      ;;
    --timeout)
      TIMEOUT="$2"
      shift 2
      ;;
    --model)
      MODEL="$2"
      shift 2
      ;;
    --context-file)
      CONTEXT_FILES+=("$2")
      shift 2
      ;;
    --template)
      TEMPLATE="$2"
      shift 2
      ;;
    *)
      echo "{\"status\":\"error\",\"output\":\"Unknown argument: $1\",\"model\":\"$MODEL\"}"
      exit 0
      ;;
  esac
done

# --- Template-Rendering (--template ersetzt --prompt) ---
if [[ -n "$TEMPLATE" ]]; then
  # Remaining positional-style key=value args were consumed by --template parsing
  # Template file gets rendered via render_template from lib.sh
  if [[ ! -f "$TEMPLATE" ]]; then
    echo "{\"status\":\"error\",\"output\":\"Template not found: $TEMPLATE\",\"model\":\"$MODEL\"}"
    exit 0
  fi
  # If PROMPT already set, use it as the "task" variable
  TEMPLATE_ARGS=()
  [[ -n "$PROMPT" ]] && TEMPLATE_ARGS+=("task=$PROMPT")
  PROMPT="$(render_template "$TEMPLATE" "${TEMPLATE_ARGS[@]}")" 2>/dev/null || {
    echo "{\"status\":\"error\",\"output\":\"Template rendering failed: $TEMPLATE\",\"model\":\"$MODEL\"}"
    exit 0
  }
fi

if [[ -z "$PROMPT" ]]; then
  echo '{"status":"error","output":"--prompt ist erforderlich","model":"'"$MODEL"'"}'
  exit 0
fi

# --- Context-Files an Prompt prependen ---
if [[ ${#CONTEXT_FILES[@]} -gt 0 ]]; then
  CONTEXT_PREFIX=""
  USED_BYTES=0
  for CTX_FILE in "${CONTEXT_FILES[@]}"; do
    if [[ ! -f "$CTX_FILE" ]]; then
      echo "{\"status\":\"error\",\"output\":\"Context file not found: $CTX_FILE\",\"model\":\"$MODEL\"}"
      exit 0
    fi
    CTX_NAME="${CTX_FILE##*/}"
    CTX_HEADER="$(printf -- '--- Context: %s ---\n' "$CTX_NAME")"
    CTX_CONTENT="$(cat "$CTX_FILE")"
    CTX_BLOCK="${CTX_HEADER}${CTX_CONTENT}"$'\n'
    BLOCK_BYTES=${#CTX_BLOCK}
    if [[ $((USED_BYTES + BLOCK_BYTES)) -gt $MAX_CONTEXT_BYTES ]]; then
      break
    fi
    CONTEXT_PREFIX+="$CTX_BLOCK"
    USED_BYTES=$((USED_BYTES + BLOCK_BYTES))
  done
  PROMPT="${CONTEXT_PREFIX}--- Task ---
${PROMPT}"
fi

# --- Timeout validieren ---
if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]]; then
  echo '{"status":"error","output":"--timeout must be a positive integer","model":"'"$MODEL"'"}'
  exit 0
fi
if [[ "$TIMEOUT" -lt "$MIN_TIMEOUT" || "$TIMEOUT" -gt "$MAX_TIMEOUT" ]]; then
  echo "{\"status\":\"error\",\"output\":\"Timeout must be between ${MIN_TIMEOUT}s and ${MAX_TIMEOUT}s (got: ${TIMEOUT}s)\",\"model\":\"$MODEL\"}"
  exit 0
fi

# --- PATH erweitern (npm global bin) ---
if command -v npm >/dev/null 2>&1; then
  NPM_PREFIX="$(npm config get prefix 2>/dev/null || true)"
  if [[ -n "$NPM_PREFIX" && "$NPM_PREFIX" != "/" && "$NPM_PREFIX" != "null" ]]; then
    NPM_BIN="$NPM_PREFIX/bin"
    [[ -d "$NPM_BIN" ]] && export PATH="$NPM_BIN:$PATH"
  fi
fi

# --- Codex verfuegbar? ---
if ! command -v codex >/dev/null 2>&1; then
  echo '{"status":"error","output":"Codex CLI nicht installiert. bash multi-model/codex-setup.sh ausfuehren.","model":"'"$MODEL"'"}'
  exit 0
fi

# --- Sandbox-Modus mappen (Codex CLI v0.104+) ---
case "$SANDBOX" in
  read) SANDBOX_FLAG="read-only" ;;
  write) SANDBOX_FLAG="workspace-write" ;;
  full) SANDBOX_FLAG="danger-full-access" ;;
  *)
    echo "{\"status\":\"error\",\"output\":\"Invalid sandbox mode: $SANDBOX (use read|write|full)\",\"model\":\"$MODEL\"}"
    exit 0
    ;;
esac

# --- Git-Repo Check ---
SKIP_GIT_FLAG=""
if ! git -C "$WORKDIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  SKIP_GIT_FLAG="--skip-git-repo-check"
fi

# --- Secure temp directory and files ---
TMPBASE="${TMPDIR:-/tmp/claude}"
if ! mkdir -p "$TMPBASE" 2>/dev/null; then
  # Fallback: create unique temp dir
  TMPBASE="$(mktemp -d "/tmp/claude-codex-XXXXXX")"
fi
chmod 700 "$TMPBASE" 2>/dev/null || true
OUTFILE="$(mktemp "${TMPBASE}/claude-codex-out-XXXXXX.txt")"
ERRFILE="$(mktemp "${TMPBASE}/claude-codex-err-XXXXXX.txt")"
chmod 600 "$OUTFILE" "$ERRFILE" 2>/dev/null || true
trap 'rm -f "$OUTFILE" "$ERRFILE"' EXIT

# --- timeout verfuegbar? (fehlt auf nativem macOS) ---
if ! command -v timeout >/dev/null 2>&1; then
  echo '{"status":"error","output":"timeout command not found. Install coreutils (brew install coreutils on macOS).","model":"'"$MODEL"'"}'
  exit 0
fi

# --- Codex ausfuehren (mit optionalem Retry) ---
cd "$WORKDIR"

run_codex() {
  # Reset output files
  : >"$OUTFILE"
  : >"$ERRFILE"
  # shellcheck disable=SC2086
  timeout "$TIMEOUT" codex exec \
    -m "$MODEL" \
    -c "model_reasoning_effort=\"$REASONING\"" \
    --sandbox "$SANDBOX_FLAG" \
    $SKIP_GIT_FLAG \
    -o "$OUTFILE" \
    "$PROMPT" >/dev/null 2>"$ERRFILE"
}

emit_error() {
  local exit_code="$1"
  local stderr_msg="" output_msg=""
  [[ -s "$ERRFILE" ]] && stderr_msg="$(cat "$ERRFILE")"
  [[ -s "$OUTFILE" ]] && output_msg="$(cat "$OUTFILE")"

  if [[ $exit_code -eq 124 ]]; then
    echo "{\"status\":\"error\",\"output\":\"Codex timeout after ${TIMEOUT}s. Try a smaller task.\",\"model\":\"$MODEL\"}"
  else
    local combined="${output_msg:+$output_msg\n}${stderr_msg}"
    echo "{\"status\":\"error\",\"output\":$(printf '%s' "$combined" | jq -Rs .),\"model\":\"$MODEL\"}"
  fi
}

if run_codex; then
  OUTPUT=""
  [[ -s "$OUTFILE" ]] && OUTPUT="$(cat "$OUTFILE")"
  echo "{\"status\":\"success\",\"output\":$(printf '%s' "$OUTPUT" | jq -Rs .),\"model\":\"$MODEL\"}"
  exit 0
fi

FIRST_EXIT=$?
FIRST_STDERR=""
[[ -s "$ERRFILE" ]] && FIRST_STDERR="$(cat "$ERRFILE")"

# --- Retry bei transienten Fehlern (1x, nicht bei --no-retry oder --sandbox full) ---
if [[ "$NO_RETRY" -eq 0 && "$SANDBOX" != "full" ]] && is_transient_error "$FIRST_STDERR" "$FIRST_EXIT" "$TIMEOUT"; then
  printf 'codex-wrapper: transient error (exit %s), retrying in %ss...\n' "$FIRST_EXIT" "$RETRY_DELAY" >&2
  sleep "$RETRY_DELAY"
  if run_codex; then
    OUTPUT=""
    [[ -s "$OUTFILE" ]] && OUTPUT="$(cat "$OUTFILE")"
    echo "{\"status\":\"success\",\"output\":$(printf '%s' "$OUTPUT" | jq -Rs .),\"model\":\"$MODEL\"}"
    exit 0
  fi
fi

emit_error "$FIRST_EXIT"
