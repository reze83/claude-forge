#!/usr/bin/env bash
set -euo pipefail
# PreToolUse Hook — URL Allowlist (WebFetch)
# Blocks requests to private/internal URLs unless explicitly allowlisted.
# Output: JSON on stdout (exit 0 ensures JSON is processed by Claude Code)
# Compatible: Bash 3.2+ (macOS) and Bash 4+

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

INPUT=$(cat 2>/dev/null || true)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null) || TOOL_NAME=""
[[ "$TOOL_NAME" != "WebFetch" ]] && exit 0

URL=$(echo "$INPUT" | jq -r '.tool_input.url // ""' 2>/dev/null) || URL=""
[[ -z "$URL" ]] && exit 0

# Block non-HTTP schemes (file://, ftp://, gopher://, etc.)
SCHEME=$(printf '%s' "$URL" | sed -E 's,^([a-zA-Z][a-zA-Z0-9+.-]*)://.*,\1,' | tr '[:upper:]' '[:lower:]')
if [[ "$SCHEME" != "http" && "$SCHEME" != "https" ]]; then
  block_or_warn "Non-HTTP scheme not allowed: $URL (scheme: $SCHEME)"
fi

debug "url-allowlist: url=$URL"

# Extract host from URL (portable, no Bash 4+ features)
get_host() {
  local url="$1"
  local rest hostpart host
  # Strip scheme
  rest=$(printf '%s' "$url" | sed -E 's,^[a-zA-Z][a-zA-Z0-9+.-]*://,,')
  # Strip userinfo
  rest=$(printf '%s' "$rest" | sed -E 's,^[^/]*@,,')
  # Extract host:port (everything before first / ? #)
  hostpart=$(printf '%s' "$rest" | sed -E 's,[/?#].*$,,')
  # Handle IPv6 brackets
  if printf '%s' "$hostpart" | grep -Eq '^\['; then
    host="$hostpart"
  else
    # Strip port
    host=$(printf '%s' "$hostpart" | sed -E 's,:[0-9]+$,,')
  fi
  printf '%s' "$host"
}

HOST=$(get_host "$URL")
[[ -z "$HOST" ]] && exit 0

# Strip trailing dot from FQDN (e.g. localhost. → localhost, metadata.google.internal. → metadata.google.internal)
HOST=$(printf '%s' "$HOST" | sed -E 's/\.$//')

HOST_LOWER=$(printf '%s' "$HOST" | tr '[:upper:]' '[:lower:]')

# User-configurable allowlist (comma-separated domains via env var)
ALLOWLIST_RAW="${URL_ALLOWLIST:-}"
if [[ -n "$ALLOWLIST_RAW" ]]; then
  IFS=',' read -r -a ALLOWLIST <<<"$ALLOWLIST_RAW"
  for a in "${ALLOWLIST[@]}"; do
    a_trim=$(printf '%s' "$a" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
    [[ -z "$a_trim" ]] && continue
    a_lower=$(printf '%s' "$a_trim" | tr '[:upper:]' '[:lower:]')
    if [[ "$HOST_LOWER" == "$a_lower" || "$HOST_LOWER" == *".${a_lower}" ]]; then
      debug "url-allowlist: allowlist match host=$HOST_LOWER allow=$a_lower"
      exit 0
    fi
  done
fi

# Private/internal URL patterns (ERE, no PCRE)
PRIVATE_PATTERNS=(
  '^localhost\.?$'
  '^127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'
  '^0\.0\.0\.0$'
  '^10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'
  '^172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}$'
  '^192\.168\.[0-9]{1,3}\.[0-9]{1,3}$'
  '^\[?::1\]?$'
  '^\[?::\]?$'
  '^\[?fe80:.*\]?$'
  '^\[?fd[0-9a-f]{2}:.*\]?$' # Unique local IPv6 fd00::/8 (RFC 4193)
  '^\[?fc[0-9a-f]{2}:.*\]?$' # Unique local IPv6 fc00::/8 (RFC 4193)
  '^\[?::ffff:.*\]?$'        # IPv4-mapped IPv6 (e.g. ::ffff:127.0.0.1 → loopback)
  '^169\.254\.169\.254$'
  '.*\.local$'
  '.*\.internal$'
  '.*\.corp$'
  '.*\.intranet$'
)

for p in "${PRIVATE_PATTERNS[@]}"; do
  if printf '%s' "$HOST_LOWER" | grep -Eiq "$p"; then
    block_or_warn "Private/internal URL not allowed: $URL (host: $HOST)"
  fi
done

exit 0
