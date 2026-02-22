# Sicherheit

**Aktivierung:** Immer aktiv — gilt in jedem Kontext, auch ausserhalb von Git-Repos.

## Hook-enforced (automatisch, nicht umgehbar)

Diese Schutzebenen sind durch claude-forge Hooks aktiv — unabhaengig vom Projekt:

- **Dateischutz (kritisch):** `.env`, `.ssh/`, `.aws/`, `.gnupg/`, `*.pem`, `*.key`, `*.p12`, `*.pfx` — Read/Write/Edit geblockt, auch in DRY_RUN. Allowlist: `.env.example`, `.env.sample`, `.env.template`
- **Dateischutz (non-critical):** `secrets/`, `.git/`, `.npmrc`, `.netrc` — Read/Write/Edit geblockt, DRY_RUN konvertiert zu Warning
- **Secret-Scan:** Patterns fuer gaengige API-Keys (Anthropic, OpenAI, GitHub, AWS, JWT, PEM, Stripe, Slack, Azure) — Pre-Write blockt, Post-Write warnt. False Positive: `# pragma: allowlist secret` pro Zeile
- **Bash-Firewall:** Destruktive Befehle (`rm -rf /`, `mkfs`, `dd`), Git-Schutz (push main, --force, reset --hard), Shell-Injection (`eval`, `bash -c`), Interpreter-Injection (`python -c`, `node -e`, `perl -e`, `ruby -e`), unsichere Permissions (`chmod 777`)
- **Hook-Integritaet:** Hook-Konfigurationsdateien — Write/Edit geblockt, auch in DRY_RUN
- **URL-Allowlist:** WebFetch auf private/interne URLs geblockt (localhost, RFC1918, Metadata, .local/.internal)

## Supply-Chain

- Vor `npm install` / `pip install`: `npm audit` bzw. `pip audit` ausfuehren
- Neue Abhaengigkeiten begrenzen — nur was wirklich gebraucht wird
- Versionen in `package.json` / `requirements.txt` pinnen (kein `*` oder `latest`)
