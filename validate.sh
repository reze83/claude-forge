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

check() {
  local desc="$1"; shift
  if eval "$@" 2>/dev/null; then
    echo -e "  ${GREEN}[PASS]${NC} $desc"
  else
    echo -e "  ${RED}[FAIL]${NC} $desc"
    ERRORS=$((ERRORS + 1))
  fi
}

warn() {
  local desc="$1"; shift
  if ! eval "$@" 2>/dev/null; then
    echo -e "  ${YELLOW}[WARN]${NC} $desc"
    WARNINGS=$((WARNINGS + 1))
  else
    echo -e "  ${GREEN}[PASS]${NC} $desc"
  fi
}

echo "=== claude-forge validation ==="
echo ""

# --- Dateien & Symlinks ---
echo "-- Dateien & Symlinks --"
check "settings.json vorhanden"      "[[ -f '$CLAUDE_DIR/settings.json' ]]"
check "CLAUDE.md vorhanden"          "[[ -f '$CLAUDE_DIR/CLAUDE.md' ]]"
check "MEMORY.md ist Symlink"        "[[ -L '$CLAUDE_DIR/MEMORY.md' ]]"
check "rules/ ist Symlink"           "[[ -L '$CLAUDE_DIR/rules' ]]"
check "hooks/ ist Symlink"           "[[ -L '$CLAUDE_DIR/hooks' ]]"
check "commands/ ist Symlink"        "[[ -L '$CLAUDE_DIR/commands' ]]"

# --- JSON-Validitaet ---
echo ""
echo "-- JSON-Validitaet --"
check "settings.json.example valides JSON"  "jq empty '$REPO_DIR/user-config/settings.json.example'"
check "hooks.json valides JSON"      "jq empty '$REPO_DIR/hooks/hooks.json'"
check "plugin.json valides JSON"     "jq empty '$REPO_DIR/.claude-plugin/plugin.json'"

# --- Hook-Scripts ---
echo ""
echo "-- Hook-Scripts --"
for hook in "$REPO_DIR/hooks/"*.sh; do
  [[ -f "$hook" ]] || continue
  name="$(basename "$hook")"
  check "$name ist ausfuehrbar"       "[[ -x '$hook' ]]"
  check "$name hat Shebang"           "head -1 '$hook' | grep -q '^#!/'"
  check "$name hat set -euo pipefail" "head -3 '$hook' | grep -q 'set -euo pipefail'"
done

# --- Agents ---
echo ""
echo "-- Agents --"
for agent in "$REPO_DIR/agents/"*.md; do
  [[ -f "$agent" ]] || continue
  name="$(basename "$agent")"
  check "$name hat YAML Frontmatter"  "head -1 '$agent' | grep -q '^---'"
  check "$name hat name: Feld"        "grep -q '^name:' '$agent'"
  check "$name hat description: Feld" "grep -q '^description:' '$agent'"
done

# --- Skills ---
echo ""
echo "-- Skills --"
for skill in "$REPO_DIR/skills/"*/SKILL.md; do
  [[ -f "$skill" ]] || continue
  name="$(basename "$(dirname "$skill")")"
  check "$name/SKILL.md hat Frontmatter" "head -1 '$skill' | grep -q '^---'"
  check "$name/SKILL.md hat name: Feld"  "grep -q '^name:' '$skill'"
done

# --- Commands ---
echo ""
echo "-- Commands --"
for cmd in "$REPO_DIR/commands/"*.md; do
  [[ -f "$cmd" ]] || continue
  name="$(basename "$cmd")"
  check "$name hat Frontmatter"       "head -1 '$cmd' | grep -q '^---'"
  check "$name hat description: Feld" "grep -q '^description:' '$cmd'"
done

# --- Tools ---
echo ""
echo "-- System-Tools --"
check "node >= 20"       "node -v 2>/dev/null | grep -qE 'v2[0-9]'"
check "python3 >= 3.12"  "python3 -c 'import sys; assert sys.version_info >= (3,12)' 2>/dev/null"
check "git vorhanden"    "git --version >/dev/null 2>&1"
check "jq vorhanden"     "jq --version >/dev/null 2>&1"
warn  "codex CLI"        "command -v codex >/dev/null 2>&1"
warn  "ruff vorhanden"   "command -v ruff >/dev/null 2>&1"

# --- Secrets-Check ---
echo ""
echo "-- Secrets-Scan --"
check "Kein API-Key in Repo"  "! grep -rIl 'sk-[a-zA-Z0-9]\{20,\}' '$REPO_DIR/' --include='*.json' --include='*.md' --include='*.sh' 2>/dev/null"
check "Kein Token in Repo"    "! grep -rIl 'ghp_[a-zA-Z0-9]\{20,\}' '$REPO_DIR/' --include='*.json' --include='*.md' --include='*.sh' 2>/dev/null"

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
