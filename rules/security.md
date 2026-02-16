# Sicherheitsregeln
## Geschuetzt (via Hook, Read/Write/Edit/Glob/Grep): .env*, secrets/, .ssh/, .aws/, .gnupg/, .git/, .npmrc, .netrc, *.pem, *.key
## Allowlist: .env.example, .env.sample, .env.template (nicht blockiert)
## Hook-Tampering-Schutz: .claude/hooks.json, .claude/hooks/, .claude/settings.json (Write/Edit blockiert)
## Blockiert: curl/wget (deny), rm -rf /|~ (Hook), Push main/master (Hook), bash -c / sh -c (Hook)
## Secret-Scan: PreToolUse (deny) + PostToolUse (warn). Pragma: `# pragma: allowlist secret` zum Ueberspringen.
## WebFetch erfordert Bestaetigung (ask-Tier).
