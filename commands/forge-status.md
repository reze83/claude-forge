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

Ermittle den tatsaechlichen Pfad von claude-forge ueber den hooks-Symlink:

```bash
FORGE_DIR="$( (readlink -f "$HOME/.claude/hooks" 2>/dev/null || readlink "$HOME/.claude/hooks") | sed 's|/hooks$||')" && cat "$FORGE_DIR/VERSION" 2>/dev/null || echo "unbekannt"
```

## Schritt 2: Symlink-Health

Pruefe ob alle erwarteten Symlinks existieren und auf gueltige Ziele zeigen:

```bash
for link in rules hooks commands multi-model; do
  target="$HOME/.claude/$link"
  if [ -L "$target" ]; then
    dest="$(readlink -f "$target" 2>/dev/null || readlink "$target")"
    if [ -e "$dest" ]; then
      echo "[OK] $link -> $dest"
    else
      echo "[BROKEN] $link -> $dest (Ziel existiert nicht)"
    fi
  else
    echo "[MISSING] $link ist kein Symlink"
  fi
done
```

## Schritt 3: Aktive Hooks

```bash
jq -r '.hooks | to_entries[] | "\(.key): \(.value | length) hooks"' "$HOME/.claude/hooks/hooks.json" 2>/dev/null || echo "hooks.json nicht gefunden"
```

## Schritt 4: Verfuegbare Updates

```bash
FORGE_DIR="$( (readlink -f "$HOME/.claude/hooks" 2>/dev/null || readlink "$HOME/.claude/hooks") | sed 's|/hooks$||')" && bash "$FORGE_DIR/update.sh" --check 2>/dev/null || echo "Update-Check fehlgeschlagen"
```

## Schritt 5: Zusammenfassung

Zeige dem User eine kompakte Uebersicht mit Emojis fuer Status (OK/WARN/ERR) und empfehle `/forge-update` falls Updates verfuegbar sind.
