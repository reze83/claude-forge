# Sicherheitsregeln
## Geschuetzt (via Hook, Read/Write/Edit/Glob/Grep): .env*, secrets/, .ssh/, .aws/, .gnupg/, .git/, .npmrc, .netrc, *.pem, *.key (case-insensitive)
## Allowlist: .env.example, .env.sample, .env.template (nicht blockiert)
## Hook-Tampering-Schutz: .claude/hooks.json, .claude/hooks/, .claude/settings.json (Write/Edit blockiert)
## Blockiert: curl/wget (deny), rm -rf /|~ (Hook, inkl. /bin/rm, command rm, env rm), Push main/master (Hook, inkl. refspec, force-push), bash -c / sh -c (Hook)
## Secret-Scan: PreToolUse (deny) + PostToolUse (warn). 11 Patterns: Anthropic, OpenAI, GitHub (ghp/gho/ghs/ghr), AWS, JWT, PEM, Stripe, Slack, Azure.
## Pragma: `# pragma: allowlist secret` zum Ueberspringen (gilt nur fuer die Zeile, nicht die gesamte Datei).
## Shared Library: hooks/lib.sh — JSON-safe block()/warn(), zentrale Patterns, Debug-Logging (CLAUDE_FORGE_DEBUG=1).
## WebFetch erfordert Bestaetigung (ask-Tier).
