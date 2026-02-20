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

# --- Dateien & Links ---
echo "-- Dateien & Links --"
[[ -f "$REPO_DIR/VERSION" ]] && pass "VERSION vorhanden" || fail "VERSION vorhanden"
[[ -f "$CLAUDE_DIR/settings.json" ]] && pass "settings.json vorhanden" || fail "settings.json vorhanden"
[[ -f "$CLAUDE_DIR/CLAUDE.md" ]] && pass "CLAUDE.md vorhanden" || fail "CLAUDE.md vorhanden"

# Repo-Pfad aus Marker oder Fallback
FORGE_REPO_DIR=""
if [[ -f "$CLAUDE_DIR/.forge-repo" ]]; then
  FORGE_REPO_DIR="$(cat "$CLAUDE_DIR/.forge-repo")"
fi
[[ -z "$FORGE_REPO_DIR" ]] && FORGE_REPO_DIR="$REPO_DIR"

check_dir_with_links() {
  local name="$1"
  local target="$CLAUDE_DIR/$name"
  if [[ ! -d "$target" ]]; then
    fail "$name Verzeichnis fehlt"
    return
  fi
  local link_count=0
  for item in "$target"/*; do
    [[ -e "$item" || -L "$item" ]] || continue
    # Symlink zum Repo (alte Installation)
    if [[ -L "$item" ]]; then
      link_count=$((link_count + 1))
      continue
    fi
    # Hardlink: Inode-Vergleich mit Repo-Datei
    local repo_file
    repo_file="$FORGE_REPO_DIR/$name/$(basename "$item")"
    if [[ -f "$item" && -f "$repo_file" ]] &&
      [[ "$(stat -c %i "$item")" == "$(stat -c %i "$repo_file")" ]]; then
      link_count=$((link_count + 1))
    fi
  done
  if [[ $link_count -gt 0 ]]; then
    pass "$name/ ($link_count Datei-Links)"
  else
    fail "$name/ hat keine Datei-Links"
  fi
}

check_dir_with_links_recursive() {
  local name="$1"
  local target="$CLAUDE_DIR/$name"
  if [[ ! -d "$target" ]]; then
    fail "$name Verzeichnis fehlt"
    return
  fi
  local link_count=0
  while IFS= read -r item; do
    [[ -e "$item" || -L "$item" ]] || continue
    if [[ -L "$item" ]]; then
      link_count=$((link_count + 1))
      continue
    fi
    local rel="${item#"$CLAUDE_DIR"/}"
    local repo_file="$FORGE_REPO_DIR/$rel"
    if [[ -f "$item" && -f "$repo_file" ]] &&
      [[ "$(stat -c %i "$item")" == "$(stat -c %i "$repo_file")" ]]; then
      link_count=$((link_count + 1))
    fi
  done < <(find "$target" \( -type l -o -type f \))
  if [[ $link_count -gt 0 ]]; then
    pass "$name/ ($link_count Datei-Links)"
  else
    fail "$name/ hat keine Datei-Links"
  fi
}

check_dir_with_links "rules"
check_dir_with_links "hooks"
check_dir_with_links "commands"
check_dir_with_links "agents"
check_dir_with_links_recursive "multi-model"
check_dir_with_links_recursive "skills"

# --- JSON-Validitaet ---
echo ""
echo "-- JSON-Validitaet --"
jq empty "$REPO_DIR/user-config/settings.json.example" 2>/dev/null &&
  pass "settings.json.example valides JSON" || fail "settings.json.example valides JSON"
jq empty "$REPO_DIR/hooks/hooks.json" 2>/dev/null &&
  pass "hooks.json valides JSON" || fail "hooks.json valides JSON"
jq empty "$REPO_DIR/.claude-plugin/plugin.json" 2>/dev/null &&
  pass "plugin.json valides JSON" || fail "plugin.json valides JSON"

# --- Hook-Scripts ---
echo ""
echo "-- Hook-Scripts --"
for hook in "$REPO_DIR/hooks/"*.sh; do
  [[ -f "$hook" ]] || continue
  name="$(basename "$hook")"
  [[ -x "$hook" ]] &&
    pass "$name ist ausfuehrbar" || fail "$name ist ausfuehrbar"
  head -1 "$hook" | grep -q '^#!/' 2>/dev/null &&
    pass "$name hat Shebang" || fail "$name hat Shebang"
  head -3 "$hook" | grep -q 'set -euo pipefail' 2>/dev/null &&
    pass "$name hat set -euo pipefail" || fail "$name hat set -euo pipefail"
done

# --- Agents ---
echo ""
echo "-- Agents --"
for agent in "$REPO_DIR/agents/"*.md; do
  [[ -f "$agent" ]] || continue
  name="$(basename "$agent")"
  head -1 "$agent" | grep -q '^---' 2>/dev/null &&
    pass "$name hat YAML Frontmatter" || fail "$name hat YAML Frontmatter"
  grep -q '^name:' "$agent" 2>/dev/null &&
    pass "$name hat name: Feld" || fail "$name hat name: Feld"
  grep -q '^description:' "$agent" 2>/dev/null &&
    pass "$name hat description: Feld" || fail "$name hat description: Feld"
done

# --- Skills ---
echo ""
echo "-- Skills --"
for skill in "$REPO_DIR/skills/"*/SKILL.md; do
  [[ -f "$skill" ]] || continue
  name="$(basename "$(dirname "$skill")")"
  head -1 "$skill" | grep -q '^---' 2>/dev/null &&
    pass "$name/SKILL.md hat Frontmatter" || fail "$name/SKILL.md hat Frontmatter"
  grep -q '^name:' "$skill" 2>/dev/null &&
    pass "$name/SKILL.md hat name: Feld" || fail "$name/SKILL.md hat name: Feld"
done

# --- Commands ---
echo ""
echo "-- Commands --"
for cmd in "$REPO_DIR/commands/"*.md; do
  [[ -f "$cmd" ]] || continue
  name="$(basename "$cmd")"
  head -1 "$cmd" | grep -q '^---' 2>/dev/null &&
    pass "$name hat Frontmatter" || fail "$name hat Frontmatter"
  grep -q '^description:' "$cmd" 2>/dev/null &&
    pass "$name hat description: Feld" || fail "$name hat description: Feld"
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

python3 -c 'import sys; assert sys.version_info >= (3,10)' 2>/dev/null &&
  pass "python3 >= 3.10" || fail "python3 >= 3.10"
git --version >/dev/null 2>&1 &&
  pass "git vorhanden" || fail "git vorhanden"
jq --version >/dev/null 2>&1 &&
  pass "jq vorhanden" || fail "jq vorhanden"
command -v codex >/dev/null 2>&1 &&
  pass "codex CLI" || warning "codex CLI"
command -v ruff >/dev/null 2>&1 &&
  pass "ruff vorhanden" || warning "ruff vorhanden"
command -v shfmt >/dev/null 2>&1 &&
  pass "shfmt vorhanden" || warning "shfmt vorhanden"
command -v shellcheck >/dev/null 2>&1 &&
  pass "shellcheck vorhanden" || warning "shellcheck vorhanden"
command -v bats >/dev/null 2>&1 &&
  pass "bats-core vorhanden" || warning "bats-core vorhanden"
command -v markdownlint-cli2 >/dev/null 2>&1 &&
  pass "markdownlint-cli2 vorhanden" || warning "markdownlint-cli2 vorhanden"
command -v gitleaks >/dev/null 2>&1 &&
  pass "gitleaks vorhanden" || warning "gitleaks vorhanden"
command -v actionlint >/dev/null 2>&1 &&
  pass "actionlint vorhanden" || warning "actionlint vorhanden"

# --- Secrets-Check ---
echo ""
echo "-- Secrets-Scan --"

check_no_secret() {
  local desc="$1" pattern="$2"
  # Scan all files; exclude lines containing pragma allowlist and test assertion lines
  if grep -rIn "$pattern" "$REPO_DIR/" --include='*.json' --include='*.md' --include='*.sh' 2>/dev/null |
    grep -v 'pragma: allowlist secret' |
    grep -v 'assert_exit' |
    grep -v 'check_no_secret' |
    grep -q .; then
    fail "$desc"
  else
    pass "$desc"
  fi
}

check_no_secret "Kein Anthropic Key" 'sk-ant-[a-zA-Z0-9_-]\{20,\}'
check_no_secret "Kein OpenAI Key" 'sk-[a-zA-Z0-9]\{48,\}'
check_no_secret "Kein GitHub Token" 'ghp_[a-zA-Z0-9]\{36\}'
check_no_secret "Kein AWS Access Key" 'AKIA[0-9A-Z]\{16\}'
check_no_secret "Kein JWT Token" 'eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.'

# --- Hook-Konsistenz ---
echo ""
echo "-- Hook-Konsistenz --"
# Dynamically get all hook event types from hooks.json
# Setup is plugin-mode only — intentionally absent from settings.json.example
HOOK_EVENTS=$(jq -r '.hooks | keys[] | select(. != "Setup")' "$REPO_DIR/hooks/hooks.json" 2>/dev/null || echo "")
for event in $HOOK_EVENTS; do
  H_COUNT=$(jq -r ".hooks.${event} | length" "$REPO_DIR/hooks/hooks.json" 2>/dev/null || echo 0)
  for i in $(seq 0 $((H_COUNT - 1))); do
    H_TO=$(jq -r ".hooks.${event}[$i].hooks[0].timeout" "$REPO_DIR/hooks/hooks.json" 2>/dev/null)
    S_TO=$(jq -r "(.hooks // {}).${event}[$i].hooks[0].timeout" "$REPO_DIR/user-config/settings.json.example" 2>/dev/null)
    H_MATCHER=$(jq -r ".hooks.${event}[$i].matcher // \"*\"" "$REPO_DIR/hooks/hooks.json" 2>/dev/null)
    if [[ "$H_TO" != "$S_TO" ]]; then
      fail "${event}[$i] ($H_MATCHER) Timeout: hooks.json=${H_TO} vs settings=${S_TO}"
    else
      pass "${event}[$i] ($H_MATCHER) Timeout konsistent (${H_TO}s)"
    fi
  done
done

# --- Hook-Script ↔ hooks.json Abgleich ---
echo ""
echo "-- Hook-Script Abgleich --"
# Every .sh in hooks/ (except lib.sh) should be referenced in hooks.json
for hook in "$REPO_DIR/hooks/"*.sh; do
  [[ -f "$hook" ]] || continue
  name="$(basename "$hook")"
  [[ "$name" == "lib.sh" ]] && continue
  if grep -q "$name" "$REPO_DIR/hooks/hooks.json" 2>/dev/null; then
    pass "$name in hooks.json referenziert"
  else
    warning "$name nicht in hooks.json referenziert (verwaist?)"
  fi
done
# Every script referenced in hooks.json should exist
for ref in $(jq -r '.. | .command? // empty' "$REPO_DIR/hooks/hooks.json" 2>/dev/null | grep -oE '[a-z_-]+\.sh'); do
  if [[ -f "$REPO_DIR/hooks/$ref" ]]; then
    pass "$ref existiert"
  else
    fail "$ref in hooks.json referenziert aber fehlt"
  fi
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
