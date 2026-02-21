# Multi-Model (Claude + Codex)

**Aktivierung:** Bei JEDER Codeaenderung wenn `codex` CLI installiert ist (`command -v codex`). Codex ist der Standard — nicht die Ausnahme.

## Auto-Delegation

Bei jeder Code-Aufgabe automatisch den passenden Command waehlen und ausfuehren:

1. Ist es eine Codeaenderung? → Nein: kein Codex noetig
2. Ist `codex` installiert? → Nein: ohne Codex weiterarbeiten
3. Trigger-Matrix pruefen → passenden Auto-Command ausfuehren

### Trigger-Matrix

| User-Intent           | Erkennungssignal                                         | Auto-Command      |
| --------------------- | -------------------------------------------------------- | ----------------- |
| Neues Feature         | "implement", "add feature", neue Datei/Modul erstellen   | `/multi-workflow` |
| Tests generieren      | "write tests for", "test coverage", Test-Datei erstellen | `/multi-test`     |
| Code dokumentieren    | "add docstrings", "document", JSDoc/typedoc Erwaehnung   | `/multi-docs`     |
| Code refactoren       | "refactor", "extract", "rename across", "move to"        | `/multi-refactor` |
| Bug debuggen          | Fehlermeldung + "why", "doesn't work", Stacktrace        | `/multi-debug`    |
| Backend/Algorithmus   | Datenstrukturen, Algorithmen, Business-Logik             | `/multi-backend`  |
| Repetitive Edits      | >3 aehnliche Edits in Folge erkannt                      | `/multi-execute`  |
| Grosses File reviewen | Datei >200 Zeilen wird reviewed                          | `/multi-backend`  |
| Migration             | "migrate", "upgrade", "convert from X to Y"              | `/multi-execute`  |
| Security-Analyse      | "audit", "security review", Vulnerability-Check          | `/multi-backend`  |
| Architektur-Vergleich | "how should we structure", Design-Entscheidung           | `/multi-plan`     |
| **Kein Match**        | Codeaenderung ohne spezifischen Trigger                  | `/multi-execute`  |

## Auto-Review

Automatisch nach groesseren Aenderungen ausfuehren — kein User-Prompt noetig:

- **Trigger:** >50 Zeilen geschrieben ODER >3 Dateien bearbeitet
- **Aktion:** `codex-wrapper.sh --sandbox read --context-file <geaenderte-dateien> --prompt "Review auf Korrektheit, Security, Performance, Best Practices"`
- **Ergebnis:** Findings zusammenfassen, kritische Issues sofort fixen

## Wann NICHT delegieren

- Triviale Aenderungen (einzelne Zeilen, Tippfehler)
- Reine Exploration ohne Code-Output (Dateien lesen, Fragen beantworten)
- Dateien mit sensiblem Inhalt (.env, Credentials)
- Tasks die interaktive User-Rueckfragen brauchen

## Sandbox-Wahl

- `read` — Reviews, Analyse, Planung
- `write` — Code-Generierung im Projektordner
- `full` — Nur wenn explizit vom User angefordert

## Commands

| Command           | Zweck                                | Sandbox  |
| ----------------- | ------------------------------------ | -------- |
| `/multi-workflow` | Voller 6-Phasen-Workflow             | write    |
| `/multi-plan`     | Parallele Plaene vergleichen         | read     |
| `/multi-execute`  | Direkte Delegation (Modus waehlbar)  | variabel |
| `/multi-backend`  | Backend/Algo-Task                    | read     |
| `/multi-frontend` | Claude implementiert, Codex reviewed | read     |
| `/multi-test`     | Dual-Model Test-Generierung          | read     |
| `/multi-refactor` | Claude plant, Codex transformiert    | write    |
| `/multi-docs`     | Codex dokumentiert, Claude prueft    | read     |
| `/multi-debug`    | Unabhaengige Dual-Analyse            | read     |

## Passive Referenz

Detail-Empfehlungen fuer Prompt-Qualitaet, Output-Bewertung und Split-Strategien:
siehe `~/.claude/skills/multi-model-reference/SKILL.md`

## Fehlerbehandlung

- Codex-Output ist JSON: `{"status":"success|error","output":"...","model":"codex"}`
- Bei `status: error` → Fehlermeldung an User, nicht still wiederholen
- Bei Timeout (240s Default) → Aufgabe kleiner formulieren, nicht Timeout erhoehen
- Codex nicht installiert → User auf `bash multi-model/codex-setup.sh` hinweisen
