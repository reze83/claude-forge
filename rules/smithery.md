# Smithery MCP — Orchestrierte Tool-Erweiterung

**Aktivierung:** Bei nicht-trivialen Tasks (>=3 Schritte, unklarer Kontext,
mehrere Loesungswege). Voraussetzung: `sequentialthinking` MCP-Tool verfuegbar.

## Interleaving-Flow

Sequential Thinking strukturiert die Entscheidungsfindung als nummerierte Thoughts.
**Zwischen** Thoughts werden andere Tools aufgerufen (Glob, Read, Bash).

### Pipeline

1. **Thought 1 — Task zerlegen:**
   Was ist das Ziel? Welche Schritte? Welche Faehigkeiten braucht es?

2. **Tool-Call: Kontext erkunden**
   Glob/Read ausfuehren → Dateitypen, Sprachen, Frameworks entdecken.

3. **Thought 2 — Faehigkeits-Luecke erkennen:**
   Gegen Entscheidungsmatrix pruefen (siehe unten).
   Braucht der Task Faehigkeiten jenseits der eingebauten Tools?

4. **Tool-Call: smithery mcp search** (nur bei erkannter Luecke)
   `smithery mcp search "<capability>"` — Server mit hohem useCount bevorzugen.

5. **Thought 3 — Ergebnisse bewerten:**
   Welche Server passen? User informieren. Entscheidung treffen.

6. **Tool-Call: smithery mcp add** (bei Bedarf)
   Server verbinden. Oder: eingebaute Tools reichen → keine Server noetig.

7. **Task ausfuehren** mit allen verfuegbaren Tools.

8. **Aufraeumen:** `smithery mcp remove <id>` fuer temporaere Server.

### Entscheidungsmatrix

| Task-Kontext                                                                 | Suchbegriff                   |
| ---------------------------------------------------------------------------- | ----------------------------- |
| Spezialisierte Sprachen (PowerShell, Terraform, Kotlin, Swift, Ruby, Lua, R) | `"<sprache>"`                 |
| Container / Orchestrierung                                                   | `"docker"`, `"kubernetes"`    |
| IaC (Terraform, Pulumi, CloudFormation)                                      | `"infrastructure"`            |
| CI/CD (Jenkins, GitLab CI, GitHub Actions)                                   | `"<tool-name>"`               |
| Datenbank-Operationen (SQL, NoSQL, Graph)                                    | `"database"`                  |
| Externe APIs / SaaS-Services                                                 | `"<service-name>"`            |
| Datenkonvertierung (PDF, CSV, XML)                                           | `"<format> convert"`          |
| Code-Analyse / Security-Audit                                                | `"code analysis"`             |
| Performance-Profiling                                                        | `"profiling"`                 |
| Kommunikation (Slack, Discord, Teams)                                        | `"<platform>"`                |
| Projektmanagement (Jira, Linear, Notion)                                     | `"<tool-name>"`               |
| Cloud-spezifisch (AWS, GCP, Azure)                                           | `"<cloud-provider>"`          |
| Monitoring / Logs / Alerting                                                 | `"monitoring"`                |
| Web-Recherche / Scraping                                                     | `"web search"`, `"scraper"`   |
| Akademische Papers (arXiv, Scholar, PubMed)                                  | `"arxiv"`, `"paper search"`   |
| DevTools / Browser-Automation (Playwright, Puppeteer)                        | `"browser"`, `"devtools"`     |
| DNS / CDN / Domain-Verwaltung                                                | `"dns"`, `"domain"`           |
| E-Mail (SMTP, IMAP, Transactional)                                           | `"email"`                     |
| Dokumentation externer Projekte                                              | `"documentation"`             |
| Tabellenkalkulation (Google Sheets, Excel)                                   | `"spreadsheet"`, `"excel"`    |
| Cloud Storage (Google Drive, OneDrive, Dropbox, S3)                          | `"cloud storage"`, `"drive"`  |
| Kalender / Scheduling (Google Calendar, Calendly)                            | `"calendar"`, `"scheduling"`  |
| Geospatial / Karten / GIS (Google Maps, Mapbox)                              | `"maps"`, `"gis"`             |
| Design-Tools / Whiteboard (Figma, Miro, Excalidraw)                          | `"figma"`, `"design"`         |
| CRM / Marketing / Analytics (Salesforce, HubSpot, PostHog)                   | `"crm"`, `"analytics"`        |
| Finance / Payment / E-Commerce (Stripe, Shopify, PayPal)                     | `"payment"`, `"e-commerce"`   |
| Social Media (Twitter/X, LinkedIn, Reddit)                                   | `"social media"`, `"twitter"` |
| Bild- / Medienverarbeitung (OCR, Image Gen)                                  | `"image"`, `"ocr"`            |
| Wissensmanagement / Memory / RAG                                             | `"memory"`, `"knowledge"`     |
| IoT / Home Automation (Home Assistant)                                       | `"iot"`, `"home automation"`  |

**Faustregel:** Die Matrix ist ein Trigger — sequential thinking entscheidet zur Laufzeit ob ein temporaerer Server gesucht und verbunden werden muss.

## Verbundene Server nutzen

- Tool aufrufen: `smithery tool call <id> <tool-name> '<json-args>'`
- Bereits verbunden pruefen: `smithery mcp list`
- Server-IDs: im Context unter `smithery_ids`

## Aufraeumen

- Temporaere Server nach Task entfernen: `smithery mcp remove <id>`
- Nur Sequential Thinking bleibt dauerhaft — alle anderen nach Task entfernen

## Fehlerbehandlung

- `smithery tool call` fehlgeschlagen → Fehlermeldung an User, nicht still ignorieren
- Server nicht erreichbar → `smithery mcp list` pruefen ob Status `connected`

## Graceful Degradation

Wenn `sequentialthinking` MCP-Tool NICHT verfuegbar:

1. Flow nativ im eigenen Denken durchfuehren (gleiche Schritte, ohne MCP-Tool)
2. Smithery-Suche bleibt moeglich via `smithery mcp search` in Bash
3. Kein Abbruch — reduzierte Strukturierung, gleiche Funktionalitaet
