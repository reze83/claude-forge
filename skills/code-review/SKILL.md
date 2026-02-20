---
name: code-review
description: "Verwende diesen Skill wenn der User nach einem Code-Review, einer Code-Analyse oder Feedback zu Code fragt. Fuehrt ein strukturiertes Review mit Schweregrad-Bewertung durch."
version: "1.0.0"
user-invocable: true
allowed-tools:
  - Read
  - Glob
  - Grep
---

# Code-Review

## Ablauf

1. **Uebersicht**: Was tut der Code? Kontext verstehen.
2. **Positives**: Was ist gut geloest? Gute Patterns benennen.
3. **Probleme**: Bugs, Sicherheitsluecken, Performance-Issues.
4. **Verbesserungen**: Konkrete Vorschlaege mit Code-Beispielen.
5. **Tests**: Fehlende Testfaelle identifizieren.

## Bewertungskriterien

- Lesbarkeit und Namensgebung
- Error Handling (keine stillen Fehler)
- Typsicherheit
- SOLID-Prinzipien
- Performance (unnoetige Iterationen, N+1 Queries)
- Sicherheit (OWASP Top 10)

## Schweregrade

- CRITICAL: Muss sofort gefixt werden (Bugs, Security)
- HIGH: Sollte vor Merge gefixt werden
- MEDIUM: Verbesserung empfohlen
- LOW: Kosmetisch / Nice-to-have

## Codex-Erweiterung (optional)

Wenn Codex CLI installiert ist (`command -v codex`), biete nach Abschluss an:

> Codex ist verfuegbar. Soll ich eine unabhaengige Codex-Review als zweite Meinung einholen? (`/multi-frontend` Pattern)

Bei Zustimmung:

```bash
bash $HOME/.claude/multi-model/codex-wrapper.sh \
  --sandbox read \
  --context-file <review-datei> \
  --prompt "Fuehre eine unabhaengige Code-Review durch und liste Findings mit Schweregrad."
```

Danach Claude- und Codex-Findings vergleichen und Unterschiede hervorheben.
Diese Erweiterung ist IMMER opt-in — niemals automatisch.

Antworte auf Deutsch.
