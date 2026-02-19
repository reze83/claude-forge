# Smithery MCP Auto-Discovery

**Aktivierung:** Diese Regeln gelten wenn `smithery_connected` im additionalContext vorhanden ist oder spezialisierte Sprachen/Frameworks/Analyse-Tasks erkannt werden.

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

Suche IMMER via `smithery mcp search`, wenn eine dieser Bedingungen zutrifft:

**Spezialisierte Sprachen/Dateitypen:**

- PowerShell (`.ps1`), Terraform (`.tf`), Ansible, Kotlin, Swift, Ruby, Lua, R
- Jeder Dateityp, der nicht zu den Standard-Sprachen (JS/TS, Python, Rust, Go, Shell, Java) gehoert

**Frameworks und Tools:**

- Docker/Kubernetes Konfigurationen → `smithery mcp search "docker"`
- IaC (Terraform, Pulumi, CloudFormation) → `smithery mcp search "infrastructure"`
- CI/CD Pipelines (Jenkins, GitLab CI) → `smithery mcp search "<tool-name>"`

**Analyse-Aufgaben:**

- Code-Analyse / Security-Audit → `smithery mcp search "code analysis"`
- Datenbankzugriff → `smithery mcp search "database"`
- Externe APIs / Services → `smithery mcp search "<service-name>"`

**Entscheidungsregel:** Wenn du Dateien analysieren sollst und kein spezialisiertes MCP-Tool verbunden ist, fuehre die Suche durch BEVOR du mit eingebautem Wissen allein arbeitest. Ein spezialisiertes Tool liefert oft bessere Ergebnisse als generische Analyse.
