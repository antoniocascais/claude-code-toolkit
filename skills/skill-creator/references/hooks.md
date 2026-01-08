# Skill Hooks Reference

Skills can define lifecycle hooks scoped to their execution. Hooks run shell commands that receive JSON data via stdin.

## Table of Contents

- [Hook Types](#hook-types)
- [Frontmatter Syntax](#frontmatter-syntax)
- [Matchers](#matchers)
- [Input/Output](#inputoutput)
- [Common Patterns](#common-patterns)
- [Configuration Options](#configuration-options)

## Hook Types

| Type | When it runs | Use case |
|------|--------------|----------|
| `PreToolUse` | Before tool executes | Validation, blocking, logging |
| `PostToolUse` | After tool completes | Formatting, verification |
| `Stop` | When skill ends | Cleanup, summary |

Additional types (see full docs): `PermissionRequest`, `UserPromptSubmit`, `Notification`, `SubagentStop`, `PreCompact`, `SessionStart`, `SessionEnd`

## Frontmatter Syntax

```yaml
---
name: my-skill
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: "jq -r '.tool_input.command' >> /tmp/log.txt"
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/format.sh"
---
```

## Matchers

```yaml
# Single tool
- matcher: Write

# Multiple tools (pipe-separated)
- matcher: "Edit|Write"

# All tools
- matcher: "*"
```

## Input/Output

### Hooks receive JSON via stdin

Use `jq` to parse:

```bash
# Get file path
jq -r '.tool_input.file_path'

# Get bash command
jq -r '.tool_input.command'

# Get with fallback
jq -r '.tool_input.description // "none"'
```

### Input JSON structure

```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file.ts",
    "content": "..."
  },
  "tool_use_id": "toolu_..."
}
```

### Environment variables

| Variable | Description |
|----------|-------------|
| `$CLAUDE_PROJECT_DIR` | Current project directory |

### Exit codes

| Code | Effect |
|------|--------|
| `0` | Success, continue |
| `2` | Block tool (PreToolUse only) |
| Other | Error, logged but continues |

## Common Patterns

### Log bash commands

```yaml
hooks:
  PreToolUse:
    - matcher: Bash
      hooks:
        - type: command
          command: "jq -r '.tool_input.command' >> /tmp/bash-log.txt"
```

### Format TypeScript after edits

```yaml
hooks:
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: |
            jq -r '.tool_input.file_path' | {
              read f
              [[ "$f" == *.ts ]] && npx prettier --write "$f" || true
            }
```

### Block sensitive files

```yaml
hooks:
  PreToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "python3 -c \"import json,sys; p=json.load(sys.stdin).get('tool_input',{}).get('file_path',''); sys.exit(2 if '.env' in p else 0)\""
```

### Run linter after Python edits

```yaml
hooks:
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: |
            jq -r '.tool_input.file_path' | {
              read f
              [[ "$f" == *.py ]] && ruff check "$f" 2>/dev/null || true
            }
```

## Configuration Options

### `once: true`

Run once per skill invocation, not per tool call:

```yaml
hooks:
  Stop:
    - hooks:
        - type: command
          command: "./summarize.sh"
          once: true
```

## References

- Full docs: https://code.claude.com/docs/en/hooks
- Examples: https://github.com/anthropics/claude-code/tree/main/examples/hooks
