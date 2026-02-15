#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# claude-forge installer
# Erstellt Symlinks von ~/develop/claude-forge/ → ~/.claude/
# Idempotent: Kann beliebig oft ausgefuehrt werden.
# ============================================================

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$CLAUDE_DIR/.backup/$TIMESTAMP"
DRY_RUN=false
WITH_CODEX=false
ERRORS=0

# --- Farben ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Argumente ---
for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY_RUN=true ;;
    --with-codex) WITH_CODEX=true ;;
    --help|-h)
      echo "Usage: install.sh [--dry-run] [--with-codex] [--help]"
      echo "  --dry-run     Zeigt was passieren wuerde, aendert nichts"
      echo "  --with-codex  Installiert zusaetzlich Codex CLI"
      exit 0 ;;
  esac
done

# --- Hilfsfunktionen ---
log_ok()   { echo -e "  ${GREEN}[OK]${NC} $1"; }
log_skip() { echo -e "  ${YELLOW}[SKIP]${NC} $1"; }
log_err()  { echo -e "  ${RED}[ERR]${NC} $1"; ERRORS=$((ERRORS + 1)); }
log_dry()  { echo -e "  ${YELLOW}[DRY]${NC} $1"; }

INSTALLED_SYMLINKS=()

cleanup_on_error() {
  echo ""
  echo -e "${RED}Fehler aufgetreten — Rollback...${NC}"
  for link in "${INSTALLED_SYMLINKS[@]}"; do
    if [[ -L "$link" ]]; then
      rm -f "$link"
      echo -e "  ${YELLOW}[ROLLBACK]${NC} Entfernt: $link"
    fi
    # Restore backup if available
    local backup_file="$BACKUP_DIR/$(basename "$link")"
    if [[ -f "$backup_file" || -d "$backup_file" ]]; then
      cp -a "$backup_file" "$link"
      echo -e "  ${YELLOW}[ROLLBACK]${NC} Wiederhergestellt: $link"
    fi
  done
  echo -e "${RED}Rollback abgeschlossen. Installation abgebrochen.${NC}"
  exit 1
}
trap cleanup_on_error ERR

backup_if_exists() {
  local target="$1"
  if [[ -e "$target" && ! -L "$target" ]]; then
    if $DRY_RUN; then
      log_dry "Wuerde sichern: $target → $BACKUP_DIR/"
    else
      mkdir -p "$BACKUP_DIR"
      cp -a "$target" "$BACKUP_DIR/$(basename "$target")"
      log_ok "Gesichert: $target → $BACKUP_DIR/"
    fi
  fi
}

create_symlink() {
  local source="$1"
  local target="$2"

  if $DRY_RUN; then
    log_dry "Wuerde verlinken: $target → $source"
    return
  fi

  backup_if_exists "$target"
  mkdir -p "$(dirname "$target")"
  ln -sfn "$source" "$target"
  INSTALLED_SYMLINKS+=("$target")
  log_ok "Verlinkt: $target → $source"
}

# --- Auto-Install fehlender Dependencies ---
auto_install() {
  local pkg="$1"
  if $DRY_RUN; then
    log_dry "Wuerde installieren: $pkg"
    return 0
  fi
  echo -e "  ${YELLOW}[AUTO]${NC} Installiere $pkg..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get install -y -qq "$pkg" 2>/dev/null && return 0
  elif command -v brew >/dev/null 2>&1; then
    brew install "$pkg" 2>/dev/null && return 0
  fi
  return 1
}

install_node() {
  if $DRY_RUN; then
    log_dry "Wuerde Node.js 20 installieren"
    return 0
  fi
  echo -e "  ${YELLOW}[AUTO]${NC} Installiere Node.js 20..."
  if command -v apt-get >/dev/null 2>&1; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - 2>/dev/null \
      && sudo apt-get install -y -qq nodejs 2>/dev/null && return 0
  elif command -v brew >/dev/null 2>&1; then
    brew install node@20 2>/dev/null && return 0
  fi
  return 1
}

auto_install_optional() {
  local cmd="$1"
  local pkg="${2:-$1}"
  if command -v "$cmd" >/dev/null 2>&1; then
    log_ok "$cmd bereits vorhanden"
    return 0
  fi
  if $DRY_RUN; then
    log_dry "Wuerde installieren: $pkg"
    return 0
  fi
  echo -e "  ${YELLOW}[AUTO]${NC} Installiere $pkg..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get install -y -qq "$pkg" 2>/dev/null && return 0
  elif command -v brew >/dev/null 2>&1; then
    brew install "$pkg" 2>/dev/null && return 0
  elif command -v pip3 >/dev/null 2>&1 && [[ "$pkg" == "ruff" ]]; then
    pip3 install --user "$pkg" 2>/dev/null && return 0
  elif command -v npm >/dev/null 2>&1 && [[ "$pkg" == "prettier" ]]; then
    npm install -g "$pkg" 2>/dev/null && return 0
  fi
  echo -e "  ${YELLOW}[WARN]${NC} $pkg konnte nicht installiert werden (optional)"
  return 1
}

# --- Pre-Checks ---
echo "=== claude-forge installer ==="
echo ""

echo "-- Pre-Checks (Pflicht) --"
if ! command -v git >/dev/null 2>&1; then
  auto_install git || log_err "git nicht gefunden und konnte nicht installiert werden."
