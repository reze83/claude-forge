#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# claude-forge installer
# Erstellt Hardlinks von claude-forge/ → ~/.claude/
# Fallback auf Symlinks bei Cross-Filesystem.
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

INSTALLED_LINKS=()

cleanup_on_error() {
  echo ""
  echo -e "${RED}Fehler aufgetreten — Rollback...${NC}"
  local backup_file
  for link in "${INSTALLED_LINKS[@]}"; do
    if [[ -L "$link" || -f "$link" ]]; then
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

create_link() {
  local source="$1"
  local target="$2"

  if $DRY_RUN; then
    log_dry "Wuerde verlinken: $target → $source"
    return
  fi

  # Idempotenz: gleicher Inode = bereits korrekt (Hardlink)
  if [[ -f "$target" && ! -L "$target" ]] &&
    [[ "$(stat -c %i "$target")" == "$(stat -c %i "$source")" ]]; then
    log_skip "$target bereits korrekt verlinkt"
    return
  fi

  # Migration: alte Symlinks auch als korrekt erkennen
  if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
    log_skip "$target bereits korrekt verlinkt (symlink, wird bei naechstem Update migriert)"
    return
  fi

  backup_if_exists "$target"
  mkdir -p "$(dirname "$target")"
  rm -f "$target"
  if ln -f "$source" "$target" 2>/dev/null; then
    INSTALLED_LINKS+=("$target")
    log_ok "Verlinkt: $target"
  else
    # Fallback: Symlink bei Cross-Filesystem
    ln -sn "$source" "$target"
    INSTALLED_LINKS+=("$target")
    log_ok "Verlinkt (symlink-fallback): $target → $source"
  fi
}

# Verlinkt alle Dateien eines Verzeichnisses einzeln (Verzeichnis wird als echtes Dir angelegt)
link_dir_contents() {
  local source_dir="$1"
  local target_dir="$2"
  local pattern="${3:-*}"

  mkdir -p "$target_dir"
  local count=0
  for item in "$source_dir"/$pattern; do
    [[ -e "$item" ]] || continue
    create_link "$item" "$target_dir/$(basename "$item")"
    count=$((count + 1))
  done
  if [[ $count -eq 0 ]]; then
    log_skip "Keine Dateien in $source_dir"
  fi
}

# Verlinkt alle Dateien eines Verzeichnisses rekursiv (Unterverzeichnisse werden als echte Dirs angelegt)
link_dir_recursive() {
  local source_dir="$1"
  local target_dir="$2"
  # Migration: alte Verzeichnis-Symlinks durch echte Dirs ersetzen
  if [[ -L "$target_dir" ]]; then
    if $DRY_RUN; then
      log_dry "Wuerde Verzeichnis-Symlink ersetzen: $target_dir"
    else
      rm -f "$target_dir"
      log_ok "Verzeichnis-Symlink migriert: $target_dir"
    fi
  fi
  mkdir -p "$target_dir"
  for item in "$source_dir"/*; do
    [[ -e "$item" ]] || continue
    local name
    name="$(basename "$item")"
    if [[ -d "$item" ]]; then
      link_dir_recursive "$item" "$target_dir/$name"
    else
      create_link "$item" "$target_dir/$name"
    fi
  done
}

# --- Sync-Funktionen ---
sync_settings_json() {
  local example_settings="$REPO_DIR/user-config/settings.json.example"
  local user_settings="$CLAUDE_DIR/settings.json"
  local merged_tmp

  if [[ ! -f "$example_settings" ]]; then
    log_err "settings.json.example fehlt"
    return 1
  fi

  if [[ ! -f "$user_settings" ]]; then
    log_skip "settings.json fehlt (sync uebersprungen)"
    return 0
  fi

  if $DRY_RUN; then
    log_dry "Wuerde settings.json mit Template mergen (hooks aus Template)"
    return 0
  fi

  merged_tmp="$(mktemp "${TMPDIR:-/tmp}/settings-merged-XXXXXX.json")"
  # Deep-merge: user values win for scalars, hooks from template,
  # array union for permissions and allowedDomains (template baseline + user additions)
  if jq -s '
    .[0] as $tpl | .[1] as $usr |
    ($tpl * $usr) |
    .hooks = $tpl.hooks |
    .permissions.ask = (($tpl.permissions.ask // []) + ($usr.permissions.ask // []) | unique) |
    .permissions.deny = (($tpl.permissions.deny // []) + ($usr.permissions.deny // []) | unique) |
    .sandbox.network.allowedDomains = (
      ($tpl.sandbox.network.allowedDomains // []) +
      ($usr.sandbox.network.allowedDomains // []) | unique
    )' "$example_settings" "$user_settings" >"$merged_tmp" 2>/dev/null; then
    backup_if_exists "$user_settings"
    mv "$merged_tmp" "$user_settings"
    log_ok "settings.json mit Template synchronisiert"
  else
    rm -f "$merged_tmp"
    log_err "settings.json konnte nicht synchronisiert werden"
    return 1
  fi
}

sync_claude_md() {
  local example_md="$REPO_DIR/user-config/CLAUDE.md.example"
  local user_md="$CLAUDE_DIR/CLAUDE.md"
  local line
  local missing_count=0
  local missing_lines=""

  if [[ ! -f "$example_md" ]]; then
    log_err "CLAUDE.md.example fehlt"
    return 1
  fi

  if [[ ! -f "$user_md" ]]; then
    log_skip "CLAUDE.md fehlt (sync uebersprungen)"
    return 0
  fi

  while IFS= read -r line; do
    [[ "$line" == @* ]] || continue
    if ! grep -Fxq -- "$line" "$user_md" 2>/dev/null; then
      missing_lines="${missing_lines}${line}
"
      missing_count=$((missing_count + 1))
    fi
  done <"$example_md"

  if [[ $missing_count -eq 0 ]]; then
    log_skip "Keine @import-Zeilen zu synchronisieren"
    return 0
  fi

  if $DRY_RUN; then
    log_dry "Wuerde $missing_count @import-Zeile(n) an CLAUDE.md anhaengen"
    return 0
  fi

  # Ensure trailing newline before appending
  if [[ -s "$user_md" ]]; then
    local last_char
    last_char="$(tail -c1 "$user_md" 2>/dev/null || true)"
    if [[ "$last_char" != "" ]]; then
      printf '\n' >>"$user_md"
    fi
  fi

  printf '%s' "$missing_lines" >>"$user_md" || {
    log_err "CLAUDE.md konnte nicht aktualisiert werden"
    return 1
  }

  log_ok "$missing_count @import-Zeile(n) in CLAUDE.md synchronisiert"
}

sync_mcp_json() {
  local src="$REPO_DIR/.mcp.json"

  [[ -f "$src" ]] || return 0

  # Iterate all server entries in .mcp.json
  local server_name
  while IFS= read -r server_name; do
    [[ -z "$server_name" ]] && continue

    # Determine transport type: http (has "url") or stdio (has "command")
    local transport url cmd args
    transport=$(jq -r ".[\"$server_name\"].type // empty" "$src" 2>/dev/null) || continue
    url=$(jq -r ".[\"$server_name\"].url // empty" "$src" 2>/dev/null) || continue
    cmd=$(jq -r ".[\"$server_name\"].command // empty" "$src" 2>/dev/null) || continue
    args=$(jq -r ".[\"$server_name\"].args // [] | join(\" \")" "$src" 2>/dev/null) || continue

    if [[ -z "$transport" ]]; then
      # Infer: url present → http, command present → stdio
      if [[ -n "$url" ]]; then
        transport="http"
      elif [[ -n "$cmd" ]]; then
        transport="stdio"
      else
        log_skip ".mcp.json: kein command/url fuer $server_name"
        continue
      fi
    fi

    if $DRY_RUN; then
      log_dry "Wuerde MCP-Server '$server_name' registrieren (user scope, $transport)"
      continue
    fi

    # Check if claude CLI is available
    if ! command -v claude >/dev/null 2>&1; then
      log_skip "claude CLI nicht gefunden (MCP-Registrierung uebersprungen)"
      return 0
    fi

    # Check if already registered at user scope
    local existing
    existing=$(claude mcp get "$server_name" 2>/dev/null || true)
    if [[ -n "$existing" && "$existing" != *"not found"* && "$existing" != *"No server"* ]]; then
      log_skip "MCP-Server '$server_name' bereits registriert"
      continue
    fi

    # Register via claude mcp add (user scope)
    local reg_ok=false
    if [[ "$transport" == "http" && -n "$url" ]]; then
      if claude mcp add --transport http --scope user "$server_name" "$url" 2>/dev/null; then
        reg_ok=true
      fi
    elif [[ -n "$cmd" ]]; then
      # shellcheck disable=SC2086
      if claude mcp add --transport stdio --scope user "$server_name" -- $cmd $args 2>/dev/null; then
        reg_ok=true
      fi
    fi

    if $reg_ok; then
      log_ok "MCP-Server '$server_name' registriert (user scope, $transport)"
    else
      log_err "MCP-Server '$server_name' konnte nicht registriert werden"
    fi
  done < <(jq -r 'keys[]' "$src" 2>/dev/null)
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
      PIP_USER=0 "$venv_dir/bin/pip" install "$pkg" 2>/dev/null; then
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
  git clone --depth 1 https://github.com/bats-core/bats-core.git "$tmp_dir" 2>/dev/null || {
    rm -rf "$tmp_dir"
    return 1
  }
  mkdir -p "$prefix"
  bash "$tmp_dir/install.sh" "$prefix" 2>/dev/null || {
    rm -rf "$tmp_dir"
    return 1
  }
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
  elif [[ "$pkg" == "@smithery/cli" ]]; then
    _install_node_tool "smithery" "@smithery/cli" && return 0
  elif [[ "$pkg" == "gh" ]]; then
    _install_github_binary "gh" "cli/cli" && return 0
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
    log_skip "$example_file existiert bereits"
  fi
done

# local-patterns.sh: Kopieren aus .example (nur wenn Ziel nicht existiert)
if [[ ! -f "$CLAUDE_DIR/local-patterns.sh" ]]; then
  if $DRY_RUN; then
    log_dry "Wuerde local-patterns.sh aus .example erstellen"
  else
    cp "$REPO_DIR/user-config/local-patterns.sh.example" "$CLAUDE_DIR/local-patterns.sh"
    log_ok "local-patterns.sh aus .example erstellt"
  fi
else
  log_skip "local-patterns.sh existiert bereits"
fi

# Sync: Template-Defaults in bestehende User-Dateien mergen
sync_settings_json
sync_claude_md
sync_mcp_json

# --- Phase 2: Rules (einzeln verlinken) ---
echo ""
echo "-- Phase 2: Rules --"
link_dir_contents "$REPO_DIR/rules" "$CLAUDE_DIR/rules" "*.md"

# --- Phase 3: Hooks (einzeln verlinken) ---
echo ""
echo "-- Phase 3: Hooks --"
link_dir_contents "$REPO_DIR/hooks" "$CLAUDE_DIR/hooks"

# --- Phase 4: Agents (einzeln verlinken) ---
echo ""
echo "-- Phase 4: Agents --"
link_dir_contents "$REPO_DIR/agents" "$CLAUDE_DIR/agents" "*.md"

# --- Phase 5: Skills (rekursiv verlinken) ---
echo ""
echo "-- Phase 5: Skills --"
mkdir -p "$CLAUDE_DIR/skills"
for skill_dir in "$REPO_DIR/skills/"*/; do
  [[ -d "$skill_dir" ]] || continue
  skill_name="$(basename "$skill_dir")"
  target="$CLAUDE_DIR/skills/$skill_name"
  # Alte Verzeichnis-Symlinks (vor v0.6) entfernen bevor echtes Dir angelegt wird
  if [[ -L "$target" ]]; then
    if $DRY_RUN; then
      log_dry "Wuerde alten Verzeichnis-Symlink entfernen: $target"
    else
      rm -f "$target"
      log_ok "Alten Verzeichnis-Symlink entfernt: $target"
    fi
  fi
  link_dir_recursive "$skill_dir" "$target"
done

# --- Phase 6: Commands (einzeln verlinken) ---
echo ""
echo "-- Phase 6: Commands --"
link_dir_contents "$REPO_DIR/commands" "$CLAUDE_DIR/commands"

# --- Phase 7: Multi-Model (einzeln verlinken) ---
echo ""
echo "-- Phase 7: Multi-Model --"
link_dir_recursive "$REPO_DIR/multi-model" "$CLAUDE_DIR/multi-model"

# --- Phase 8: Codex CLI (optional) ---
if $WITH_CODEX; then
  echo ""
  echo "-- Phase 8: Codex CLI --"
  if $DRY_RUN; then
    log_dry "Wuerde codex-setup.sh ausfuehren"
  else
    bash "$REPO_DIR/multi-model/codex-setup.sh"
  fi
fi

# --- Phase 9: Optionale CLIs ---
echo ""
echo "-- Phase 9: Optionale CLIs --"
auto_install_optional smithery @smithery/cli || true
auto_install_optional gh gh || true

# --- Repo-Marker ---
if ! $DRY_RUN; then
  printf '%s\n' "$REPO_DIR" >"$CLAUDE_DIR/.forge-repo"
  log_ok "Repo-Marker geschrieben: $CLAUDE_DIR/.forge-repo"
else
  log_dry "Wuerde Repo-Marker schreiben: $CLAUDE_DIR/.forge-repo"
fi

# --- VERSION ---
create_link "$REPO_DIR/VERSION" "$CLAUDE_DIR/VERSION"

# --- Validierung ---
echo ""
if ! $DRY_RUN; then
  echo "-- Validierung --"
  trap - ERR
  bash "$REPO_DIR/validate.sh" || {
    echo -e "${YELLOW}[WARN]${NC} Validierung hat Fehler gemeldet (Links sind trotzdem installiert)."
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

# --- Hinweis: Smithery CLI ---
if ! command -v smithery >/dev/null 2>&1; then
  echo ""
  echo -e "${YELLOW}[INFO]${NC} smithery mcp search benoetigt Smithery CLI."
  echo -e "       Optional: ${GREEN}npm install -g @smithery/cli && smithery login${NC}"
fi

# --- Auto-compact threshold ---
if ! grep -qE "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE" "$HOME/.bashrc" "$HOME/.zshrc" 2>/dev/null; then
  echo ""
  echo -e "${YELLOW}[INFO]${NC} Auto-compact threshold nicht konfiguriert."
  echo -e "       Claude Code compact'et standardmaessig bei 95% Kontextauslastung."
  echo -e "       Empfohlen: 75% fuer frueheres, weniger invasives Compacting."
  if [[ "$DRY_RUN" == true ]]; then
    echo -e "       ${YELLOW}[DRY_RUN]${NC} Wuerde fragen: export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=75 >> ~/.bashrc"
  elif [[ -t 0 ]]; then
    printf "       Jetzt in ~/.bashrc eintragen? [Y/n] "
    read -r answer </dev/tty
    if [[ -z "$answer" || "$answer" =~ ^[Yy]$ ]]; then
      printf '\n# Claude Code — auto-compact threshold\nexport CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=75\n' >>"$HOME/.bashrc"
      echo -e "       ${GREEN}[OK]${NC} Eingetragen. Wirksam ab der naechsten Shell-Session."
    else
      echo -e "       Manuell eintragen: ${GREEN}export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=75${NC} in ~/.bashrc"
    fi
  else
    printf '\n# Claude Code — auto-compact threshold\nexport CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=75\n' >>"$HOME/.bashrc"
    echo -e "       ${GREEN}[OK]${NC} Nicht-interaktiv: automatisch in ~/.bashrc eingetragen."
  fi
fi

# --- Hinweis: GitHub CLI ---
if ! command -v gh >/dev/null 2>&1; then
  echo ""
  echo -e "${YELLOW}[INFO]${NC} GitHub CLI ist nicht installiert."
  echo -e "       Optional: ${GREEN}install.sh installiert gh automatisch beim naechsten Lauf${NC}"
fi

echo ""
echo -e "${GREEN}=== Installation abgeschlossen ===${NC}"
if [[ -d "$BACKUP_DIR" ]]; then
  echo -e "Backups: $BACKUP_DIR"
fi
