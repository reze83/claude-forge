# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## claude-forge

Bash-basiertes Security- & Productivity-Framework fuer Claude Code CLI.

## Befehle

```bash
# Tests
bash tests/test-hooks.sh        # Hook unit tests (215 tests)
bash tests/test-install.sh      # Install/Uninstall lifecycle (34 tests)
bash tests/test-update.sh       # Update script (6 tests)
bash tests/test-codex.sh        # Codex wrapper (13 tests)
bash tests/test-validate.sh     # Validation run (1 test)

# Einzelnen Hook testen (assert_exit pattern)
echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' | bash hooks/bash-firewall.sh

# Installation (Hardlink-Modus)
bash install.sh                 # Standard
bash install.sh --dry-run       # Vorschau ohne Aenderungen
bash install.sh --with-codex    # Mit Codex CLI

# Validierung
bash validate.sh                # Prueft Verzeichnisse, Datei-Links, JSON, Scripts

# Deinstallation
bash uninstall.sh --dry-run
bash uninstall.sh
```

## Architektur

### Duales Deployment-Modell

Das Repo ist gleichzeitig ein **Claude Code Plugin** (`plugin.json`) und ein **Hardlink-basiertes Config-Repo**:

- **Install-Modus** (`bash install.sh`): Permanente Installation. Hooks laufen via `~/.claude/settings.json` → `$HOME/.claude/hooks/*.sh`
- **Plugin-Modus** (`claude --plugin-dir <repo>`): Temporaer. Hooks laufen via `hooks/hooks.json` → `${CLAUDE_PLUGIN_ROOT}/hooks/*.sh`
- **Niemals beide gleichzeitig** — install.sh erkennt laufende Plugin-Instanzen und bricht ab

### Deployments

| Repo-Datei                        | Ziel                     | Methode                        |
| --------------------------------- | ------------------------ | ------------------------------ |
| user-config/settings.json.example | ~/.claude/settings.json  | Kopie (einmalig) + Deep-Merge  |
| user-config/CLAUDE.md.example     | ~/.claude/CLAUDE.md      | Kopie (einmalig) + Import-Sync |
| rules/, hooks/, commands/         | ~/.claude/\*/\*          | Hardlinks (Symlink-Fallback)   |
| agents/\*.md                      | ~/.claude/agents/\*.md   | Hardlinks (Symlink-Fallback)   |
| skills/\*/                        | ~/.claude/skills/\*/     | Hardlinks rekursiv (Fallback)  |
| multi-model/                      | ~/.claude/multi-model/\* | Hardlinks rekursiv (Fallback)  |
| VERSION                           | ~/.claude/VERSION        | Hardlink (Symlink-Fallback)    |

**settings.json**: Wird einmalig aus Template kopiert. Bei Updates via `jq` deep-merged: Skalare Werte gewinnt der User, `hooks` komplett aus Template, Arrays (`permissions.ask`, `permissions.deny`, `sandbox.network.allowedDomains`) werden per Union gemerged (Template-Baseline + User-Eintraege, dedupliziert).

**CLAUDE.md**: Wird einmalig aus Template kopiert. Bei Updates werden fehlende `@import`-Zeilen am Ende angehaengt. Bestehende User-Inhalte werden nie geaendert.

**Verzeichnisse**: Alle Verzeichnisse (hooks/, rules/, commands/, agents/, skills/, multi-model/) sind echte Verzeichnisse in `~/.claude/`. Die Dateien darin sind Hardlinks zum Repo (Fallback: Symlinks bei Cross-Filesystem). Eine Marker-Datei `~/.claude/.forge-repo` speichert den Repo-Pfad. So kann der User eigene Dateien hinzufuegen und bekommt trotzdem Updates via `git pull`.

### Hook-System

Alle Hooks sourcen `hooks/lib.sh` fuer:

- `block(reason)` — PreToolUse deny (exit 0 + JSON, NICHT exit 2)
- `warn(message)` — PostToolUse systemMessage
- `context(k1,v1,...)` — additionalContext JSON via jq
- `debug(msg)` — Optional-Logging bei `CLAUDE_FORGE_DEBUG=1`
- `SECRET_PATTERNS[]` / `SECRET_LABELS[]` — 11 ERE-Pattern (DRY)

