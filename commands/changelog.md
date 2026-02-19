---
description: "Generiere CHANGELOG-Eintraege aus Git-History (Conventional Commits)"
model: sonnet
allowed-tools:
  - Bash
  - Read
  - Edit
---

# Changelog Generator

Generiere CHANGELOG-Eintraege aus der Git-History basierend auf Conventional Commits.

## Schritt 1: Letzte Version ermitteln

```bash
git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0"
```

## Schritt 2: Commits seit letztem Tag sammeln

```bash
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$LAST_TAG" ]; then
  git log "$LAST_TAG"..HEAD --pretty=format:"%s" --no-merges
else
  git log --pretty=format:"%s" --no-merges -50
fi
```

## Schritt 3: Commits nach Typ gruppieren

Sortiere die Commits nach Conventional Commit Typ:

- **Features** (`feat:`): Neue Funktionen
- **Bug Fixes** (`fix:`): Fehlerkorrekturen
- **Performance** (`perf:`): Performance-Verbesserungen
- **Documentation** (`docs:`): Dokumentation
- **Refactoring** (`refactor:`): Code-Umstrukturierung
- **Tests** (`test:`): Tests
- **Chores** (`chore:`): Wartung, CI, Dependencies

## Schritt 4: CHANGELOG-Eintrag erstellen

Formatiere als Keep a Changelog Eintrag unter `[Unreleased]`:

```markdown
## [Unreleased]

### Added

- feat: Beschreibung

### Fixed

- fix: Beschreibung

### Changed

- refactor: Beschreibung

### Performance

- perf: Beschreibung
```

## Schritt 5: In CHANGELOG.md einfuegen

Lies die bestehende CHANGELOG.md und fuege den neuen Eintrag nach dem Header ein (vor dem ersten vorhandenen Versions-Eintrag). Falls `[Unreleased]` bereits existiert, ersetze dessen Inhalt.

Zeige dem User den generierten Eintrag vor dem Schreiben.
