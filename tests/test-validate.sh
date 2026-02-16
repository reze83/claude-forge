#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Validate-Tests
# Prueft ob validate.sh korrekt durchlaeuft
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "=== Validate-Tests ==="
echo ""

# validate.sh muss nach Installation funktionieren
if bash "$SCRIPT_DIR/validate.sh" >/dev/null 2>&1; then
  echo -e "  ${GREEN}[PASS]${NC} validate.sh laeuft durch"
  PASS=$((PASS + 1))
else
  echo -e "  ${RED}[FAIL]${NC} validate.sh fehlgeschlagen"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "================================="
echo -e "Tests: $((PASS + FAIL)) | ${GREEN}$PASS bestanden${NC} | ${RED}$FAIL fehlgeschlagen${NC}"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
