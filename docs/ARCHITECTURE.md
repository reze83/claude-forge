# claude-forge Architektur

## Warum Hybrid Plugin + Symlink?

Claude Code Plugins (`plugin.json`) koennen nur Komponenten innerhalb ihres
Namespace verwalten. User-Scope Dateien wie `~/.claude/settings.json` oder
`~/.claude/CLAUDE.md` liegen ausserhalb dieses Namespace.

Loesung: Das Repo ist beides — ein Plugin UND ein Symlink-basiertes Config-Repo.

## Dateipfade

| Repo-Datei                        | Ziel                     | Methode                        | Zweck                 |
| --------------------------------- | ------------------------ | ------------------------------ | --------------------- |
| user-config/settings.json.example | ~/.claude/settings.json  | Kopie (einmalig) + Deep-Merge  | Hauptkonfiguration    |
| user-config/CLAUDE.md.example     | ~/.claude/CLAUDE.md      | Kopie (einmalig) + Import-Sync | Globale Instruktionen |
| rules/\*.md                       | ~/.claude/rules/\*.md    | Hardlinks (Symlink-Fallback)   | Constraint-Regeln     |
| hooks/\*                          | ~/.claude/hooks/\*       | Hardlinks (Symlink-Fallback)   | Hook-Scripts          |
| commands/\*                       | ~/.claude/commands/\*    | Hardlinks (Symlink-Fallback)   | Slash-Commands        |
| agents/\*.md                      | ~/.claude/agents/\*.md   | Hardlinks (Symlink-Fallback)   | Subagenten            |
| skills/\*/                        | ~/.claude/skills/\*/     | Hardlinks rekursiv (Fallback)  | Skills                |
| multi-model/\*                    | ~/.claude/multi-model/\* | Hardlinks (Symlink-Fallback)   | Codex CLI Wrapper     |

### Kopie + Merge vs. Hardlinks

- **settings.json**: Wird einmalig aus `.example` kopiert. Bei jedem Update/Install
  werden alle Template-Bloecke via `jq` deep-merged (`sync_settings_json()`).
  Template dient als Basis, User-Werte gewinnen bei Konflikten. Der `hooks`-Block
  wird immer komplett aus dem Template uebernommen.
- **CLAUDE.md**: Wird einmalig aus `.example` kopiert. Bei Updates werden fehlende
  `@import`-Zeilen am Ende angehaengt (`sync_claude_md()`). Bestehende
  User-Inhalte werden nie geaendert.
- **Hardlinks**: Alle Verzeichnisse (hooks/, rules/, commands/, agents/,
  skills/, multi-model/) sind echte Verzeichnisse in `~/.claude/`. Die Dateien
  darin sind Hardlinks zum Repo (Fallback: Symlinks bei Cross-Filesystem).
  So kann der User eigene Dateien hinzufuegen und bekommt trotzdem Updates
  via `git pull`. Neue Repo-Dateien werden beim naechsten `install.sh` oder
  `/forge-update` automatisch verlinkt. Eine Marker-Datei `~/.claude/.forge-repo`
  speichert den Repo-Pfad (ersetzt `readlink`-basierte Discovery).

## WICHTIG: Installationsmodus

**Install-Modus** (`bash install.sh`) und **Plugin-Modus** (`claude --plugin-dir`)
duerfen NICHT gleichzeitig aktiv sein. Sonst werden Hooks doppelt geladen.

- Install-Modus: Empfohlen fuer permanente Installation (Hardlinks, Symlink-Fallback)
- Plugin-Modus: Fuer temporaeres Testen oder Projekt-Level
- install.sh erkennt laufende Plugin-Instanzen und bricht ab

## Install / Update / Uninstall Lifecycle

