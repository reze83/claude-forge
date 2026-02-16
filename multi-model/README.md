# Multi-Model Modul (Claude + Codex)

## Architektur

```
Claude Code (Orchestrator)
    |
    └── codex-wrapper.sh → codex exec
         ├── Auto-detect: --skip-git-repo-check (non-git dirs)
         ├── Stderr capture (separate file, surfaced on error)
         ├── Timeout validation (30-600s, default 240s)
         └── Auth: ChatGPT Plus/Pro Subscription
```

## Voraussetzungen
- Codex CLI: `bash multi-model/codex-setup.sh`
- ChatGPT Plus oder Pro Abo

## Commands
| Command | Sandbox | Beschreibung |
|---------|---------|-------------|
| /multi-workflow | write | Voller 6-Phasen Workflow |
| /multi-plan | read | Parallele Planung, Vergleich |
| /multi-execute | variabel | Direkte Codex-Delegation |
| /multi-backend | read | Backend/Algo-Task |
| /multi-frontend | write | Frontend (Claude-led) |

## Sandbox-Modi (Codex CLI v0.101+)
| Modus | Codex-Flag | Beschreibung |
|-------|-----------|-------------|
| read | --sandbox read-only | Nur lesen |
| write | --sandbox workspace-write | Schreiben im Projektordner |
| full | --sandbox danger-full-access | Voller Zugriff |

## codex-wrapper.sh

### Flags
| Flag | Default | Beschreibung |
|------|---------|-------------|
| --sandbox | write | Sandbox-Modus (read/write/full) |
| --prompt | (required) | Aufgabe fuer Codex |
| --workdir | $(pwd) | Arbeitsverzeichnis |
| --timeout | 240 | Timeout in Sekunden (30-600) |

### Automatisches Verhalten
- **Non-Git Directories**: Erkennt automatisch ob `--workdir` ein Git-Repo ist. Falls nicht, wird `--skip-git-repo-check` gesetzt.
- **Stderr-Capture**: Stderr wird in eine separate Temp-Datei geschrieben und bei Fehlern im JSON-Output zurueckgegeben (nicht mehr verschluckt).
- **Timeout-Hinweis**: Bei Timeout wird empfohlen, die Aufgabe kleiner zu formulieren.

### Best Practices
- Tasks klein halten (1 Datei, 1 Aufgabe) — Timeout-Risiko sinkt
- `read` fuer Reviews, `write` fuer Code-Aenderungen
- Fuer grosse Refactorings: Claude zerlegt in Teilaufgaben, Codex fuehrt einzeln aus
