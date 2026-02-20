# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- hooks/bash-firewall.sh: interpreter injection patterns now match versioned variants (`python3.12 -c`, `python2.7 -c`, `nodejs -e`, `perl5.36 -e`, `ruby3.2 -e`)
- hooks/protect-files.sh: tiered block model — critical patterns (`.env`, `.ssh/`, `.aws/`, `.gnupg/`, `*.pem`, `*.key`, hook config) use `block()` directly, never bypassable via `CLAUDE_FORGE_DRY_RUN`; non-critical patterns (`secrets/`, `.git/`, `.npmrc`, `.netrc`) remain at `block_or_warn()`
- rules/security.md: document tiered DRY_RUN behavior (critical vs non-critical patterns)
- tests: +8 tests (3 interpreter variants, 5 tiered block DRY_RUN) — 267 total

## [0.5.3] - 2026-02-20

### Changed

- rules/smithery.md: clarify only Sequential Thinking is permanently connected — all other MCP servers are temporary per task
- settings.json.example: remove unsupported `matcher` from `UserPromptSubmit` hook
- hooks/hooks.json: remove unsupported `matcher` from `UserPromptSubmit` hook

### Fixed

- settings.json.example: remove dead `autoUpdatesChannel` (overridden by `autoUpdates: false`)
- settings.json.example: add `Bash(npm install *)` and `Bash(pip install *)` to `ask` permissions (supply-chain protection)
- settings.json.example: add `server.smithery.ai` to sandbox `allowedDomains`
- install.sh: `sync_settings_json()` uses array union for `permissions.ask`, `permissions.deny` and `sandbox.network.allowedDomains` — template baseline entries now reach existing users on update instead of being silently dropped
- install.sh: deploy `VERSION` file to `~/.claude/` via `create_link` — fixes `forgeVersion` always showing `"unknown"` in hooks
- uninstall.sh: clean up `~/.claude/VERSION` on uninstall (with dry-run support)
- validate.sh: add deployed VERSION check (`~/.claude/VERSION` exists)
- tests: +2 install tests (VERSION deployed, VERSION removed), +12 hook tests, +5 array merge tests — 259 total

## [0.5.2] - 2026-02-20

### Added

- hooks/bash-firewall.sh: 4 interpreter injection deny patterns (python -c, node -e, perl -e, ruby -e)
- hooks/protect-files.sh: matcher extended to `Read|Write|Edit|Glob|Grep` — closes gap where Glob/Grep could scan sensitive paths
- hooks/lib.sh: new shared functions `notify()`, `log_event()` — reduces duplication across 5 hooks
- validate.sh: agents/ and skills/ hardlink validation, hook↔hooks.json cross-reference check
- update.sh: ERR trap restores git stash on install failure, explicit stash conflict error message
- tests: +20 tests (interpreter injection, Glob/Grep protection, teammate-gate dirty-tree, pre-write-backup .bak creation, url-allowlist IPv6) — 240 total
- skills: `allowed-tools` for code-review (Read/Glob/Grep), explain-code (Read/Glob/Grep), deploy (Read/Glob/Grep/Bash)
- skills/performance-reference/: new passive skill — extracted DB/Frontend/Backend optimization tips from performance rule (loaded on demand, not on every session)
- CI: shfmt now mandatory with `tests/*.sh` included; Go setup for shfmt install

### Changed

- hooks/bash-firewall.sh: grep alternation optimization — 2 grep calls for allowed commands instead of 60 (per-pattern loop replaced with combined `pat1|pat2|...` quick-check)
- hooks: stop.sh, session-logger.sh, session-start.sh, subagent-start.sh, subagent-stop.sh refactored to use shared `notify()` and `log_event()` from lib.sh
- rules/smithery.md: replace passive triggers with sequential thinking as decision engine — 5-step evaluation flow with 30-category decision matrix that proactively provisions MCP servers before falling back to built-in tools
- rules: all 9 rules optimized for global use (-43 net lines) — security, git-workflow, token-optimization, code-standards, docs, multi-model, performance, api-design, smithery
- user-config/CLAUDE.md.example: remove vague principles (SOLID, DRY, YAGNI), add environment context, NEVER/ALWAYS hard rules, expanded post-compact reminders, and categorized imports