```
install.sh                         uninstall.sh
    │                                  │
    ├── sudo -v (Passwort cachen)      ├── Datei-Symlinks entfernen
    ├── Auto-Install Dependencies      │   └── readlink check (Ziel → Repo)
    │   ├── Pflicht: git,jq,node,      │   └── Fallback: alte Dir-Symlinks
    │   │   python3                     ├── Backup-Hinweis anzeigen
    │   ├── Optional: shfmt,ruff,      └── --dry-run Modus
    │   │   prettier (mit Fallbacks)
    │   └── QA-Tools: shellcheck,
    │       bats,markdownlint-cli2,
    │       gitleaks,actionlint
    ├── Plugin-Modus Check             update.sh
    ├── User-Config:                       │
    │   ├── Kopie (wenn nicht exist.)      ├── git fetch + Changelog
    │   ├── sync_settings_json()           ├── Lokale Aenderungen stashen
    │   │   (Deep-Merge, User gewinnt)     ├── git pull --ff-only
    │   └── sync_claude_md()               ├── install.sh (Hardlinks + Deps)
    │       (fehlende @imports)            ├── Stash wiederherstellen
    ├── Hardlinks erstellen                └── VERSION Vergleich
    │   ├── link_dir_contents()
    │   │   (echte Dirs + Hardlinks)
    │   └── link_dir_recursive()
    │       (Skills: rekursive Hardlinks)
    ├── validate.sh (abgefangen)
    ├── PATH-Check + Empfehlung
    ├── Codex-Hinweis (optional)
    └── ERR Trap → Rollback
```

### Dependency-Fallbacks (optionale Formatter)

| Tool     | Fallback-Kette                                                                                                                    |
| -------- | --------------------------------------------------------------------------------------------------------------------------------- |
| ruff     | apt/brew → pip3 install --user → python3 -m pip → venv (`PIP_USER=0`, ~/.local/venvs/claude-forge-tools/) + Symlink ~/.local/bin/ |
| prettier | apt/brew → npm install -g → Verify PATH → Symlink ~/.local/bin/                                                                   |
| shfmt    | apt/brew                                                                                                                          |

### Dependency-Fallbacks (optionale QA-Tools)

| Tool              | Fallback-Kette                                                                                                       |
| ----------------- | -------------------------------------------------------------------------------------------------------------------- |
| shellcheck        | apt/brew                                                                                                             |
| bats-core         | apt (Paketname: bats) / brew (Paketname: bats-core) → git clone + install.sh nach ~/.local via \_install_bats_core() |
| markdownlint-cli2 | apt/brew → npm install -g via \_install_node_tool()                                                                  |
| gitleaks          | apt/brew → GitHub Release via \_install_github_binary() (arch: x86_64/x64/amd64)                                     |
| actionlint        | apt/brew → GitHub Release via \_install_github_binary() (arch: x86_64/x64/amd64)                                     |

Nach der Installation prueft ein PATH-Check, ob `~/.local/bin` und das npm-global-bin
Verzeichnis im PATH liegen. Falls nicht, wird eine konkrete `export PATH=...` Empfehlung ausgegeben.

### Rollback-Mechanismus

install.sh trackt alle erstellten Datei-Symlinks in `INSTALLED_SYMLINKS[]`.
Bei einem Fehler (ERR Trap) werden alle Symlinks entfernt und Backups
wiederhergestellt. validate.sh Fehler loesen keinen Rollback aus.

## Hook-Architektur

### 18 Hooks, 13 Event-Typen

