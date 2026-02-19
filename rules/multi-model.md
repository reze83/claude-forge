# Multi-Model (Claude + Codex)

## Rollenverteilung

- **Claude** (Orchestrator): Planung, Frontend, Review, Refactoring, komplexe Logik
- **Codex** (Executor): Backend-Prototypen, Algorithmen, isolierte Tasks
- Claude zerlegt grosse Aufgaben in Teilschritte — Codex fuehrt einzeln aus

## Wann Codex delegieren

Schlage dem User proaktiv Codex-Delegation vor, wenn ALLE Bedingungen zutreffen:

1. `codex` CLI ist installiert (`command -v codex`)
2. Die Aufgabe hat klar abgegrenzten Input/Output (1 Datei, 1 Funktion)
3. Die Aufgabe faellt in eine dieser Kategorien:

- Backend-Logik und Algorithmen mit klarem Input/Output
- Code-Reviews und Security-Audits (Sandbox `read`)
- Parallele Planung: zwei Perspektiven, dann vergleichen (`/multi-plan`)
- Boilerplate-Generierung und repetitive Patterns

**Formulierung:** "Diese Aufgabe eignet sich fuer Codex-Delegation (`/multi-backend`). Soll ich das delegieren?"

## Wann NICHT delegieren

- Aufgaben die Kontext ueber mehrere Dateien erfordern (Claude kennt den Codebase besser)
- UI/UX-Entscheidungen und Accessibility
- Tasks die interaktive User-Rueckfragen brauchen
- Sicherheitskritische Aenderungen ohne anschliessendes Review

## Sandbox-Wahl

- `read` — Reviews, Analyse, Planung (Standard fuer `/multi-backend`, `/multi-plan`)
- `write` — Code-Generierung im Projektordner (Standard fuer `/multi-workflow`)
- `full` — Nur wenn explizit vom User angefordert (System-Zugriff noetig)

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

## Fehlerbehandlung

- Codex-Output ist JSON: `{"status":"success|error","output":"...","model":"codex"}`
- Bei `status: error` → Fehlermeldung an User, nicht still wiederholen
- Bei Timeout (240s Default) → Aufgabe kleiner formulieren, nicht Timeout erhoehen
- Codex nicht installiert → User auf `bash multi-model/codex-setup.sh` hinweisen
