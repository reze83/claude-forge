#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# claude-forge uninstaller
# Entfernt alle Symlinks die auf das Repo zeigen.
# Stellt Backups wieder her falls vorhanden.
# ============================================================

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
DRY_RUN=false

# shellcheck disable=SC2034  # RED kept for consistency with other scripts
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Argumente ---
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --help | -h)
      echo "Usage: uninstall.sh [--dry-run] [--help]"
      echo "  --dry-run  Zeigt was entfernt wuerde, aendert nichts"
      exit 0
      ;;
  esac
done

remove_if_symlink_to_repo() {
  local target="$1"
  if [[ -L "$target" ]]; then
    local link_target
    link_target="$(readlink -f "$target" 2>/dev/null || readlink "$target")"
    if [[ "$link_target" == "$REPO_DIR/"* || "$link_target" == "$REPO_DIR" ]]; then
      if $DRY_RUN; then
        echo -e "  ${YELLOW}[DRY]${NC} Wuerde entfernen: $target"
      else
        rm "$target"
        echo -e "  ${GREEN}[OK]${NC} Entfernt: $target"
      fi
    fi
  fi
}

echo "=== claude-forge uninstaller ==="
if $DRY_RUN; then
  echo -e "${YELLOW}(Dry-Run Modus — keine Aenderungen)${NC}"
fi
echo ""

# Alle Datei-Symlinks in Verzeichnissen entfernen (neues Layout)
for dir in rules hooks commands multi-model agents; do
  if [[ -d "$CLAUDE_DIR/$dir" ]]; then
    for item in "$CLAUDE_DIR/$dir"/*; do
      [[ -e "$item" || -L "$item" ]] || continue
      remove_if_symlink_to_repo "$item"
    done
  fi
  # Fallback: alte Directory-Symlinks (vor v2) ebenfalls entfernen
  remove_if_symlink_to_repo "$CLAUDE_DIR/$dir"
done

# Skills (rekursiv — Datei-Symlinks in Unterverzeichnissen)
for skill_dir in "$REPO_DIR/skills/"*/; do
  [[ -d "$skill_dir" ]] || continue
  skill_name="$(basename "$skill_dir")"
  target_skill="$CLAUDE_DIR/skills/$skill_name"
  # Fallback: alte Directory-Symlinks (vor v0.6) ebenfalls entfernen
  remove_if_symlink_to_repo "$target_skill"
  if [[ -d "$target_skill" ]]; then
    find "$target_skill" -type l | while IFS= read -r link; do
      remove_if_symlink_to_repo "$link"
    done
    # Leere Verzeichnisse aufraeumen (bottom-up)
    find "$target_skill" -type d -empty -delete 2>/dev/null || true
  fi
done

# Letztes Backup finden und anbieten
LATEST_BACKUP="$(ls -dt "$CLAUDE_DIR/.backup/"*/ 2>/dev/null | head -1 || true)"
if [[ -n "$LATEST_BACKUP" ]]; then
  echo ""
  echo -e "${YELLOW}Backup gefunden: $LATEST_BACKUP${NC}"
  echo "Manuell wiederherstellen mit: cp -a $LATEST_BACKUP* $CLAUDE_DIR/"
fi

echo ""
echo -e "${GREEN}=== Deinstallation abgeschlossen ===${NC}"
