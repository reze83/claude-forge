---
name: performance-reference
description: "Referenzmaterial fuer Performance-Optimierung. Wird von der performance.md Rule referenziert — nur bei expliziter Anfrage oder Review laden."
version: "1.0.0"
user-invocable: false
---

# Performance-Referenz (passive Empfehlungen)

Diese Empfehlungen nur bei expliziter Anfrage oder Code-Review anwenden.

## Datenbank

- Indices fuer haeufig gefilterte/sortierte Spalten
- Connection Pooling statt neue Verbindungen pro Request

## Frontend

- Bundle-Size: Tree-Shaking, Code-Splitting, Dynamic Imports
- Lazy Loading fuer nicht-kritische Ressourcen (Bilder, Routen, Komponenten)
- Bilder: Moderne Formate (WebP/AVIF), responsive `srcset`
- CSS: Critical CSS inline, Rest async laden

## Backend

- Caching-Strategie (In-Memory, Redis, CDN) — passend zum Invalidierungsbedarf
- Batch-Verarbeitung statt Einzel-Operationen bei Massen-Daten
- Rate Limiting und Backpressure gegen Ueberlastung
- Keine unnoetige Serialisierung/Deserialisierung in Hot Paths
- Timeouts und Circuit Breakers fuer externe Abhaengigkeiten
