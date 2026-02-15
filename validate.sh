#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# claude-forge validator
# Prueft JSON-Syntax, Symlinks, Hook-Berechtigungen, Tools
# ============================================================

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
ERRORS=0
WARNINGS=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}[PASS]${NC} $1"; }

fail() {
  echo -e "  ${RED}[FAIL]${NC} $1"
  ERRORS=$((ERRORS + 1))
}

warning() {
  echo -e "  ${YELLOW}[WARN]${NC} $1"
  WARNINGS=$((WARNINGS + 1))
}

echo "=== claude-forge validation ==="
echo ""

# --- Dateien & Symlinks ---
echo "-- Dateien & Symlinks --"
[[ -f "$REPO_DIR/VERSION" ]]          && pass "VERSION vorhanden"       || fail "VERSION vorhanden"
[[ -f "$CLAUDE_DIR/settings.json" ]] && pass "settings.json vorhanden" || fail "settings.json vorhanden"
[[ -f "$CLAUDE_DIR/CLAUDE.md" ]]     && pass "CLAUDE.md vorhanden"     || fail "CLAUDE.md vorhanden"

check_symlink() {
  local name="$1"
  local target="$CLAUDE_DIR/$name"
  if [[ ! -L "$target" ]]; then
    fail "$name ist kein Symlink"
  elif [[ ! -e "$target" ]]; then
    fail "$name → $(readlink "$target") (Ziel existiert nicht)"
  else
    pass "$name → $(readlink "$target")"
  fi
}

check_symlink "MEMORY.md"
check_symlink "rules"
check_symlink "hooks"
check_symlink "commands"
check_symlink "multi-model"

# --- JSON-Validitaet ---
echo ""
echo "-- JSON-Validitaet --"
jq empty "$REPO_DIR/user-config/settings.json.example" 2>/dev/null \
  && pass "settings.json.example valides JSON" || fail "settings.json.example valides JSON"
jq empty "$REPO_DIR/hooks/hooks.json" 2>/dev/null \
  && pass "hooks.json valides JSON" || fail "hooks.json valides JSON"
jq empty "$REPO_DIR/.claude-plugin/plugin.json" 2>/dev/null \
  && pass "plugin.json valides JSON" || fail "plugin.json valides JSON"

# --- Hook-Scripts ---
echo ""
echo "-- Hook-Scripts --"
for hook in "$REPO_DIR/hooks/"*.sh; do
  [[ -f "$hook" ]] || continue
  name="$(basename "$hook")"
  [[ -x "$hook" ]] \
    && pass "$name ist ausfuehrbar" || fail "$name ist ausfuehrbar"
  head -1 "$hook" | grep -q '^#!/' 2>/dev/null \
    && pass "$name hat Shebang" || fail "$name hat Shebang"
  head -3 "$hook" | grep -q 'set -euo pipefail' 2>/dev/null \
    && pass "$name hat set -euo pipefail" || fail "$name hat set -euo pipefail"
done

# --- Agents ---
echo ""
echo "-- Agents --"
for agent in "$REPO_DIR/agents/"*.md; do
  [[ -f "$agent" ]] || continue
  name="$(basename "$agent")"
  head -1 "$agent" | grep -q '^---' 2>/dev/null \
    && pass "$name hat YAML Frontmatter" || fail "$name hat YAML Frontmatter"
  grep -q '^name:' "$agent" 2>/dev/null \
    && pass "$name hat name: Feld" || fail "$name hat name: Feld"
  grep -q '^description:' "$agent" 2>/dev/null \
    && pass "$name hat description: Feld" || fail "$name hat description: Feld"
done

# --- Skills ---
echo ""
echo "-- Skills --"
for skill in "$REPO_DIR/skills/"*/SKILL.md; do
  [[ -f "$skill" ]] || continue
  name="$(basename "$(dirname "$skill")")"
  head -1 "$skill" | grep -q '^---' 2>/dev/null \
    && pass "$name/SKILL.md hat Frontmatter" || fail "$name/SKILL.md hat Frontmatter"
  grep -q '^name:' "$skill" 2>/dev/null \
    && pass "$name/SKILL.md hat name: Feld" || fail "$name/SKILL.md hat name: Feld"
done

