# Sicherheit

**Aktivierung:** Immer aktiv — gilt in jedem Kontext, auch ausserhalb von Git-Repos.

## Hook-enforced (automatisch, nicht umgehbar)

- **Dateischutz:** `.env`, `.ssh/`, `.aws/`, `.gnupg/`, `*.pem`, `*.key`, `*.p12`, `*.pfx` — Read/Write/Edit geblockt. Allowlist: `.env.example`, `.env.sample`, `.env.template`
- **Secret-Scan:** 11 Patterns (Anthropic, OpenAI, GitHub, AWS, JWT, PEM, Stripe, Slack, Azure) — Pre-Write blockt, Post-Write warnt. False Positive: `# pragma: allowlist secret` pro Zeile
- **Bash-Firewall:** Destruktive Befehle (`rm -rf /`, `mkfs`, `dd`), Git-Schutz (push main, --force, reset --hard), Shell-Injection (`eval`, `bash -c`), unsichere Permissions (`chmod 777`)
- **Hook-Integritaet:** `.claude/hooks/`, `hooks.json`, `settings.json` — Write/Edit geblockt
- **URL-Allowlist:** WebFetch auf private/interne URLs geblockt (localhost, RFC1918, Metadata, .local/.internal)

## Supply-Chain

- Vor `npm install` / `pip install`: `npm audit` bzw. `pip audit` ausfuehren
- Neue Abhaengigkeiten begrenzen — nur was wirklich gebraucht wird
- Versionen in `package.json` / `requirements.txt` pinnen (kein `*` oder `latest`)
