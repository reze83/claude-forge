# Code-Standards

**Aktivierung:** Diese Standards gelten beim Schreiben und Editieren von Code-Dateien (JS/TS, Python, Rust, Go, Shell, Java, etc.).

## Syntax & Stil

- Moderne Syntax: ES2024+, Python 3.12+, aktuelle Rust Edition
- Funktionen max. 50 Zeilen — bei Ueberschreitung aufteilen
- Keine Magic Numbers — Konstanten definieren
- Error Handling: keine stillen Fehler, immer explizit
- Shell/Bash: `shellcheck`-konform, `printf` statt `echo -e`, `set -euo pipefail`
- Go: Standard-Fehlerbehandlung — `if err != nil { return fmt.Errorf("context: %w", err) }`

## Typisierung

- TypeScript: `strict` Mode aktiviert, Return-Typen immer explizit
- Python: Type Hints fuer alle Funktionssignaturen inkl. Return-Typ
- Generics bevorzugen statt `any`/`object`
- Keine `null`-Assertion (`!`) ohne vorherige Pruefung

## Testing

- Neues Feature: Test vor Implementierung (TDD)
- Bugfix: Reproduzierenden Test schreiben, dann fixen
- Tests vor Commit ausfuehren

## Auto-Formatierung

Hooks formatieren automatisch nach jedem Edit (prettier, ruff, rustfmt, gofmt, shfmt). Kein manuelles Formatting noetig.
