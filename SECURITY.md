# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 0.11.x  | Yes       |
| < 0.11  | No        |

## Reporting a Vulnerability

If you discover a security vulnerability in claude-forge, please report it responsibly:

1. **Do NOT open a public issue** for security vulnerabilities
2. Email the maintainer or use [GitHub's private vulnerability reporting](https://github.com/reze83/claude-forge/security/advisories/new)
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

You should receive a response within 48 hours.

## Security Architecture

claude-forge provides defense-in-depth for Claude Code sessions:

### Hooks (PreToolUse)

| Hook               | Protection                                                                                                            |
| ------------------ | --------------------------------------------------------------------------------------------------------------------- |
| bash-firewall.sh   | Blocks destructive commands (rm -rf, eval, bash -c) with input normalization and bypass protection (25 deny patterns) |
| protect-files.sh   | Blocks access to sensitive files (.env, .ssh/, .aws/, _.pem, _.key) with case-insensitive matching                    |
| secret-scan-pre.sh | Scans Write/Edit content for 11 secret patterns BEFORE writing (deny on match)                                        |

### Hooks (PostToolUse)

| Hook           | Protection                                             |
| -------------- | ------------------------------------------------------ |
| secret-scan.sh | Scans written files for leaked secrets (warn on match) |

### Hook-Tampering Protection

Write/Edit operations on `.claude/hooks.json`, `.claude/hooks/`, and `.claude/settings.json` are blocked by protect-files.sh.

### Secret Patterns (11)

Anthropic API Key, OpenAI API Key, GitHub PAT/OAuth/Server/Refresh tokens, AWS Access Key, JWT, Private Key, Stripe Live Key, Slack Token, Azure Storage Key.

### Design Principles

- All JSON output uses `jq -Rs` escaping to prevent injection
- `block()` uses `exit 0` + `permissionDecision:"deny"` so Claude Code processes the JSON
- Content size limits prevent DoS (1MB max for secret scanning)
- Pragma allowlist applies per-line only (not per-file)
- No silent failures — all errors are logged

## Security Audit History

### v0.11.0 — Feb 2026 (11 findings, all fixed)

| ID     | Severity | Hook             | Description                                                             | Fix                                                |
| ------ | -------- | ---------------- | ----------------------------------------------------------------------- | -------------------------------------------------- |
| CF-001 | High     | protect-files.sh | Double slash bypass: `/.claude//hooks.json` not blocked                 | `realpath -m` normalization before pattern match   |
| CF-002 | High     | protect-files.sh | Path traversal bypass: `/.claude/x/../hooks.json` not blocked           | `realpath -m` normalization                        |
| CF-003 | High     | protect-files.sh | Single dot bypass: `/.claude/./hooks.json` not blocked                  | `realpath -m` normalization                        |
| CF-004 | Medium   | url-allowlist.sh | `file:///etc/passwd` not blocked (non-HTTP scheme)                      | Scheme check before host extraction                |
| CF-005 | Medium   | url-allowlist.sh | IPv4-mapped IPv6 `::ffff:127.0.0.1` not blocked                         | Added `::ffff:*` pattern                           |
| CF-006 | Medium   | url-allowlist.sh | Unique local IPv6 `fd00::/fc00::` not blocked                           | Added `fd[0-9a-f]{2}:` / `fc[0-9a-f]{2}:` patterns |
| CF-007 | Medium   | url-allowlist.sh | FQDN trailing dot (`metadata.google.internal.`) bypassed hostname match | Strip trailing dot before matching                 |
| CF-008 | Medium   | bash-firewall.sh | `rm -fr /` not blocked (flag order `-fr` vs `-rf`)                      | POSIX `[[:alpha:]]` permutation patterns           |
| CF-009 | Medium   | bash-firewall.sh | `rm -rf -- /` not blocked (double-dash before path)                     | Optional intermediate flags group                  |
| CF-010 | Medium   | bash-firewall.sh | `rm -rf --no-preserve-root /` not blocked                               | Optional intermediate flags group                  |
| CF-011 | Low      | download-gh.js   | No checksum verification after binary download                          | SHA256 verification from GitHub `checksums.txt`    |
