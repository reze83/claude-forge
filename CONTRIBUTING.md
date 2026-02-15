# Contributing to claude-forge

## Development Workflow

1. Create a feature branch: `git checkout -b feature/<name>` or `fix/<name>`
2. Make changes and add tests
3. Run the test suite (see below)
4. Commit with [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
5. Push to your branch and open a PR against `main`
6. Never push directly to `main`

## Coding Standards

- All shell scripts must start with `#!/usr/bin/env bash` and `set -euo pipefail`
- Use JSON output format for hooks (see existing hooks for examples)
- Validate JSON with `jq` — never hand-craft JSON strings
- Functions should be max 50 lines — split if longer
- No magic numbers — define constants
- Error handling: no silent failures, always explicit

## Hook Development

### Output Format

PreToolUse hooks that block must output JSON and exit with code 2:

```json
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"..."}}
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Allow / Success |
| 2 | Block (PreToolUse) |
| 1 | Script error |

### Timeout Consistency

Hook timeouts must match between `hooks/hooks.json` (plugin mode) and `user-config/settings.json.example` (symlink mode). The validator checks this automatically.

## Testing

Run all tests before committing:

```bash
bash tests/test-hooks.sh      # Hook unit tests (44 tests)
bash tests/test-update.sh     # Update script tests (6 tests)
bash tests/test-install.sh    # Install/uninstall tests (11 tests)
bash tests/test-codex.sh      # Codex wrapper tests (6 tests)
bash tests/test-validate.sh   # Validation tests (1 test)
bash validate.sh              # Full validation suite
```

Total: 68 tests

### Adding Tests

Add new test cases to `tests/test-hooks.sh` using the `assert_exit` helper:

```bash
assert_exit "Description" <expected_exit_code> "$SCRIPT" '<json_input>'
```

## PR Checklist

- [ ] Tests pass (`bash tests/test-hooks.sh && bash validate.sh`)
- [ ] Shell scripts have shebang and `set -euo pipefail`
- [ ] JSON files are valid (`jq empty <file>`)
- [ ] Hook timeouts are consistent across hooks.json and settings.json.example
- [ ] No secrets or API keys in committed files
- [ ] Conventional Commit message used
