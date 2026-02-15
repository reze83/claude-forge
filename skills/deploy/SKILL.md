---
name: deploy
description: "Verwende diesen Skill wenn der User ein Deployment durchfuehren oder einen Deploy-Prozess starten moechte."
version: "1.0.0"
user-invocable: true
disable-model-invocation: true
---
# Deploy

Deploy $ARGUMENTS:

1. **Tests**: Test-Suite ausfuehren, bei Fehler abbrechen
2. **Build**: Produktions-Build erstellen
3. **Deploy**: Auf Ziel-Environment deployen
4. **Verify**: Health-Check nach Deployment
5. **Report**: Zusammenfassung mit Status + URL
