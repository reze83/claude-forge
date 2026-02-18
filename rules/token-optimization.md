# Token-Optimierung

## Modell-Auswahl

- Subagents (Task-Tool): `claude-sonnet-4-6` — schnell, kostenguenstig
- Hauptagent: `claude-opus-4-6` — komplex, architekturell
- Einfache Lookups (Grep/Glob/Read): kein Subagent noetig — direkt ausfuehren

## MCP-Server

- Nicht benoetigte MCP-Server deaktivieren: `disabledMcpServers` in `.claude/settings.json`
- Pro Projekt nur Server aktivieren, die wirklich gebraucht werden

## Context-Window-Schonung

- `head_limit` bei Grep nutzen um Treffer zu begrenzen
- `offset` + `limit` bei Read nutzen statt ganze Dateien laden
- Subagents fuer breite Exploration nutzen (schuetzt Haupt-Context)
- Redundante Tool-Calls vermeiden — parallele Calls statt sequenzielle bevorzugen

## Memory

- Cross-Session-Wissen in `~/.claude/projects/*/memory/MEMORY.md` ablegen
- Laufenden Context nicht fuer stabiles Referenzwissen verschwenden
