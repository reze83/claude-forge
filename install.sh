#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# claude-forge installer
# Erstellt Symlinks von claude-forge/ → ~/.claude/
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
    --dry-run) DRY_RUN=true ;;
    --with-codex) WITH_CODEX=true ;;
    --help | -h)
      echo "Usage: install.sh [--dry-run] [--with-codex] [--help]"
      echo "  --dry-run     Zeigt was passieren wuerde, aendert nichts"
      echo "  --with-codex  Installiert zusaetzlich Codex CLI"
      exit 0
      ;;
  esac
done

# --- Hilfsfunktionen ---
log_ok() { echo -e "  ${GREEN}[OK]${NC} $1"; }
log_skip() { echo -e "  ${YELLOW}[SKIP]${NC} $1"; }
log_err() {
  echo -e "  ${RED}[ERR]${NC} $1"
  ERRORS=$((ERRORS + 1))
}
log_dry() { echo -e "  ${YELLOW}[DRY]${NC} $1"; }

INSTALLED_SYMLINKS=()

cleanup_on_error() {
  echo ""
  echo -e "${RED}Fehler aufgetreten — Rollback...${NC}"
  local backup_file
  for link in "${INSTALLED_SYMLINKS[@]}"; do
    if [[ -L "$link" ]]; then
      rm -f "$link"
      echo -e "  ${YELLOW}[ROLLBACK]${NC} Entfernt: $link"
    fi
    # Restore backup if available
    backup_file="$BACKUP_DIR/$(basename "$link")"
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
  if command -v brew >/dev/null 2>&1; then
    brew install node@20 2>/dev/null && return 0
  elif command -v apt-get >/dev/null 2>&1; then
    # Download setup script first, then execute (safer than curl|bash)
    local setup_script
    setup_script="$(mktemp "${TMPDIR:-/tmp}/nodesource-setup-XXXXXX.sh")"
    if curl -fsSL https://deb.nodesource.com/setup_20.x -o "$setup_script" 2>/dev/null; then
      sudo -E bash "$setup_script" 2>/dev/null &&
        sudo apt-get install -y -qq nodejs 2>/dev/null
      local result=$?
      rm -f "$setup_script"
      [[ $result -eq 0 ]] && return 0
    fi
    rm -f "$setup_script" 2>/dev/null || true
  fi
  return 1
}

_install_python_tool() {
  local cmd="$1"
  local pkg="$2"
  local venv_dir

  if command -v pip3 >/dev/null 2>&1; then
    pip3 install --user "$pkg" 2>/dev/null && return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 -m pip install --user "$pkg" 2>/dev/null && return 0
    # Fallback: venv-based install (Debian/Ubuntu block system pip)
    venv_dir="$HOME/.local/venvs/claude-forge-tools"
    if python3 -m venv "$venv_dir" 2>/dev/null &&
      "$venv_dir/bin/pip" install "$pkg" 2>/dev/null; then
      mkdir -p "$HOME/.local/bin"
      ln -sf "$venv_dir/bin/$cmd" "$HOME/.local/bin/$cmd"
      log_ok "$pkg installiert via venv ($venv_dir)"
      return 0
    fi
  fi
  return 1
}

_install_node_tool() {
  local cmd="$1"
  local pkg="$2"
  local npm_bin

  if command -v npm >/dev/null 2>&1; then
    npm install -g "$pkg" 2>/dev/null || true
    # Verify binary is in PATH after npm install
    if command -v "$cmd" >/dev/null 2>&1; then
      return 0
    fi
    # npm global bin may not be in PATH — create symlink as fallback
    npm_bin="$(npm prefix -g 2>/dev/null)/bin/$cmd"
    if [[ -x "$npm_bin" ]]; then
      mkdir -p "$HOME/.local/bin"
      ln -sf "$npm_bin" "$HOME/.local/bin/$cmd"
      log_ok "$pkg installiert (Symlink: ~/.local/bin/$cmd)"
      echo -e "  ${YELLOW}[INFO]${NC} npm global bin ist nicht im PATH. Stelle sicher, dass ~/.local/bin im PATH liegt."
      return 0
    fi
  fi
  return 1
}

_install_github_binary() {
  local cmd="$1"
  local repo="$2"
  local os arch tarball_url tarball_file

  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  # Map uname -m to regex matching common GitHub release naming conventions
  case "$(uname -m)" in
    x86_64) arch="(x86_64|x64|amd64)" ;;
    aarch64 | arm64) arch="(arm64|aarch64)" ;;
    *) return 1 ;;
  esac

  # Fetch latest release tarball URL from GitHub API
  tarball_url="$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null |
    jq -r --arg os "$os" --arg arch "$arch" \
      '.assets[] | select(.name | test($os; "i")) | select(.name | test($arch)) | select(.name | test("\\.(tar\\.gz|tgz)$")) | .browser_download_url' |
    head -1)"

  if [[ -z "$tarball_url" || "$tarball_url" == "null" ]]; then
    return 1
  fi

  tarball_file="$(mktemp "${TMPDIR:-/tmp}/github-binary-XXXXXX.tar.gz")"
  if curl -fsSL "$tarball_url" -o "$tarball_file" 2>/dev/null; then
    mkdir -p "$HOME/.local/bin"
    tar -xzf "$tarball_file" -C "$HOME/.local/bin" "$cmd" 2>/dev/null ||
      tar -xzf "$tarball_file" --strip-components=1 -C "$HOME/.local/bin" 2>/dev/null ||
      {
        rm -f "$tarball_file"
        return 1
      }
    chmod +x "$HOME/.local/bin/$cmd"
    rm -f "$tarball_file"
    log_ok "$cmd installiert via GitHub Release ($repo)"
    return 0
  fi
  rm -f "$tarball_file" 2>/dev/null || true
  return 1
}

