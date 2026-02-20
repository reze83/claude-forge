---
name: refactor
description: "Verwende diesen Skill wenn der User Code refactoren, umstrukturieren oder die Code-Qualitaet verbessern moechte. Fuehrt strukturiertes Refactoring mit Sicherheitsnetz durch."
version: "1.0.0"
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# Refactoring

Refactore $ARGUMENTS:

## Ablauf

1. **Analyse**: Verstehe den aktuellen Code:
   - Was tut der Code? Welche Verantwortlichkeiten hat er?
   - Welche Code Smells liegen vor? (Lange Funktionen, Duplikation, God Class, Feature Envy)
   - Welche Abhaengigkeiten gibt es? (Imports, Referenzen, APIs)

2. **Sicherheitsnetz**: Bevor du aenderst:
   - Pruefe ob Tests vorhanden sind und laufen
   - Falls keine Tests: generiere erst Characterization Tests fuer das bestehende Verhalten
   - Fuehre Tests aus — sie muessen gruenn sein

3. **Strategie**: Waehle den Refactoring-Ansatz:
   - **Extract**: Methode/Funktion/Klasse extrahieren
   - **Rename**: Klarere Namensgebung
   - **Simplify**: Bedingungen vereinfachen, verschachtelte Logik aufloesen
   - **Move**: Verantwortlichkeiten in passende Module verschieben
   - **Compose**: Kleine Methoden statt einer grossen
   - Immer in kleinen Schritten — nach jedem Schritt Tests ausfuehren

4. **Umsetzung**: Fuehre das Refactoring durch:
   - Ein Refactoring-Schritt pro Durchgang
   - Nach jedem Schritt: Tests ausfuehren
   - Bei Test-Fehler: sofort zurueckrollen und Ursache analysieren
   - Keine Funktionsaenderungen — nur Strukturverbesserung

5. **Verify**: Abschlusspruefung:
   - Alle Tests grueen
   - Keine neuen Warnungen
   - Code ist lesbarer / wartbarer als vorher

## Ausgabe

Zeige dem User:

- Vorher/Nachher Vergleich (was geaendert wurde)
- Angewandte Refactoring-Techniken
- Testergebnisse

## Codex-Erweiterung (optional)

Wenn Codex CLI installiert ist (`command -v codex`), biete nach dem Refactoring-Plan an:

> Codex ist verfuegbar. Soll Codex die mechanischen Transformationen uebernehmen? (`/multi-refactor` Pattern)

Bei Zustimmung — pro Zieldatei:

```bash
bash $HOME/.claude/multi-model/codex-wrapper.sh \
  --sandbox write \
  --context-file <zieldatei> \
  --prompt "Refactoring: <konkrete-transformation>. Keine Verhaltensaenderung."
```

Nur mechanische Transformationen delegieren; Abwaegungen und finale Review bleiben bei Claude.
Diese Erweiterung ist IMMER opt-in — niemals automatisch.

Antworte auf Deutsch.
