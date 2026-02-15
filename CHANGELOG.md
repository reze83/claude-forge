# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- install.sh: ruff installation fails when pip3 binary is missing and sudo requires password
- install.sh: prettier installed via npm but not found in PATH (npm global bin not in PATH)

### Added
- install.sh: 3-stage ruff fallback (pip3 → python3 -m pip → venv-based install)
- install.sh: prettier PATH verification after npm install with symlink fallback to ~/.local/bin
- install.sh: post-install PATH check warns if ~/.local/bin or npm global bin are missing from PATH

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
- Tests for secret-scan.sh, session-logger.sh, and update.sh (50 total)

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
