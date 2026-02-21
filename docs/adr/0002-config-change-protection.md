# ADR-0002: ConfigChange Hook for Configuration Audit and Protection

## Status

Accepted.

## Context

Claude Code fires a `ConfigChange` event when configuration is modified during a session.
The `source` field identifies what changed:

- `user_settings` — ~/.claude/settings.json
- `project_settings` — .claude/settings.json
- `local_settings` — .claude/settings.local.json
- `policy_settings` — managed policy settings (CANNOT be blocked by hooks)
- `skills` — skill files in .claude/skills/

The existing `protect-files.sh` hook (PreToolUse) blocks Write/Edit on `.claude/settings.json`
and `hooks.json`. However, configuration may change through means other than direct file
writes (e.g., Claude Code UI, `/hooks` menu). ConfigChange covers all such changes.

## Decision

Implement `config-change.sh` as a `ConfigChange` event hook with these behaviors:

1. **Default (always):** Log all config changes to `~/.claude/config-changes.log` with
   timestamp, source, and session_id. Provides an audit trail with zero user friction.

2. **`policy_settings`:** Always exit 0 regardless of any opt-in settings. The Claude Code
   specification states policy_settings changes cannot be blocked.

3. **Opt-in block (`CLAUDE_FORGE_CONFIG_LOCK=1`):** For non-policy config changes, exit 2
   to block the change. Not enabled by default because it would prevent Claude Code itself
   from applying necessary configuration during normal use.

### Blocking mechanism

ConfigChange blocking uses `exit 2` (same as PermissionRequest, TeammateIdle, TaskCompleted),
not `block()` from lib.sh. The `block()` function is PreToolUse-only — it outputs
`hookSpecificOutput.permissionDecision` which is only processed for PreToolUse events.

### Hook registration

ConfigChange is registered without a matcher field (handles all source values).
Filtering is done inside the script to keep the audit log complete.

## Consequences

- All config changes are logged by default (audit trail)
- No change to normal Claude Code operation without opt-in
- `CLAUDE_FORGE_CONFIG_LOCK=1` enables strict config protection
- Complements `protect-files.sh` (file-write protection) rather than replacing it
