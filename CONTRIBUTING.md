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

PreToolUse hooks that block must output JSON and exit with code 0 (so Claude Code processes the JSON):

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "..."
  }
}
```

Use `block()` from `hooks/lib.sh` — never craft JSON manually.

### Exit Codes

| Code | Meaning                                                          |
| ---- | ---------------------------------------------------------------- |
| 0    | Success — stdout JSON is processed by Claude Code                |
| 2    | Blocking error — stdout JSON is IGNORED, stderr is fed to Claude |
| 1    | Script error                                                     |

### Timeout Consistency

Hook timeouts must match between `hooks/hooks.json` (plugin mode) and `user-config/settings.json.example` (symlink mode). The validator checks this automatically.

## Testing

Run all tests before committing:

```bash
bash tests/test-hooks.sh      # Hook unit tests (222 tests)
bash tests/test-plugin.sh     # Plugin-mode tests (9 tests)
bash tests/test-update.sh     # Update script tests (6 tests)
bash tests/test-install.sh    # Install/uninstall tests (35 tests)
bash tests/test-codex.sh      # Codex wrapper tests (30 tests)
bash tests/test-validate.sh   # Validation tests (1 test)
bash tests/bench-hooks.sh     # Hook benchmark (avg/min/max ms)
bash validate.sh              # Full validation suite
```

Total: 310 tests

### Adding Tests

Add new test cases to `tests/test-hooks.sh` using the `assert_exit` helper:

```bash
assert_exit "Description" <expected_exit_code> "$SCRIPT" '<json_input>'
```

## Agent Requirements

Agent files in `agents/*.md` must include YAML frontmatter with these fields:

| Field       | Required | Allowed values                                                                                                                       |
| ----------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| name        | yes      | any string                                                                                                                           |
| description | yes      | any string                                                                                                                           |
| model       | yes      | `sonnet`, `haiku`, `opus`                                                                                                            |
| maxTurns    | yes      | integer 1-50                                                                                                                         |
| tools       | yes      | Read, Write, Edit, MultiEdit, Bash, Glob, Grep, WebSearch, WebFetch, Task, NotebookEdit, TodoRead, TodoWrite, LS, or `mcp__*` prefix |

`validate.sh` checks all agent fields automatically.

## CI Changelog Check

CI warns (non-blocking) when a PR changes code files but does not update `CHANGELOG.md`.
Code paths checked: `hooks/`, `rules/`, `agents/`, `commands/`, `skills/`, `multi-model/`, `.claude-plugin/`, and lifecycle scripts (`install.sh`, `uninstall.sh`, `update.sh`, `validate.sh`).

## PR Checklist

- [ ] Tests pass (`bash tests/test-hooks.sh && bash validate.sh`)
- [ ] Shell scripts have shebang and `set -euo pipefail`
- [ ] JSON files are valid (`jq empty <file>`)
- [ ] Hook timeouts are consistent across hooks.json and settings.json.example
- [ ] No secrets or API keys in committed files
- [ ] CHANGELOG.md updated (CI warns if missing for code changes)
- [ ] Conventional Commit message used
