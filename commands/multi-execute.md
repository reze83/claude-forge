---
description: "Delegiere eine Aufgabe direkt an Codex CLI mit waehlbarem Sandbox-Modus"
argument-hint: <sandbox-modus: read|write|full> <aufgabe>
model: opus
allowed-tools:
  - Bash
  - Read
---
# Multi-Execute

Delegiere eine Aufgabe an Codex CLI.

## Schritt 1: Argumente parsen
Aus $ARGUMENTS:
- Erstes Wort = Sandbox-Modus (read, write, full). Default: write.
- Rest = Die Aufgabe fuer Codex.

## Schritt 2: Codex ausfuehren (PFLICHT)
Diesen Schritt IMMER ausfuehren — das ist der Kern dieses Commands:
```bash
bash $HOME/.claude/multi-model/codex-wrapper.sh \
  --sandbox <modus> \
  --prompt "<aufgabe>"
```

## Schritt 3: Ergebnis
Zeige Codex' Output dem User und biete an:
1. Output direkt uebernehmen
2. Output von Claude refactoren lassen
3. Verwerfen
