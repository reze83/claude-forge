---
description: "Strukturiertes Refactoring mit Claude-Planung und Codex-Transformation pro Datei"
argument-hint: <refactoring-beschreibung>
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

# Multi-Refactor

Refactoring-Aufgabe: $ARGUMENTS

## Schritt 1: Analyse

Analysiere den betroffenen Code:

- Code Smells identifizieren (lange Funktionen, Duplikation, God Class, Feature Envy)
- Scope bestimmen: welche Dateien sind betroffen?
- Abhaengigkeiten und Referenzen kartieren

## Schritt 2: Refactoring-Plan

Erstelle einen konkreten Plan:

- Reihenfolge der Dateien (Abhaengigkeiten beachten)
- Transformation pro Datei beschreiben
- Risiken und Rueckfall-Strategie definieren

## Schritt 3: Codex-Transformation (PFLICHT)

Delegiere die Transformationen an Codex — EINE Datei pro Aufruf. Diesen Schritt IMMER ausfuehren:

```bash
bash $HOME/.claude/multi-model/codex-wrapper.sh \
  --sandbox write \
  --context-file <aktuelle-datei> \
  --prompt "Refactoring: <konkrete-transformation-fuer-diese-datei>"
```

Bei mehreren Dateien: Codex-Aufrufe nacheinander, jede Datei einzeln.

## Schritt 4: Review pro Datei

Pruefe jede Codex-Aenderung sofort:

- Korrektheit: Verhalt sich der Code identisch?
- Lesbarkeit: Ist die Transformation eine Verbesserung?
- Kompatibilitaet: Stimmen Imports und Referenzen noch?

Falls Codex-Output nicht genuegt: Claude refactort selbst (kein zweiter Codex-Aufruf).

## Schritt 5: Integration

- Imports und Referenzen ueber alle Dateien aktualisieren
- Tests ausfuehren — alle muessen gruen sein
- Bei Testfehler: sofort zurueckrollen und Ursache analysieren
