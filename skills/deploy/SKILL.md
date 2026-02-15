---
name: deploy
description: "Verwende diesen Skill wenn der User ein Deployment durchfuehren oder einen Deploy-Prozess starten moechte. Erkennt automatisch das Projekt-Setup und waehlt die passende Deploy-Strategie."
version: "1.0.0"
user-invocable: true
disable-model-invocation: true
---
# Deploy

Deploy $ARGUMENTS:

> **Hinweis**: Dieser Skill erkennt automatisch die Projekt-Konfiguration (package.json, Cargo.toml, pyproject.toml, Dockerfile, etc.) und passt die Schritte entsprechend an. Falls kein Deploy-Target erkannt wird, frage den User nach dem Ziel.

## Ablauf

1. **Detect**: Projekt-Typ und Deploy-Target erkennen (Vercel, Netlify, Docker, npm publish, PyPI, etc.)
2. **Tests**: Test-Suite ausfuehren, bei Fehler abbrechen
3. **Build**: Produktions-Build erstellen (falls noetig)
4. **Deploy**: Auf Ziel-Environment deployen
5. **Verify**: Health-Check nach Deployment
6. **Report**: Zusammenfassung mit Status + URL

## Unterstuetzte Targets

Erkenne automatisch anhand vorhandener Config-Dateien:
- `vercel.json` / `.vercel/` → `vercel --prod`
- `netlify.toml` → `netlify deploy --prod`
- `Dockerfile` → Docker build + push
- `fly.toml` → `fly deploy`
- `package.json` mit `"publish"` → `npm publish`
- `pyproject.toml` → `python -m build && twine upload`
- Sonst: Frage den User nach der Deploy-Methode
