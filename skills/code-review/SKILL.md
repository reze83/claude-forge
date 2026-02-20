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

Antworte auf Deutsch.
