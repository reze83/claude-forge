---
description: "Zeige claude-forge Status: Version, Hooks, Symlinks, Updates"
model: sonnet
allowed-tools:
  - Bash
  - Read
---

# Forge Status

Zeige den aktuellen Status der claude-forge Installation.

## Schritt 1: Version

Ermittle den tatsaechlichen Pfad von claude-forge ueber einen Datei-Symlink in hooks/:

```bash
CLAUDE_DIR=~/.claude
FORGE_DIR="$( (readlink -f "$CLAUDE_DIR/hooks/lib.sh" 2>/dev/null || readlink "$CLAUDE_DIR/hooks/lib.sh") | sed 's|/hooks/lib.sh$||')" && cat "$FORGE_DIR/VERSION" 2>/dev/null || echo "unbekannt"
```

## Schritt 2: Symlink-Health

Pruefe ob alle erwarteten Datei-Symlinks in den Verzeichnissen existieren und auf gueltige Ziele zeigen:

```bash
CLAUDE_DIR=~/.claude
for dir in rules hooks commands multi-model agents skills; do
  target="$CLAUDE_DIR/$dir"
  if [ ! -d "$target" ]; then
    echo "[MISSING] $dir/ existiert nicht"
    continue
  fi
  total=0; ok=0; broken=0
  for f in "$target"/*; do
    [ -e "$f" ] || continue
    total=$((total + 1))
    if [ -L "$f" ]; then
      dest="$(readlink -f "$f" 2>/dev/null || readlink "$f")"
      if [ -e "$dest" ]; then
        ok=$((ok + 1))
      else
        broken=$((broken + 1))
        echo "[BROKEN] $dir/$(basename "$f") -> $dest"
      fi
    fi
  done
  if [ "$broken" -eq 0 ] && [ "$ok" -gt 0 ]; then
    echo "[OK] $dir/ ($ok Datei-Symlinks)"
  elif [ "$total" -eq 0 ]; then
    echo "[WARN] $dir/ ist leer"
  fi
done
```

## Schritt 3: Aktive Hooks

```bash
CLAUDE_DIR=~/.claude
jq -r '.hooks | to_entries[] | "\(.key): \(.value | length) hooks"' "$CLAUDE_DIR/hooks/hooks.json" 2>/dev/null || echo "hooks.json nicht gefunden"
```

## Schritt 4: Verfuegbare Updates

```bash
CLAUDE_DIR=~/.claude
FORGE_DIR="$( (readlink -f "$CLAUDE_DIR/hooks/lib.sh" 2>/dev/null || readlink "$CLAUDE_DIR/hooks/lib.sh") | sed 's|/hooks/lib.sh$||')" && bash "$FORGE_DIR/update.sh" --check 2>/dev/null || echo "Update-Check fehlgeschlagen"
```

## Schritt 5: Zusammenfassung

Zeige dem User eine kompakte Uebersicht mit Emojis fuer Status (OK/WARN/ERR) und empfehle `/forge-update` falls Updates verfuegbar sind.
