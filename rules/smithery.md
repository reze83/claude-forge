# Smithery MCP — Sequential Thinking als Entscheidungs-Engine

**Aktivierung:** Bei JEDEM nicht-trivialen Task. Sequential thinking evaluiert den Kontext und entscheidet, ob MCP-Server aktiviert werden muessen — BEVOR mit eingebauten Tools gearbeitet wird.

## Entscheidungs-Flow (in sequential thinking ausfuehren)

1. **Task analysieren:** Was ist das Ziel? Welche Faehigkeiten braucht es?
2. **Gegen Entscheidungsmatrix pruefen** — faellt der Task in eine dieser Kategorien?

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

3. **Verbundene Server pruefen:** Nur Sequential Thinking ist dauerhaft verbunden. Alle anderen werden bei Bedarf temporaer hinzugefuegt.
   - Server-IDs: im Context unter `smithery_ids`
   - Tools auflisten: `smithery tool list <id>`
4. **Luecke erkannt?** → `smithery mcp search "<capability>"` ausfuehren
   - Server mit hohem `useCount` bevorzugen (bewaehrt, stabil)
   - Verbinden: `smithery mcp add "<connectionUrl>"`
   - User kurz informieren welcher Server aktiviert wurde
5. **Task ausfuehren** mit allen verfuegbaren Tools (eingebaut + MCP)

## Verbundene Server nutzen

- Tool aufrufen: `smithery tool call <id> <tool-name> '<json-args>'`
- Bereits verbunden pruefen: `smithery mcp list`

## Aufraeumen

- Temporaere Server nach Task entfernen: `smithery mcp remove <id>`
- Nur Sequential Thinking bleibt dauerhaft — alle anderen nach Task entfernen

## Fehlerbehandlung

- `smithery tool call` fehlgeschlagen → Fehlermeldung an User, nicht still ignorieren
- Server nicht erreichbar → `smithery mcp list` pruefen ob Status `connected`
