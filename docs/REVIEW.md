# Plan-Review Ergebnisse

## Methodik
16-Schritte Sequential Thinking + 3 parallele Research-Agenten:
1. **Offizielle Doku** (WebSearch/WebFetch): Plugin, Hooks, Agents, Skills, Commands Schema
2. **Codex CLI** (WebSearch): Aktuelle Version, API, Breaking Changes
3. **Lokale Plugins** (Explore): Exakte Formate der installierten offiziellen Plugins

## Gefundene Probleme und durchgefuehrte Fixes

### KRITISCH (gefixt)

| # | Problem | Fix |
|---|---------|-----|
| K1 | install.sh hatte keine Phase fuer Commands-Symlinks | Phase 5 fuer `commands/ → ~/.claude/commands/` hinzugefuegt |
| K2 | Doppelt-Laden-Risiko bei gleichzeitiger Plugin + Symlink Nutzung | Dokumentation: ENTWEDER/ODER |
| K3 | codex-wrapper.sh fehlte `-` Flag fuer stdin-Pipe an Codex CLI | `codex -q --approval-mode "$APPROVAL" - < "$TMPFILE"` |

### HOCH (gefixt)

| # | Problem | Fix |
|---|---------|-----|
| H1 | Hooks nutzten Legacy exit-code-only statt modernem JSON-Output | `block()` Hilfsfunktion mit JSON-Output + Exit 2 Fallback |
| H2 | Model-IDs hartcodiert — veralten schnell | Alias `model: sonnet` fuer alle Agents |
| H3 | Keine Timeouts in settings.json Hooks | timeout: 10/10/30/15 Sekunden hinzugefuegt |
| H4 | Keine Tests fuer codex-wrapper.sh | test-codex.sh mit 6 Testfaellen hinzugefuegt |

### MITTEL (gefixt)

| # | Problem | Fix |
|---|---------|-----|
| M1 | `color` Feld fehlte bei Agents | research→blue, test-runner→green, security-auditor→red |
| M2 | `version` fehlte bei Skills | version: "1.0.0" + user-invocable: true |
| M3 | auto-format.sh nutzte npx statt direkten Prettier-Aufruf | `node_modules/.bin/prettier` direkt + Fallback |
| M4 | chmod Pattern matchte nicht `chmod 0777` | Regex zu `chmod\s+0?(777\|666)` erweitert |
| M5 | Commands hatten kein `model` Feld | `model: opus` fuer alle Multi-Model Commands |

## Verifizierte Formate

| Komponente | Format korrekt? | Verifiziert gegen |
|---|---|---|
| plugin.json | Ja | Anthropic commit-commands, feature-dev, hookify |
| hooks.json | Ja | Anthropic hookify, security-guidance |
| Agent YAML | Ja | Offizielle Doku + bestehende Agents |
| Skill YAML | Ja | Anthropic example-plugin, hookify |
| Command YAML | Ja | Anthropic commit-commands, feature-dev |
| settings.json Hooks | Ja | Bestehende settings.json |
| Hook I/O | Ja | Offizielle Doku 2026 |
| Codex CLI | Ja | npm @openai/codex v0.97.0 |
