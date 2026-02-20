---
description: "Sende Backend/Algorithmen-Task an Codex CLI im read-only Modus"
argument-hint: <backend-aufgabe>
model: sonnet
allowed-tools:
  - Bash
  - Read
  - Glob
---

# Multi-Backend

Backend-Aufgabe an Codex delegieren: $ARGUMENTS

## Schritt 1: Kontext

Lies die Projekt-Konfiguration (package.json, Cargo.toml, pyproject.toml) und uebergib sie als Kontext.

## Schritt 2: Codex aufrufen (PFLICHT)

Diesen Schritt IMMER ausfuehren — die Aufgabe geht an Codex, nicht an Claude:

```bash
bash $HOME/.claude/multi-model/codex-wrapper.sh \
  --sandbox read \
  --prompt "Projekt-Kontext: <kontext>. Aufgabe: $ARGUMENTS"
```

## Schritt 3: Ergebnis praesentieren

Zeige Codex' Vorschlag und bewerte ihn nach unseren Code-Standards.
