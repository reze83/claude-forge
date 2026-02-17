# claude-forge

Bash-basiertes Security- & Productivity-Framework fuer Claude Code CLI.

## Git

- Solo-Projekt: Feature-Branch + PR (bash-firewall blockiert Push auf main)
- CI (test.yml) validiert nach Push: ShellCheck, markdownlint, shfmt, gitleaks, actionlint + Tests

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
- plugin.json: KEIN `hooks`-Feld setzen — wird automatisch aus hooks/hooks.json geladen
- `printf` statt `echo -e` (POSIX-Portabilitaet)

## Testen

- `bash tests/test-hooks.sh` vor jedem Commit
- Test-Pattern: `assert_exit "Beschreibung" <exit_code> "$SCRIPT" '<json>'`
- CI fuehrt zusaetzlich: markdownlint, shfmt -d, gitleaks, actionlint

## install.sh Erweiterungen

- `sudo -v` am Anfang cached Passwort einmalig (uebersprungen bei dry-run und passwordless sudo)
- Neue Tool-Fallbacks in `auto_install_optional()`: npm via `_install_node_tool()`, GitHub Releases via `_install_github_binary()`
- `_install_github_binary()` Arch-Mapping: `x86_64` → Regex `(x86_64|x64|amd64)`, `aarch64` → `(arm64|aarch64)`
- `bats-core` Sonderfall: apt-Paketname ist `bats`, brew ist `bats-core`
- Optionale Tools duerfen fehlschlagen (nur Warning, kein Abbruch)

## Doc-Sync (projektspezifisch)

- hooks/ geaendert → docs/ARCHITECTURE.md (Abschnitt Hook-Architektur)
- Neuer Hook/Skill/Command → docs/ARCHITECTURE.md (Dateipfade-Tabelle)
- Konvention geaendert → CONTRIBUTING.md
- Test-Anzahl geaendert → CONTRIBUTING.md (Abschnitt Testing), README.md (Badge), docs/ARCHITECTURE.md (Test-Tabelle)
- Neues Markdown-Muster verletzt Linter → .markdownlint.yml pruefen
