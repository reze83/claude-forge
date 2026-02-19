# API-Design

## REST-Konventionen

- Ressourcen als Nomen (Plural): `/users`, `/orders/{id}/items`
- HTTP-Verben semantisch: GET (lesen), POST (erstellen), PUT/PATCH (aendern), DELETE (loeschen)
- Konsistente URL-Struktur: kebab-case, keine Verben in URLs
- Idempotenz: PUT und DELETE muessen idempotent sein

## Versionierung

- URL-Prefix bevorzugt: `/api/v1/` (einfach, explizit)
- Aeltere Version mindestens eine Major-Version unterstuetzen
- Breaking Changes nur in neuer Major-Version

## Fehler-Responses

- Einheitliches Error-Format ueber alle Endpoints:
  ```json
  { "error": { "code": "VALIDATION_ERROR", "message": "...", "details": [...] } }
  ```
- HTTP-Statuscodes korrekt nutzen (400 vs. 422, 401 vs. 403, 404 vs. 410)
- Keine Stack-Traces in Produktion — nur in Development

## Pagination

- Cursor-basiert fuer grosse/dynamische Datenmengen (kein Offset-Drift)
- Offset-basiert nur fuer statische/kleine Datenmengen
- Response-Metadaten: `total`, `hasMore`, `nextCursor`

## Request/Response

- Konsistente Namensgebung: camelCase (JSON) oder snake_case — nie mischen
- Keine Envelope-Wrapper ohne Grund (kein `{ "data": { "data": ... } }`)
- Partial Updates via PATCH mit nur geaenderten Feldern
- Filter, Sortierung, Felder via Query-Parameter: `?sort=-created_at&fields=id,name`

## Sicherheit

- Authentication via Bearer Token (Header), nie in URL-Parametern
- Rate Limiting mit `Retry-After` Header
- CORS restriktiv konfigurieren — nur erlaubte Origins
- Input-Validierung an der API-Grenze, nicht im Service-Layer allein