fi
if ! command -v jq >/dev/null 2>&1; then
  auto_install jq || log_err "jq nicht gefunden und konnte nicht installiert werden."
fi
if ! command -v node >/dev/null 2>&1; then
  install_node || log_err "node nicht gefunden und konnte nicht installiert werden."
fi
if ! command -v python3 >/dev/null 2>&1; then
  auto_install python3 || log_err "python3 nicht gefunden und konnte nicht installiert werden."
fi
[[ -d "$CLAUDE_DIR" ]] || { mkdir -p "$CLAUDE_DIR" && log_ok "$CLAUDE_DIR erstellt"; }

# Final verification
command -v git >/dev/null 2>&1 || { log_err "git nicht verfuegbar."; }
command -v jq >/dev/null 2>&1 || { log_err "jq nicht verfuegbar."; }
command -v node >/dev/null 2>&1 || { log_err "node nicht verfuegbar."; }
command -v python3 >/dev/null 2>&1 || { log_err "python3 nicht verfuegbar."; }

if [[ $ERRORS -gt 0 ]]; then
  echo -e "\n${RED}Pre-Checks fehlgeschlagen. $ERRORS Fehler.${NC}"
  exit 1
fi
log_ok "Alle Pflicht-Dependencies vorhanden."

# --- Optionale Formatter (fuer auto-format.sh) ---
echo ""
echo "-- Optionale Formatter --"
auto_install_optional shfmt
auto_install_optional ruff
auto_install_optional prettier

if pgrep -f "claude.*--plugin-dir.*claude-forge" >/dev/null 2>&1; then
  log_err "claude-forge laeuft als Plugin. Beende Claude und starte ohne --plugin-dir."
  exit 1
fi

# --- Phase 1: User-Config ---
echo ""
echo "-- Phase 1: User-Config --"

# settings.json und CLAUDE.md: Kopieren aus .example (nur wenn Ziel nicht existiert)
for example_file in settings.json CLAUDE.md; do
  if [[ ! -f "$CLAUDE_DIR/$example_file" ]]; then
    if $DRY_RUN; then
      log_dry "Wuerde $example_file aus .example erstellen"
    else
      cp "$REPO_DIR/user-config/${example_file}.example" "$CLAUDE_DIR/$example_file"
      log_ok "$example_file aus .example erstellt"
    fi
  else
    log_skip "$example_file existiert bereits (nicht ueberschrieben)"
  fi
done

# MEMORY.md: Symlink (wird von Claude Code automatisch gepflegt)
create_symlink "$REPO_DIR/user-config/MEMORY.md" "$CLAUDE_DIR/MEMORY.md"

# Rules: Symlink aus Repo-Root
create_symlink "$REPO_DIR/rules" "$CLAUDE_DIR/rules"

# --- Phase 2: Hooks ---
echo ""
echo "-- Phase 2: Hooks --"
create_symlink "$REPO_DIR/hooks" "$CLAUDE_DIR/hooks"

# --- Phase 3: Agents (einzeln verlinken) ---
echo ""
echo "-- Phase 3: Agents --"
mkdir -p "$CLAUDE_DIR/agents"
for agent in "$REPO_DIR/agents/"*.md; do
  [[ -f "$agent" ]] || continue
  create_symlink "$agent" "$CLAUDE_DIR/agents/$(basename "$agent")"
done

# --- Phase 4: Skills (einzeln verlinken) ---
echo ""
echo "-- Phase 4: Skills --"
mkdir -p "$CLAUDE_DIR/skills"
for skill_dir in "$REPO_DIR/skills/"*/; do
  [[ -d "$skill_dir" ]] || continue
  skill_name="$(basename "$skill_dir")"
  create_symlink "$skill_dir" "$CLAUDE_DIR/skills/$skill_name"
done

# --- Phase 5: Commands (Symlink auf gesamtes Verzeichnis) ---
echo ""
echo "-- Phase 5: Commands --"
create_symlink "$REPO_DIR/commands" "$CLAUDE_DIR/commands"

# --- Phase 6: Multi-Model (Wrapper verlinken) ---
echo ""
echo "-- Phase 6: Multi-Model --"
create_symlink "$REPO_DIR/multi-model" "$CLAUDE_DIR/multi-model"

# --- Phase 7: Codex CLI (optional) ---
if $WITH_CODEX; then
  echo ""
  echo "-- Phase 7: Codex CLI --"
  if $DRY_RUN; then
    log_dry "Wuerde codex-setup.sh ausfuehren"
  else
    bash "$REPO_DIR/multi-model/codex-setup.sh"
  fi
fi

# --- Validierung ---
echo ""
if ! $DRY_RUN; then
  echo "-- Validierung --"
  bash "$REPO_DIR/validate.sh" || {
    echo -e "${YELLOW}[WARN]${NC} Validierung hat Fehler gemeldet (Symlinks sind trotzdem installiert)."
  }
fi

# --- Hinweis: Codex CLI ---
if ! command -v codex >/dev/null 2>&1; then
  echo ""
  echo -e "${YELLOW}[INFO]${NC} Codex CLI ist nicht installiert. /multi-* Commands benoetigen Codex."
  echo -e "       Optional installieren: ${GREEN}bash install.sh --with-codex${NC}"
fi

echo ""
echo -e "${GREEN}=== Installation abgeschlossen ===${NC}"
if [[ -d "$BACKUP_DIR" ]]; then
  echo -e "Backups: $BACKUP_DIR"
fi
