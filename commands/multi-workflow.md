---
description: "Orchestriere Multi-Model Workflow — Claude plant und reviewed, Codex liefert Backend-Prototypen"
argument-hint: <task-beschreibung>
model: opus
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
---
# Multi-Model Workflow

Du orchestrierst einen 6-Phasen-Workflow mit Claude (du) und Codex CLI.

## Phasen

### Phase 1: Analyse
Verstehe die Aufgabe: $ARGUMENTS
- Lies relevante Dateien (package.json, Cargo.toml, pyproject.toml fuer Kontext)
- Identifiziere Frontend- vs. Backend-Anteile

### Phase 2: Planung
Erstelle einen Implementierungsplan:
- Was macht Claude? (Frontend, Orchestration, komplexe Logik)
- Was macht Codex? (Backend-Prototyp, Algorithmen)

### Phase 3: Codex-Delegation
Fuer Backend/Algorithmen-Tasks, delegiere an Codex:
```bash
bash ~/develop/claude-forge/multi-model/codex-wrapper.sh \
  --sandbox write \
  --prompt "Implementiere: <konkreter Backend-Task>"
```

### Phase 4: Claude-Implementierung
Implementiere die Frontend/Orchestration-Anteile direkt.

### Phase 5: Integration
Fuege Claude- und Codex-Ergebnisse zusammen. Refactore den Codex-Output nach unseren Code-Standards.

### Phase 6: Review
Pruefe das Gesamtergebnis:
- Tests vorhanden?
- Code-Standards eingehalten?
- Keine Secrets/Vulnerabilities?

## Rollenverteilung
| Domain | Zustaendig | Grund |
|--------|-----------|-------|
| Orchestration | Claude | Workflow-Steuerung, Refactoring |
| Backend/Algo | Codex | Schnelle Prototypen, Performance |
| Frontend/UI | Claude | Design, Accessibility |
| Review | Beide | Codex: Security — Claude: Qualitaet |
