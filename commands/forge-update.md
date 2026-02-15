---
description: "Aktualisiere claude-forge auf die neueste Version"
model: sonnet
allowed-tools:
  - Bash
---
# Forge Update

Aktualisiere claude-forge auf die neueste Version.

## Schritt 1: Update ausfuehren
```bash
bash "$HOME/.claude/claude-forge/update.sh"
```

## Schritt 2: Ergebnis
Zeige dem User was sich geaendert hat. Falls der Output "Bereits aktuell" enthaelt, bestaetigen. Sonst die neuen Commits zusammenfassen und empfehlen `/forge-status` auszufuehren.
