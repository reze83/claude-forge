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
TIMEOUT=180
WORKDIR="$(pwd)"

# --- Pre-Checks ---
if ! command -v jq >/dev/null 2>&1; then
  echo '{"status":"error","output":"jq nicht installiert. apt install jq","model":"codex"}'
  exit 1
fi

# --- Argumente ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sandbox) SANDBOX="$2"; shift 2 ;;
    --prompt)  PROMPT="$2"; shift 2 ;;
    --workdir) WORKDIR="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [[ -z "$PROMPT" ]]; then
  echo '{"status":"error","output":"--prompt ist erforderlich","model":"codex"}'
  exit 1
fi

# --- PATH erweitern (npm global bin) ---
NPM_BIN="$(npm config get prefix 2>/dev/null)/bin" || true
[[ -d "$NPM_BIN" ]] && export PATH="$NPM_BIN:$PATH"

# --- Codex verfuegbar? ---
if ! command -v codex >/dev/null 2>&1; then
  echo '{"status":"error","output":"Codex CLI nicht installiert. bash multi-model/codex-setup.sh ausfuehren.","model":"codex"}'
  exit 1
fi

# --- Sandbox-Modus mappen (Codex CLI v0.101+) ---
case "$SANDBOX" in
  read)  SANDBOX_FLAG="read-only" ;;
  write) SANDBOX_FLAG="workspace-write" ;;
  full)  SANDBOX_FLAG="danger-full-access" ;;
  *)     SANDBOX_FLAG="workspace-write" ;;
esac

# --- Temp-Datei fuer Output ---
mkdir -p "${TMPDIR:-/tmp/claude}" 2>/dev/null || true
OUTFILE="$(mktemp "${TMPDIR:-/tmp/claude}/claude-codex-out-XXXXXX.txt")"
trap 'rm -f "$OUTFILE"' EXIT

# --- Codex ausfuehren (non-interactive via exec) ---
cd "$WORKDIR"
timeout "$TIMEOUT" codex exec \
  --sandbox "$SANDBOX_FLAG" \
  -o "$OUTFILE" \
  "$PROMPT" >/dev/null 2>&1 || {
  EXIT_CODE=$?
  if [[ $EXIT_CODE -eq 124 ]]; then
    echo "{\"status\":\"error\",\"output\":\"Codex Timeout nach ${TIMEOUT}s\",\"model\":\"codex\"}"
  else
    # Fehler-Output aus der Datei oder stderr lesen
    ERROR_MSG=""
    [[ -s "$OUTFILE" ]] && ERROR_MSG="$(cat "$OUTFILE")"
    echo "{\"status\":\"error\",\"output\":$(echo "$ERROR_MSG" | jq -Rs .),\"model\":\"codex\"}"
  fi
  exit 0  # Immer exit 0 damit Claude den Fehler verarbeiten kann
}

# --- Erfolg ---
OUTPUT=""
[[ -s "$OUTFILE" ]] && OUTPUT="$(cat "$OUTFILE")"
echo "{\"status\":\"success\",\"output\":$(echo "$OUTPUT" | jq -Rs .),\"model\":\"codex\"}"