Input kommt via stdin als JSON. Ausgabe via stdout als JSON. Exit-Codes: `0`=verarbeiten, `2`=blockieren (stdout wird ignoriert bei exit 2 — daher block() nutzt exit 0 mit JSON).

## Hook-Entwicklung

- Output nur via `block()`/`warn()` aus `hooks/lib.sh` — nie manuell JSON bauen
- Source-Pattern: `source "$(cd "$(dirname "$0")" && pwd)/lib.sh"`
- Secret-Patterns nur in `hooks/lib.sh` pflegen (DRY)
- Neuer Hook → Eintrag in `hooks/hooks.json` UND `user-config/settings.json.example` (identische Timeouts)
- plugin.json: KEIN `hooks`-Feld setzen — wird automatisch aus `hooks/hooks.json` geladen
- `printf` statt `echo -e` (POSIX-Portabilitaet)
- `validate.sh` prueft Timeout-Konsistenz zwischen `hooks.json` und `settings.json.example`

### Offizielle Hook-Events (alle 14)

`SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PermissionRequest`, `PostToolUse`, `PostToolUseFailure`, `Notification`, `SubagentStart`, `SubagentStop`, `Stop`, `TeammateIdle`, `TaskCompleted`, `PreCompact`, `SessionEnd`

`Setup` ist NICHT offiziell — nur in `hooks.json` (Plugin-Modus) registriert.
`UserPromptSubmit`, `Stop`, `TeammateIdle` und `TaskCompleted` unterstuetzen keinen `matcher` — immer ohne Matcher-Feld definieren.

## Bash 3.2+ Kompatibilitaet (macOS)

- Keine assoziativen Arrays (`declare -A`) — parallele Arrays nutzen
- Kein `${var,,}` — `printf '%s' "$var" | tr '[:upper:]' '[:lower:]'`
- Kein `readarray`/`mapfile` — `while IFS= read -r line`
- Kein `&>>` oder `|&` — `>> file 2>&1` bzw. `2>&1 |`

## Patterns: ERE, kein PCRE

Alle grep/regex Patterns nutzen `grep -E`. Kein `\d` (→ `[0-9]`), kein `\w` (→ `[a-zA-Z0-9_]`), keine Lookaheads.

## Testen

- `bash tests/test-hooks.sh` vor jedem Commit
- Test-Pattern: `assert_exit "Beschreibung" <exit_code> "$SCRIPT" '<json>'`
- CI fuehrt zusaetzlich: markdownlint, shfmt -d, gitleaks, actionlint

## install.sh Erweiterungen

- `sudo -v` am Anfang cached Passwort einmalig (uebersprungen bei dry-run und passwordless sudo)
- Neue Tool-Fallbacks in `auto_install_optional()`: npm via `_install_node_tool()`, GitHub Releases via `_install_github_binary()`
- `_install_github_binary()` Arch-Mapping: `x86_64` → Regex `(x86_64|x64|amd64)`, `aarch64` → `(arm64|aarch64)`
- `bats-core` Sonderfall: apt-Paketname ist `bats`, brew ist `bats-core`, Fallback via `_install_bats_core()` (git clone nach ~/.local, kein sudo)
- Optionale Tools duerfen fehlschlagen (nur Warning, kein Abbruch)

## Doc-Sync (projektspezifisch)

- `hooks/` geaendert → `docs/ARCHITECTURE.md` (Hook-Tabelle: Anzahl, Zeilen)
- Neuer Hook/Skill/Command → `docs/ARCHITECTURE.md` (Dateipfade-Tabelle)
- Test-Anzahl geaendert → `CONTRIBUTING.md`, `README.md` (Badge), `docs/ARCHITECTURE.md` (Test-Tabelle + Total)
- Konvention geaendert → `CONTRIBUTING.md`
- Neues Markdown-Muster verletzt Linter → `.markdownlint.yml` pruefen
- Lifecycle-Scripts gekoppelt: `install.sh` ↔ `uninstall.sh` ↔ `update.sh` ↔ `validate.sh` ↔ `commands/forge-doctor.md`
- Diese CLAUDE.md aktualisieren wenn sich Projektstruktur, Befehle oder Konventionen aendern

## Git

- Solo-Projekt: Feature-Branch + PR (bash-firewall blockiert Push auf main)
- CI (test.yml) validiert nach Push: ShellCheck, markdownlint, shfmt, gitleaks, actionlint + Tests