| Hook                | Event              | Matcher                       | Modus            | Zweck                                                                                                                                                        |
| ------------------- | ------------------ | ----------------------------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| bash-firewall.sh    | PreToolUse         | Bash                          | Symlink + Plugin | Gefaehrliche Befehle blocken — Input-Normalisierung (abs. Pfade, command/exec/env Prefix), 25 Deny-Patterns (inkl. Subshell/Pipe/Backtick/Herestring-Schutz) |
| protect-files.sh    | PreToolUse         | Read\|Write\|Edit\|Glob\|Grep | Symlink + Plugin | Sensible Dateien schuetzen + Hook-Tampering-Schutz (dry-run via CLAUDE_FORGE_DRY_RUN)                                                                        |
| secret-scan-pre.sh  | PreToolUse         | Write\|Edit                   | Symlink + Plugin | Secret-Erkennung in Content VOR dem Schreiben (deny, dry-run via CLAUDE_FORGE_DRY_RUN)                                                                       |
| pre-write-backup.sh | PreToolUse         | Write\|Edit                   | Symlink + Plugin | .bak-Backup vor Write/Edit (opt-in via CLAUDE_FORGE_BACKUP=1)                                                                                                |
| url-allowlist.sh    | PreToolUse         | WebFetch                      | Symlink + Plugin | Private/interne URLs blocken (localhost, RFC1918, Metadata, .local/.internal/.corp)                                                                          |
| auto-format.sh      | PostToolUse        | Edit\|Write                   | Symlink + Plugin | Auto-Formatting (Polyglot, async)                                                                                                                            |
| secret-scan.sh      | PostToolUse        | Edit\|Write                   | Symlink + Plugin | Secret-Erkennung in geschriebenen Dateien (warn)                                                                                                             |
| setup.sh            | Setup ¹            | \*                            | Plugin only      | Dependency-Check (git, jq, node >=20, python3 >=3.10), Symlink-Health, additionalContext                                                                     |
| smithery-context.sh | UserPromptSubmit   | \*                            | Symlink + Plugin | Verbundene Smithery MCP Server als additionalContext injizieren (kein Netzwerk, graceful no-op wenn nicht installiert)                                       |
| session-start.sh    | SessionStart       | \*                            | Symlink + Plugin | Session-Init: Version als additionalContext, Logging                                                                                                         |
| subagent-start.sh   | SubagentStart      | \*                            | Symlink + Plugin | Subagent-Start Logging (agent_type, agent_id)                                                                                                                |
| subagent-stop.sh    | SubagentStop       | \*                            | Symlink + Plugin | Subagent-Stop Logging (agent_type, agent_id, stop_hook_active)                                                                                               |
| stop.sh             | Stop               | _(kein matcher)_              | Symlink + Plugin | Turn-Ende Logging + Desktop-Notification; ueberspringt bei stop_hook_active=true                                                                             |
| post-failure.sh     | PostToolUseFailure | \*                            | Symlink + Plugin | Tool-Fehler Logging + additionalContext                                                                                                                      |
| pre-compact.sh      | PreCompact         | \*                            | Symlink + Plugin | Context-Compaction Logging                                                                                                                                   |
| task-gate.sh        | TaskCompleted      | _(kein matcher)_              | Symlink + Plugin | Quality Gate: Hook-Tests vor Task-Abschluss (opt-in via CLAUDE_FORGE_TASK_GATE=1)                                                                            |
| teammate-gate.sh    | TeammateIdle       | _(kein matcher)_              | Symlink + Plugin | Uncommitted-Changes Check vor Teammate-Idle (opt-in via CLAUDE_FORGE_TEAMMATE_GATE=1)                                                                        |
| session-logger.sh   | SessionEnd         | \*                            | Symlink + Plugin | Session-Ende Log + Desktop-Notification                                                                                                                      |

¹ `Setup` ist **kein offizielles Claude Code Hook-Event** laut Hooks-Referenz und bleibt nur in `hooks.json` (Plugin-Modus).

### Shared Library: hooks/lib.sh

All hooks source a shared library that provides:

