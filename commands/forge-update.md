---
description: "Aktualisiere claude-forge auf die neueste Version"
model: sonnet
allowed-tools:
  - Bash
---
# Forge Update

Aktualisiere claude-forge auf die neueste Version.

## Schritt 1: Repo-Pfad ermitteln und Update ausfuehren

Finde den tatsaechlichen Pfad von claude-forge indem du dem hooks-Symlink folgst:
```bash
FORGE_DIR="$(readlink -f "$HOME/.claude/hooks" 2>/dev/null | sed 's|/hooks$||')" && bash "$FORGE_DIR/update.sh"
```

## Schritt 2: Ergebnis
Zeige dem User was sich geaendert hat. Falls der Output "Bereits aktuell" enthaelt, bestaetigen. Sonst die neuen Commits zusammenfassen und empfehlen `/forge-status` auszufuehren.
