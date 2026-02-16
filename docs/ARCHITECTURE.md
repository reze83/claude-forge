# claude-forge Architektur

## Warum Hybrid Plugin + Symlink?

Claude Code Plugins (`plugin.json`) koennen nur Komponenten innerhalb ihres
Namespace verwalten. User-Scope Dateien wie `~/.claude/settings.json` oder
`~/.claude/CLAUDE.md` liegen ausserhalb dieses Namespace.

Loesung: Das Repo ist beides — ein Plugin UND ein Symlink-basiertes Config-Repo.

## Dateipfade

| Repo-Datei | Ziel | Methode | Zweck |
|---|---|---|---|
| user-config/settings.json.example | ~/.claude/settings.json | Kopie (einmalig) | Hauptkonfiguration |
| user-config/CLAUDE.md.example | ~/.claude/CLAUDE.md | Kopie (einmalig) | Globale Instruktionen |
| user-config/MEMORY.md | ~/.claude/MEMORY.md | Symlink | Persistenter Speicher |
| rules/ | ~/.claude/rules/ | Symlink | Constraint-Regeln |
| hooks/ | ~/.claude/hooks/ | Symlink | Hook-Scripts |
| commands/ | ~/.claude/commands/ | Symlink | Slash-Commands |
| agents/*.md | ~/.claude/agents/*.md | Symlink (einzeln) | Subagenten |
| skills/*/ | ~/.claude/skills/*/ | Symlink (einzeln) | Skills |
| multi-model/ | ~/.claude/multi-model/ | Symlink | Codex CLI Wrapper |

### Kopie vs. Symlink

- **Kopie**: `settings.json` und `CLAUDE.md` werden aus `.example`-Vorlagen kopiert.
  Existierende Dateien werden NICHT ueberschrieben. So kann jeder User seine
  eigenen Praeferenzen pflegen (Sprache, MCP-Server, Permissions etc.).
- **Symlink**: Alle anderen Komponenten werden verlinkt. Aenderungen im Repo
  wirken sich sofort aus — ein `git pull` genuegt.

## WICHTIG: Installationsmodus

**Symlink-Modus** (`bash install.sh`) und **Plugin-Modus** (`claude --plugin-dir`)
duerfen NICHT gleichzeitig aktiv sein. Sonst werden Hooks doppelt geladen.

- Symlink-Modus: Empfohlen fuer permanente Installation
- Plugin-Modus: Fuer temporaeres Testen oder Projekt-Level
- install.sh erkennt laufende Plugin-Instanzen und bricht ab

## Install / Update / Uninstall Lifecycle

```
install.sh                      uninstall.sh
    │                               │
    ├── Auto-Install Dependencies   ├── Symlinks entfernen (readlink check)
    │   ├── Pflicht: git,jq,node,   │   └── Nur wenn Ziel → Repo
    │   │   python3                  ├── Backup-Hinweis anzeigen
    │   └── Optional: shfmt,ruff,   └── --dry-run Modus
    │       prettier (mit Fallbacks)
    ├── Plugin-Modus Check          update.sh
    ├── Backup bestehender Dateien      │
    ├── Symlinks erstellen              ├── git fetch + Changelog anzeigen
    │   └── INSTALLED_SYMLINKS[]        ├── Lokale Aenderungen stashen
    ├── validate.sh (abgefangen)        ├── git pull --ff-only
    ├── PATH-Check + Empfehlung         ├── install.sh (neue Symlinks + Deps)
    ├── Codex-Hinweis (optional)        ├── Stash wiederherstellen
    └── ERR Trap → Rollback             └── VERSION Vergleich anzeigen
```

### Dependency-Fallbacks (optionale Formatter)

| Tool | Fallback-Kette |
|---|---|
| ruff | apt/brew → pip3 install --user → python3 -m pip → venv (~/.local/venvs/claude-forge-tools/) + Symlink ~/.local/bin/ |
| prettier | apt/brew → npm install -g → Verify PATH → Symlink ~/.local/bin/ |
| shfmt | apt/brew |

Nach der Installation prueft ein PATH-Check, ob `~/.local/bin` und das npm-global-bin
Verzeichnis im PATH liegen. Falls nicht, wird eine konkrete `export PATH=...` Empfehlung ausgegeben.

### Rollback-Mechanismus

install.sh trackt alle erstellten Symlinks in `INSTALLED_SYMLINKS[]`.
Bei einem Fehler (ERR Trap) werden alle Symlinks entfernt und Backups
wiederhergestellt. validate.sh Fehler loesen keinen Rollback aus.

## Hook-Architektur

### 6 Hooks, 3 Event-Typen

| Hook | Event | Matcher | Zweck |
|---|---|---|---|
| bash-firewall.sh | PreToolUse | Bash | Gefaehrliche Befehle blocken — Input-Normalisierung (abs. Pfade, command/exec/env Prefix), 25 Deny-Patterns (inkl. Subshell/Pipe/Backtick/Herestring-Schutz) |
| protect-files.sh | PreToolUse | Read\|Write\|Edit\|Glob\|Grep | Sensible Dateien schuetzen + Hook-Tampering-Schutz |
| secret-scan-pre.sh | PreToolUse | Write\|Edit | Secret-Erkennung in Content VOR dem Schreiben (deny) |
| auto-format.sh | PostToolUse | Edit\|Write | Auto-Formatting (Polyglot) |
| secret-scan.sh | PostToolUse | Edit\|Write | Secret-Erkennung in geschriebenen Dateien (warn) |
| session-logger.sh | Stop | * | Session-Ende Log + Desktop-Notification |

### Shared Library: hooks/lib.sh

All hooks source a shared library that provides:

| Function | Purpose |
|---|---|
| `block(reason)` | JSON-safe deny output using `jq -Rs` escaping. Prevents JSON injection from user-controlled paths. |
| `warn(message)` | JSON-safe notification output for PostToolUse hooks. |
| `debug(message)` | Optional logging to `~/.claude/hooks-debug.log` (enable with `CLAUDE_FORGE_DEBUG=1`). |
| `SECRET_PATTERNS[]` | 11 ERE patterns shared between secret-scan-pre.sh and secret-scan.sh (DRY). |
| `SECRET_LABELS[]` | Human-readable labels for each pattern. |
| `MAX_CONTENT_SIZE` | 1MB limit constant for content scanning. |

The library is loaded via `source "$(cd "$(dirname "$0")" && pwd)/lib.sh"`, which resolves correctly for both symlink and plugin modes.

### Hook-Output: Modernes JSON-Format

PreToolUse Hooks nutzen das JSON-Output-Format auf stdout (via `block()` from lib.sh):
```json
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"..."}}
```
Plus `exit 2` als Fallback fuer aeltere Claude Code Versionen.
All string values are escaped via `jq -Rs` to prevent JSON injection.

PostToolUse Hooks koennen Warnungen zurueckgeben (via `warn()` from lib.sh):
```json
{"hookSpecificOutput":{"hookEventName":"PostToolUse","notification":"..."}}
```

### Hook-Pfade: Zwei Systeme

1. **settings.json** nutzt `$HOME/.claude/hooks/` → funktioniert via Symlink
2. **hooks.json** nutzt `${CLAUDE_PLUGIN_ROOT}/hooks/` → funktioniert als Plugin
   - `${CLAUDE_PLUGIN_ROOT}` wird von Claude Code automatisch gesetzt wenn das Repo als Plugin geladen wird (`claude --plugin-dir`)
   - Im Symlink-Modus wird hooks.json NICHT genutzt; stattdessen gelten die Hook-Definitionen in settings.json

Timeouts muessen in beiden Dateien identisch sein — `validate.sh` prueft das.

### protect-files.sh: Schutz-Stufen

| Dateimuster | Read | Write | Edit | Glob/Grep |
|---|---|---|---|---|
| .env, .ssh/, .aws/, .gnupg/, .git/ | Blockiert | Blockiert | Blockiert | Blockiert |
| .env.example, .env.sample, .env.template | Erlaubt | Erlaubt | Erlaubt | Erlaubt |
| .npmrc, .netrc | Blockiert | Blockiert | Blockiert | Blockiert |
| *.pem, *.key, *.p12, *.pfx | Blockiert | Blockiert | Blockiert | Blockiert |
| package-lock.json | Erlaubt | Blockiert | Blockiert | Erlaubt |
| .claude/hooks.json, .claude/hooks/, .claude/settings.json | Erlaubt | Blockiert | Blockiert | Erlaubt |

### secret-scan-pre.sh: PreToolUse Secret-Scan

Scannt `.tool_input.content` (Write) und `.tool_input.new_string` (Edit) VOR dem Schreiben.
Bei High-Confidence Match wird die Operation blockiert (deny + exit 2).

**Content-Size-Limit:** Content ueber 1MB wird auf 1MB gekuerzt (DoS-Schutz).

**Zeilenweise Pragma-Allowlist:** `# pragma: allowlist secret` oder
`// pragma: allowlist secret` ueberspringt NUR die Zeile in der es steht.
Eine Pragma-Zeile schuetzt NICHT andere Zeilen im selben Content.

### secret-scan: Erkannte Patterns (11)

Definiert in `hooks/lib.sh`, gemeinsam genutzt von secret-scan-pre.sh und secret-scan.sh:

| Pattern | Beispiel |
|---|---|
| Anthropic API Key | `sk-ant-...` |
| OpenAI API Key | `sk-...` (48+ Zeichen) |
| GitHub PAT | `ghp_...` (36 Zeichen) |
| GitHub OAuth/Server Token | `gho_...` / `ghs_...` (36+ Zeichen) |
| GitHub Refresh Token | `ghr_...` (36+ Zeichen) |
| AWS Access Key | `AKIA...` (16 Zeichen) |
| JWT Token | `eyJ...eyJ...` |
| Private Key Block | `-----BEGIN PRIVATE KEY-----` |
| Stripe Live Key | `sk_live_...` (24+ Zeichen) |
| Slack Token | `xoxb-...` / `xoxp-...` / `xoxa-...` |
| Azure Storage Key | `AccountKey=...` (30+ Zeichen) |

### auto-format.sh: Unterstuetzte Formatter

| Dateiendung | Formatter | Installiert via |
|---|---|---|
| .js, .jsx, .ts, .tsx, .json, .css, .html, .md, .yaml | prettier | npm |
| .py | ruff | pip3 / apt / venv-fallback |
| .rs | rustfmt | rustup |
| .go | gofmt | go install |
| .sh | shfmt | apt / brew |

## Command-Architektur

### Multi-Model Commands (5)

Delegieren Aufgaben an Codex CLI via `codex-wrapper.sh`:
- `/multi-workflow` — Claude plant, Codex implementiert, Claude reviewed
- `/multi-plan` — Parallele Plaene von Claude und Codex
- `/multi-execute` — Direkte Codex-Delegation
- `/multi-backend` — Backend/Algo Tasks an Codex (read-only)
- `/multi-frontend` — Frontend von Claude, Codex reviewt

### Forge Commands (2)

Self-Management direkt aus Claude Code:
- `/forge-status` — Version, Symlinks, Hooks, Updates
- `/forge-update` — Triggert update.sh

### codex-wrapper.sh: Error Handling & Robustness

Alle Fehler-Pfade geben strukturiertes JSON zurueck mit `exit 0`,
damit Claude den Output parsen kann:
```json
{"status":"error","output":"Codex CLI nicht installiert...","model":"codex"}
```

#### Non-Git Directory Support
The wrapper auto-detects if `--workdir` is inside a git repository.
If not, `--skip-git-repo-check` is passed to `codex exec` automatically.
This allows Codex to work on standalone script directories without `git init`.

#### Stderr Capture
Stderr is captured to a separate temp file instead of being silenced.
On error, both stdout output and stderr are combined in the JSON response,
making debugging significantly easier.

#### Input Validation
- Sandbox mode is validated against allowed values (`read|write|full`)
- Timeout is validated as positive integer, then checked to be within 30-600 seconds (default: 240s)
- Non-numeric `--timeout` values return structured error JSON instead of uncontrolled abort
- Missing `--prompt` and unknown arguments return structured error JSON

## Validierung

validate.sh prueft in 9 Sektionen:

1. **Dateien & Symlinks** — Existenz + readlink Ziel-Pruefung
2. **JSON-Validitaet** — settings.json.example, hooks.json, plugin.json
3. **Hook-Scripts** — Ausfuehrbar, Shebang, set -euo pipefail
4. **Agents** — YAML Frontmatter, Pflichtfelder
5. **Skills** — YAML Frontmatter, Pflichtfelder
6. **Commands** — YAML Frontmatter, Pflichtfelder
7. **System-Tools** — Pflicht (node, python3, git, jq) + Optional (codex, ruff, shfmt)
8. **Secrets-Scan** — 11 Patterns (Anthropic, OpenAI, GitHub PAT/OAuth/Server/Refresh, AWS, JWT, PEM, Stripe, Slack, Azure)
9. **Hook-Konsistenz** — Timeout-Vergleich hooks.json vs. settings.json.example

## Warum Bash statt Python fuer Hooks?

- Keine Dependencies (jq reicht fuer JSON)
- Schnellerer Startup (~5ms vs ~200ms)
- Einfacher zu debuggen
- Konsistent mit bestehenden Hooks

## Test-Architektur

| Test-Suite | Tests | Prueft |
|---|---|---|
| test-hooks.sh | 104 | bash-firewall (48: basic+bypass+subshell/pipe/backtick/herestring), protect-files (29: basic+case-insensitive+allowlist+tampering+non-ASCII), secret-scan (16: pre+post+pragma), auto-format (2), session-logger (3: basic+log-rotation) |
| test-update.sh | 6 | --help, VERSION, Nicht-Git-Repo, --check |
| test-install.sh | 11 | Install/Uninstall Lifecycle |
| test-codex.sh | 11 | Codex Wrapper (error handling, timeout validation incl. non-numeric, live) |
| test-validate.sh | 1 | Validierungs-Durchlauf |

CI (`test.yml`) fuehrt alle Tests auf ubuntu-22.04 aus (ausser test-codex.sh und test-validate.sh). ShellCheck laeuft als zusaetzlicher statischer Analyse-Step.
Total: 133 tests (104 hooks + 11 install + 6 update + 11 codex + 1 validate).
