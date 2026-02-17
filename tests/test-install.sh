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
  local desc="$1"
  shift
  # shellcheck disable=SC2294  # eval used intentionally with internal-only test expressions
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
assert "settings.json vorhanden (Kopie)" "[[ -f '$FAKE_HOME/.claude/settings.json' && ! -L '$FAKE_HOME/.claude/settings.json' ]]"
assert "CLAUDE.md vorhanden (Kopie)" "[[ -f '$FAKE_HOME/.claude/CLAUDE.md' && ! -L '$FAKE_HOME/.claude/CLAUDE.md' ]]"
assert "MEMORY.md ist Symlink" "[[ -L '$FAKE_HOME/.claude/MEMORY.md' ]]"
assert "hooks/ ist Symlink" "[[ -L '$FAKE_HOME/.claude/hooks' ]]"
assert "rules/ ist Symlink" "[[ -L '$FAKE_HOME/.claude/rules' ]]"
assert "commands/ ist Symlink" "[[ -L '$FAKE_HOME/.claude/commands' ]]"

# --- Idempotenz ---
echo ""
echo "-- Idempotenz --"
echo '{"custom": true}' >"$FAKE_HOME/.claude/settings.json"
HOME="$FAKE_HOME" bash "$SCRIPT_DIR/install.sh" >/dev/null 2>&1
assert "Zweite Installation ueberschreibt settings.json nicht" "grep -q 'custom' '$FAKE_HOME/.claude/settings.json'"

# --- Hook-Sync Edge Cases ---
echo ""
echo "-- Hook-Sync --"

# Corrupt settings.json — sync should fail gracefully
SYNC_HOME=$(mktemp -d /tmp/claude-test-sync-XXXXXX)
mkdir -p "$SYNC_HOME/.claude"
printf '{invalid json\n' >"$SYNC_HOME/.claude/settings.json"
SYNC_OUT=$(HOME="$SYNC_HOME" bash "$SCRIPT_DIR/install.sh" 2>&1 || true)
assert "Corrupt settings.json -> sync fails gracefully" "echo '$SYNC_OUT' | grep -q 'hooks-Block konnte nicht synchronisiert werden'"
rm -rf "$SYNC_HOME"

# Empty settings.json — sync should add hooks block
SYNC_HOME=$(mktemp -d /tmp/claude-test-sync-XXXXXX)
mkdir -p "$SYNC_HOME/.claude"
echo '{}' >"$SYNC_HOME/.claude/settings.json"
HOME="$SYNC_HOME" bash "$SCRIPT_DIR/install.sh" >/dev/null 2>&1 || true
assert "Empty settings.json -> hooks added" "jq -e '.hooks' '$SYNC_HOME/.claude/settings.json' >/dev/null 2>&1"
rm -rf "$SYNC_HOME"

# Dry-run mode — sync should only log, not modify
SYNC_HOME=$(mktemp -d /tmp/claude-test-sync-XXXXXX)
mkdir -p "$SYNC_HOME/.claude"
echo '{"custom":true}' >"$SYNC_HOME/.claude/settings.json"
SYNC_OUT=$(HOME="$SYNC_HOME" bash "$SCRIPT_DIR/install.sh" --dry-run 2>&1 || true)
assert "Dry-run -> sync only logs" "echo '$SYNC_OUT' | grep -q 'Wuerde hooks-Block'"
assert "Dry-run -> settings.json unchanged" "! jq -e '.hooks' '$SYNC_HOME/.claude/settings.json' >/dev/null 2>&1"
rm -rf "$SYNC_HOME"

# --- Deinstallation ---
echo ""
echo "-- Deinstallation --"
HOME="$FAKE_HOME" bash "$SCRIPT_DIR/uninstall.sh" >/dev/null 2>&1
assert "MEMORY.md Symlink entfernt" "[[ ! -L '$FAKE_HOME/.claude/MEMORY.md' ]]"
assert "hooks/ Symlink entfernt" "[[ ! -L '$FAKE_HOME/.claude/hooks' ]]"
assert "settings.json bleibt (Kopie)" "[[ -f '$FAKE_HOME/.claude/settings.json' ]]"

echo ""
echo "================================="
echo -e "Tests: $((PASS + FAIL)) | ${GREEN}$PASS bestanden${NC} | ${RED}$FAIL fehlgeschlagen${NC}"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
