# ADR-0001: LLM-Based Hook Handlers (type: prompt and type: agent)

## Status

Accepted — Documentation only, not deployed by default.

## Context

Claude Code supports three hook handler types: `command` (Bash script receiving JSON on
stdin), `prompt` (single-turn LLM call with the hook text as a prompt), and `agent`
(multi-turn LLM with tool access). All claude-forge hooks use `type: "command"`.

Prompt hooks can perform semantic validation that shell scripts cannot:

- "Are all requested tasks complete?"
- "Do any unresolved errors remain in this conversation?"
- "Does this output look complete or truncated?"

The primary trade-off is token cost and latency. A `prompt` hook on `PreToolUse` would
fire on every Write/Edit/Bash — potentially dozens of times per session — making the cost
prohibitive. A `prompt` hook on `Stop` fires once per Claude turn, which is acceptable
as an explicit opt-in.

## Decision

LLM-based hooks are NOT included in the default claude-forge deployment (hooks.json or
user-config/settings.json.example). They are provided here as opt-in templates that users
can add manually to their ~/.claude/settings.json.

### Recommended configuration: Stop hook with completion verification

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Review the conversation. Are all tasks the user explicitly requested complete? Have any errors or test failures been left unresolved? If everything is done, respond with {\"ok\": true}. If not, respond with {\"ok\": false, \"reason\": \"what remains\"}.",
            "model": "claude-haiku-4-5-20251001",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

Model choice: `claude-haiku-4-5-20251001` for cost efficiency.

### When to use prompt hooks

| Event      | Fires          | Use case                | Cost impact  |
| ---------- | -------------- | ----------------------- | ------------ |
| Stop       | Once per turn  | Completion verification | Low (opt-in) |
| SessionEnd | Once/session   | Session summarization   | Very low     |
| PreCompact | Before compact | Context summarization   | Low          |

### When NOT to use prompt hooks

| Event            | Fires             | Problem             |
| ---------------- | ----------------- | ------------------- |
| PreToolUse       | Every tool call   | Token cost too high |
| PostToolUse      | Every tool result | Token cost too high |
| UserPromptSubmit | Every user msg    | Latency too high    |

## Consequences

- Zero token cost by default (prompt hooks not deployed)
- Users who want intelligent validation can add Stop/SessionEnd prompt hooks manually
- Future: env-var opt-in (e.g., `CLAUDE_FORGE_LLM_STOP_HOOK=1`) that dynamically
  enables a Stop prompt hook via a command hook wrapper
