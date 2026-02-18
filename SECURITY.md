# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.3.x   | Yes       |
| < 0.3   | No        |

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

| Hook | Protection |
|------|-----------|
| bash-firewall.sh | Blocks destructive commands (rm -rf, eval, bash -c) with input normalization and bypass protection (25 deny patterns) |
| protect-files.sh | Blocks access to sensitive files (.env, .ssh/, .aws/, *.pem, *.key) with case-insensitive matching |
| secret-scan-pre.sh | Scans Write/Edit content for 11 secret patterns BEFORE writing (deny on match) |

### Hooks (PostToolUse)

| Hook | Protection |
|------|-----------|
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