### Fixed

- install.sh: `link_dir_recursive` now detects and replaces legacy directory symlinks before `mkdir -p`, fixing migration of e.g. `multi-model/prompts` from symlink to real dir with file-level hardlinks (#70)

## [0.5.1] - 2026-02-20

### Changed

- rules: add top-level `**Aktivierung:**` conditions to 6 context-dependent rules (git-workflow, code-standards, docs, performance, multi-model, smithery), following the pattern established by api-design.md
- rules/smithery.md: expand trigger categories from 3 to 7 (add web/research, data sources/APIs, communication/PM, cloud/monitoring)
- install.sh: skills now use recursive file symlinks instead of directory symlinks (`link_dir_recursive()`), enabling per-file overrides; old directory symlinks are auto-removed during install
- uninstall.sh: skills cleanup now removes file symlinks recursively and cleans up empty directories
- commands/forge-doctor.md, commands/forge-status.md: skill checks updated for recursive file symlinks
- install.sh: multi-model now uses `link_dir_recursive()` instead of `link_dir_contents()`, ensuring prompts/ files get individual hardlinks instead of a directory symlink
- uninstall.sh: multi-model cleanup now uses recursive removal like skills (handles subdirectories)
- validate.sh: add `check_dir_with_links_recursive()` for multi-model validation with subdirectories
- commands/forge-doctor.md: link-check now handles skills and multi-model with recursive `find` instead of flat glob
- install.sh: switch from symlinks to hardlinks (`create_link()`), with symlink fallback for cross-filesystem; writes `.forge-repo` marker file for repo discovery
- uninstall.sh: detect hardlinks via inode comparison (`remove_if_linked_to_repo()`), backwards-compatible with old symlinks
- validate.sh: detect hardlinks via inode comparison (`check_dir_with_links()`), backwards-compatible with old symlinks
- hooks/setup.sh: link health check now detects hardlinks (dir exists + not empty)
- commands/forge-status.md, forge-doctor.md, forge-update.md: repo discovery via `.forge-repo` marker with readlink fallback
- Test counts: 24 install tests (+8), 229 total (+8)
- rules/smithery.md: add explicit trigger conditions for auto-discovery (specialized languages, frameworks, decision rule)
- rules/multi-model.md: add proactive Codex delegation with condition-action pairs
- rules/performance.md: split into active checks (applied on every edit) vs passive reference (on request only)
- rules/docs.md: replace vague "nicht-trivial" with 4 concrete trigger conditions and 3 exclusions
- rules/docs.md: replace forge-specific section with generic "Projektspezifische Mappings" (globally applicable)
- rules/token-optimization.md: replace hardcoded model IDs with generic names, add exploration threshold
- rules/api-design.md: add activation condition for HTTP endpoints, default camelCase for JSON
- rules/git-workflow.md: add explicit branch-creation instruction when on main
- rules/code-standards.md: add "Gekoppelte Scripts" section — lifecycle scripts must be checked together
- CLAUDE.md: gitignored (local dev-only file, users get their own via install.sh template)

## [0.5.0] - 2026-02-19

### Added

- hooks/url-allowlist.sh: new PreToolUse hook — blocks WebFetch to private/internal URLs (localhost, RFC1918, link-local, metadata endpoint, .local/.internal/.corp/.intranet domains); supports `URL_ALLOWLIST` env var for exceptions
- hooks/pre-write-backup.sh: new PreToolUse hook (opt-in) — creates .bak backup before Write/Edit operations; enabled via `CLAUDE_FORGE_BACKUP=1`, skips /tmp/ and node_modules/
- hooks/lib.sh: hook metrics EXIT trap — logs execution time per hook to `hooks-debug.log` when `CLAUDE_FORGE_DEBUG=1`
- hooks/protect-files.sh: dry-run support via `block_or_warn()` — respects `CLAUDE_FORGE_DRY_RUN=1`
- hooks/secret-scan-pre.sh: dry-run support via `block_or_warn()` — respects `CLAUDE_FORGE_DRY_RUN=1`
- rules/performance.md: new rule — database query optimization, frontend bundle analysis, backend profiling, general performance patterns
- rules/api-design.md: new rule — REST conventions, versioning, error responses, pagination, rate limiting, security headers
- skills/test-gen/SKILL.md: new skill — structured test generation with Analyze → Strategy → Generate → Verify workflow
- skills/refactor/SKILL.md: new skill — structured refactoring with safety net (characterization tests), supports Extract/Inline/Rename/Simplify patterns
- commands/forge-doctor.md: new command — 6-step diagnostics: forge path, symlink check, dependency check, JSON validation, timeout consistency, auto-repair
- commands/changelog.md: new command — generates CHANGELOG entries from git log using Conventional Commits, Keep a Changelog format
- agents/dependency-auditor.md: new agent — dependency audit (npm/pip/cargo audit, outdated packages, licenses, unused deps, version pinning)
- agents/perf-profiler.md: new agent — performance profiling (static analysis, bundle analysis, profiler integration, database query analysis)
- tests/test-hooks.sh: 28 new tests — url-allowlist (18), pre-write-backup (5), dry-run for protect-files (1) and secret-scan-pre (1), hook metrics (1), updated protect-files test (2)

### Changed

- Component counts: 18 hooks (+2), 9 rules (+2), 6 skills (+2), 9 commands (+2), 5 agents (+2)
- Test counts: 187 hook tests (+28), 221 total (+28)
- rules/security.md: added URL-Allowlist and Pre-Write Backup sections, updated Dry-Run section
- user-config/CLAUDE.md.example: added @import for performance.md and api-design.md

## [0.4.0] - 2026-02-19

### Added

- hooks/smithery-context.sh: new UserPromptSubmit hook — injects connected Smithery MCP servers as `additionalContext` on every prompt (graceful no-op if smithery not installed)
- rules/smithery.md: new rule — describes how to discover and use Smithery MCP tools from context
- hooks/hooks.json + settings.json.example: UserPromptSubmit event registered (timeout: 10s)
- tests/test-hooks.sh: 3 new tests for smithery-context (159→162)
- hooks/lib.sh: `block_or_warn()` — dry-run aware block; respects `CLAUDE_FORGE_DRY_RUN=1` for user-defined patterns only
- hooks/lib.sh: local-patterns loader — sources `~/.claude/local-patterns.sh` with permission check (skipped if group/world-writable)
- hooks/bash-firewall.sh: apply local patterns via `block_or_warn()` with array-length guard and safe grep
- user-config/local-patterns.sh.example: ERE template for user-defined deny patterns with annotated examples
- install.sh: deploy `local-patterns.sh.example` to `~/.claude/local-patterns.sh` on first install
- tests/test-hooks.sh: 15 new tests (144→159) — force-with-lease, editors, mkfs/dd, dry-run, local-patterns, security regression

### Fixed

- hooks/bash-firewall.sh: block `--force-with-lease` on all branches (was not covered)
- hooks/bash-firewall.sh: block `--force/-f` on all branches (was only main/master)
- hooks/bash-firewall.sh: add `vim`, `emacs` to blocked editor commands (alongside `nano`/`vi`)
- hooks/bash-firewall.sh: add `mkfs` and `dd of=/dev/` as destructive command patterns
- hooks/bash-firewall.sh: update all 26 `DENY_REASONS` with concrete alternative suggestions

---

- hooks/subagent-start.sh: new SubagentStart hook — logs subagent spawn (agent_type, agent_id, session_id)
- hooks/subagent-stop.sh: new SubagentStop hook — logs subagent completion (agent_type, agent_id, stop_hook_active)
- hooks/stop.sh: new Stop hook — logs Claude turn completion + desktop notification; skips when stop_hook_active=true to prevent recursion
- hooks/hooks.json + settings.json.example: SubagentStart, SubagentStop, Stop events registered (timeout: 10s each)
- tests/test-hooks.sh: 6 new tests for subagent-start (2), subagent-stop (2), stop (2) — 138 → 144 total
- settings.json.example: `autoUpdatesChannel: latest`
- settings.json.example: `sandbox.autoAllowBashIfSandboxed: true` — ensures Bash allow-list entries are respected inside sandbox
- settings.json.example: `CLAUDE_CODE_DISABLE_AUTO_MEMORY=0` — opt users into auto memory regardless of gradual rollout

### Changed

- settings.json.example: removed non-official hook event `Setup` (not in official hooks reference; only in hooks.json for plugin mode)
- settings.json.example: restored `TaskCompleted` and `TeammateIdle` hooks (both are officially documented events; previously removed in error)
- settings.json.example: removed hardcoded `CLAUDE_CODE_TMPDIR` env var (sandbox sets `$TMPDIR` automatically with correct UID subpath)
- settings.json.example: removed redundant Bash allows for dedicated-tool operations (`cat`, `head`, `tail`, `find`, `sed`, `awk`) — Claude uses Read/Grep/Glob/Edit instead
- docs/ARCHITECTURE.md: corrected hook table — `TaskCompleted`/`TeammateIdle` are official (Symlink + Plugin), only `Setup` is plugin-only
- CLAUDE.md: corrected official hook events list, added all 14 documented events

- install.sh: sudo credential caching at install start (`sudo -v`) — prompts for password once, skipped in dry-run and when passwordless
- install.sh: QA-Tools auto-installation (shellcheck, gitleaks, bats-core, markdownlint-cli2, actionlint) as optional dev tools
- install.sh: `_install_github_binary()` helper — downloads latest release binaries from GitHub (used for gitleaks, actionlint)
- install.sh: `auto_install_optional()` extended with fallbacks for markdownlint-cli2 (npm), gitleaks/actionlint (GitHub binary), bats-core (apt name mapping → git clone)
- install.sh: `_install_bats_core()` helper — clones bats-core from GitHub and installs to ~/.local (no sudo required)
- validate.sh: warning-level checks for shellcheck, bats-core, markdownlint-cli2, gitleaks, actionlint
- test.yml: CI steps for markdownlint, shfmt formatting check, gitleaks secret scan, actionlint workflow linting
- test-install.sh: QA-Tools section test (16 total, was 15)
- .markdownlint.yml: markdownlint configuration (MD013/MD033/MD041 disabled)
- setup.sh: new Setup hook — checks dependencies (git, jq, node >=20, python3 >=3.10), validates symlink health (hooks/, rules/, commands/), injects additionalContext
- hooks/lib.sh: `context()` helper function — builds additionalContext JSON from key-value pairs using jq
- hooks.json + settings.json.example: Setup event registered (timeout: 30s)
- test-hooks.sh: 6 new tests for setup.sh (138 total)
- 5 new hook scripts: session-start.sh (SessionStart), post-failure.sh (PostToolUseFailure), pre-compact.sh (PreCompact), task-gate.sh (TaskCompleted), teammate-gate.sh (TeammateIdle)
- SECURITY.md: security policy with vulnerability reporting and architecture overview
- GitHub issue/PR templates (bug report, feature request, pull request)
- GitHub repository topics (claude-code, hooks, security, cli, multi-model, codex, bash, developer-tools)
- output-styles/ directory for future custom output styles
- plugin.json: outputStyles field
- plugin.json: repository, license, keywords, author object
- hooks.json + settings.json.example: SessionStart, PostToolUseFailure, PreCompact, TaskCompleted, TeammateIdle events registered
- install.sh: auto-sync hooks block from settings.json.example into existing ~/.claude/settings.json on update (preserves user settings)
- statusMessage field on all hook definitions
- async: true on auto-format hook (PostToolUse)
- ARCHITECTURE.md: Hook Handler Types documentation (command/prompt/agent), universal JSON output fields, event-specific output
- bash-firewall.sh: 5 new deny patterns — command substitution, backtick substitution, process substitution, pipe-to-shell (incl. absolute paths), herestring protection (25 total)
- codex-wrapper.sh: integer validation for --timeout (non-numeric values now return structured JSON error)
- test.yml: ShellCheck static analysis step in CI pipeline
- test-hooks.sh: 17 new tests — subshell/pipe/backtick/herestring bypass (14), log rotation (1), non-ASCII paths (2)
- test-hooks.sh: 9 new tests for 5 new hooks — session-start (2), post-failure (2), pre-compact (2), task-gate (2), teammate-gate (2) (113 total)
- test-codex.sh: 2 new tests — non-numeric timeout validation (11 total)
- install.sh: `_install_python_tool()` and `_install_node_tool()` helper functions extracted from `auto_install_optional()`
- test-hooks.sh: 19 negative/error tests — corrupt JSON (6), empty stdin (6), missing tool_input (6), oversized input (1) (132 total)
- test-install.sh: 4 hook-sync edge-case tests — corrupt JSON, empty settings, dry-run (15 total)
- .gitignore: IDE files (.idea, .vscode, \*.swp), coverage directories

### Fixed

- update.sh: `git stash pop` merge conflicts now auto-resolved by accepting remote version (local changes in install dir are not authoritative)
- install.sh: `_install_github_binary()` arch mapping — `uname -m` returns `x86_64` but GitHub assets use `x64` (gitleaks) or `amd64` (actionlint); now matches all variants via regex `(x86_64|x64|amd64)`
- install.sh: `_install_python_tool()` venv fallback failed when global pip config has `user=true` (PEP 668 systems); now overrides with `PIP_USER=0`
- install.sh: apt-based tool installation (bats, shellcheck) failed silently when sudo required a password; now prompts once at install start

- codex-wrapper.sh: suppress `codex exec` stdout to prevent duplicate output (output is read from `-o` file); fixes invalid JSON in wrapper response
- bash-firewall.sh, protect-files.sh, secret-scan-pre.sh, secret-scan.sh, auto-format.sh: defensive jq error handling — corrupt/empty JSON input no longer crashes hooks (exit 0 on parse failure)
- **CRITICAL:** block() exit code — changed from exit 2 to exit 0 so Claude Code processes the JSON output (exit 2 causes stdout JSON to be ignored per hooks reference)
- **CRITICAL:** warn() output field — changed from undocumented `notification` to documented `systemMessage` universal field
- session-logger.sh: event type corrected from Stop to SessionEnd
- settings.json.example: hooks now properly nested under `"hooks"` key (was at top-level)
- TaskCompleted/TeammateIdle: removed unsupported `matcher` field (these events always fire on every occurrence per official docs)
- task-gate.sh: path sanitization for CLAUDE_FORGE_DIR to prevent command injection
- CONTRIBUTING.md: exit code documentation updated (0=JSON processed, 2=JSON ignored), test counts corrected (133 total)
- ARCHITECTURE.md: Hook table updated (6→11 hooks, 3→8 event types), warn() description corrected, block() exit code documentation fixed
- README.md: hook count updated (6→11), test badge updated (114→133), directory structure updated
- plugin.json: version synced to 0.3.0 (was 0.2.1)
- plugin.json: removed `hooks` field (auto-loaded from hooks/hooks.json per plugin spec)
- plugin.json: removed empty `lspServers` field
- settings.json.example: replaced deprecated `includeCoAuthoredBy` with `attribution` object
- secret-scan.sh: added `--` before file path argument to prevent flag interpretation
- test-hooks.sh: all block tests updated from expected exit 2 to exit 0 (matching block() fix)
- test-hooks.sh: added EXIT trap for temp directory cleanup on abnormal exit
- install.sh: moved `local` declaration out of for-loop in cleanup_on_error()
- test.yml: ShellCheck severity set to `warning` (info-level SC1091/SC2016/SC2015 are false positives)
- uninstall.sh: added shellcheck disable SC2034 for intentionally unused RED variable
- test-install.sh: added shellcheck disable SC2294 for intentional eval usage
- git-workflow.md: added CI-status check rule (verify test.yml passes after push)

## [0.3.0] - 2026-02-18

### Added

- hooks/lib.sh: shared library with JSON-safe block()/warn(), centralized secret patterns, debug logging (CLAUDE_FORGE_DEBUG=1)
- bash-firewall.sh: input normalization — strips absolute paths (/bin/rm→rm), command/exec/env prefixes
- bash-firewall.sh: new deny patterns — separated flags (rm -r -f), force-push (-f/--force), refspec (HEAD:main), exec prefix
- protect-files.sh: case-insensitive matching for all protected patterns and extensions
- secret-scan-pre.sh: content size limit (1MB) to prevent DoS
- secret-scan: 5 new patterns — GitHub OAuth/Server/Refresh tokens (gho*/ghs*/ghr*), Stripe (sk_live*), Slack (xox\*), Azure (AccountKey=)
- auto-format.sh: safe prettier resolution — walks up from file directory instead of using CWD-relative path
- auto-format.sh: formatter failure notification via PostToolUse warn()
- session-logger.sh: atomic log rotation using mkdir-based lock
- codex-wrapper.sh: secure temp files with chmod 700/600 and mkdir fallback
- test-hooks.sh: 22 new tests — bypass variants, case-insensitive, pragma scope, new patterns (87 total)

### Fixed

- **CRITICAL:** JSON injection in block() — all hooks now use jq for JSON escaping instead of printf string interpolation
- **CRITICAL:** pragma allowlist scope — now applies per-line only, not to entire file content
- uninstall.sh: prefix matching uses trailing slash to prevent matching similarly-named directories
- validate.sh: secrets scan includes test files (filtered by assert_exit/check_no_secret context)
- session-logger test uses CLAUDE_LOG_DIR for sandbox isolation (TMPDIR_TEST instead of $HOME/.claude)
- session-logger.sh creates LOG_DIR if missing (defensive mkdir before write)
- add .gitleaks.toml to allowlist test-hooks.sh (intentional fake secrets for detection testing)
- add .editorconfig for consistent shfmt formatting (2-space indent, switch_case_indent)

### Changed

- All hooks refactored to use shared hooks/lib.sh (DRY, consistent output format)
- Secret patterns increased from 6 to 11 (Anthropic, OpenAI, GitHub PAT/OAuth/Server/Refresh, AWS, JWT, PEM, Stripe, Slack, Azure)
- session-logger.sh: printf instead of echo -e for POSIX portability
- Hook test count: 65 → 87 (+22 new tests)
- Total test count: 92 → 114

## [0.2.3] - 2026-02-16

### Added

- secret-scan-pre.sh: new PreToolUse hook that scans Write/Edit content for secrets BEFORE writing (deny on match)
- secret-scan-pre.sh: `# pragma: allowlist secret` / `// pragma: allowlist secret` to suppress false positives
- protect-files.sh: allowlist for `.env.example`, `.env.sample`, `.env.template` (no longer blocked)
- protect-files.sh: hook-tampering protection — blocks Write/Edit on `.claude/hooks.json`, `.claude/hooks/`, `.claude/settings.json`
- bash-firewall.sh: `bash -c` / `sh -c` deny pattern to prevent command wrapping bypass
- codex-wrapper.sh: `timeout` existence check with actionable error message for macOS users
- test-hooks.sh: 21 new tests for all changes (92 total across all suites)

### Changed

- Hooks count: 5 → 6 (added secret-scan-pre.sh)

## [0.2.2] - 2026-02-16

### Fixed

- codex-wrapper.sh: auto-detect non-git directories and pass `--skip-git-repo-check`
- codex-wrapper.sh: capture stderr separately instead of silencing with `>/dev/null 2>&1`
- codex-wrapper.sh: use `printf` instead of `echo` for safer output encoding
- install.sh: ruff installation fails when pip3 binary is missing and sudo requires password
- install.sh: prettier installed via npm but not found in PATH (npm global bin not in PATH)

### Added

- codex-wrapper.sh: timeout validation (30-600s range, rejects out-of-bounds values)
- codex-wrapper.sh: actionable timeout error message ("Try a smaller task")
- install.sh: 3-stage ruff fallback (pip3 → python3 -m pip → venv-based install)
- install.sh: prettier PATH verification after npm install with symlink fallback to ~/.local/bin
- install.sh: post-install PATH check warns if ~/.local/bin or npm global bin are missing from PATH
- test-codex.sh: 3 new tests for timeout validation (71 total)
- multi-model/README.md: flags reference, auto-behavior docs, best practices section

### Changed

- codex-wrapper.sh: default timeout increased from 180s to 240s

## [0.2.1] - 2026-02-15

### Added

- `/forge-status` command: show version, symlink health, hooks, available updates
- `/forge-update` command: trigger updates from within Claude Code
- `secret-scan.sh` PostToolUse hook: detect leaked secrets after Write/Edit
- `update.sh` for one-command updates with version comparison
- `VERSION` file for version tracking
- Auto-install missing dependencies in install.sh (apt-get/brew)
- Auto-install optional formatters (shfmt, ruff, prettier)
- Symlink target validation in validate.sh (readlink check)
- Tests for secret-scan.sh, session-logger.sh, and update.sh (68 total)

### Fixed

- protect-files.sh: block .npmrc and .netrc (auth token protection)
- codex-wrapper.sh: consistent exit 0 for all error paths

## [0.2.0] - 2026-02-15

### Fixed

- Hook timeout inconsistency between hooks.json and settings.json.example (auto-format: 15→30s, session-logger: 10→15s)
- codex-wrapper.sh uses `$TMPDIR` instead of hardcoded `/tmp`
- protect-files.sh allows Read on package-lock.json (only blocks Write/Edit)
- Secret scan patterns expanded (Anthropic, OpenAI, AWS, JWT)
- Attribution setting uses object format per official docs
- validate.sh failure no longer triggers install rollback

### Added

- Shell script formatting via shfmt in auto-format.sh
- Hook timeout consistency validation in validate.sh
- Dry-run mode for uninstall.sh (`--dry-run`)
- Rollback on error during install.sh
- Plugin-mode conflict detection in install.sh
- Codex missing hint after install
- CONTRIBUTING.md with development guidelines
- CHANGELOG.md
- README.md troubleshooting section
- GitHub Actions CI workflow

## [0.1.0] - 2025-02-15

### Added

- Initial release
- 4 hooks: bash-firewall, protect-files, auto-format, session-logger
- 3 agents: research, test-runner, security-auditor
- 4 skills: code-review, explain-code, deploy, project-init
- 5 commands: multi-model workflow (Claude + Codex CLI)
- 4 rules: git-workflow, security, token-optimization, code-standards
- Symlink installer and uninstaller
- Plugin mode support via .claude-plugin/plugin.json
- Validation script
- Test suite
