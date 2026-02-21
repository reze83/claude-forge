# Smithery MCP — Orchestrierte Tool-Erweiterung

**Aktivierung:** Bei nicht-trivialen Tasks (>=3 Schritte, unklarer Kontext,
mehrere Loesungswege). Voraussetzung: `sequentialthinking` MCP-Tool verfuegbar.

## ST-orchestrierter Flow

Sequential Thinking ist der aeussere Rahmen. Tool-Calls passieren **zwischen** Thoughts:

```
User-Prompt
  → Sequential Thinking aktivieren
    → Thought 1: Task analysieren — Ziel, Schritte, benoetigte Faehigkeiten
    → Thought 2: Kontext erkunden (Glob/Read zwischen Thoughts) — Dateitypen, Sprachen, Frameworks
    → Thought 3: Faehigkeits-Luecke erkennen — gegen Entscheidungsmatrix pruefen (siehe Skill-Referenz)
    → Thought 4: smithery mcp search (nur bei erkannter Luecke) — Server mit hohem useCount bevorzugen
    → Thought 5: Ergebnisse bewerten — User informieren, beste Server vorschlagen
    → Thought 6: Entscheidung — smithery mcp add oder eingebaute Tools reichen
  → Task mit erweiterten Tools ausfuehren
  → smithery mcp remove (temporaere Server aufraeumen)
```

Thoughts 4-6 entfallen wenn Thought 3 keine Luecke erkennt.

## Aufraeumen

- Temporaere Server nach Task entfernen: `smithery mcp remove <id>`
- Nur Sequential Thinking bleibt dauerhaft — alle anderen nach Task entfernen

## Graceful Degradation

Wenn `sequentialthinking` MCP-Tool NICHT verfuegbar:

1. Flow nativ im eigenen Denken durchfuehren (gleiche Schritte, ohne MCP-Tool)
2. Smithery-Suche bleibt moeglich via `smithery mcp search` in Bash
3. Kein Abbruch — reduzierte Strukturierung, gleiche Funktionalitaet

## Passive Referenz

Entscheidungsmatrix (30 Kategorien), CLI-Befehle und Fehlerbehandlung: siehe `~/.claude/skills/smithery-reference/SKILL.md`
