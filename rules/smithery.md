# Smithery MCP Auto-Discovery

**Aktivierung:** Diese Regeln gelten wenn `smithery_connected` im additionalContext vorhanden ist oder eine Aufgabe spezialisierte Faehigkeiten erfordert, die ueber die eingebauten Tools hinausgehen (siehe "Wann aktiv suchen").

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

Suche via `smithery mcp search`, wenn eine Aufgabe in diese Kategorien faellt und kein passendes MCP-Tool bereits verbunden ist:

**Spezialisierte Sprachen/Dateitypen:**

- PowerShell (`.ps1`), Terraform (`.tf`), Ansible, Kotlin, Swift, Ruby, Lua, R
- Jeder Dateityp, der nicht zu den Standard-Sprachen (JS/TS, Python, Rust, Go, Shell, Java) gehoert

**Frameworks und Infrastruktur:**

- Docker/Kubernetes → `smithery mcp search "docker"`
- IaC (Terraform, Pulumi, CloudFormation) → `smithery mcp search "infrastructure"`
- CI/CD (Jenkins, GitLab CI, GitHub Actions) → `smithery mcp search "<tool-name>"`

**Web und Recherche:**

- Spezialisierte Websuche / Scraping → `smithery mcp search "web search"`
- News / Echtzeit-Daten → `smithery mcp search "news"`
- Dokumentation externer Projekte → `smithery mcp search "documentation"`

**Datenquellen und APIs:**

- Datenbankzugriff (SQL, NoSQL, Graph) → `smithery mcp search "database"`
- Externe APIs / SaaS-Services → `smithery mcp search "<service-name>"`
- Datenkonvertierung (PDF, CSV, XML) → `smithery mcp search "<format> convert"`

**Analyse und Qualitaet:**

- Code-Analyse / Security-Audit → `smithery mcp search "code analysis"`
- Performance-Profiling → `smithery mcp search "profiling"`
- Accessibility / SEO-Pruefung → `smithery mcp search "accessibility"`

**Kommunikation und Projektmanagement:**

- Slack, Discord, Teams → `smithery mcp search "<platform>"`
- Jira, Linear, Notion, Trello → `smithery mcp search "<tool-name>"`
- E-Mail-Versand/-Empfang → `smithery mcp search "email"`

**Cloud und Monitoring:**

- AWS/GCP/Azure-spezifische Operationen → `smithery mcp search "<cloud-provider>"`
- Logs, Metriken, Alerting → `smithery mcp search "monitoring"`
- DNS, CDN, Domain-Verwaltung → `smithery mcp search "<service>"`

**Entscheidungsregel:** Wenn die eingebauten Tools (Bash, Read, Grep, WebFetch, WebSearch) fuer eine Aufgabe nicht ausreichen oder ein spezialisiertes Tool bessere Ergebnisse liefern wuerde, fuehre die Suche durch BEVOR du mit Workarounds arbeitest.
