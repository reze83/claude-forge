# Git-Workflow

**Aktivierung:** Diese Regeln gelten in Git-Repositories. Ausserhalb von Repos (kein `.git/`-Verzeichnis) sind nur die Hook-enforced Abschnitte aktiv.

## Branch-Strategie

- GitHub Flow: `feature/`, `fix/`, `docs/`, `chore/` → `main`
- Immer Feature-Branch + PR — nie direkt auf `main` arbeiten
- Wenn auf `main` und Code-Aenderungen anstehen: Branch erstellen BEVOR der erste Edit passiert. Vorschlag: `git checkout -b <prefix>/<kurzbeschreibung>`

## Commits

- Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, `perf:`, `ci:`, `revert:`
- Optionaler Scope: `feat(auth): add login endpoint`
- Commit-Messages auf Englisch, kurz und praegnant
- Breaking Changes: `feat!:` oder Footer `BREAKING CHANGE: <beschreibung>`

## Geschuetzt (Hook-enforced)

- `git push main/master` — geblockt durch `bash-firewall.sh`
- `--force` / `--force-with-lease` — geblockt (alle Branches)
- `git reset --hard` — geblockt
- `--amend` auf bereits gepushte Commits — geblockt
- Refspec-Bypass (`git push origin HEAD:main`) — ebenfalls erkannt

## PR-Strategie

- Features: Squash-Merge (saubere History auf `main`)
- Hotfixes: Merge-Commit (Zeitstempel erhalten)
- PRs klein halten — ein Feature, ein PR

## CI/CD

- Vor Commit: Tests + Linting lokal pruefen
- Nach Push: CI-Status pruefen (`test.yml` muss durchlaufen)
- Bei CI-Failure: sofort fixen, nicht ignorieren
- `git stash` fuer WIP — nie unfertige Aenderungen commiten
