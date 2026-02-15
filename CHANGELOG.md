# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Hook timeout inconsistency between hooks.json and settings.json.example (auto-format: 15→30s, session-logger: 10→15s)
- codex-wrapper.sh uses `$TMPDIR` instead of hardcoded `/tmp`
- protect-files.sh allows Read on package-lock.json (only blocks Write/Edit)
- Secret scan patterns expanded (Anthropic, OpenAI, AWS, JWT)
- Attribution setting uses object format per official docs

### Added
- Shell script formatting via shfmt in auto-format.sh
- Hook timeout consistency validation in validate.sh
- Dry-run mode for uninstall.sh (`--dry-run`)
- Rollback on error during install.sh
- Plugin-mode conflict detection in install.sh
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
