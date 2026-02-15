<div align="center">

# claude-forge

**Modulares Claude Code Config-Repository**
Security Hooks | Auto-Formatting | Secret-Scan | Multi-Model Support

[![Version](https://img.shields.io/badge/version-0.2.1-blue?style=flat-square)](CHANGELOG.md)
[![CI](https://img.shields.io/github/actions/workflow/status/reze83/claude-forge/test.yml?branch=main&style=flat-square&label=CI)](https://github.com/reze83/claude-forge/actions)
[![Tests](https://img.shields.io/badge/tests-50%20passed-brightgreen?style=flat-square)](#)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)

</div>

---

## Quickstart

```bash
git clone https://github.com/reze83/claude-forge.git ~/.claude/claude-forge
cd ~/.claude/claude-forge
bash install.sh
```

> [!TIP]
> Der Clone-Pfad ist frei waehlbar, z.B. auch `${XDG_DATA_HOME:-$HOME/.local/share}/claude-forge`.

<details>
<summary><strong>Alternative: Plugin-Modus</strong></summary>

```bash
claude --plugin-dir <pfad-zum-repo>
```

> [!WARNING]
> **Nicht beides gleichzeitig nutzen** — Hooks wuerden doppelt geladen!

</details>

---

## Features

### Security

| Hook | Funktion |
|------|----------|
| **Bash-Firewall** | Blockt `rm -rf /`, `git push main`, `chmod 777`, `eval`, interaktive Editoren u.v.m. |
| **File-Protection** | Schuetzt `.env`, `.ssh/`, `.aws/`, `.npmrc`, `*.pem`, `*.key` vor Zugriff |
| **Secret-Scan** | Erkennt geleakte API-Keys (Anthropic, OpenAI, GitHub, AWS), JWT-Tokens, Private Keys |

### Produktivitaet

| Hook / Command | Funktion |
|----------------|----------|
| **Auto-Format** | Formatiert JS/TS/Python/Rust/Go/Shell automatisch nach jedem Edit |
| **Multi-Model** | Delegiert Tasks an Codex CLI — 5 Workflow-Commands (`/multi-*`) |
| **Session-Logger** | Desktop-Notification + Log bei Session-Ende |

### Self-Management

```
/forge-status    Version, Symlink-Health, Hooks, verfuegbare Updates
/forge-update    One-Command Update direkt aus Claude Code
```

```bash
bash update.sh          # git pull + neue Dependencies + neue Symlinks
bash update.sh --check  # Nur pruefen ob Updates verfuegbar
```

---

## Komponenten

| Typ | Anzahl | Inhalt |
|-----|--------|--------|
| Hooks | 5 | bash-firewall, protect-files, auto-format, secret-scan, session-logger |
| Agents | 3 | research, test-runner, security-auditor |
| Skills | 4 | code-review, explain-code, deploy, project-init |
| Commands | 7 | multi-model (5), forge-status, forge-update |
| Rules | 4 | git-workflow, security, token-optimierung, code-standards |

---

## Voraussetzungen

`install.sh` installiert fehlende Dependencies automatisch (apt/brew).

| | Pakete |
|---|--------|
| **Pflicht** | git, jq, node >= 20, python3 >= 3.10 |
| **Optional** | shfmt, ruff, prettier (Auto-Formatter), Codex CLI |

---

## Multi-Model (Claude + Codex)

<details>
<summary><strong>Setup & Commands anzeigen</strong></summary>

```bash
bash install.sh --with-codex
# oder manuell: bash multi-model/codex-setup.sh
```

| Command | Beschreibung |
|---------|-------------|
| `/multi-workflow` | Claude plant, Codex implementiert, Claude reviewed |
| `/multi-plan` | Parallele Plaene von Claude und Codex |
| `/multi-execute` | Direkte Codex-Delegation (read/write) |
| `/multi-backend` | Backend/Algorithmen an Codex (read-only) |
| `/multi-frontend` | Frontend von Claude, Codex reviewed |

</details>

---

## Troubleshooting

<details>
<summary><strong>Installation</strong></summary>

**Dependencies fehlen** — `install.sh` installiert Pflicht-Dependencies (git, jq, node, python3) und optionale Formatter (shfmt, ruff, prettier) automatisch via apt-get oder brew.

**Symlink-Fehler** — Bestehende Dateien in `~/.claude/` werden automatisch nach `~/.claude/.backup/<timestamp>/` gesichert. Bei Fehlern wird ein Rollback durchgefuehrt.

</details>

<details>
<summary><strong>Hook-Blockierung</strong></summary>

**package-lock.json** — Write und Edit sind blockiert, Read ist erlaubt. Siehe `hooks/protect-files.sh`.

**Eigene Scripts blockiert** — Die `bash-firewall.sh` blockiert gefaehrliche Befehle. Erlaubte/blockierte Muster stehen direkt im Script.

</details>

<details>
<summary><strong>Codex CLI</strong></summary>

**codex nicht gefunden** — `bash multi-model/codex-setup.sh` ausfuehren oder manuell `npm install -g @openai/codex`.

**Codex Timeout** — Standard-Timeout ist 180s. Anpassbar per `--timeout` in `codex-wrapper.sh`.

</details>

<details>
<summary><strong>Debugging</strong></summary>

Hook manuell testen:
```bash
echo '{"tool_input":{"command":"ls -la"}}' | bash hooks/bash-firewall.sh
echo '{"tool_input":{"file_path":"/home/user/.env"}}' | bash hooks/protect-files.sh
```

Validierung:
```bash
bash validate.sh
```

</details>

---

<details>
<summary><strong>Verzeichnisstruktur</strong></summary>

```
claude-forge/
├── install.sh                      Symlink-Installer (Auto-Install Dependencies)
├── uninstall.sh                    Saubere Deinstallation (--dry-run)
├── update.sh                       One-Command Updater (--check)
├── validate.sh                     Konfig-Validierung + Secret-Scan
├── VERSION                         Aktuelle Version
├── user-config/                    Vorlagen fuer ~/.claude/
│   ├── settings.json.example       Hauptkonfiguration (kopiert bei Install)
│   ├── CLAUDE.md.example           Globale Instruktionen (kopiert bei Install)
│   └── MEMORY.md                   Persistenter Speicher (symlinked)
├── hooks/                          → ~/.claude/hooks/
│   ├── bash-firewall.sh            Gefaehrliche Befehle blocken
│   ├── protect-files.sh            Sensible Dateien schuetzen
│   ├── auto-format.sh              Auto-Formatting (JS/TS/Python/Rust/Go/Shell)
│   ├── secret-scan.sh              Secret-Erkennung nach Write/Edit
│   └── session-logger.sh           Session-Ende Notification
├── rules/                          → ~/.claude/rules/ (symlinked)
├── agents/                         → ~/.claude/agents/
├── skills/                         → ~/.claude/skills/
├── commands/                       → ~/.claude/commands/
├── multi-model/                    → ~/.claude/multi-model/ (Codex CLI)
├── tests/                          Test-Suite (50 Tests)
└── docs/                           Architektur-Dokumentation
```

</details>

## Deinstallation

```bash
bash uninstall.sh           # Entfernt alle Symlinks
bash uninstall.sh --dry-run # Zeigt was entfernt wuerde
```

---

<div align="center">

**[Architektur](docs/ARCHITECTURE.md)** | **[Contributing](CONTRIBUTING.md)** | **[Changelog](CHANGELOG.md)**

</div>
