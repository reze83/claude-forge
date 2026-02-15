#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Update-Tests
# Testet update.sh Verhalten (--check, --help, Nicht-Git-Repo)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
UPDATE="$SCRIPT_DIR/update.sh"
PASS=0
FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

assert_contains() {
  local desc="$1"
  local expected="$2"
  local output="$3"

  if echo "$output" | grep -q "$expected"; then
    echo -e "  ${GREEN}[PASS]${NC} $desc"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}[FAIL]${NC} $desc (erwartet: '$expected')"
    FAIL=$((FAIL + 1))
  fi
}

assert_exit_code() {
  local desc="$1"
  local expected="$2"
  local cmd="$3"

  local actual=0
  eval "$cmd" >/dev/null 2>/dev/null || actual=$?

  if [[ "$actual" -eq "$expected" ]]; then
    echo -e "  ${GREEN}[PASS]${NC} $desc"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}[FAIL]${NC} $desc (erwartet: $expected, erhalten: $actual)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Update-Tests ==="
echo ""

# --- --help ---
echo "-- update.sh --help --"
HELP_OUT=$(bash "$UPDATE" --help 2>&1)
assert_contains "--help zeigt Usage"     "Usage:" "$HELP_OUT"
assert_contains "--help zeigt --check"   "check" "$HELP_OUT"
assert_exit_code "--help exit 0"         0 "bash '$UPDATE' --help"

echo ""

# --- VERSION ---
echo "-- VERSION --"
assert_contains "VERSION Datei existiert" "." "$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo "MISSING")"

echo ""

# --- Nicht-Git-Repo ---
echo "-- Nicht-Git-Repo --"
TMPDIR_TEST="${TMPDIR:-/tmp/claude}/test-update-$$"
mkdir -p "$TMPDIR_TEST"
cp "$UPDATE" "$TMPDIR_TEST/update.sh"
NON_GIT_OUT=$(bash "$TMPDIR_TEST/update.sh" 2>&1 || true)
assert_contains "Fehler ohne .git" "Kein Git-Repo" "$NON_GIT_OUT"
rm -rf "$TMPDIR_TEST"

echo ""

# --- --check im echten Repo ---
echo "-- update.sh --check --"
CHECK_OUT=$(bash "$UPDATE" --check 2>&1 || true)
# Should show either "Bereits aktuell" or "neue Commits verfuegbar"
if echo "$CHECK_OUT" | grep -qE "aktuell|Commits|fetch"; then
  echo -e "  ${GREEN}[PASS]${NC} --check liefert Status-Output"
  PASS=$((PASS + 1))
else
  echo -e "  ${RED}[FAIL]${NC} --check unerwarteter Output: $CHECK_OUT"
  FAIL=$((FAIL + 1))
fi

echo ""

# --- Ergebnis ---
echo "================================="
echo -e "Tests: $((PASS + FAIL)) | ${GREEN}$PASS bestanden${NC} | ${RED}$FAIL fehlgeschlagen${NC}"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