# --- Commands ---
echo ""
echo "-- Commands --"
for cmd in "$REPO_DIR/commands/"*.md; do
  [[ -f "$cmd" ]] || continue
  name="$(basename "$cmd")"
  head -1 "$cmd" | grep -q '^---' 2>/dev/null \
    && pass "$name hat Frontmatter" || fail "$name hat Frontmatter"
  grep -q '^description:' "$cmd" 2>/dev/null \
    && pass "$name hat description: Feld" || fail "$name hat description: Feld"
done

# --- Tools ---
echo ""
echo "-- System-Tools --"

# Node version check: v20+ (supports v20-v99)
NODE_VER="$(node -v 2>/dev/null || echo "")"
if [[ "$NODE_VER" =~ ^v([0-9]+)\. ]] && [[ "${BASH_REMATCH[1]}" -ge 20 ]]; then
  pass "node >= 20 ($NODE_VER)"
else
  fail "node >= 20 (aktuell: ${NODE_VER:-nicht installiert})"
fi

python3 -c 'import sys; assert sys.version_info >= (3,10)' 2>/dev/null \
  && pass "python3 >= 3.10" || fail "python3 >= 3.10"
git --version >/dev/null 2>&1 \
  && pass "git vorhanden" || fail "git vorhanden"
jq --version >/dev/null 2>&1 \
  && pass "jq vorhanden" || fail "jq vorhanden"
command -v codex >/dev/null 2>&1 \
  && pass "codex CLI" || warning "codex CLI"
command -v ruff >/dev/null 2>&1 \
  && pass "ruff vorhanden" || warning "ruff vorhanden"
command -v shfmt >/dev/null 2>&1 \
  && pass "shfmt vorhanden" || warning "shfmt vorhanden"

# --- Secrets-Check ---
echo ""
echo "-- Secrets-Scan --"

check_no_secret() {
  local desc="$1" pattern="$2"
  if grep -rIl --exclude-dir=tests "$pattern" "$REPO_DIR/" --include='*.json' --include='*.md' --include='*.sh' 2>/dev/null; then
    fail "$desc"
  else
    pass "$desc"
  fi
}

check_no_secret "Kein Anthropic Key"  'sk-ant-[a-zA-Z0-9_-]\{20,\}'
check_no_secret "Kein OpenAI Key"     'sk-[a-zA-Z0-9]\{48,\}'
check_no_secret "Kein GitHub Token"   'ghp_[a-zA-Z0-9]\{36\}'
check_no_secret "Kein AWS Access Key" 'AKIA[0-9A-Z]\{16\}'
check_no_secret "Kein JWT Token"      'eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.'

# --- Hook-Konsistenz ---
echo ""
echo "-- Hook-Konsistenz --"
for event in PreToolUse PostToolUse Stop; do
  H_COUNT=$(jq -r ".hooks.${event} | length" "$REPO_DIR/hooks/hooks.json" 2>/dev/null || echo 0)
  for i in $(seq 0 $((H_COUNT - 1))); do
    H_TO=$(jq -r ".hooks.${event}[$i].hooks[0].timeout" "$REPO_DIR/hooks/hooks.json" 2>/dev/null)
    S_TO=$(jq -r ".${event}[$i].hooks[0].timeout" "$REPO_DIR/user-config/settings.json.example" 2>/dev/null)
    H_MATCHER=$(jq -r ".hooks.${event}[$i].matcher // \"*\"" "$REPO_DIR/hooks/hooks.json" 2>/dev/null)
    if [[ "$H_TO" != "$S_TO" ]]; then
      fail "${event}[$i] ($H_MATCHER) Timeout: hooks.json=${H_TO} vs settings=${S_TO}"
    else
      pass "${event}[$i] ($H_MATCHER) Timeout konsistent (${H_TO}s)"
    fi
  done
done

# --- Ergebnis ---
echo ""
echo "================================="
echo -e "Ergebnis: ${ERRORS} Fehler, ${WARNINGS} Warnungen"
if [[ $ERRORS -eq 0 ]]; then
  echo -e "${GREEN}Validierung BESTANDEN.${NC}"
else
  echo -e "${RED}Validierung FEHLGESCHLAGEN.${NC}"
  exit 1
fi
