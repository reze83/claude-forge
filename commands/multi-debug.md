---
description: "Bug-Analyse mit unabhaengiger Claude- und Codex-Perspektive fuer hoehere Trefferquote"
argument-hint: <bug-beschreibung>
model: opus
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# Multi-Debug

Bug untersuchen: $ARGUMENTS

## Schritt 1: Bug erfassen

Aus $ARGUMENTS extrahieren:

- Symptome und Fehlermeldung
- Erwartetes vs. tatsaechliches Verhalten
- Schritte zur Reproduktion (falls angegeben)
- Relevanten Code und Kontext lesen

## Schritt 2: Claude-Analyse (unabhaengig)

Erstelle deine eigene Root-Cause-Hypothese:

- Execution-Path nachverfolgen
- Verdaechtige Code-Stellen identifizieren
- Fix-Vorschlag formulieren
- WICHTIG: Ergebnis noch NICHT anwenden — erst Codex-Analyse abwarten

## Schritt 3: Codex-Analyse (PFLICHT)

Lasse Codex unabhaengig analysieren. Diesen Schritt IMMER ausfuehren:

```bash
bash $HOME/.claude/multi-model/codex-wrapper.sh \
  --sandbox read \
  --context-file <relevante-datei> \
  --prompt "Bug-Analyse: <symptome>. Kontext: <relevanter-code>. Finde die Root Cause und schlage einen Fix vor."
```

## Schritt 4: Vergleich + Entscheidung

Vergleiche beide Analysen transparent:

- **Uebereinstimmung** → Hohe Konfidenz. Fix direkt anwenden.
- **Abweichung** → Beide Analysen mit Begruendung dem User vorlegen. User entscheidet welcher Fix angewendet wird.

## Schritt 5: Fix anwenden

Implementiere den gewaehlten Fix und fuehre Tests aus. Alle muessen gruen sein.