| Function             | Purpose                                                                                            |
| -------------------- | -------------------------------------------------------------------------------------------------- |
| `block(reason)`      | JSON-safe deny output using `jq -Rs` escaping. Prevents JSON injection from user-controlled paths. |
| `block_or_warn(msg)` | Dry-run aware: uses `warn()` when `CLAUDE_FORGE_DRY_RUN=1`, else `block()`.                        |
| `warn(message)`      | JSON-safe systemMessage output for PostToolUse hooks.                                              |
| `context(k1,v1,…)`   | Builds additionalContext JSON from key-value pairs using `jq -cn '$ARGS.named'`.                   |
| `debug(message)`     | Optional logging to `~/.claude/hooks-debug.log` (enable with `CLAUDE_FORGE_DEBUG=1`).              |
| `SECRET_PATTERNS[]`  | 11 ERE patterns shared between secret-scan-pre.sh and secret-scan.sh (DRY).                        |
| `SECRET_LABELS[]`    | Human-readable labels for each pattern.                                                            |
| `MAX_CONTENT_SIZE`   | 1MB limit constant for content scanning.                                                           |
| Hook Metrics (trap)  | EXIT trap logs execution time per hook to `hooks-debug.log` (only when `CLAUDE_FORGE_DEBUG=1`).    |

The library is loaded via `source "$(cd "$(dirname "$0")" && pwd)/lib.sh"`, which resolves correctly for both symlink and plugin modes.

### Hook-Output: Modernes JSON-Format

PreToolUse Hooks nutzen das JSON-Output-Format auf stdout (via `block()` from lib.sh):

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "..."
  }
}
```

Exit 0 ensures stdout JSON is processed by Claude Code (exit 2 would cause JSON to be ignored).
All string values are escaped via `jq -Rs` to prevent JSON injection.

PostToolUse Hooks koennen Warnungen zurueckgeben (via `warn()` from lib.sh):

```json
{ "systemMessage": "..." }
```

### Hook-Pfade: Zwei Systeme

1. **settings.json** nutzt `$HOME/.claude/hooks/` → funktioniert via Hardlink/Symlink
2. **hooks.json** nutzt `${CLAUDE_PLUGIN_ROOT}/hooks/` → funktioniert als Plugin
   - `${CLAUDE_PLUGIN_ROOT}` wird von Claude Code automatisch gesetzt wenn das Repo als Plugin geladen wird (`claude --plugin-dir`)
   - Im Install-Modus wird hooks.json NICHT genutzt; stattdessen gelten die Hook-Definitionen in settings.json

Timeouts muessen in beiden Dateien identisch sein — `validate.sh` prueft das.

### protect-files.sh: Schutz-Stufen

| Dateimuster                                               | Read      | Write     | Edit      | Glob/Grep |
| --------------------------------------------------------- | --------- | --------- | --------- | --------- |
| .env, .ssh/, .aws/, .gnupg/, .git/                        | Blockiert | Blockiert | Blockiert | Blockiert |
| .env.example, .env.sample, .env.template                  | Erlaubt   | Erlaubt   | Erlaubt   | Erlaubt   |
| .npmrc, .netrc                                            | Blockiert | Blockiert | Blockiert | Blockiert |
| _.pem, _.key, _.p12, _.pfx                                | Blockiert | Blockiert | Blockiert | Blockiert |
| package-lock.json                                         | Erlaubt   | Blockiert | Blockiert | Erlaubt   |
| .claude/hooks.json, .claude/hooks/, .claude/settings.json | Erlaubt   | Blockiert | Blockiert | Erlaubt   |

### secret-scan-pre.sh: PreToolUse Secret-Scan

Scannt `.tool_input.content` (Write) und `.tool_input.new_string` (Edit) VOR dem Schreiben.
Bei High-Confidence Match wird die Operation blockiert (deny + exit 2).

**Content-Size-Limit:** Content ueber 1MB wird auf 1MB gekuerzt (DoS-Schutz).

**Zeilenweise Pragma-Allowlist:** `# pragma: allowlist secret` oder
`// pragma: allowlist secret` ueberspringt NUR die Zeile in der es steht.
Eine Pragma-Zeile schuetzt NICHT andere Zeilen im selben Content.

### secret-scan: Erkannte Patterns (11)

Definiert in `hooks/lib.sh`, gemeinsam genutzt von secret-scan-pre.sh und secret-scan.sh:

