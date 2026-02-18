# Git-Workflow

## Branch-Strategie

- GitHub Flow: `feature/`, `fix/`, `docs/`, `chore/` → `main`
- Immer Feature-Branch + PR — nie direkt auf `main` arbeiten

## Commits

- Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- Commit-Messages auf Englisch, kurz und praegnant

## Geschuetzt (Hook-enforced)

- `git push main/master` — geblockt durch `bash-firewall.sh`
- `--force` / `--force-with-lease` — geblockt (alle Branches)
- `git reset --hard` — geblockt
- `--amend` auf bereits gepushte Commits — geblockt
- Refspec-Bypass (`git push origin HEAD:main`) — ebenfalls erkannt

## CI/CD

- Vor Commit: Tests + Linting lokal pruefen
- Nach Push: CI-Status pruefen (`test.yml` muss durchlaufen)
- Bei CI-Failure: sofort fixen, nicht ignorieren
