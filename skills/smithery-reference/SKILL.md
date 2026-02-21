---
name: smithery-reference
description: "Referenzmaterial fuer Smithery MCP-Orchestrierung. Wird von der smithery.md Rule referenziert — nur bei expliziter Anfrage laden."
version: "1.0.0"
user-invocable: false
---

# Smithery-Referenz (passive Empfehlungen)

Diese Empfehlungen nur bei expliziter Anfrage oder MCP-Server-Evaluation anwenden.

## Entscheidungsmatrix

Gegen diese Matrix pruefen wenn Sequential Thinking eine Faehigkeits-Luecke erkennt:

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

**Faustregel:** Die Matrix ist ein Trigger — Sequential Thinking entscheidet zur Laufzeit ob ein temporaerer Server gesucht und verbunden werden muss.

## Smithery CLI-Befehle

```bash
# Server suchen (useCount als Qualitaetssignal)
smithery mcp search "<capability>"

# Server verbinden (temporaer fuer aktuellen Task)
smithery mcp add <server-id>

# Verbundene Server pruefen
smithery mcp list

# Server nach Task entfernen
smithery mcp remove <id>
```

MCP-Tools verbundener Server werden direkt als Tools aufgerufen (kein `smithery tool call` noetig).

## Fehlerbehandlung

- Server nicht erreichbar → `smithery mcp list` pruefen ob Status `connected`
- MCP-Tool fehlgeschlagen → Fehlermeldung an User, nicht still ignorieren
- `smithery mcp search` ohne Treffer → eingebaute Tools nutzen, kein Retry
