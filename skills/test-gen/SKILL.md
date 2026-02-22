---
name: test-gen
description: "Verwende diesen Skill wenn der User Tests generieren, Testabdeckung erhoehen oder fehlende Tests fuer bestehenden Code erstellen moechte."
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

# Test-Generierung

Generiere Tests fuer $ARGUMENTS:

## Ablauf

1. **Analyse**: Lies den zu testenden Code. Identifiziere:
   - Oeffentliche API (Funktionen, Methoden, Exports)
   - Abhaengigkeiten (Imports, externe Services)
   - Edge Cases (null, leere Arrays, Grenzen, Fehler)
   - Bestehendes Test-Framework (jest, vitest, pytest, cargo test, etc.)

2. **Strategie**: Bestimme den Test-Ansatz:
   - **Unit Tests**: Isolierte Funktionen, reine Logik
   - **Integration Tests**: Zusammenspiel von Modulen, DB-Zugriffe
   - **Edge Cases**: Grenzwerte, Fehler, leere Inputs, Timeouts
   - Mocking-Strategie fuer externe Abhaengigkeiten

3. **Generierung**: Erstelle Tests nach diesen Prinzipien:
   - Arrange-Act-Assert Pattern (AAA)
   - Ein Assert pro Test (wo sinnvoll)
   - Deskriptive Testnamen: `should return empty array when no items match`
   - Test-Datei neben Source-Datei oder im tests/ Verzeichnis (Projekt-Konvention folgen)
   - Kein Test fuer triviale Getter/Setter

4. **Verify**: Fuehre die generierten Tests aus:
   - Alle Tests muessen gruenn sein
   - Bei Fehler: analysieren und fixen
   - Coverage-Bericht anzeigen (falls verfuegbar)

## Ausgabe

Zeige dem User:

- Anzahl generierter Tests
- Abgedeckte Szenarien (Happy Path, Error Cases, Edge Cases)
- Empfehlung fuer weitere Tests (falls Luecken erkannt)

## Codex-Erweiterung (optional)

Wenn Codex CLI installiert ist (`command -v codex`), biete nach Abschluss an:

> Codex ist verfuegbar. Soll Codex zusaetzliche Tests aus einer anderen Perspektive generieren? (`/multi-test` Pattern)

Bei Zustimmung:

```bash
bash $HOME/.claude/multi-model/codex-wrapper.sh \
  --sandbox write \
  --context-file <quelldatei> \
  --prompt "Generiere zusaetzliche Tests aus einer anderen Perspektive. Framework: <framework>."
```

Nur einzigartige, nicht-duplizierte Testfaelle uebernehmen und mit bestehenden Tests zusammenfuehren.
Diese Erweiterung ist IMMER opt-in — niemals automatisch.

Antworte auf Deutsch.
