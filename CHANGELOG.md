# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-02-16

### Added
- hooks/lib.sh: shared library with JSON-safe block()/warn(), centralized secret patterns, debug logging (CLAUDE_FORGE_DEBUG=1)
- bash-firewall.sh: input normalization — strips absolute paths (/bin/rm→rm), command/exec/env prefixes
- bash-firewall.sh: new deny patterns — separated flags (rm -r -f), force-push (-f/--force), refspec (HEAD:main), exec prefix
- protect-files.sh: case-insensitive matching for all protected patterns and extensions
- secret-scan-pre.sh: content size limit (1MB) to prevent DoS
- secret-scan: 5 new patterns — GitHub OAuth/Server/Refresh tokens (gho_/ghs_/ghr_), Stripe (sk_live_), Slack (xox*), Azure (AccountKey=)
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
