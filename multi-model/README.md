# Multi-Model Modul (Claude + Codex)

## Architektur

```
Claude Code (Orchestrator)
    |
    └── codex-wrapper.sh → codex exec
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
