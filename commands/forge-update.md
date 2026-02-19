---
description: "Aktualisiere claude-forge auf die neueste Version"
model: sonnet
allowed-tools:
  - Bash
---

# Forge Update

Aktualisiere claude-forge auf die neueste Version.

## Schritt 1: Repo-Pfad ermitteln und Update ausfuehren

Finde den tatsaechlichen Pfad von claude-forge ueber einen Datei-Symlink in hooks/:

```bash
CLAUDE_DIR=~/.claude
FORGE_DIR="$( (readlink -f "$CLAUDE_DIR/hooks/lib.sh" 2>/dev/null || readlink "$CLAUDE_DIR/hooks/lib.sh") | sed 's|/hooks/lib.sh$||')" && bash "$FORGE_DIR/update.sh"
```

## Schritt 2: Ergebnis

Zeige dem User was sich geaendert hat. Falls der Output "Bereits aktuell" enthaelt, bestaetigen. Sonst die neuen Commits zusammenfassen und empfehlen `/forge-status` auszufuehren.
