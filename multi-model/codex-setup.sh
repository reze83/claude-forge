#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Codex CLI Setup fuer Claude Code Multi-Model Workflow
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Codex CLI Setup ==="
echo ""

# --- Pre-Check: Node.js ---
if ! command -v node >/dev/null 2>&1; then
  echo -e "${RED}[ERR]${NC} Node.js nicht gefunden."
  exit 1
fi

NODE_MAJOR=$(node -v | sed 's/v\([0-9]*\).*/\1/')
if [[ "$NODE_MAJOR" -lt 20 ]]; then
  echo -e "${RED}[ERR]${NC} Node.js >= 20 erforderlich (gefunden: $(node -v))"
  exit 1
fi
echo -e "${GREEN}[OK]${NC} Node.js $(node -v)"

# --- Installation ---
if command -v codex >/dev/null 2>&1; then
  echo -e "${YELLOW}[SKIP]${NC} Codex CLI bereits installiert: $(codex --version 2>/dev/null || echo 'unbekannt')"
else
  echo "Installiere Codex CLI..."
  npm install -g @openai/codex
  echo -e "${GREEN}[OK]${NC} Codex CLI installiert"
fi

# --- Login ---
echo ""
echo "Starte Codex Login..."
echo -e "${YELLOW}Hinweis: Falls der Browser nicht oeffnet (WSL2), nutze --device-auth.${NC}"
echo "  1) Browser-Login:  codex login"
echo "  2) Device-Auth:    codex login --device-auth  (fuer Remote/WSL2)"
echo ""
if [[ ! -t 0 ]]; then
  LOGIN_METHOD="${CODEX_LOGIN_METHOD:-1}"
  echo -e "${YELLOW}[INFO]${NC} Nicht-interaktiv: nutze Login-Methode $LOGIN_METHOD"
else
  read -rp "Welche Methode? [1/2]: " LOGIN_METHOD
fi
case "$LOGIN_METHOD" in
  2) codex login --device-auth ;;
  *) codex login ;;
esac

# --- Verifikation ---
echo ""
echo "Teste Codex CLI..."
if codex --version >/dev/null 2>&1; then
  echo -e "${GREEN}[OK]${NC} Codex CLI funktioniert: $(codex --version)"
else
  echo -e "${RED}[ERR]${NC} Codex CLI Test fehlgeschlagen"
  exit 1
fi

echo ""
echo -e "${GREEN}=== Codex CLI Setup abgeschlossen ===${NC}"
echo "Nutze jetzt /multi-workflow <aufgabe> in Claude Code."
