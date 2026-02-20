#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Codex-Wrapper-Tests
# Testet codex-wrapper.sh — Fehlerbehandlung + Live-Aufruf
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WRAPPER="$SCRIPT_DIR/multi-model/codex-wrapper.sh"
PASS=0
FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

skip() {
  echo -e "  ${YELLOW}[SKIP]${NC} $1"
}

echo "=== Codex-Wrapper-Tests ==="
echo ""

# --- Fehlerbehandlung ---
echo "-- Fehlerbehandlung --"

# Test 1: Fehlender --prompt
OUT=$(bash "$WRAPPER" 2>&1) || true
assert_contains "Fehlender Prompt → error" '"status":"error"' "$OUT"

# Test 2: JSON-Output bei Fehler (default model=gpt-5.3-codex)
assert_contains "Fehler-Output ist JSON mit model" '"model":"gpt-5.3-codex"' "$OUT"

# Test 3: jq verfuegbar
if command -v jq >/dev/null 2>&1; then
  echo -e "  ${GREEN}[PASS]${NC} jq ist installiert"
  PASS=$((PASS + 1))
else
  echo -e "  ${RED}[FAIL]${NC} jq fehlt"
  FAIL=$((FAIL + 1))
fi

# Test: Timeout-Validierung (zu klein)
OUT=$(bash "$WRAPPER" --sandbox read --timeout 5 --prompt "test" 2>&1) || true
assert_contains "Timeout zu klein → error" '"status":"error"' "$OUT"
assert_contains "Timeout-Fehler nennt Bereich" 'between' "$OUT"

# Test: Timeout-Validierung (zu gross)
OUT=$(bash "$WRAPPER" --sandbox read --timeout 9999 --prompt "test" 2>&1) || true
assert_contains "Timeout zu gross → error" '"status":"error"' "$OUT"

# Test: Timeout-Validierung (nicht-numerisch)
OUT=$(bash "$WRAPPER" --sandbox read --timeout abc --prompt "test" 2>&1) || true
assert_contains "Nicht-numerischer Timeout → error" '"status":"error"' "$OUT"
assert_contains "Nicht-numerischer Timeout → integer msg" 'integer' "$OUT"

# Test: --model Flag aendert model im Output
OUT=$(bash "$WRAPPER" --model o4-mini 2>&1) || true
assert_contains "--model setzt model im Output" '"model":"o4-mini"' "$OUT"

# Test: Default model ist gpt-5.3-codex
OUT=$(bash "$WRAPPER" 2>&1) || true
assert_contains "Default model ist gpt-5.3-codex" '"model":"gpt-5.3-codex"' "$OUT"

# --- render_template Tests ---
echo ""
echo "-- render_template --"

# Source lib.sh directly (no bash -c subshell)
# shellcheck source=../multi-model/lib.sh
source "$SCRIPT_DIR/multi-model/lib.sh"

# Temp-Template erstellen
TPL_DIR="$(mktemp -d)"
trap 'rm -rf "$TPL_DIR"' EXIT

cat >"$TPL_DIR/test.tpl" <<'TMPL'
Hello {{name}}, welcome to {{project}}.
TMPL

# Test: Einfache Substitution
OUT=$(render_template "$TPL_DIR/test.tpl" name=World project=Forge 2>&1) || true
assert_contains "render_template: einfache Substitution" 'Hello World, welcome to Forge.' "$OUT"

# Test: Fehlende Datei → exit 1
OUT=$(render_template /nonexistent/file.md 2>&1) || true
assert_contains "render_template: fehlende Datei → Fehler" 'not found' "$OUT"

# Test: Unsubstituierte Placeholder → Warning
cat >"$TPL_DIR/warn.tpl" <<'TMPL'
{{greeting}} {{unused}}
TMPL
OUT=$(render_template "$TPL_DIR/warn.tpl" greeting=Hi 2>&1) || true
assert_contains "render_template: warnt ueber unsubstituierte Placeholder" 'unsubstituted' "$OUT"
assert_contains "render_template: Output enthaelt substituierten Wert" 'Hi' "$OUT"

# Test: Sonderzeichen in Werten (sed-safe)
cat >"$TPL_DIR/special.tpl" <<'TMPL'
path={{path}}
TMPL
OUT=$(render_template "$TPL_DIR/special.tpl" "path=/usr/local/bin" 2>&1) || true
assert_contains "render_template: Sonderzeichen in Werten" '/usr/local/bin' "$OUT"

# --- context-file Tests ---
echo ""
echo "-- context-file --"

cat >"$TPL_DIR/ctx1.txt" <<'TMPL'
file content here
TMPL
cat >"$TPL_DIR/ctx2.txt" <<'TMPL'
second file
TMPL

# Test: --context-file fehlende Datei → error
OUT=$(bash "$WRAPPER" --context-file /nonexistent/file.txt --prompt "test" 2>&1) || true
assert_contains "--context-file fehlende Datei → error" '"status":"error"' "$OUT"
assert_contains "--context-file nennt Datei" 'Context file not found' "$OUT"

# Test: --context-file existierend (wrapper wird wegen fehlendem codex/timeout scheitern,
#       aber NICHT wegen context-file — also kein "Context file not found" im Output)
OUT=$(bash "$WRAPPER" --context-file "$TPL_DIR/ctx1.txt" --prompt "test" 2>&1) || true
if echo "$OUT" | grep -q 'Context file not found'; then
  printf '  %b[FAIL]%b context-file akzeptiert existierende Datei\n' "$RED" "$NC"
  FAIL=$((FAIL + 1))
else
  printf '  %b[PASS]%b context-file akzeptiert existierende Datei\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
fi

# Test: --template fehlende Datei → error
OUT=$(bash "$WRAPPER" --template /nonexistent/template.md --prompt "test" 2>&1) || true
assert_contains "--template fehlende Datei → error" 'Template not found' "$OUT"

# --- Live-Tests (nur wenn Codex installiert) ---
echo ""
echo "-- Live-Tests --"

if command -v codex >/dev/null 2>&1; then
  # Test 4: Sandbox read (Codex antwortet)
  OUT=$(bash "$WRAPPER" --sandbox read --prompt "Reply with exactly one word: PING" --timeout 30 2>&1) || true
  assert_contains "Sandbox read → success" '"status":"success"' "$OUT"

  # Test 5: Output enthaelt Codex-Antwort
  assert_contains "Output enthaelt Antwort" 'PING' "$OUT"

  # Test 6: JSON ist valide
  if echo "$OUT" | jq empty 2>/dev/null; then
    echo -e "  ${GREEN}[PASS]${NC} Output ist valides JSON"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}[FAIL]${NC} Output ist kein valides JSON"
    FAIL=$((FAIL + 1))
  fi
else
  skip "Codex nicht installiert — Live-Tests uebersprungen"
  skip "Codex nicht installiert — Live-Tests uebersprungen"
  skip "Codex nicht installiert — Live-Tests uebersprungen"
fi

echo ""
echo "================================="
echo -e "Tests: $((PASS + FAIL)) | ${GREEN}$PASS bestanden${NC} | ${RED}$FAIL fehlgeschlagen${NC}"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
