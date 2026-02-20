# Token-Optimierung

**Aktivierung:** Immer aktiv — gilt fuer jeden Task.

## Modell-Auswahl (Subagents via Task-Tool)

- Standard-Tasks: `model: "sonnet"` — schnell, kostenguenstig
- Triviale Tasks (Formatierung, Lookups): `model: "haiku"` — minimal cost
- Einfache Lookups (Grep/Glob/Read): kein Subagent noetig — direkt ausfuehren

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