_install_bats_core() {
  local tmp_dir prefix
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/bats-core-XXXXXX")"
  prefix="${HOME}/.local"
  git clone --depth 1 https://github.com/bats-core/bats-core.git "$tmp_dir" 2>/dev/null || { rm -rf "$tmp_dir"; return 1; }
  mkdir -p "$prefix"
  bash "$tmp_dir/install.sh" "$prefix" 2>/dev/null || { rm -rf "$tmp_dir"; return 1; }
  rm -rf "$tmp_dir"
  # Ensure ~/.local/bin is in PATH for current session
  if ! command -v bats >/dev/null 2>&1; then
    export PATH="$prefix/bin:$PATH"
  fi
  if command -v bats >/dev/null 2>&1; then
    log_ok "bats-core installiert via git clone ($prefix)"
    return 0
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
  # bats-core: apt package name is "bats", brew name is "bats-core"
  local apt_pkg="$pkg"
  [[ "$pkg" == "bats-core" ]] && apt_pkg="bats"
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get install -y -qq "$apt_pkg" 2>/dev/null && return 0
  elif command -v brew >/dev/null 2>&1; then
    brew install "$pkg" 2>/dev/null && return 0
  fi
  if [[ "$pkg" == "ruff" ]]; then
    _install_python_tool "$cmd" "$pkg" && return 0
  elif [[ "$pkg" == "prettier" || "$pkg" == "markdownlint-cli2" ]]; then
    _install_node_tool "$cmd" "$pkg" && return 0
  elif [[ "$pkg" == "gitleaks" ]]; then
    _install_github_binary "gitleaks" "gitleaks/gitleaks" && return 0
  elif [[ "$pkg" == "actionlint" ]]; then
    _install_github_binary "actionlint" "rhysd/actionlint" && return 0
  elif [[ "$pkg" == "bats-core" ]]; then
    _install_bats_core && return 0
  fi
  echo -e "  ${YELLOW}[WARN]${NC} $pkg konnte nicht installiert werden (optional)"
  return 1
}

# --- Pre-Checks ---
echo "=== claude-forge installer ==="
echo ""

# Cache sudo credentials upfront (prompts for password once if needed)
if ! $DRY_RUN && command -v sudo >/dev/null 2>&1 && ! sudo -n true 2>/dev/null; then
  echo -e "${YELLOW}[INFO]${NC} Einige Pakete benoetigen sudo. Bitte Passwort eingeben:"
  sudo -v || echo -e "  ${YELLOW}[WARN]${NC} sudo nicht verfuegbar — apt-Pakete werden uebersprungen"
fi

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
auto_install_optional shfmt || true
auto_install_optional ruff || true
auto_install_optional prettier || true

# --- Optionale QA-Tools ---
echo ""
echo "-- Optionale QA-Tools --"
auto_install_optional shellcheck || true
auto_install_optional bats bats-core || true
auto_install_optional markdownlint-cli2 markdownlint-cli2 || true
auto_install_optional gitleaks gitleaks || true
auto_install_optional actionlint actionlint || true

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

# Sync hooks block from settings.json.example into existing settings.json
EXAMPLE_SETTINGS="$REPO_DIR/user-config/settings.json.example"
if [[ -f "$CLAUDE_DIR/settings.json" ]] && jq -e '.hooks' "$EXAMPLE_SETTINGS" >/dev/null 2>&1; then
  if $DRY_RUN; then
    log_dry "Wuerde hooks-Block in settings.json synchronisieren"
  else
    MERGED_TMP="$(mktemp "${TMPDIR:-/tmp}/settings-merged-XXXXXX.json")"
    if jq -s '.[0] * {hooks: .[1].hooks}' \
      "$CLAUDE_DIR/settings.json" "$EXAMPLE_SETTINGS" >"$MERGED_TMP" 2>/dev/null; then
      backup_if_exists "$CLAUDE_DIR/settings.json"
      mv "$MERGED_TMP" "$CLAUDE_DIR/settings.json"
      log_ok "hooks-Block in settings.json synchronisiert"
    else
      rm -f "$MERGED_TMP"
      log_err "hooks-Block konnte nicht synchronisiert werden"
    fi
  fi
fi

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
  trap - ERR
  bash "$REPO_DIR/validate.sh" || {
    echo -e "${YELLOW}[WARN]${NC} Validierung hat Fehler gemeldet (Symlinks sind trotzdem installiert)."
  }
fi

# --- PATH-Check ---
PATH_HINTS=()
if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  PATH_HINTS+=("$HOME/.local/bin")
fi
if command -v npm >/dev/null 2>&1; then
  NPM_GLOBAL_BIN="$(npm prefix -g 2>/dev/null)/bin"
  if [[ -n "$NPM_GLOBAL_BIN" && "$NPM_GLOBAL_BIN" != "/bin" && -d "$NPM_GLOBAL_BIN" ]] &&
    [[ ":$PATH:" != *":$NPM_GLOBAL_BIN:"* ]]; then
    PATH_HINTS+=("$NPM_GLOBAL_BIN")
  fi
fi
if [[ ${#PATH_HINTS[@]} -gt 0 ]]; then
  echo ""
  echo -e "${YELLOW}[INFO]${NC} Folgende Verzeichnisse sind nicht im PATH:"
  for p in "${PATH_HINTS[@]}"; do
    echo -e "       - $p"
  done
  echo -e "       Empfehlung: In ~/.bashrc oder ~/.zshrc einfuegen:"
  echo -e "       ${GREEN}export PATH=\"${PATH_HINTS[*]// /:}:\$PATH\"${NC}"
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
