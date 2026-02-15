---
description: "Frontend-Task von Claude bearbeitet, mit Codex-Review"
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

## Schritt 2: Codex-Review (PFLICHT)
Lasse Codex den Code reviewen. Diesen Schritt IMMER ausfuehren:
```bash
bash $HOME/.claude/multi-model/codex-wrapper.sh \
  --sandbox read \
  --prompt "Reviewe diesen Frontend-Code auf Performance und Best Practices: <code>"
```

## Schritt 3: Feedback integrieren
Werte Codex' Feedback aus und integriere sinnvolle Vorschlaege.
