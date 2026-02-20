---
description: "Code-Dokumentation mit Codex-Generierung und Claude-Qualitaetspruefung"
argument-hint: <zieldateien>
model: sonnet
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# Multi-Docs

Dokumentation ergaenzen fuer: $ARGUMENTS

## Schritt 1: Bestand erfassen

Lies die Zieldateien und identifiziere:

- Undokumentierte Exports (Funktionen, Klassen, Typen)
- Passendes Doc-Format (auto-detect):
  - TypeScript/JavaScript: JSDoc
  - Python: Google-style Docstrings
  - Go: godoc-Kommentare
  - Rust: `///` Doc-Kommentare
  - Shell: Funktions-Header-Kommentare
- Bestehende Dokumentations-Konventionen im Projekt

## Schritt 2: Codex-Generierung (PFLICHT)

Lasse Codex die Dokumentation generieren. Diesen Schritt IMMER ausfuehren:

```bash
bash $HOME/.claude/multi-model/codex-wrapper.sh \
  --sandbox read \
  --context-file <zieldatei> \
  --prompt "Generiere Dokumentation fuer alle undokumentierten Exports. Format: <format>. Konventionen: <konventionen>"
```

## Schritt 3: Qualitaetspruefung

Pruefe Codex' Dokumentation auf:

- Technische Genauigkeit (Parameter-Beschreibungen, Return-Typen, Nebenwirkungen)
- Vollstaendigkeit (alle Parameter dokumentiert, Edge Cases erwaehnt)
- Konsistenz mit bestehendem Stil
- Entferne unpraezise oder falsche Aussagen

## Schritt 4: Anwenden

Uebernimm die geprueften Kommentare in die Quelldateien. Aendere keinen Code — nur Dokumentation.
