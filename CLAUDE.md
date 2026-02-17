# claude-forge

Bash-basiertes Security- & Productivity-Framework fuer Claude Code CLI.

## Git
- Solo-Projekt: Direkt auf main committen ist OK
- CI (test.yml) validiert nach Push

## Bash 3.2+ Kompatibilitaet (macOS)
- Keine assoziativen Arrays (`declare -A`) — parallele Arrays nutzen
- Kein `${var,,}` — `printf '%s' "$var" | tr '[:upper:]' '[:lower:]'`
- Kein `readarray`/`mapfile` — `while IFS= read -r line`
- Kein `&>>` oder `|&` — `>> file 2>&1` bzw. `2>&1 |`

## Patterns: ERE, kein PCRE
- Alle grep/regex Patterns nutzen `grep -E` (Extended Regular Expressions)
- Kein `\d` (→ `[0-9]`), kein `\w` (→ `[a-zA-Z0-9_]`), keine Lookaheads

## Hook-Entwicklung
- Output nur via `block()`/`warn()` aus `hooks/lib.sh` — nie manuell JSON bauen
- Source-Pattern: `source "$(cd "$(dirname "$0")" && pwd)/lib.sh"`
- Exit-Codes: 0=Success (JSON wird verarbeitet), 2=Block (JSON wird IGNORIERT, stderr→Claude), 1=Script-Error
- Secret-Patterns nur in `hooks/lib.sh` pflegen (DRY)
- Neuer Hook → Eintrag in hooks/hooks.json UND user-config/settings.json.example (identische Timeouts)
- `printf` statt `echo -e` (POSIX-Portabilitaet)

## Testen
- `bash tests/test-hooks.sh` vor jedem Commit
- Test-Pattern: `assert_exit "Beschreibung" <exit_code> "$SCRIPT" '<json>'`

## Doc-Sync (projektspezifisch)
- hooks/ geaendert → docs/ARCHITECTURE.md (Abschnitt Hook-Architektur)
- Neuer Hook/Skill/Command → docs/ARCHITECTURE.md (Dateipfade-Tabelle)
- Konvention geaendert → CONTRIBUTING.md
- Test-Anzahl geaendert → CONTRIBUTING.md (Abschnitt Testing)