| Pattern                   | Beispiel                             |
| ------------------------- | ------------------------------------ |
| Anthropic API Key         | `sk-ant-...`                         |
| OpenAI API Key            | `sk-...` (48+ Zeichen)               |
| GitHub PAT                | `ghp_...` (36 Zeichen)               |
| GitHub OAuth/Server Token | `gho_...` / `ghs_...` (36+ Zeichen)  |
| GitHub Refresh Token      | `ghr_...` (36+ Zeichen)              |
| AWS Access Key            | `AKIA...` (16 Zeichen)               |
| JWT Token                 | `eyJ...eyJ...`                       |
| Private Key Block         | `-----BEGIN PRIVATE KEY-----`        |
| Stripe Live Key           | `sk_live_...` (24+ Zeichen)          |
| Slack Token               | `xoxb-...` / `xoxp-...` / `xoxa-...` |
| Azure Storage Key         | `AccountKey=...` (30+ Zeichen)       |

### auto-format.sh: Unterstuetzte Formatter

| Dateiendung                                          | Formatter | Installiert via            |
| ---------------------------------------------------- | --------- | -------------------------- |
| .js, .jsx, .ts, .tsx, .json, .css, .html, .md, .yaml | prettier  | npm                        |
| .py                                                  | ruff      | pip3 / apt / venv-fallback |
| .rs                                                  | rustfmt   | rustup                     |
| .go                                                  | gofmt     | go install                 |
| .sh                                                  | shfmt     | apt / brew                 |

## Command-Architektur

### Multi-Model Commands (5)

Delegieren Aufgaben an Codex CLI via `codex-wrapper.sh`:

- `/multi-workflow` — Claude plant, Codex implementiert, Claude reviewed
- `/multi-plan` — Parallele Plaene von Claude und Codex
- `/multi-execute` — Direkte Codex-Delegation
- `/multi-backend` — Backend/Algo Tasks an Codex (read-only)
- `/multi-frontend` — Frontend von Claude, Codex reviewt

### Forge Commands (4)

Self-Management direkt aus Claude Code:

- `/forge-status` — Version, Symlinks, Hooks, Updates
- `/forge-update` — Triggert update.sh
- `/forge-doctor` — Diagnostik + Auto-Repair (Symlinks, Deps, JSON, Timeouts)
- `/changelog` — CHANGELOG-Eintraege aus Git-History generieren (Conventional Commits)

### codex-wrapper.sh: Error Handling & Robustness

Alle Fehler-Pfade geben strukturiertes JSON zurueck mit `exit 0`,
damit Claude den Output parsen kann:

