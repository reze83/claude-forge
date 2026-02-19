---
description: "Diagnostik + Auto-Repair fuer claude-forge Installation"
model: sonnet
allowed-tools:
  - Bash
  - Read
  - Write
---

# Forge Doctor

Diagnostiziere und repariere die claude-forge Installation.

## Schritt 1: Forge-Pfad ermitteln

```bash
CLAUDE_DIR=~/.claude
FORGE_DIR="$(cat "$CLAUDE_DIR/.forge-repo" 2>/dev/null)" || FORGE_DIR="$( (readlink -f "$CLAUDE_DIR/hooks/lib.sh" 2>/dev/null || readlink "$CLAUDE_DIR/hooks/lib.sh") | sed 's|/hooks/lib.sh$||')" && echo "Forge: $FORGE_DIR" || echo "Forge: NICHT GEFUNDEN"
```

## Schritt 2: Link-Check

Pruefe ALLE Link-Verzeichnisse (hooks, rules, commands, agents, skills, multi-model).
Fuer jede Datei: ist der Link (Hardlink oder Symlink) intakt?

```bash
CLAUDE_DIR=~/.claude
FORGE_DIR="$(cat "$CLAUDE_DIR/.forge-repo" 2>/dev/null)" || FORGE_DIR="$( (readlink -f "$CLAUDE_DIR/hooks/lib.sh" 2>/dev/null || readlink "$CLAUDE_DIR/hooks/lib.sh") | sed 's|/hooks/lib.sh$||')"
broken=0
for dir in hooks rules commands agents; do
  [ -d "$CLAUDE_DIR/$dir" ] || { echo "[MISSING] $dir/"; continue; }
  for f in "$CLAUDE_DIR/$dir"/*; do
    [ -e "$f" ] || [ -L "$f" ] || continue
    if [ -L "$f" ]; then
      dest="$(readlink -f "$f" 2>/dev/null || readlink "$f")"
      [ -e "$dest" ] || { echo "[BROKEN] $dir/$(basename "$f") -> $dest"; broken=$((broken+1)); }
    elif [ -f "$f" ]; then
      repo_file="$FORGE_DIR/$dir/$(basename "$f")"
      if [ -f "$repo_file" ] && [ "$(stat -c %i "$f")" = "$(stat -c %i "$repo_file")" ]; then
        : # ok
      else
        echo "[UNLINKED] $dir/$(basename "$f")"
      fi
    fi
  done
done
# Rekursiv verlinkte Verzeichnisse (skills, multi-model)
for dir in skills multi-model; do
  [ -d "$CLAUDE_DIR/$dir" ] || { echo "[MISSING] $dir/"; continue; }
  find "$CLAUDE_DIR/$dir" \( -type l -o -type f \) | while IFS= read -r f; do
    if [ -L "$f" ]; then
      dest="$(readlink -f "$f" 2>/dev/null || readlink "$f")"
      [ -e "$dest" ] || { echo "[BROKEN] ${f#"$CLAUDE_DIR"/} -> $dest"; broken=$((broken+1)); }
    elif [ -f "$f" ]; then
      rel="${f#"$CLAUDE_DIR"/}"
      repo_file="$FORGE_DIR/$rel"
      [ -f "$repo_file" ] && [ "$(stat -c %i "$f")" = "$(stat -c %i "$repo_file")" ] || echo "[UNLINKED] $rel"
    fi
  done
done
echo "Broken links: $broken"
```

## Schritt 3: Dependency-Check

Pruefe ob alle benoetigten Tools installiert sind:

```bash
for cmd in git jq bash; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "[OK] $cmd: $(command -v "$cmd")"
  else
    echo "[MISSING] $cmd"
  fi
done
for cmd in node prettier ruff shfmt shellcheck; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "[OK] $cmd (optional)"
  else
    echo "[WARN] $cmd nicht gefunden (optional)"
  fi
done
```

## Schritt 4: JSON-Validierung

```bash
CLAUDE_DIR=~/.claude
for f in "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/hooks/hooks.json"; do
  if [ -f "$f" ]; then
    if jq empty "$f" 2>/dev/null; then
      echo "[OK] $(basename "$f") valide"
    else
      echo "[ERR] $(basename "$f") invalide JSON"
    fi
  fi
done
```

## Schritt 5: Hook-Timeout-Konsistenz

Vergleiche Timeouts zwischen hooks.json und settings.json:

```bash
CLAUDE_DIR=~/.claude
FORGE_DIR="$(cat "$CLAUDE_DIR/.forge-repo" 2>/dev/null)" || FORGE_DIR="$( (readlink -f "$CLAUDE_DIR/hooks/lib.sh" 2>/dev/null || readlink "$CLAUDE_DIR/hooks/lib.sh") | sed 's|/hooks/lib.sh$||')"
if [ -f "$FORGE_DIR/validate.sh" ]; then
  bash "$FORGE_DIR/validate.sh" 2>&1 | tail -20
fi
```

## Schritt 6: Repair

Falls Probleme gefunden:

- **Broken Links**: Frage den User ob `bash $FORGE_DIR/install.sh` ausgefuehrt werden soll
- **Missing Deps**: Zeige Install-Befehle fuer fehlende Tools
- **Invalid JSON**: Zeige die fehlerhafte Zeile und biete Korrektur an
- **Timeout-Mismatch**: Zeige welche Werte abweichen

Zeige dem User eine Zusammenfassung mit Status-Emojis und konkreten Repair-Vorschlaegen.
