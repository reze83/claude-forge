# Git-Workflow

**Aktivierung:** Diese Regeln gelten in Git-Repositories. Ausserhalb von Repos (kein `.git/`-Verzeichnis) sind nur die Hook-enforced Abschnitte aktiv.

## Branch-Strategie

- GitHub Flow: `feature/`, `fix/`, `docs/`, `chore/` → `main`
- Immer Feature-Branch + PR — nie direkt auf `main` arbeiten
- Wenn auf `main` und Code-Aenderungen anstehen: Branch erstellen BEVOR der erste Edit passiert. Vorschlag: `git checkout -b <prefix>/<kurzbeschreibung>`

## Commits

- Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, `perf:`, `ci:`, `revert:`
- Commit-Messages auf Englisch, kurz und praegnant
- Breaking Changes: `feat!:` oder Footer `BREAKING CHANGE: <beschreibung>`

## Geschuetzt (Hook-enforced)

Push auf main, `--force`, `reset --hard` und `--amend` auf gepushte Commits sind durch Hooks geblockt.

## PR-Strategie

- Features: Squash-Merge (saubere History auf `main`)
- Hotfixes: Merge-Commit (Zeitstempel erhalten)

## CI/CD

- Vor Commit: Tests + Linting lokal pruefen
- Nach Push: CI-Status pruefen (Pipeline muss durchlaufen)
- Bei CI-Failure: sofort fixen, nicht ignorieren
- `git stash` fuer WIP — nie unfertige Aenderungen commiten

## Release-Checkliste

Vor jedem Release-Commit (auf eigenem `chore/vX.Y.Z`-Branch) sicherstellen:

1. **Version-Dateien konsistent** — alle Stellen die eine Version enthalten muessen uebereinstimmen:
   - `VERSION`, `package.json`, `Cargo.toml`, `pyproject.toml`, `plugin.json`, README-Badge
2. **CHANGELOG finalisieren** — `[Unreleased]` umbenennen zu `[X.Y.Z] - YYYY-MM-DD`, leeres `[Unreleased]` oben lassen
3. **Tests + Validierung lokal gruen** — `validate.sh` (falls vorhanden), alle Test-Suites
4. **Release-Commit auf Branch + PR** — nie direkt auf `main`; CI muss durchlaufen bevor Merge
