---
description: "Generiere parallele Implementierungsplaene von Claude und Codex zum Vergleich"
argument-hint: <feature-beschreibung>
model: sonnet
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
---

# Multi-Plan

Erstelle zwei parallele Implementierungsplaene fuer: $ARGUMENTS

## Schritt 1: Kontext sammeln

Lies relevante Dateien fuer den Projektkontext.

## Schritt 2: Claude-Plan

Erstelle deinen eigenen Implementierungsplan direkt hier.

## Schritt 3: Codex-Plan (PFLICHT)

Hole Codex' Perspektive. Diesen Schritt IMMER ausfuehren:

```bash
bash $HOME/.claude/multi-model/codex-wrapper.sh \
  --sandbox read \
  --prompt "Erstelle einen Implementierungsplan fuer: $ARGUMENTS. Beschreibe Architektur, Dateien, Abhaengigkeiten."
```

## Schritt 4: Vergleich

Prasentiere beide Plaene nebeneinander:

- Gemeinsamkeiten
- Unterschiede
- Empfehlung welchen Ansatz (oder Kombination) der User waehlen sollte
