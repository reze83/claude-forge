#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Install/Uninstall Tests
# Nutzt temporaeres HOME um echte Config nicht zu beschaedigen
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FAKE_HOME=$(mktemp -d /tmp/claude-test-home-XXXXXX)
PASS=0
FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

trap 'rm -rf "$FAKE_HOME"' EXIT

assert() {
  local desc="$1"; shift
  if eval "$@" 2>/dev/null; then
    echo -e "  ${GREEN}[PASS]${NC} $desc"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}[FAIL]${NC} $desc"
    FAIL=$((FAIL + 1))
  fi
}

# Setup: Fake .claude Verzeichnis
mkdir -p "$FAKE_HOME/.claude/"{agents,skills,plugins}

echo "=== Install-Tests ==="
echo ""

# --- Dry-Run ---
echo "-- Dry-Run --"
HOME="$FAKE_HOME" bash "$SCRIPT_DIR/install.sh" --dry-run >/dev/null 2>&1
assert "Dry-Run erstellt settings.json nicht" "[[ ! -f '$FAKE_HOME/.claude/settings.json' ]]"

# --- Echte Installation ---
echo ""
echo "-- Installation --"
HOME="$FAKE_HOME" bash "$SCRIPT_DIR/install.sh" >/dev/null 2>&1
assert "settings.json vorhanden (Kopie)"  "[[ -f '$FAKE_HOME/.claude/settings.json' && ! -L '$FAKE_HOME/.claude/settings.json' ]]"
assert "CLAUDE.md vorhanden (Kopie)"      "[[ -f '$FAKE_HOME/.claude/CLAUDE.md' && ! -L '$FAKE_HOME/.claude/CLAUDE.md' ]]"
assert "MEMORY.md ist Symlink"            "[[ -L '$FAKE_HOME/.claude/MEMORY.md' ]]"
assert "hooks/ ist Symlink"               "[[ -L '$FAKE_HOME/.claude/hooks' ]]"
assert "rules/ ist Symlink"               "[[ -L '$FAKE_HOME/.claude/rules' ]]"
assert "commands/ ist Symlink"            "[[ -L '$FAKE_HOME/.claude/commands' ]]"

# --- Idempotenz ---
echo ""
echo "-- Idempotenz --"
echo '{"custom": true}' > "$FAKE_HOME/.claude/settings.json"
HOME="$FAKE_HOME" bash "$SCRIPT_DIR/install.sh" >/dev/null 2>&1
assert "Zweite Installation ueberschreibt settings.json nicht" "grep -q 'custom' '$FAKE_HOME/.claude/settings.json'"

# --- Deinstallation ---
echo ""
echo "-- Deinstallation --"
HOME="$FAKE_HOME" bash "$SCRIPT_DIR/uninstall.sh" >/dev/null 2>&1
assert "MEMORY.md Symlink entfernt"        "[[ ! -L '$FAKE_HOME/.claude/MEMORY.md' ]]"
assert "hooks/ Symlink entfernt"           "[[ ! -L '$FAKE_HOME/.claude/hooks' ]]"
assert "settings.json bleibt (Kopie)"      "[[ -f '$FAKE_HOME/.claude/settings.json' ]]"

echo ""
echo "================================="
echo -e "Tests: $((PASS + FAIL)) | ${GREEN}$PASS bestanden${NC} | ${RED}$FAIL fehlgeschlagen${NC}"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
