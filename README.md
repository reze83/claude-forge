# claude-forge

Modulares Claude Code Config-Repository mit Multi-Model Support.

## Quickstart (Symlink-Modus — empfohlen)

```bash
# Clone (Pfad ist frei waehlbar)
git clone https://github.com/reze83/claude-forge.git ~/.claude/claude-forge
# oder: git clone ... "${XDG_DATA_HOME:-$HOME/.local/share}/claude-forge"

cd ~/.claude/claude-forge
bash install.sh            # Hooks, Agents, Skills, Commands
bash install.sh --with-codex  # Optional: + Codex CLI fuer /multi-* Commands
```

## Alternative: Plugin-Modus

```bash
claude --plugin-dir <pfad-zum-repo>
```

> **NICHT beides gleichzeitig nutzen** — Hooks wuerden doppelt geladen!

## Update

```bash
bash update.sh          # Holt neueste Version und aktualisiert Installation
bash update.sh --check  # Nur pruefen ob Updates verfuegbar sind
```

## Was ist enthalten?

| Komponente | Beschreibung |
|---|---|
| 5 Hooks | Bash-Firewall, File-Protection, Auto-Format, Secret-Scan, Session-Logger |
| 3 Agents | Research, Test-Runner, Security-Auditor |
| 4 Skills | Code-Review, Explain-Code, Deploy, Project-Init |
| 7 Commands | Multi-Model (5), /forge-status, /forge-update |
| 4 Rules | Git-Workflow, Security, Token-Optimierung, Code-Standards |

## Voraussetzungen

`install.sh` installiert fehlende Dependencies automatisch (apt/brew).

**Pflicht**: git, jq, node >= 20, python3 >= 3.12
**Optional**: shfmt, ruff, prettier (Auto-Formatter), Codex CLI

## Verzeichnisstruktur

```
claude-forge/
├── .claude-plugin/plugin.json      Plugin-Manifest
├── .github/workflows/test.yml      CI Pipeline
├── install.sh                      Symlink-Installer (Auto-Install Dependencies)
├── uninstall.sh                    Saubere Deinstallation (--dry-run)
├── update.sh                       One-Command Updater (--check)
├── validate.sh                     Konfig-Validierung + Secret-Scan
├── VERSION                         Aktuelle Version
├── CHANGELOG.md                    Aenderungshistorie
├── CONTRIBUTING.md                 Entwickler-Richtlinien
├── user-config/                    Vorlagen fuer ~/.claude/
│   ├── settings.json.example       Hauptkonfiguration (kopiert bei Install)
│   ├── CLAUDE.md.example           Globale Instruktionen (kopiert bei Install)
│   └── MEMORY.md                   Persistenter Speicher (symlinked)
├── rules/                          → ~/.claude/rules/ (symlinked)
├── hooks/                          → ~/.claude/hooks/
│   ├── bash-firewall.sh            Gefaehrliche Befehle blocken
│   ├── protect-files.sh            Sensible Dateien schuetzen
│   ├── auto-format.sh              Auto-Formatting (JS/TS/Python/Rust/Go/Shell)
│   ├── secret-scan.sh              Secret-Erkennung nach Write/Edit
│   └── session-logger.sh           Session-Ende Notification
├── agents/                         → ~/.claude/agents/
├── skills/                         → ~/.claude/skills/
├── commands/                       → ~/.claude/commands/
│   ├── multi-*.md                  Multi-Model Commands (5)
│   ├── forge-status.md             /forge-status
│   └── forge-update.md             /forge-update
├── multi-model/                    → ~/.claude/multi-model/ (Codex CLI)
├── tests/                          Test-Suite (50 Tests)
│   ├── test-hooks.sh               Hook Unit-Tests (44)
│   ├── test-update.sh              Update-Tests (6)
│   ├── test-install.sh             Install/Uninstall Tests
│   └── test-codex.sh               Codex Wrapper Tests
└── docs/                           Architektur-Dokumentation
```

## Multi-Model (Claude + Codex)

Codex CLI optional installieren:

```bash
bash multi-model/codex-setup.sh
```

Dann in Claude Code:

```
/multi-workflow Implementiere eine REST API mit Express
/multi-plan Feature X mit Claude und Codex planen
/multi-execute read Analysiere die Codebase
/multi-backend Erstelle einen Sortieralgorithmus
/multi-frontend Erstelle ein Login-Formular
```

## Forge-Verwaltung

In Claude Code:

```
/forge-status    # Version, Symlinks, Hooks, verfuegbare Updates
/forge-update    # Auf neueste Version aktualisieren
```

## Anpassung

Siehe [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) fuer Design-Entscheidungen.

## Troubleshooting

### Installation

**Dependencies fehlen**: `install.sh` installiert fehlende Pflicht-Dependencies (git, jq, node, python3) und optionale Formatter (shfmt, ruff, prettier) automatisch via apt-get oder brew.

**Symlink-Fehler**: Falls bestehende Dateien (keine Symlinks) in `~/.claude/` existieren, werden sie automatisch nach `~/.claude/.backup/<timestamp>/` gesichert. Bei Fehlern waehrend der Installation wird automatisch ein Rollback durchgefuehrt.

### Hook-Blockierung

**package-lock.json**: Write und Edit sind blockiert, Read ist erlaubt. Falls ein Tool faelschlicherweise blockiert wird, die Datei `hooks/protect-files.sh` pruefen.

**Eigene Scripts blockiert**: Die `bash-firewall.sh` blockiert gefaehrliche Befehle. Erlaubte/blockierte Muster stehen direkt im Script.

### Codex CLI

**codex nicht gefunden**: `bash multi-model/codex-setup.sh` ausfuehren oder manuell `npm install -g @openai/codex`.

**Codex Timeout**: Standard-Timeout ist 180s. Kann per `--timeout` Parameter im `codex-wrapper.sh` angepasst werden.

### Plugin vs Symlink Modus

**Hooks werden doppelt geladen**: Nie Plugin-Modus (`--plugin-dir`) und Symlink-Modus gleichzeitig nutzen. Der Installer erkennt laufende Plugin-Instanzen und warnt.

### Debugging

**Logs**: Session-Logs werden bei Stop-Events geschrieben. Pfad: `~/.claude/sessions/`.

**Hook manuell testen**:
```bash
echo '{"tool_input":{"command":"ls -la"}}' | bash hooks/bash-firewall.sh
echo '{"tool_input":{"file_path":"/home/user/.env"}}' | bash hooks/protect-files.sh
```

**JSON-Validierung**:
```bash
jq empty hooks/hooks.json
jq empty user-config/settings.json.example
bash validate.sh
```

## Deinstallation

```bash
bash uninstall.sh
```
