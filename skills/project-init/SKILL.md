---
name: project-init
description: "Verwende diesen Skill wenn der User ein neues Projekt erstellen, initialisieren oder scaffolden moechte. Unterstuetzt TypeScript/Node.js, Python und Rust Projekte."
version: "1.0.0"
user-invocable: true
disable-model-invocation: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - AskUserQuestion
---
# Neues Projekt erstellen

## Ablauf

1. **Projekt-Details erfragen** (falls nicht in $ARGUMENTS):
   - Projektname (kebab-case, z.B. `my-api`)
   - Sprache: TypeScript / Python / Rust
   - Typ: CLI, API, Library, Fullstack

2. **Projekt-Verzeichnis erstellen**:
   ```
   ~/develop/<projektname>/
   ```

3. **Git initialisieren**:
   ```bash
   git init
   git checkout -b develop
   ```

4. **Sprach-spezifisches Template anwenden**:
   Lese das passende Template aus `templates/` und erstelle die Dateien:
   - TypeScript: Lies templates/node-ts.md
   - Python: Lies templates/python.md
   - Rust: Lies templates/rust.md

5. **Claude Code Config erstellen**:
   - `.claude/settings.json` (Projekt-Scope)
   - `CLAUDE.md` mit Projekt-Beschreibung, Build/Test-Commands, Konventionen
   - `.mcp.json` falls MCP-Server benoetigt

6. **Initial Commit**:
   ```bash
   git add -A
   git commit -m "chore: initial project setup"
   ```

7. **Zusammenfassung**: Zeige erstellte Dateien und naechste Schritte.
