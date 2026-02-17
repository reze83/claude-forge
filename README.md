<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/logo-dark.svg">
  <source media="(prefers-color-scheme: light)" srcset="docs/assets/logo-light.svg">
  <img alt="claude-forge" src="docs/assets/logo-light.svg" width="380">
</picture>

<br>

[![Version](https://img.shields.io/badge/version-0.3.0-blue?style=flat-square)](CHANGELOG.md)
[![CI](https://img.shields.io/github/actions/workflow/status/reze83/claude-forge/test.yml?branch=main&style=flat-square&label=CI)](https://github.com/reze83/claude-forge/actions)
[![Tests](https://img.shields.io/badge/tests-171%20passed-brightgreen?style=flat-square)](#)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)

<!-- Demo GIF — generate with: vhs docs/assets/demo.tape -->
<img src="docs/assets/demo.gif" alt="claude-forge Demo — Multi-Model Workflow mit Claude und Codex" width="700">

</div>

---

## Inhalt

- [Quickstart](#quickstart)
- [Features](#features)
- [Komponenten](#komponenten)
- [Voraussetzungen](#voraussetzungen)
- [Multi-Model (Claude + Codex)](#multi-model-claude--codex)
- [Troubleshooting](#troubleshooting)
- [Verzeichnisstruktur](#verzeichnisstruktur)
- [Deinstallation](#deinstallation)

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

| Hook                   | Funktion                                                                                                                                                                 |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Bash-Firewall**      | Blockt `rm -rf /`, `git push main`, `chmod 777`, `eval`, `bash -c` — inkl. Bypass-Schutz (absolute Pfade, command/env/exec Prefix, getrennte Flags, Refspec, Force-Push) |
| **File-Protection**    | Schuetzt `.env`, `.ssh/`, `.aws/`, `.npmrc`, `*.pem`, `*.key` (case-insensitive). Allowlist fuer `.env.example`/`.env.sample`                                            |
| **Secret-Scan (Pre)**  | Blockt 11 Secret-Patterns in Write/Edit-Content BEVOR sie geschrieben werden. Pragma-Allowlist gilt pro Zeile                                                            |
| **Secret-Scan (Post)** | Warnt bei 11 Secret-Typen: Anthropic, OpenAI, GitHub (PAT/OAuth/Server/Refresh), AWS, JWT, PEM, Stripe, Slack, Azure                                                     |
| **Hook-Tampering**     | Schuetzt `.claude/hooks.json`, `.claude/hooks/`, `.claude/settings.json` vor Manipulation                                                                                |

### Produktivitaet

| Hook / Command     | Funktion                                                                  |
| ------------------ | ------------------------------------------------------------------------- |
| **Auto-Format**    | Formatiert JS/TS/Python/Rust/Go/Shell automatisch nach jedem Edit (async) |
| **Multi-Model**    | Delegiert Tasks an Codex CLI — 5 Workflow-Commands (`/multi-*`)           |
| **Setup**          | Dependency-Check, Symlink-Health, Projekt-Context bei `--init`            |
| **Session-Start**  | Forge-Version als Context, Session-Logging                                |
| **Post-Failure**   | Tool-Fehler Logging + Context-Hinweis                                     |
| **Pre-Compact**    | Context-Compaction Logging                                                |
| **Task-Gate**      | Quality Gate: Hook-Tests vor Task-Abschluss (opt-in)                      |
| **Teammate-Gate**  | Uncommitted-Changes Check vor Teammate-Idle (opt-in)                      |
| **Session-Logger** | Desktop-Notification + Log bei Session-Ende                               |

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

| Typ      | Anzahl | Inhalt                                                                                                                                                             |
| -------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Hooks    | 12     | bash-firewall, protect-files, secret-scan-pre, auto-format, secret-scan, setup, session-start, post-failure, pre-compact, task-gate, teammate-gate, session-logger |
| Agents   | 3      | research, test-runner, security-auditor                                                                                                                            |
| Skills   | 4      | code-review, explain-code, deploy, project-init                                                                                                                    |
| Commands | 7      | multi-model (5), forge-status, forge-update                                                                                                                        |
| Rules    | 4      | git-workflow, security, token-optimierung, code-standards                                                                                                          |

---

## Voraussetzungen

`install.sh` installiert fehlende Dependencies automatisch (apt/brew/pip/npm mit Fallbacks).

|              | Pakete                                            |
| ------------ | ------------------------------------------------- |
| **Pflicht**  | git, jq, node >= 20, python3 >= 3.10              |
| **Optional** | shfmt, ruff, prettier (Auto-Formatter), Codex CLI |

> [!NOTE]
> Falls `pip3` nicht verfuegbar ist (z.B. Debian/Ubuntu ohne python3-pip), installiert `install.sh` ruff automatisch in einem venv unter `~/.local/venvs/claude-forge-tools/`. Bei fehlenden PATH-Eintraegen wird am Ende ein konkreter `export PATH=...` Vorschlag ausgegeben.

---

## Multi-Model (Claude + Codex)

<details>
<summary><strong>Setup & Commands anzeigen</strong></summary>

```bash
bash install.sh --with-codex
# oder manuell: bash multi-model/codex-setup.sh
```

| Command           | Beschreibung                                       |
| ----------------- | -------------------------------------------------- |
| `/multi-workflow` | Claude plant, Codex implementiert, Claude reviewed |
| `/multi-plan`     | Parallele Plaene von Claude und Codex              |
| `/multi-execute`  | Direkte Codex-Delegation (read/write)              |
| `/multi-backend`  | Backend/Algorithmen an Codex (read-only)           |
| `/multi-frontend` | Frontend von Claude, Codex reviewed                |

</details>

---

## Troubleshooting

<details>
<summary><strong>Installation</strong></summary>

**Dependencies fehlen** — `install.sh` installiert Pflicht-Dependencies (git, jq, node, python3) und optionale Formatter (shfmt, ruff, prettier) automatisch via apt-get, brew, pip oder npm mit mehreren Fallbacks.

**ruff laesst sich nicht installieren** — Auf Debian/Ubuntu ohne python3-pip nutzt der Installer automatisch ein venv (`~/.local/venvs/claude-forge-tools/`) und verlinkt die Binaries nach `~/.local/bin/`.

**prettier/codex nicht gefunden nach Installation** — Falls `npm install -g` in ein Verzeichnis installiert das nicht im PATH liegt (z.B. `~/.npm-global/bin/`), erstellt der Installer einen Symlink nach `~/.local/bin/`. Am Ende wird eine PATH-Empfehlung angezeigt.

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

**Codex Timeout** — Standard-Timeout ist 240s (Range: 30-600s). Anpassbar per `--timeout` in `codex-wrapper.sh`. Bei Timeouts: Aufgabe in kleinere Teilschritte zerlegen.

**"Not inside a trusted directory"** — Der Wrapper erkennt automatisch ob das Arbeitsverzeichnis ein Git-Repo ist und setzt `--skip-git-repo-check` falls nicht. Falls der Fehler trotzdem auftritt: Wrapper-Version pruefen (`/forge-status`).

**Leere Fehlermeldung** — Stderr wird jetzt separat erfasst und im JSON-Output zurueckgegeben. Bei alteren Wrapper-Versionen wurde stderr verschluckt — Update via `/forge-update`.

</details>

<details>
<summary><strong>Debugging</strong></summary>

Hook manuell testen:

```bash
echo '{"tool_input":{"command":"ls -la"}}' | bash hooks/bash-firewall.sh
echo '{"tool_input":{"file_path":"/home/user/.env"}}' | bash hooks/protect-files.sh
echo '{"tool_name":"Write","tool_input":{"file_path":"/tmp/t","content":"sk-ant-FAKE_KEY_HERE"}}' | bash hooks/secret-scan-pre.sh
```

Debug-Logging aktivieren:

```bash
export CLAUDE_FORGE_DEBUG=1  # Schreibt nach ~/.claude/hooks-debug.log
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
│   ├── lib.sh                      Shared library (block/warn/debug/patterns)
│   ├── bash-firewall.sh            Gefaehrliche Befehle blocken
│   ├── protect-files.sh            Sensible Dateien schuetzen
│   ├── auto-format.sh              Auto-Formatting (JS/TS/Python/Rust/Go/Shell)
│   ├── secret-scan-pre.sh          Secret-Erkennung VOR Write/Edit (deny)
│   ├── secret-scan.sh              Secret-Erkennung nach Write/Edit (warn)
│   ├── setup.sh                    Setup-Check (Dependencies + Symlinks)
│   ├── session-start.sh            Session-Init + Version Context
│   ├── post-failure.sh             Tool-Fehler Logging
│   ├── pre-compact.sh              Compaction Logging
│   ├── task-gate.sh                Quality Gate (TaskCompleted)
│   ├── teammate-gate.sh            Uncommitted-Changes Gate (TeammateIdle)
│   └── session-logger.sh           Session-Ende Notification
├── rules/                          → ~/.claude/rules/ (symlinked)
├── agents/                         → ~/.claude/agents/
├── skills/                         → ~/.claude/skills/
├── commands/                       → ~/.claude/commands/
├── multi-model/                    → ~/.claude/multi-model/ (Codex CLI)
├── tests/                          Test-Suite (171 Tests)
└── docs/                           Dokumentation
    ├── ARCHITECTURE.md              Architektur-Uebersicht
    ├── demo.tape                    VHS Tape-Datei (GIF-Recording)
    └── assets/                      Bilder & Medien
        ├── logo-light.svg           Logo fuer Light-Mode
        ├── logo-dark.svg            Logo fuer Dark-Mode
        └── demo.gif                 Terminal-Demo (generiert)
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
