#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Plugin-Mode Tests
# Prueft plugin.json Felder und Plugin-Struktur
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_JSON="$SCRIPT_DIR/.claude-plugin/plugin.json"
PASS=0
FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() {
  printf "  ${GREEN}[PASS]${NC} %s\n" "$1"
  PASS=$((PASS + 1))
}

fail() {
  printf "  ${RED}[FAIL]${NC} %s\n" "$1"
  FAIL=$((FAIL + 1))
}

echo "=== Plugin-Tests ==="
echo ""

# 1. plugin.json existiert
if [[ -f "$PLUGIN_JSON" ]]; then
  pass "plugin.json existiert"
else
  fail "plugin.json existiert"
  echo ""
  echo "================================="
  printf "Tests: %d | ${GREEN}%d bestanden${NC} | ${RED}%d fehlgeschlagen${NC}\n" "$((PASS + FAIL))" "$PASS" "$FAIL"
  exit 1
fi

# 2. plugin.json valides JSON
if jq empty "$PLUGIN_JSON" 2>/dev/null; then
  pass "plugin.json valides JSON"
else
  fail "plugin.json valides JSON"
  echo ""
  echo "================================="
  printf "Tests: %d | ${GREEN}%d bestanden${NC} | ${RED}%d fehlgeschlagen${NC}\n" "$((PASS + FAIL))" "$PASS" "$FAIL"
  exit 1
fi

# 3. name == "claude-forge"
PLUGIN_NAME="$(jq -r '.name' "$PLUGIN_JSON")"
if [[ "$PLUGIN_NAME" == "claude-forge" ]]; then
  pass "name == claude-forge"
else
  fail "name == claude-forge (got: $PLUGIN_NAME)"
fi

# 4. description vorhanden
PLUGIN_DESC="$(jq -r '.description // empty' "$PLUGIN_JSON")"
if [[ -n "$PLUGIN_DESC" ]]; then
  pass "description vorhanden"
else
  fail "description vorhanden"
fi

# 5. kein hooks-Feld (Plugin-Constraint)
if jq -e '.hooks' "$PLUGIN_JSON" >/dev/null 2>&1; then
  fail "kein hooks-Feld (Plugin laedt hooks/hooks.json automatisch)"
else
  pass "kein hooks-Feld"
fi

# 6. version == VERSION
PLUGIN_VER="$(jq -r '.version' "$PLUGIN_JSON")"
REPO_VER="$(tr -d '[:space:]' <"$SCRIPT_DIR/VERSION")"
if [[ "$PLUGIN_VER" == "$REPO_VER" ]]; then
  pass "version == VERSION ($REPO_VER)"
else
  fail "version ($PLUGIN_VER) != VERSION ($REPO_VER)"
fi

# 7. commands/ existiert
if [[ -d "$SCRIPT_DIR/commands" ]]; then
  pass "commands/ existiert"
else
  fail "commands/ existiert"
fi

# 8. agents/ existiert
if [[ -d "$SCRIPT_DIR/agents" ]]; then
  pass "agents/ existiert"
else
  fail "agents/ existiert"
fi

# 9. hooks.json nutzt ${CLAUDE_PLUGIN_ROOT}
HOOKS_JSON="$SCRIPT_DIR/hooks/hooks.json"
if grep -q 'CLAUDE_PLUGIN_ROOT' "$HOOKS_JSON" 2>/dev/null; then
  pass "hooks.json nutzt \${CLAUDE_PLUGIN_ROOT}"
else
  fail "hooks.json nutzt \${CLAUDE_PLUGIN_ROOT}"
fi

echo ""
echo "================================="
printf "Tests: %d | ${GREEN}%d bestanden${NC} | ${RED}%d fehlgeschlagen${NC}\n" "$((PASS + FAIL))" "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
