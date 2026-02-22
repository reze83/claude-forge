---
description: "Erstelle Tests mit dualem Claude/Codex-Workflow — Claude identifiziert, Codex generiert, Claude reviewed"
argument-hint: <quelldatei>
model: opus
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# Multi-Test

Erstelle oder erweitere Tests fuer: $ARGUMENTS

## Schritt 1: Kontext

Lies die angegebene Quelldatei und erkenne automatisch:

- Test-Framework (jest, vitest, pytest, go test, cargo test, bats, etc.)
- Bestehende Test-Konventionen (Dateiname-Pattern, Verzeichnis)
- Exportierte Funktionen/Klassen, Abhaengigkeiten, Edge Cases

## Schritt 2: Testdesign

Identifiziere konkrete Testfaelle:

- Happy Path fuer jede exportierte Funktion
- Edge Cases (leere Eingaben, Grenzwerte, Null/Undefined)
- Fehlerpfade (invalide Eingaben, Exceptions, Timeouts)
- Notiere Framework und Konventionen fuer Codex

## Schritt 3: Codex-Generierung (PFLICHT)

Lasse Codex die Tests generieren. Diesen Schritt IMMER ausfuehren:

```bash
bash $HOME/.claude/multi-model/codex-wrapper.sh \
  --sandbox write \
  --context-file <quelldatei> \
  --prompt "Generiere Tests fuer die uebergebene Datei. Framework: <framework>. Konventionen: <konventionen>. Teste: <testfaelle>"
```

## Schritt 4: Review + Korrektur

Pruefe Codex' Tests auf:

- Korrekte Imports und Pfade
- Sinnvolle Assertions (nicht nur Existenz-Checks)
- Fehlende Edge Cases aus Schritt 2 ergaenzen
- Code-Standards (Naming, Struktur, keine Magic Numbers)

## Schritt 5: Finalisieren

Schreibe die finale Testdatei und fuehre die Tests aus. Alle muessen gruen sein.
