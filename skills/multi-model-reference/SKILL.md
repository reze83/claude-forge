---
name: multi-model-reference
description: "Referenzmaterial fuer Multi-Model-Workflows (Claude + Codex). Wird von der multi-model.md Rule referenziert — nur bei expliziter Anfrage laden."
version: "1.0.0"
user-invocable: false
---

# Multi-Model-Referenz (passive Empfehlungen)

Diese Empfehlungen nur bei expliziter Anfrage oder Multi-Model-Review anwenden.

## Prompt Engineering fuer Codex

### Effektive Prompts

- **Spezifisch**: "Implementiere eine Funktion `validateEmail(input: string): boolean`" statt "Validiere Emails"
- **Output-Format**: Erwartetes Format explizit angeben ("Return als TypeScript-Modul mit Exports")
- **Kontext mitgeben**: `--context-file` fuer relevante Dateien (max. 50KB)
- **Templates nutzen**: `--template` fuer wiederholbare Prompt-Strukturen

### Anti-Patterns

| Anti-Pattern                     | Problem                         | Besser                                      |
| -------------------------------- | ------------------------------- | ------------------------------------------- |
| Vage Aufgabe ("mach das besser") | Codex rät was gemeint ist       | Konkrete Transformation benennen            |
| Mehrere Dateien auf einmal       | Timeout-Risiko, Kontext-Verlust | 1 Datei pro Codex-Aufruf                    |
| Kein Output-Format               | Inkonsistente Ergebnisse        | Format vorgeben (Modul, JSON, etc.)         |
| Grosser Kontext ohne Fokus       | Irrelevante Teile verwirren     | Nur relevante Abschnitte via --context-file |
| Implizite Abhaengigkeiten        | Codex kennt Imports nicht       | Framework + Sprache explizit nennen         |

### Prompt-Template-Beispiel

```
Sprache: {{language}}
Framework: {{framework}}
Aufgabe: {{task}}

Kontext:
- Projekt nutzt {{conventions}}
- Tests mit {{test_framework}}

Erwartetes Output:
- Nur die Funktion/Klasse, kein Boilerplate
- Typen explizit (kein any/object)
- Fehlerbehandlung via try/catch
```

## Output-Bewertung

### Checkliste nach Codex-Aufruf

1. **Korrektheit**: Erfuellt der Code die Aufgabe? Edge Cases beruecksichtigt?
2. **Code-Standards**: Typen explizit, max. 50 Zeilen pro Funktion, keine Magic Numbers?
3. **Security**: OWASP Top 10, keine Injection-Vektoren, Input-Validierung?
4. **Imports**: Sind alle Abhaengigkeiten vorhanden? Keine fehlenden Imports?
5. **Tests**: Codex-generierter Code muss getestet werden (nicht blind uebernehmen)

### Haeufige Codex-Schwaechen

- **Import-Pfade**: Codex kennt die Projektstruktur nicht — Imports manuell pruefen
- **Typen**: Tendenz zu `any` oder fehlenden Return-Typen — nachschaerfen
- **Error Handling**: Oft zu optimistisch — Fehlerfaelle ergaenzen
- **Naming**: Generische Namen (`data`, `result`, `temp`) — projektspezifisch umbenennen

## Claude+Codex Split-Strategien

### Wann Codex fuehrt

| Aufgabe                     | Grund                                    |
| --------------------------- | ---------------------------------------- |
| Algorithmen mit klarem I/O  | Bounded scope, testbar                   |
| Boilerplate-Generierung     | Repetitiv, gut parallelisierbar          |
| Test-Scaffolding            | Mechanisch, klare Struktur               |
| Code-Reviews (read sandbox) | Zweite Perspektive, keine Aenderungen    |
| Dokumentation generieren    | Volumen-Aufgabe, Claude prueft Qualitaet |

### Wann Claude fuehrt

| Aufgabe                    | Grund                                |
| -------------------------- | ------------------------------------ |
| Cross-File Refactoring     | Kontext ueber mehrere Dateien noetig |
| Architektur-Entscheidungen | Abwaegen, Tradeoffs erklaeren        |
| UI/UX-Implementierung      | Design-Sensibilitaet, Accessibility  |
| Fehleranalyse (Debugging)  | Interaktive Rueckfragen, Hypothesen  |
| Integration nach Codex     | Imports, Referenzen, Gesamtbild      |

### Orchestrierungs-Pattern

```
Claude: Aufgabe zerlegen (1 Datei pro Codex-Aufruf)
  → Codex: Datei A transformieren
  → Codex: Datei B transformieren (parallel moeglich)
Claude: Ergebnisse integrieren (Imports, Referenzen)
Claude: Tests ausfuehren
Claude: Review + Refactoring
```

## Sandbox-Auswahl

### Entscheidungsbaum

```
Aendert Codex Dateien?
├── Nein → read
│   Beispiele: Reviews, Analyse, Planung, Docs-Generierung
└── Ja → Welche Dateien?
    ├── Nur im Projektordner → write
    │   Beispiele: Code-Generierung, Refactoring, Tests
    └── Ausserhalb / System-Dateien → full (nur auf User-Anfrage!)
        Beispiele: Globale Config, System-Tools
```

### Sandbox-Verhalten

| Modus | Lesen         | Schreiben     | Netzwerk | Use Case                  |
| ----- | ------------- | ------------- | -------- | ------------------------- |
| read  | Projektordner | Nein          | Nein     | Reviews, Analyse          |
| write | Projektordner | Projektordner | Nein     | Code-Generierung          |
| full  | Alles         | Alles         | Ja       | Nur auf explizite Anfrage |

## Troubleshooting

### Timeout (Exit Code 124)

- **Ursache**: Aufgabe zu gross oder Codex braucht zu lange
- **Loesung**: Aufgabe kleiner formulieren (1 Datei, 1 Funktion)
- **Nicht**: Timeout erhoehen (Default 240s ist ausreichend)
- **Retry**: Automatisch bei Timeout < 60s (seit v0.8.0)

### Auth-Fehler

- **Ursache**: ChatGPT-Session abgelaufen oder kein Plus/Pro-Abo
- **Loesung**: `codex auth` ausfuehren, Browser-Login
- **Kein Retry**: Auth-Fehler sind nicht transient

### Truncated Output

- **Ursache**: Codex-Antwort zu lang fuer Terminal-Buffer
- **Loesung**: Codex nach kompaktem Output fragen ("nur die Funktion, kein Boilerplate")
- **Alternative**: `--context-file` reduzieren um Platz fuer Output zu schaffen

### Codex nicht installiert

- **Loesung**: `bash multi-model/codex-setup.sh`
- **Voraussetzung**: Node.js >= 20, ChatGPT Plus/Pro Abo
