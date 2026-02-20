# Multi-Model (Claude + Codex)

**Aktivierung:** Diese Regeln gelten wenn `codex` CLI installiert ist (`command -v codex`) und die Aufgabe klar abgegrenzten Input/Output hat.

## Wann Codex delegieren

Schlage dem User proaktiv Codex-Delegation vor, wenn ALLE Bedingungen zutreffen:

1. Die Aufgabe hat klar abgegrenzten Input/Output (1 Datei, 1 Funktion)
2. Die Aufgabe faellt in eine dieser Kategorien:

- Backend-Logik und Algorithmen mit klarem Input/Output
- Code-Reviews und Security-Audits (Sandbox `read`)
- Parallele Planung: zwei Perspektiven, dann vergleichen (`/multi-plan`)
- Boilerplate-Generierung und repetitive Patterns

**Formulierung:** "Diese Aufgabe eignet sich fuer Codex-Delegation (`/multi-backend`). Soll ich das delegieren?"

## Wann NICHT delegieren

- Aufgaben die Kontext ueber mehrere Dateien erfordern
- UI/UX-Entscheidungen und Accessibility
- Tasks die interaktive User-Rueckfragen brauchen
- Sicherheitskritische Aenderungen ohne anschliessendes Review

## Sandbox-Wahl

- `read` — Reviews, Analyse, Planung
- `write` — Code-Generierung im Projektordner
- `full` — Nur wenn explizit vom User angefordert

## Prompt-Qualitaet

- Tasks klein halten: 1 Datei, 1 Aufgabe — reduziert Timeout-Risiko
- Projektkontext mitgeben: Sprache, Framework, relevante Dateien
- Erwartetes Output-Format definieren (z.B. "Return als TypeScript-Modul")
- Codex-Output immer gegen Code-Standards pruefen und refactoren

## Commands

| Command           | Zweck                                | Sandbox  |
| ----------------- | ------------------------------------ | -------- |
| `/multi-workflow` | Voller 6-Phasen-Workflow             | write    |
| `/multi-plan`     | Parallele Plaene vergleichen         | read     |
| `/multi-execute`  | Direkte Delegation (Modus waehlbar)  | variabel |
| `/multi-backend`  | Backend/Algo-Task                    | read     |
| `/multi-frontend` | Claude implementiert, Codex reviewed | read     |

## Passive Referenz

Detail-Empfehlungen fuer Prompt-Qualitaet, Output-Bewertung und Split-Strategien:
siehe `~/.claude/skills/multi-model-reference/SKILL.md`

## Fehlerbehandlung

- Codex-Output ist JSON: `{"status":"success|error","output":"...","model":"codex"}`
- Bei `status: error` → Fehlermeldung an User, nicht still wiederholen
- Bei Timeout (240s Default) → Aufgabe kleiner formulieren, nicht Timeout erhoehen
- Codex nicht installiert → User auf `bash multi-model/codex-setup.sh` hinweisen
