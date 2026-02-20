# API-Design

**Aktivierung:** Diese Standards gelten wenn HTTP-Endpoints geschrieben werden (Express, FastAPI, Gin, Spring, etc.). Pruefe aktiv dagegen bei Code-Reviews von API-Code.

## REST-Konventionen

- Ressourcen als Nomen (Plural): `/users`, `/orders/{id}/items`
- Konsistente URL-Struktur: kebab-case, keine Verben in URLs
- Idempotenz: PUT und DELETE muessen idempotent sein

## Versionierung

- URL-Prefix bevorzugt: `/api/v1/` (einfach, explizit)
- Aeltere Version mindestens eine Major-Version unterstuetzen

## Fehler-Responses

- Einheitliches Error-Format ueber alle Endpoints:
  ```json
  { "error": { "code": "VALIDATION_ERROR", "message": "...", "details": [...] } }
  ```
- HTTP-Statuscodes korrekt nutzen (400 vs. 422, 401 vs. 403, 404 vs. 410)

## Pagination

- Cursor-basiert fuer grosse/dynamische Datenmengen (kein Offset-Drift)
- Offset-basiert nur fuer statische/kleine Datenmengen
- Response-Metadaten: `total`, `hasMore`, `nextCursor`

## Request/Response

- Konsistente Namensgebung: camelCase bevorzugt (JSON-Standard), snake_case wenn Projekt es bereits nutzt — nie mischen
- Keine Envelope-Wrapper ohne Grund (kein `{ "data": { "data": ... } }`)
- Partial Updates via PATCH mit nur geaenderten Feldern
- Filter, Sortierung, Felder via Query-Parameter: `?sort=-created_at&fields=id,name`

## Sicherheit

- Authentication via Bearer Token (Header), nie in URL-Parametern
- Rate Limiting mit `Retry-After` Header
- CORS restriktiv konfigurieren — nur erlaubte Origins
- Input-Validierung an der API-Grenze, nicht im Service-Layer allein
