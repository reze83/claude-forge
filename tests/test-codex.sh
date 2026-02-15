#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Codex-Wrapper-Tests
# Testet codex-wrapper.sh ohne echten Codex CLI
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WRAPPER="$SCRIPT_DIR/multi-model/codex-wrapper.sh"
PASS=0
FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

assert_contains() {
  local desc="$1"
  local expected="$2"
  local actual="$3"

  if echo "$actual" | grep -q "$expected"; then
    echo -e "  ${GREEN}[PASS]${NC} $desc"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}[FAIL]${NC} $desc (erwartet '$expected' in Output)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Codex-Wrapper-Tests ==="
echo ""

# Test 1: Fehlender --prompt
OUT=$(bash "$WRAPPER" 2>&1) || true
assert_contains "Fehlender Prompt → error" '"status":"error"' "$OUT"

# Test 2: Fehlender Codex CLI (PATH manipulieren)
OUT=$(PATH=/usr/bin bash "$WRAPPER" --prompt "test" 2>&1) || true
assert_contains "Fehlender Codex → error" 'nicht installiert' "$OUT"

# Test 3: Sandbox-Modus Mapping (pruefe ob Variable gesetzt wird)
OUT=$(PATH=/usr/bin bash "$WRAPPER" --sandbox read --prompt "test" 2>&1) || true
assert_contains "Sandbox read → error (kein codex)" '"status":"error"' "$OUT"

OUT=$(PATH=/usr/bin bash "$WRAPPER" --sandbox full --prompt "test" 2>&1) || true
assert_contains "Sandbox full → error (kein codex)" '"status":"error"' "$OUT"

# Test 5: Timeout-Parameter wird akzeptiert
OUT=$(PATH=/usr/bin bash "$WRAPPER" --timeout 5 --prompt "test" 2>&1) || true
assert_contains "Timeout-Parameter akzeptiert" '"status":"error"' "$OUT"

# Test 6: jq verfuegbar
if command -v jq >/dev/null 2>&1; then
  echo -e "  ${GREEN}[PASS]${NC} jq ist installiert"
  PASS=$((PASS + 1))
else
  echo -e "  ${RED}[FAIL]${NC} jq fehlt"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "================================="
echo -e "Tests: $((PASS + FAIL)) | ${GREEN}$PASS bestanden${NC} | ${RED}$FAIL fehlgeschlagen${NC}"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
