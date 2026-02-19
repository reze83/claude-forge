---
description: "Zeige claude-forge Status: Version, Hooks, Links, Updates"
model: sonnet
allowed-tools:
  - Bash
  - Read
---

# Forge Status

Zeige den aktuellen Status der claude-forge Installation.

## Schritt 1: Version

Ermittle den tatsaechlichen Pfad von claude-forge ueber die Marker-Datei (Fallback: readlink):

```bash
CLAUDE_DIR=~/.claude
FORGE_DIR="$(cat "$CLAUDE_DIR/.forge-repo" 2>/dev/null)" || FORGE_DIR="$( (readlink -f "$CLAUDE_DIR/hooks/lib.sh" 2>/dev/null || readlink "$CLAUDE_DIR/hooks/lib.sh") | sed 's|/hooks/lib.sh$||')" && cat "$FORGE_DIR/VERSION" 2>/dev/null || echo "unbekannt"
```

## Schritt 2: Link-Health

Pruefe ob alle erwarteten Datei-Links (Hardlinks oder Symlinks) in den Verzeichnissen existieren:

```bash
CLAUDE_DIR=~/.claude
FORGE_DIR="$(cat "$CLAUDE_DIR/.forge-repo" 2>/dev/null)" || FORGE_DIR="$( (readlink -f "$CLAUDE_DIR/hooks/lib.sh" 2>/dev/null || readlink "$CLAUDE_DIR/hooks/lib.sh") | sed 's|/hooks/lib.sh$||')"
for dir in rules hooks commands multi-model agents; do
  target="$CLAUDE_DIR/$dir"
  if [ ! -d "$target" ]; then
    echo "[MISSING] $dir/ existiert nicht"
    continue
  fi
  total=0; ok=0
  for f in "$target"/*; do
    [ -e "$f" ] || [ -L "$f" ] || continue
    total=$((total + 1))
    # Symlink
    if [ -L "$f" ]; then
      dest="$(readlink -f "$f" 2>/dev/null || readlink "$f")"
      [ -e "$dest" ] && ok=$((ok + 1)) || echo "[BROKEN] $dir/$(basename "$f") -> $dest"
      continue
    fi
    # Hardlink: Inode-Vergleich
    repo_file="$FORGE_DIR/$dir/$(basename "$f")"
    if [ -f "$repo_file" ] && [ "$(stat -c %i "$f")" = "$(stat -c %i "$repo_file")" ]; then
      ok=$((ok + 1))
    fi
  done
  if [ "$ok" -gt 0 ]; then
    echo "[OK] $dir/ ($ok Datei-Links)"
  elif [ "$total" -eq 0 ]; then
    echo "[WARN] $dir/ ist leer"
  fi
done
# Skills separat (rekursive Datei-Links)
if [ -d "$CLAUDE_DIR/skills" ]; then
  total=0; ok=0
  while IFS= read -r f; do
    total=$((total + 1))
    if [ -L "$f" ]; then
      dest="$(readlink -f "$f" 2>/dev/null || readlink "$f")"
      [ -e "$dest" ] && ok=$((ok + 1)) || echo "[BROKEN] skills/... -> $dest"
    elif [ -f "$f" ]; then
      rel="${f#"$CLAUDE_DIR"/}"
      repo_file="$FORGE_DIR/$rel"
      if [ -f "$repo_file" ] && [ "$(stat -c %i "$f")" = "$(stat -c %i "$repo_file")" ]; then
        ok=$((ok + 1))
      fi
    fi
  done < <(find "$CLAUDE_DIR/skills" \( -type l -o -type f \))
  if [ "$ok" -gt 0 ]; then
    echo "[OK] skills/ ($ok Datei-Links)"
  elif [ "$total" -eq 0 ]; then
    echo "[WARN] skills/ ist leer"
  fi
else
  echo "[MISSING] skills/ existiert nicht"
fi
```

## Schritt 3: Aktive Hooks

```bash
CLAUDE_DIR=~/.claude
jq -r '.hooks | to_entries[] | "\(.key): \(.value | length) hooks"' "$CLAUDE_DIR/hooks/hooks.json" 2>/dev/null || echo "hooks.json nicht gefunden"
```

## Schritt 4: Verfuegbare Updates

```bash
CLAUDE_DIR=~/.claude
FORGE_DIR="$(cat "$CLAUDE_DIR/.forge-repo" 2>/dev/null)" || FORGE_DIR="$( (readlink -f "$CLAUDE_DIR/hooks/lib.sh" 2>/dev/null || readlink "$CLAUDE_DIR/hooks/lib.sh") | sed 's|/hooks/lib.sh$||')" && bash "$FORGE_DIR/update.sh" --check 2>/dev/null || echo "Update-Check fehlgeschlagen"
```

## Schritt 5: Zusammenfassung

Zeige dem User eine kompakte Uebersicht mit Emojis fuer Status (OK/WARN/ERR) und empfehle `/forge-update` falls Updates verfuegbar sind.
