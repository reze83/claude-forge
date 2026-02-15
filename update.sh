#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# claude-forge updater
# Holt die neueste Version und aktualisiert die Installation.
# Usage: bash update.sh [--check]
#   --check  Nur pruefen ob Updates verfuegbar sind
# ============================================================

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECK_ONLY=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

for arg in "$@"; do
  case "$arg" in
    --check) CHECK_ONLY=true ;;
    --help|-h)
      echo "Usage: update.sh [--check] [--help]"
      echo "  --check  Nur pruefen ob Updates verfuegbar sind"
      exit 0 ;;
  esac
done

cd "$REPO_DIR"

# --- Git-Check ---
if [[ ! -d ".git" ]]; then
  echo -e "${RED}[ERR]${NC} Kein Git-Repo. Update nur mit git clone Installation moeglich."
  exit 1
fi

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
CURRENT_COMMIT="$(git rev-parse --short HEAD)"

echo "=== claude-forge update ==="
echo -e "Branch: ${CYAN}${CURRENT_BRANCH}${NC} (${CURRENT_COMMIT})"
echo ""

# --- Fetch ---
echo "-- Pruefe auf Updates --"
git fetch --quiet origin "$CURRENT_BRANCH" 2>/dev/null || {
  echo -e "${RED}[ERR]${NC} git fetch fehlgeschlagen. Netzwerk pruefen."
  exit 1
}

LOCAL="$(git rev-parse HEAD)"
REMOTE="$(git rev-parse "origin/$CURRENT_BRANCH" 2>/dev/null || echo "$LOCAL")"

if [[ "$LOCAL" == "$REMOTE" ]]; then
  echo -e "  ${GREEN}[OK]${NC} Bereits aktuell."
  exit 0
fi

# --- Aenderungen anzeigen ---
COMMIT_COUNT="$(git rev-list --count HEAD.."origin/$CURRENT_BRANCH")"
echo -e "  ${YELLOW}${COMMIT_COUNT} neue Commits verfuegbar${NC}"
echo ""
echo "-- Aenderungen --"
git log --oneline --no-merges HEAD.."origin/$CURRENT_BRANCH"
echo ""

if $CHECK_ONLY; then
  echo -e "Update ausfuehren mit: ${CYAN}bash update.sh${NC}"
  exit 0
fi

# --- Lokale Aenderungen pruefen ---
if [[ -n "$(git status --porcelain)" ]]; then
  echo -e "${YELLOW}[WARN]${NC} Lokale Aenderungen gefunden — stashe sie vor dem Update."
  git stash --include-untracked
  STASHED=true
  echo -e "  ${GREEN}[OK]${NC} Aenderungen gestashed."
else
  STASHED=false
fi

# --- Pull ---
echo ""
echo "-- Update --"
git pull --ff-only origin "$CURRENT_BRANCH" || {
  echo -e "${RED}[ERR]${NC} Fast-forward merge nicht moeglich. Manuell mergen:"
  echo "  git pull origin $CURRENT_BRANCH"
  if $STASHED; then
    git stash pop
  fi
  exit 1
}

NEW_COMMIT="$(git rev-parse --short HEAD)"
echo -e "  ${GREEN}[OK]${NC} Aktualisiert: ${CURRENT_COMMIT} → ${NEW_COMMIT}"

# --- Installer neu ausfuehren (neue Symlinks + Dependencies) ---
echo ""
echo "-- Installation aktualisieren --"
bash "$REPO_DIR/install.sh"

# --- Stash wiederherstellen ---
if $STASHED; then
  echo ""
  echo "-- Lokale Aenderungen wiederherstellen --"
  git stash pop && echo -e "  ${GREEN}[OK]${NC} Stash wiederhergestellt." \
    || echo -e "${YELLOW}[WARN]${NC} Stash-Konflikte. Manuell loesen: git stash pop"
fi

echo ""
echo -e "${GREEN}=== Update abgeschlossen ===${NC}"
