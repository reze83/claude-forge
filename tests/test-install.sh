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
assert "hooks/ ist Verzeichnis" "[[ -d '$FAKE_HOME/.claude/hooks' && ! -L '$FAKE_HOME/.claude/hooks' ]]"
assert "hooks/ enthaelt Datei-Symlinks" "[[ -L '$FAKE_HOME/.claude/hooks/bash-firewall.sh' ]]"
assert "rules/ ist Verzeichnis" "[[ -d '$FAKE_HOME/.claude/rules' && ! -L '$FAKE_HOME/.claude/rules' ]]"
assert "rules/ enthaelt Datei-Symlinks" "[[ -L '$FAKE_HOME/.claude/rules/git-workflow.md' ]]"
assert "commands/ ist Verzeichnis" "[[ -d '$FAKE_HOME/.claude/commands' && ! -L '$FAKE_HOME/.claude/commands' ]]"
assert "skills/ ist Verzeichnis" "[[ -d '$FAKE_HOME/.claude/skills' && ! -L '$FAKE_HOME/.claude/skills' ]]"
assert "skills/code-review/ ist Verzeichnis (kein Symlink)" "[[ -d '$FAKE_HOME/.claude/skills/code-review' && ! -L '$FAKE_HOME/.claude/skills/code-review' ]]"
assert "skills/ enthaelt Datei-Symlinks" "[[ -L '$FAKE_HOME/.claude/skills/code-review/SKILL.md' ]]"
assert "skills/ Unterverzeichnisse rekursiv verlinkt" "[[ -L '$FAKE_HOME/.claude/skills/project-init/templates/node-ts.md' ]]"

# --- Idempotenz ---
echo ""
echo "-- Idempotenz --"
echo '{"custom": true}' >"$FAKE_HOME/.claude/settings.json"
HOME="$FAKE_HOME" bash "$SCRIPT_DIR/install.sh" >/dev/null 2>&1
assert "Zweite Installation ueberschreibt settings.json nicht" "grep -q 'custom' '$FAKE_HOME/.claude/settings.json'"

# --- QA-Tools Sektion ---
echo ""
echo "-- QA-Tools Sektion --"
QA_HOME=$(mktemp -d /tmp/claude-test-qa-XXXXXX)
mkdir -p "$QA_HOME/.claude"
# shellcheck disable=SC2034  # QATOOLS_OUT used via eval in assert()
QATOOLS_OUT=$(HOME="$QA_HOME" bash "$SCRIPT_DIR/install.sh" 2>&1 || true)
assert "QA-Tools Sektion laeuft ohne Fatal" "echo \"\$QATOOLS_OUT\" | grep -q 'Optionale QA-Tools'"
rm -rf "$QA_HOME"

# --- Hook-Sync Edge Cases ---
echo ""
echo "-- Hook-Sync --"

# Corrupt settings.json — sync should fail gracefully
SYNC_HOME=$(mktemp -d /tmp/claude-test-sync-XXXXXX)
mkdir -p "$SYNC_HOME/.claude"
printf '{invalid json\n' >"$SYNC_HOME/.claude/settings.json"
SYNC_OUT=$(HOME="$SYNC_HOME" bash "$SCRIPT_DIR/install.sh" 2>&1 || true)
assert "Corrupt settings.json -> sync fails gracefully" "echo '$SYNC_OUT' | grep -q 'settings.json konnte nicht synchronisiert werden'"
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
assert "Dry-run -> sync only logs" "echo '$SYNC_OUT' | grep -q 'Wuerde settings.json mit Template mergen'"
assert "Dry-run -> settings.json unchanged" "! jq -e '.hooks' '$SYNC_HOME/.claude/settings.json' >/dev/null 2>&1"
rm -rf "$SYNC_HOME"

# --- Deinstallation ---
echo ""
echo "-- Deinstallation --"
HOME="$FAKE_HOME" bash "$SCRIPT_DIR/uninstall.sh" >/dev/null 2>&1
assert "hooks/ Datei-Symlinks entfernt" "[[ ! -L '$FAKE_HOME/.claude/hooks/bash-firewall.sh' ]]"
assert "skills/ Datei-Symlinks entfernt" "[[ ! -L '$FAKE_HOME/.claude/skills/code-review/SKILL.md' ]]"
assert "settings.json bleibt (Kopie)" "[[ -f '$FAKE_HOME/.claude/settings.json' ]]"

echo ""
echo "================================="
echo -e "Tests: $((PASS + FAIL)) | ${GREEN}$PASS bestanden${NC} | ${RED}$FAIL fehlgeschlagen${NC}"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
