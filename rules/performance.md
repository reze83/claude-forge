# Performance

## Aktive Pruefung (bei jedem Code-Edit anwenden)

Weise unaufgefordert auf diese Probleme hin, wenn sie im geschriebenen oder editierten Code auftreten:

- N+1 Queries — Eager Loading / Batch-Abfragen vorschlagen
- `SELECT *` — nur benoetigte Spalten abfragen
- O(n^2) Schleifen bei potentiell grossen Datenmengen — effizienteren Algorithmus vorschlagen
- Fehlende Pagination bei Listen-Endpoints — Cursor-basiert empfehlen
- Synchrone I/O im Main-Thread — Async-Alternative vorschlagen
- Memory Leaks: Event-Listener ohne Cleanup, Subscriptions ohne Unsubscribe

## Passive Referenz (nur bei expliziter Anfrage oder Review)

### Datenbank

- Indices fuer haeufig gefilterte/sortierte Spalten
- Connection Pooling statt neue Verbindungen pro Request

### Frontend

- Bundle-Size: Tree-Shaking, Code-Splitting, Dynamic Imports
- Lazy Loading fuer nicht-kritische Ressourcen (Bilder, Routen, Komponenten)
- Bilder: Moderne Formate (WebP/AVIF), responsive `srcset`
- CSS: Critical CSS inline, Rest async laden

### Backend

- Caching-Strategie (In-Memory, Redis, CDN) — passend zum Invalidierungsbedarf
- Batch-Verarbeitung statt Einzel-Operationen bei Massen-Daten
- Rate Limiting und Backpressure gegen Ueberlastung
- Keine unnoetige Serialisierung/Deserialisierung in Hot Paths
- Timeouts und Circuit Breakers fuer externe Abhaengigkeiten

## Grundsatz

- Frueh messen, spaet optimieren — Profiler nutzen statt raten
- Keine vorzeitige Optimierung — erst wenn ein Engpass gemessen wurde
