#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Codex CLI Wrapper fuer Claude Code (v0.101+)
# Aufgerufen von multi-* Commands via Bash.
#
# Usage: codex-wrapper.sh --sandbox <mode> --prompt "<prompt>"
#   --sandbox: read | write | full (default: write)
#   --prompt:  Die Aufgabe fuer Codex
#
# Output: JSON auf stdout
#   { "status": "success|error", "output": "...", "model": "codex" }
# ============================================================

SANDBOX="write"
PROMPT=""
TIMEOUT=240
WORKDIR="$(pwd)"

readonly MIN_TIMEOUT=30
readonly MAX_TIMEOUT=600

# --- Pre-Checks ---
if ! command -v jq >/dev/null 2>&1; then
  echo '{"status":"error","output":"jq nicht installiert. apt install jq","model":"codex"}'
  exit 0
fi

# --- Argumente ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sandbox|--prompt|--workdir|--timeout)
      if [[ $# -lt 2 ]]; then
        echo "{\"status\":\"error\",\"output\":\"Missing value for $1\",\"model\":\"codex\"}"
        exit 0
      fi
      ;;&
    --sandbox) SANDBOX="$2"; shift 2 ;;
    --prompt)  PROMPT="$2"; shift 2 ;;
    --workdir) WORKDIR="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    *)
      echo "{\"status\":\"error\",\"output\":\"Unknown argument: $1\",\"model\":\"codex\"}"
      exit 0
      ;;
  esac
done

if [[ -z "$PROMPT" ]]; then
  echo '{"status":"error","output":"--prompt ist erforderlich","model":"codex"}'
  exit 0
fi

# --- Timeout validieren ---
if [[ "$TIMEOUT" -lt "$MIN_TIMEOUT" || "$TIMEOUT" -gt "$MAX_TIMEOUT" ]]; then
  echo "{\"status\":\"error\",\"output\":\"Timeout must be between ${MIN_TIMEOUT}s and ${MAX_TIMEOUT}s (got: ${TIMEOUT}s)\",\"model\":\"codex\"}"
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
  echo '{"status":"error","output":"Codex CLI nicht installiert. bash multi-model/codex-setup.sh ausfuehren.","model":"codex"}'
  exit 0
fi

# --- Sandbox-Modus mappen (Codex CLI v0.101+) ---
case "$SANDBOX" in
  read)  SANDBOX_FLAG="read-only" ;;
  write) SANDBOX_FLAG="workspace-write" ;;
  full)  SANDBOX_FLAG="danger-full-access" ;;
  *)
    echo "{\"status\":\"error\",\"output\":\"Invalid sandbox mode: $SANDBOX (use read|write|full)\",\"model\":\"codex\"}"
    exit 0
    ;;
esac

# --- Git-Repo Check ---
SKIP_GIT_FLAG=""
if ! git -C "$WORKDIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  SKIP_GIT_FLAG="--skip-git-repo-check"
fi

# --- Temp-Dateien fuer Output + Stderr ---
TMPBASE="${TMPDIR:-/tmp/claude}"
mkdir -p "$TMPBASE" 2>/dev/null || true
OUTFILE="$(mktemp "${TMPBASE}/claude-codex-out-XXXXXX.txt")"
ERRFILE="$(mktemp "${TMPBASE}/claude-codex-err-XXXXXX.txt")"
trap 'rm -f "$OUTFILE" "$ERRFILE"' EXIT

# --- timeout verfuegbar? (fehlt auf nativem macOS) ---
if ! command -v timeout >/dev/null 2>&1; then
  echo '{"status":"error","output":"timeout command not found. Install coreutils (brew install coreutils on macOS).","model":"codex"}'
  exit 0
fi

# --- Codex ausfuehren (non-interactive via exec) ---
cd "$WORKDIR"
# shellcheck disable=SC2086
timeout "$TIMEOUT" codex exec \
  --sandbox "$SANDBOX_FLAG" \
  $SKIP_GIT_FLAG \
  -o "$OUTFILE" \
  "$PROMPT" 2>"$ERRFILE" || {
  EXIT_CODE=$?
  STDERR_MSG=""
  [[ -s "$ERRFILE" ]] && STDERR_MSG="$(cat "$ERRFILE")"
  OUTPUT_MSG=""
  [[ -s "$OUTFILE" ]] && OUTPUT_MSG="$(cat "$OUTFILE")"

  if [[ $EXIT_CODE -eq 124 ]]; then
    echo "{\"status\":\"error\",\"output\":\"Codex timeout after ${TIMEOUT}s. Try a smaller task.\",\"model\":\"codex\"}"
  else
    COMBINED="${OUTPUT_MSG:+$OUTPUT_MSG\n}${STDERR_MSG}"
    echo "{\"status\":\"error\",\"output\":$(printf '%s' "$COMBINED" | jq -Rs .),\"model\":\"codex\"}"
  fi
  exit 0
}

# --- Erfolg ---
OUTPUT=""
[[ -s "$OUTFILE" ]] && OUTPUT="$(cat "$OUTFILE")"
echo "{\"status\":\"success\",\"output\":$(printf '%s' "$OUTPUT" | jq -Rs .),\"model\":\"codex\"}"
