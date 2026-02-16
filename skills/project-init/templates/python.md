# Python 3.12+ Projekt-Template

## Dateien erstellen

### pyproject.toml
```toml
[project]
name = "<projektname>"
version = "0.0.1"
requires-python = ">=3.12"

[tool.ruff]
target-version = "py312"
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP", "S", "B", "SIM", "TCH"]

[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["src"]
```

### Verzeichnisstruktur
```
src/
└── <projektname>/
    ├── __init__.py
    └── main.py
tests/
├── __init__.py
└── test_main.py
```

### .gitignore
```
__pycache__/
*.pyc
.venv/
dist/
*.egg-info/
.env*
CLAUDE.local.md
.claude/settings.local.json
```

### Nach Erstellung
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install ruff pytest
```
