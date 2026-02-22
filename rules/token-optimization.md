# Token-Optimierung

**Aktivierung:** Immer aktiv — gilt fuer jeden Task.

## Modell-Auswahl (Subagents via Task-Tool)

- Standard-Tasks: `model: "sonnet"` — schnell, kostenguenstig
- Triviale Tasks (Formatierung, Lookups): `model: "haiku"` — minimal cost
- Einfache Lookups (Grep/Glob/Read): kein Subagent noetig — direkt ausfuehren

## Such-Tool-Wahl

| Tool                     | Wann nutzen                                               |
| ------------------------ | --------------------------------------------------------- |
| Glob / Grep / Read       | Lokale Codebase — immer bevorzugen, kein Netzwerk         |
| `context7`               | Docs zu bekannten Libraries (versioniert, API-Referenz)   |
| `exa` (web_search)       | Aktuelle Web-Infos, News, unbekannte Packages, Changelogs |
| `exa` (get_code_context) | Code-Beispiele, Stack Overflow, GitHub-Snippets zu APIs   |
| WebSearch                | Fallback wenn exa nicht verfuegbar                        |
| WebFetch                 | Einzelne bekannte URL abrufen — kein generelles Suchen    |

## MCP-Server

- Nicht benoetigte MCP-Server deaktivieren: `disabledMcpServers` in `.claude/settings.json`
- Pro Projekt nur Server aktivieren, die wirklich gebraucht werden

## Context-Window-Schonung

- `head_limit` bei Grep nutzen um Treffer zu begrenzen
- `offset` + `limit` bei Read nutzen statt ganze Dateien laden
- Subagents fuer breite Exploration nutzen (>3 Dateien unbekannt, Codebase-Struktur unklar)
- Background-Tasks (`run_in_background`) fuer lange Operationen (Tests, Builds)

## Memory

- Nach Sessions mit wiederverwendbarem Wissen: in `~/.claude/projects/*/memory/MEMORY.md` ablegen
- Laufenden Context nicht fuer stabiles Referenzwissen verschwenden
