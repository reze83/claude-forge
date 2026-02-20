# Smithery MCP — Sequential Thinking als Entscheidungs-Engine

**Aktivierung:** Bei JEDEM nicht-trivialen Task. Sequential thinking evaluiert den Kontext und entscheidet, ob MCP-Server aktiviert werden muessen — BEVOR mit eingebauten Tools gearbeitet wird.

## Entscheidungs-Flow (in sequential thinking ausfuehren)

1. **Task analysieren:** Was ist das Ziel? Welche Faehigkeiten braucht es?
2. **Verbundene Server pruefen:** Deckt ein bereits verbundener Server den Bedarf?
   - Server-IDs: im Context unter `smithery_ids`
   - Tools auflisten: `smithery tool list <id>`
3. **Luecke erkannt?** → `smithery mcp search "<capability>"` ausfuehren
   - Server mit hohem `useCount` bevorzugen (bewaehrt, stabil)
   - Verbinden: `smithery mcp add "<connectionUrl>"`
   - User kurz informieren welcher Server aktiviert wurde
4. **Task ausfuehren** mit allen verfuegbaren Tools (eingebaut + MCP)

## Entscheidungsmatrix — Wann MCP-Server suchen

| Task-Kontext                                                                 | Suchbegriff                |
| ---------------------------------------------------------------------------- | -------------------------- |
| Spezialisierte Sprachen (PowerShell, Terraform, Kotlin, Swift, Ruby, Lua, R) | `"<sprache>"`              |
| Container / Orchestrierung                                                   | `"docker"`, `"kubernetes"` |
| IaC (Terraform, Pulumi, CloudFormation)                                      | `"infrastructure"`         |
| Datenbank-Operationen (SQL, NoSQL, Graph)                                    | `"database"`               |
| Datenkonvertierung (PDF, CSV, XML)                                           | `"<format> convert"`       |
| Code-Analyse / Security-Audit                                                | `"code analysis"`          |
| Monitoring / Logs / Alerting                                                 | `"monitoring"`             |
| Externe Services / Plattformen                                               | `"<service-name>"`         |

**Faustregel:** Wenn ein spezialisiertes Tool bessere Ergebnisse liefern wuerde als Bash + WebSearch, ZUERST smithery durchsuchen.

## Verbundene Server nutzen

- Tool aufrufen: `smithery tool call <id> <tool-name> '<json-args>'`
- Bereits verbunden pruefen: `smithery mcp list`

## Aufraeumen

- Temporaere Server nach Task entfernen: `smithery mcp remove <id>`
- User fragen ob Server dauerhaft bleiben soll — sonst entfernen

## Fehlerbehandlung

- `smithery tool call` fehlgeschlagen → Fehlermeldung an User, nicht still ignorieren
- Server nicht erreichbar → `smithery mcp list` pruefen ob Status `connected`
