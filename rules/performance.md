# Performance

**Aktivierung:** Diese Regeln gelten beim Schreiben und Editieren von Code. Aktive Pruefung bei jedem Code-Edit, passive Referenz nur bei expliziter Anfrage.

## Aktive Pruefung (bei jedem Code-Edit anwenden)

Weise unaufgefordert auf diese Probleme hin, wenn sie im geschriebenen oder editierten Code auftreten:

- N+1 Queries — Eager Loading / Batch-Abfragen vorschlagen
- `SELECT *` — nur benoetigte Spalten abfragen
- O(n^2) Schleifen bei potentiell grossen Datenmengen — effizienteren Algorithmus vorschlagen
- Fehlende Pagination bei Listen-Endpoints — Cursor-basiert empfehlen
- Synchrone I/O im Main-Thread — Async-Alternative vorschlagen
- Memory Leaks: Event-Listener ohne Cleanup, Subscriptions ohne Unsubscribe

## Passive Referenz

Detail-Empfehlungen fuer Datenbank, Frontend und Backend-Optimierung: siehe `~/.claude/skills/performance-reference/SKILL.md`
