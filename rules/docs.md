# Dokumentationspflege

**Aktivierung:** Diese Regeln gelten bei Code-Aenderungen in Projekten mit Dokumentationsdateien (CHANGELOG, README, ARCHITECTURE, docs/).

## Wann aktualisieren

Docs aktualisieren wenn MINDESTENS EINES zutrifft:

- Public API-Surface geaendert (neue/entfernte/umbenannte Endpoints, Funktionen, CLI-Flags)
- Neue Abhaengigkeit hinzugefuegt oder entfernt
- Neues User-sichtbares Verhalten (Feature, Hook, Skill, Command)
- Architektur-Entscheidung getroffen (neues Pattern, neue Komponente)

NICHT aktualisieren bei:

- Reines Refactoring ohne externe Auswirkung
- Bugfixes die kein Verhalten aendern
- Interne Umbenennung ohne API-Effekt

Inline-Kommentare: **Warum** erklaeren, nicht **Was** — der Code ist das "Was"

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
- Siehe Doc-Sync Abschnitt im Projekt-`CLAUDE.md` (Repo-Root) fuer vollstaendige Regeln
