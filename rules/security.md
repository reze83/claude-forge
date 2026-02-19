# Sicherheit

## Dateischutz (Hook-enforced)

- Sensible Dateien sind durch `protect-files.sh` geblockt (Read, Write, Edit)
- Pattern: `.env`, `.ssh/`, `.aws/`, `.gnupg/`, `.git/`, `.npmrc`, `.netrc`, `*.pem`, `*.key`, `*.p12`, `*.pfx`, `*.keystore`
- Allowlist: `.env.example`, `.env.sample`, `.env.template` — duerfen gelesen und geschrieben werden

## Secret-Scan (Hook-enforced)

- Pre-Write (`secret-scan-pre.sh`): Blockt 11 Secret-Patterns BEVOR sie geschrieben werden
- Post-Write (`secret-scan.sh`): Warnt bei Secrets in geschriebenen Dateien
- Pattern: Anthropic, OpenAI, GitHub (PAT/OAuth/Server/Refresh), AWS, JWT, PEM, Stripe, Slack, Azure
- False Positive: `# pragma: allowlist secret` — gilt nur fuer die betroffene Zeile

## Bash-Firewall (Hook-enforced)

- Destruktive Befehle: `rm -rf /`, `mkfs`, `dd of=/dev/` — inkl. absolute Pfade
- Git-Schutz: `git push main/master`, `--force`, `reset --hard`, `--amend`
- Shell-Injection: `eval`, `bash -c`, `exec`, `source` mit Variablen
- Unsichere Permissions: `chmod 777`, `chmod o+w`
- Bypass-Schutz: `command`, `env`, `exec` Prefixes, getrennte Flags

## Hook-Integritaet (Hook-enforced)

- `.claude/hooks.json`, `.claude/hooks/`, `.claude/settings.json` — Write/Edit geblockt
- Keine Aenderungen an Hook-Konfiguration oder Hook-Scripten

## Supply-Chain

- Vor `npm install` / `pip install`: `npm audit` bzw. `pip audit` ausfuehren
- Neue Abhaengigkeiten begrenzen — nur was wirklich gebraucht wird
- Versionen in `package.json` / `requirements.txt` pinnen (kein `*` oder `latest`)

## Dry-Run

- Bash-Firewall ohne Blockierung testen: `CLAUDE_FORGE_DRY_RUN=1 bash hooks/bash-firewall.sh`
- Eigene Block-Patterns definieren: `~/.claude/local-patterns.sh` (Vorlage: `user-config/local-patterns.sh.example`)

## WebFetch

- `WebFetch` erfordert User-Bestaetigung (Sandbox-Restriction)
- Keine internen/privaten URLs ohne explizite User-Freigabe fetchen
