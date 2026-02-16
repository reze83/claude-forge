# claude-forge Demo Recording
# Generate: cd ~/develop/claude-forge && vhs docs/demo.tape
# Requires: vhs, jq

Output docs/assets/demo.gif

# Terminal configuration (optimized for GitHub README)
Set Shell "bash"
Set FontSize 26
Set Width 1200
Set Height 650
Set Theme "Catppuccin Mocha"
Set Framerate 60
Set TypingSpeed 60ms
Set Padding 20
Set Margin 20
Set MarginFill "#1e1e2e"
Set BorderRadius 10
Set PlaybackSpeed 1.0

# --- Setup (hidden from recording) ---
Hide
Type `export PS1='\[\033[1;36m\]claude-forge\[\033[0m\] \[\033[1;33m\]demo\[\033[0m\] $ '`
Enter
Sleep 300ms
Type "cd /home/c/develop/claude-forge"
Enter
Sleep 300ms
# Create temp file with fake secret for scene 3
Type "echo 'ANTHROPIC_API_KEY=sk-ant-api03-abcdefghijklmnopqrst' > /tmp/claude/demo-secret-test.txt"
Enter
Sleep 300ms
Type "clear"
Enter
Sleep 300ms
Show

# --- Scene 1: Bash-Firewall blocks dangerous command ---
Sleep 600ms
Type "# Hook 1: bash-firewall — blocks dangerous commands"
Enter
Sleep 800ms
Type `echo '{"tool_input":{"command":"rm -rf /"}}' | bash hooks/bash-firewall.sh 2>&1 | jq .`
Sleep 400ms
Enter
Sleep 2500ms

# --- Scene 2: File protection ---
Type "# Hook 2: protect-files — guards sensitive files"
Enter
Sleep 800ms
Type `echo '{"tool_input":{"file_path":"/home/user/.env"}}' | bash hooks/protect-files.sh 2>&1 | jq .`
Sleep 400ms
Enter
Sleep 2500ms

# --- Scene 3: Secret-Scan detection ---
Type "# Hook 3: secret-scan — detects leaked credentials"
Enter
Sleep 800ms
Type `echo '{"tool_input":{"file_path":"/tmp/claude/demo-secret-test.txt"}}' | bash hooks/secret-scan.sh | jq .`
Sleep 400ms
Enter
Sleep 3s

# --- Cleanup (hidden) ---
Hide
Type "rm -f /tmp/claude/demo-secret-test.txt"
Enter
Show
Sleep 500ms
