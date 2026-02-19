# Code-Standards

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

- TDD bevorzugt: Test zuerst, dann Implementierung
- Jedes neue Feature braucht Tests
- Tests vor Commit ausfuehren

## Auto-Formatierung (Hook-gestuetzt)

- `auto-format.sh` formatiert nach jedem Edit automatisch (async)
- JS/TS: `prettier`, Python: `ruff format`, Rust: `rustfmt`, Go: `gofmt`, Shell: `shfmt`
- Fehlende Formatter werden uebersprungen — kein Fehler
