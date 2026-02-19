# Smithery MCP Auto-Discovery

## Verfügbare Tools nutzen

Wenn `smithery_connected` im additionalContext vorhanden ist, sind Smithery MCP Tools verfügbar.
Prüfe die verbundenen Server und nutze sie proaktiv für passende Aufgaben:

- Tools eines Servers auflisten: `smithery tool list <id>`
- Tool aufrufen: `smithery tool call <id> <tool-name> '<json-args>'`
- Server-IDs: im Context unter `smithery_ids`

## Eigenständige Entdeckung

Wenn du für eine Aufgabe ein externes Tool brauchst und es noch nicht verbunden ist:

1. Suche mit `smithery mcp search "<aufgabe>"` nach einem geeigneten Server
2. Bevorzuge Server mit hohem `useCount` (bewährt, stabil)
3. Verbinde mit `smithery mcp add "<connectionUrl>"`
4. Informiere den User kurz darüber, welchen Server du hinzugefügt hast
5. Nutze das Tool direkt

## Aufräumen

- Temporär hinzugefügte Server nach dem Test wieder entfernen: `smithery mcp remove <id>`
- Frage den User, ob er den Server dauerhaft behalten möchte — entferne ihn sonst

## Fehlerbehandlung

- Schlägt `smithery tool call` fehl: Fehlermeldung an User weitergeben, nicht still ignorieren
- Server nicht erreichbar: `smithery mcp list` prüfen, ob Status `connected` ist

## Wann aktiv suchen

- Code-Analyse / Security-Audit → `smithery mcp search "code analysis"`
- Datenbankzugriff → `smithery mcp search "database"`
- Externe APIs / Services → `smithery mcp search "<service-name>"`
- Wenn der User ein Tool benötigt, das nicht in `smithery_connected` ist
