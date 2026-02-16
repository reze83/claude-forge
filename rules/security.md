# Sicherheit
- Sensible Dateien (.env, .ssh/, .aws/, .gnupg/, .git/, *.pem, *.key) sind hook-geschuetzt — nicht versuchen zu lesen/schreiben
- Allowlist: .env.example, .env.sample, .env.template sind erlaubt
- Keine Secrets in Code schreiben. Bei False Positives: `# pragma: allowlist secret` (gilt nur fuer die Zeile)
- Hook-Konfiguration (.claude/hooks.json, .claude/settings.json) nicht veraendern
- Keine destruktiven Befehle: rm -rf /, git push main, git reset --hard, eval, bash -c
- WebFetch erfordert Bestaetigung
