# claude-forge

Modulares Claude Code Config-Repository mit Multi-Model Support.

## Quickstart (Symlink-Modus — empfohlen)

```bash
git clone https://github.com/reze83/claude-forge.git ~/develop/claude-forge
cd ~/develop/claude-forge
bash install.sh
```

## Alternative: Plugin-Modus

```bash
claude --plugin-dir ~/develop/claude-forge
```

> **NICHT beides gleichzeitig nutzen** — Hooks wuerden doppelt geladen!

## Was ist enthalten?

| Komponente | Beschreibung |
|---|---|
| 4 Hooks | Bash-Firewall, File-Protection, Auto-Format, Session-Logger |
| 3 Agents | Research, Test-Runner, Security-Auditor |
| 4 Skills | Code-Review, Explain-Code, Deploy, Project-Init |
| 5 Commands | Multi-Model Workflow (Claude + Codex CLI) |
| 4 Rules | Git-Workflow, Security, Token-Optimierung, Code-Standards |

## Voraussetzungen

- WSL2 / Ubuntu 22.04+
- Node.js >= 20 (`node --version`)
- Python 3.12+ (`python3 --version`)
- Git (`git --version`)
- jq (`jq --version`)
- Optional: Codex CLI (`npm install -g @openai/codex`)

## Verzeichnisstruktur

```
claude-forge/
├── .claude-plugin/plugin.json      Plugin-Manifest
├── install.sh                      Symlink-Installer
├── uninstall.sh                    Saubere Deinstallation
├── validate.sh                     Konfig-Validierung
├── user-config/                    → ~/.claude/ (Symlinks)
│   ├── settings.json               Hauptkonfiguration
│   ├── CLAUDE.md                   Globale Instruktionen
│   ├── MEMORY.md                   Persistenter Speicher
│   └── rules/                      Constraint-Regeln
├── hooks/                          → ~/.claude/hooks/
│   ├── bash-firewall.sh            Gefaehrliche Befehle blocken
│   ├── protect-files.sh            Sensible Dateien schuetzen
│   ├── auto-format.sh              Auto-Formatting (Polyglot)
│   └── session-logger.sh           Session-Ende Notification
├── agents/                         → ~/.claude/agents/
├── skills/                         → ~/.claude/skills/
├── commands/                       → ~/.claude/commands/
├── multi-model/                    Codex CLI Support
├── project-template/               Template fuer neue Projekte
├── tests/                          Test-Suite
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

## Anpassung

Siehe [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) fuer Design-Entscheidungen.

## Deinstallation

```bash
bash uninstall.sh
```
