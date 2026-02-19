# Dokumentationspflege

## Wann aktualisieren

- Nach nicht-trivialen Code-Aenderungen (neue Features, API-Aenderungen, Architektur-Entscheidungen)
- Nicht bei reinen Refactorings ohne externe Auswirkung
- Inline-Kommentare: **Warum** erklaeren, nicht **Was** — der Code ist das "Was"

## Was aktualisieren

- `CHANGELOG.md` → Eintrag unter `[Unreleased]`
- `README.md` → Features, Beispiele, Badges (Test-Count)
- `ARCHITECTURE.md` → Struktur, Diagramme, Entscheidungen
- `CONTRIBUTING.md` → Konventionen, Test-Befehle, Checklisten
- `docs/` → weiterfuehrende Dokumentation

## Projektspezifisch (claude-forge)

- Hooks geaendert → `docs/ARCHITECTURE.md` (Hook-Tabelle aktualisieren)
- Neuer Hook/Skill/Command → `docs/ARCHITECTURE.md` (Dateipfade-Tabelle)
- Test-Anzahl geaendert → `CONTRIBUTING.md`, `README.md` (Badge), `docs/ARCHITECTURE.md`
- Siehe Doc-Sync Abschnitt in `CLAUDE.md` fuer vollstaendige Regeln
