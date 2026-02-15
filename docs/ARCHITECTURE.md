# claude-forge Architektur

## Warum Hybrid Plugin + Symlink?

Claude Code Plugins (`plugin.json`) koennen nur Komponenten innerhalb ihres
Namespace verwalten. User-Scope Dateien wie `~/.claude/settings.json` oder
`~/.claude/CLAUDE.md` liegen ausserhalb dieses Namespace.

Loesung: Das Repo ist beides — ein Plugin UND ein Symlink-basiertes Config-Repo.

## Dateipfade

| Repo-Datei | Symlink-Ziel | Zweck |
|---|---|---|
| user-config/settings.json | ~/.claude/settings.json | Hauptkonfiguration |
| user-config/CLAUDE.md | ~/.claude/CLAUDE.md | Globale Instruktionen |
| user-config/MEMORY.md | ~/.claude/MEMORY.md | Persistenter Speicher |
| user-config/rules/ | ~/.claude/rules/ | Constraint-Regeln |
| hooks/ | ~/.claude/hooks/ | Hook-Scripts |
| commands/ | ~/.claude/commands/ | Slash-Commands |
| agents/*.md | ~/.claude/agents/*.md | Subagenten (einzeln) |
| skills/*/ | ~/.claude/skills/*/ | Skills (einzeln) |

## WICHTIG: Installationsmodus

**Symlink-Modus** (`bash install.sh`) und **Plugin-Modus** (`claude --plugin-dir`)
duerfen NICHT gleichzeitig aktiv sein. Sonst werden Hooks doppelt geladen.

- Symlink-Modus: Empfohlen fuer permanente Installation
- Plugin-Modus: Fuer temporaeres Testen oder Projekt-Level

## Hook-Output: Modernes JSON-Format

Hooks nutzen das JSON-Output-Format auf stdout (empfohlen seit 2026):
```json
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"..."}}
```
Plus `exit 2` als Fallback fuer aeltere Claude Code Versionen.

## Hook-Pfade: Zwei Systeme

1. **settings.json** nutzt `$HOME/.claude/hooks/` → funktioniert via Symlink
2. **hooks.json** nutzt `${CLAUDE_PLUGIN_ROOT}/hooks/` → funktioniert als Plugin

## Warum Bash statt Python fuer Hooks?

- Keine Dependencies (jq reicht fuer JSON)
- Schnellerer Startup (~5ms vs ~200ms)
- Einfacher zu debuggen
- Konsistent mit bestehenden Hooks
