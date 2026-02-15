# claude-forge Architektur

## Warum Hybrid Plugin + Symlink?

Claude Code Plugins (`plugin.json`) koennen nur Komponenten innerhalb ihres
Namespace verwalten. User-Scope Dateien wie `~/.claude/settings.json` oder
`~/.claude/CLAUDE.md` liegen ausserhalb dieses Namespace.

Loesung: Das Repo ist beides — ein Plugin UND ein Symlink-basiertes Config-Repo.

## Dateipfade

| Repo-Datei | Ziel | Methode | Zweck |
|---|---|---|---|
| user-config/settings.json.example | ~/.claude/settings.json | Kopie (einmalig) | Hauptkonfiguration |
| user-config/CLAUDE.md.example | ~/.claude/CLAUDE.md | Kopie (einmalig) | Globale Instruktionen |
| user-config/MEMORY.md | ~/.claude/MEMORY.md | Symlink | Persistenter Speicher |
| rules/ | ~/.claude/rules/ | Symlink | Constraint-Regeln |
| hooks/ | ~/.claude/hooks/ | Symlink | Hook-Scripts |
| commands/ | ~/.claude/commands/ | Symlink | Slash-Commands |
| agents/*.md | ~/.claude/agents/*.md | Symlink (einzeln) | Subagenten |
| skills/*/ | ~/.claude/skills/*/ | Symlink (einzeln) | Skills |
| multi-model/ | ~/.claude/multi-model/ | Symlink | Codex CLI Wrapper |

### Kopie vs. Symlink

- **Kopie**: `settings.json` und `CLAUDE.md` werden aus `.example`-Vorlagen kopiert.
  Existierende Dateien werden NICHT ueberschrieben. So kann jeder User seine
  eigenen Praeferenzen pflegen (Sprache, MCP-Server, Permissions etc.).
- **Symlink**: Alle anderen Komponenten werden verlinkt. Aenderungen im Repo
  wirken sich sofort aus.

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
