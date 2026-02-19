# Token-Optimierung

## Modell-Auswahl

- Subagents (Task-Tool): `claude-sonnet-4-6` — schnell, kostenguenstig
- Triviale Subagents (Formatierung, Lookups): `claude-haiku-4-5` — minimal cost
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
- Background-Tasks (`run_in_background`) fuer lange Operationen (Tests, Builds)
- Dateien nicht mehrfach lesen — einmal lesen, Information nutzen

## Memory

- Cross-Session-Wissen in `~/.claude/projects/*/memory/MEMORY.md` ablegen
- Laufenden Context nicht fuer stabiles Referenzwissen verschwenden
