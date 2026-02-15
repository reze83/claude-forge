---
description: "Frontend-Task von Claude bearbeitet, optional mit Codex-Review"
argument-hint: <frontend-aufgabe>
model: opus
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---
# Multi-Frontend

Frontend-Aufgabe: $ARGUMENTS

## Schritt 1: Claude implementiert
Implementiere die Frontend-Aufgabe direkt. Du bist hier der Lead.

## Schritt 2: Codex-Review (optional)
Frage den User ob ein Codex-Review gewuenscht ist. Falls ja:
```bash
bash ~/develop/claude-forge/multi-model/codex-wrapper.sh \
  --sandbox read \
  --prompt "Reviewe diesen Frontend-Code auf Performance und Best Practices: <code>"
```

## Schritt 3: Feedback integrieren
Werte Codex' Feedback aus und integriere sinnvolle Vorschlaege.
