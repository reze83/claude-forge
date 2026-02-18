# Rust Projekt-Template

## Befehle ausfuehren

```bash
cargo init <projektname>
cd <projektname>
```

### Clippy-Config in Cargo.toml ergaenzen
```toml
[lints.clippy]
pedantic = { level = "warn", priority = -1 }
```

### Verzeichnisstruktur (von cargo init)
```
src/
└── main.rs           # oder lib.rs fuer Libraries
tests/                # Integration Tests
```

### .gitignore ergaenzen
```
CLAUDE.local.md
.claude/settings.local.json
```
