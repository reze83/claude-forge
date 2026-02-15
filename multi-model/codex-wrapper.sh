#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Codex CLI Wrapper fuer Claude Code
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

# --- Codex verfuegbar? ---
if ! command -v codex >/dev/null 2>&1; then
  echo '{"status":"error","output":"Codex CLI nicht installiert. bash multi-model/codex-setup.sh ausfuehren.","model":"codex"}'
  exit 1
fi

# --- Sandbox-Modus mappen ---
case "$SANDBOX" in
  read)  APPROVAL="suggest" ;;
  write) APPROVAL="auto-edit" ;;
  full)  APPROVAL="full-auto" ;;
  *)     APPROVAL="auto-edit" ;;
esac

# --- Temp-Datei fuer Prompt ---
TMPFILE="$(mktemp /tmp/claude-codex-XXXXXX.txt)"
echo "$PROMPT" > "$TMPFILE"
trap 'rm -f "$TMPFILE"' EXIT

# --- Codex ausfuehren ---
cd "$WORKDIR"
OUTPUT=$(timeout "$TIMEOUT" codex -q --approval-mode "$APPROVAL" - < "$TMPFILE" 2>&1) || {
  EXIT_CODE=$?
  if [[ $EXIT_CODE -eq 124 ]]; then
    echo "{\"status\":\"error\",\"output\":\"Codex Timeout nach ${TIMEOUT}s\",\"model\":\"codex\"}"
  else
    echo "{\"status\":\"error\",\"output\":$(echo "$OUTPUT" | jq -Rs .),\"model\":\"codex\"}"
  fi
  exit 0  # Immer exit 0 damit Claude den Fehler verarbeiten kann
}

# --- Erfolg ---
echo "{\"status\":\"success\",\"output\":$(echo "$OUTPUT" | jq -Rs .),\"model\":\"codex\"}"
