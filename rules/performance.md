# Performance

## Datenbank & Queries

- N+1 Queries vermeiden — Eager Loading / Batch-Abfragen nutzen
- Indices fuer haeufig gefilterte/sortierte Spalten
- `SELECT *` vermeiden — nur benoetigte Spalten abfragen
- Pagination bei grossen Ergebnismengen (Cursor-basiert bevorzugt)
- Connection Pooling statt neue Verbindungen pro Request

## Frontend

- Bundle-Size ueberwachen — Tree-Shaking, Code-Splitting, Dynamic Imports
- Lazy Loading fuer nicht-kritische Ressourcen (Bilder, Routen, Komponenten)
- Keine synchronen Operationen im Main-Thread (Web Workers fuer CPU-intensive Tasks)
- Bilder: Moderne Formate (WebP/AVIF), responsive `srcset`, Lazy Loading
- CSS: Critical CSS inline, Rest async laden

## Backend

- Caching-Strategie definieren (In-Memory, Redis, CDN) — passend zum Invalidierungsbedarf
- Async/Non-blocking I/O fuer externe Aufrufe (API, DB, Filesystem)
- Batch-Verarbeitung statt Einzel-Operationen bei Massen-Daten
- Rate Limiting und Backpressure gegen Ueberlastung
- Keine unnoetige Serialisierung/Deserialisierung in Hot Paths

## Allgemein

- Frueh messen, spaet optimieren — Profiler nutzen statt raten
- Algorithmen-Komplexitaet beachten (O(n^2) Schleifen vermeiden bei grossen Datenmengen)
- Keine vorzeitige Optimierung — erst wenn ein Engpass gemessen wurde
- Memory Leaks vermeiden: Event-Listener aufraemen, Subscriptions unsubscriben
- Timeouts und Circuit Breakers fuer externe Abhaengigkeiten