```json
{
  "status": "error",
  "output": "Codex CLI nicht installiert...",
  "model": "codex"
}
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

1. **Dateien & Symlinks** — Verzeichnisse mit Datei-Symlinks pruefung
2. **JSON-Validitaet** — settings.json.example, hooks.json, plugin.json
3. **Hook-Scripts** — Ausfuehrbar, Shebang, set -euo pipefail
4. **Agents** — YAML Frontmatter, Pflichtfelder
5. **Skills** — YAML Frontmatter, Pflichtfelder
6. **Commands** — YAML Frontmatter, Pflichtfelder
7. **System-Tools** — Pflicht (node, python3, git, jq) + Optional (codex, ruff, shfmt, shellcheck, bats-core, markdownlint-cli2, gitleaks, actionlint)
8. **Secrets-Scan** — 11 Patterns (Anthropic, OpenAI, GitHub PAT/OAuth/Server/Refresh, AWS, JWT, PEM, Stripe, Slack, Azure)
9. **Hook-Konsistenz** — Timeout-Vergleich hooks.json vs. settings.json.example

## Hook Handler Types

Claude Code supports three handler types for hooks. claude-forge currently uses `command` handlers
but documents all three for reference:

| Type      | Description                                                                  | Use Case                                       |
| --------- | ---------------------------------------------------------------------------- | ---------------------------------------------- |
| `command` | Shell command (bash script). Receives JSON on stdin, returns JSON on stdout. | All current claude-forge hooks                 |
| `prompt`  | Single-turn LLM call. The hook text is sent as a prompt to a model.          | Semantic analysis, summarization               |
| `agent`   | Multi-turn LLM agent with tool access. Has full conversation capabilities.   | Complex decision-making, multi-step validation |

### Handler Fields

| Field           | Type    | Description                                                                |
| --------------- | ------- | -------------------------------------------------------------------------- |
| `type`          | string  | `"command"`, `"prompt"`, or `"agent"`                                      |
| `command`       | string  | Shell command to execute (command type only)                               |
| `prompt`        | string  | LLM prompt text (prompt/agent types only)                                  |
| `model`         | string  | Model to use (prompt/agent types only, e.g. `"claude-haiku-4-5-20251001"`) |
| `timeout`       | number  | Max execution time in seconds                                              |
| `statusMessage` | string  | Message shown in Claude Code UI while hook runs                            |
| `async`         | boolean | Run hook asynchronously (PostToolUse only)                                 |
| `once`          | boolean | Run hook only once per session                                             |

### Universal JSON Output Fields

All hook handlers can return these fields in their JSON output:

| Field            | Type    | Description                           |
| ---------------- | ------- | ------------------------------------- |
| `continue`       | boolean | Whether to continue processing        |
| `stopReason`     | string  | Reason for stopping the session       |
| `suppressOutput` | boolean | Suppress tool output from being shown |
| `systemMessage`  | string  | Message shown to the user             |

### Event-Specific Output

PreToolUse hooks use `hookSpecificOutput.permissionDecision` (`"allow"` / `"deny"` / `"ask"`)
with `hookSpecificOutput.permissionDecisionReason`. PostToolUse hooks can use `hookSpecificOutput.decision`
and `hookSpecificOutput.reason`.

## Warum Bash statt Python fuer Hooks?

- Keine Dependencies (jq reicht fuer JSON)
- Schnellerer Startup (~5ms vs ~200ms)
- Einfacher zu debuggen
- Konsistent mit bestehenden Hooks

## Test-Architektur

| Test-Suite       | Tests | Prueft                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| ---------------- | ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| test-hooks.sh    | 187   | bash-firewall (63: basic+bypass+subshell/pipe/backtick/herestring+force-with-lease+editors+mkfs/dd+dry-run+local-patterns), protect-files (29: basic+case-insensitive+allowlist+tampering+non-ASCII+dry-run), secret-scan (16: pre+post+pragma+dry-run), auto-format (2), url-allowlist (18: public+private+deny-json+empty), pre-write-backup (5: opt-in+skip-tmp+skip-node_modules), session-logger (3: basic+log-rotation), session-start (2), setup (3: basic+additionalContext+forgeVersion), post-failure (2), pre-compact (2), task-gate (2), teammate-gate (2), subagent-start (2), subagent-stop (2), stop (2), hook-metrics (1), negative/error (22: corrupt JSON+empty stdin+missing fields+oversized) |
| test-update.sh   | 6     | --help, VERSION, Nicht-Git-Repo, --check                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| test-install.sh  | 24    | Install/Uninstall Lifecycle (Hardlinks, rekursive Skills, Repo-Marker), QA-Tools Section, Settings-Merge Edge Cases (corrupt JSON, empty settings, dry-run)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| test-codex.sh    | 11    | Codex Wrapper (error handling, timeout validation incl. non-numeric, live)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| test-validate.sh | 1     | Validierungs-Durchlauf                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |

CI (`test.yml`) fuehrt alle Tests auf ubuntu-22.04 aus (ausser test-codex.sh und test-validate.sh). ShellCheck, markdownlint, shfmt, gitleaks und actionlint laufen als zusaetzliche statische Analyse-Steps.
Total: 229 tests (187 hooks + 24 install + 6 update + 11 codex + 1 validate).
