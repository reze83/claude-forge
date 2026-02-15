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

# --- Pre-Checks ---
echo "=== claude-forge installer ==="
echo ""

echo "-- Pre-Checks --"
command -v jq >/dev/null 2>&1 || { log_err "jq nicht gefunden. apt install jq"; }
command -v node >/dev/null 2>&1 || { log_err "node nicht gefunden."; }
command -v git >/dev/null 2>&1 || { log_err "git nicht gefunden."; }
[[ -d "$CLAUDE_DIR" ]] || { log_err "$CLAUDE_DIR existiert nicht."; }

if [[ $ERRORS -gt 0 ]]; then
  echo -e "\n${RED}Pre-Checks fehlgeschlagen. $ERRORS Fehler.${NC}"
  exit 1
fi
log_ok "Alle Pre-Checks bestanden."

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
  bash "$REPO_DIR/validate.sh"
fi

echo ""
echo -e "${GREEN}=== Installation abgeschlossen ===${NC}"
if [[ -d "$BACKUP_DIR" ]]; then
  echo -e "Backups: $BACKUP_DIR"
fi
