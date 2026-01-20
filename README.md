# claude-code-toolkit

My Claude Code configs — grab what you need.

## What's Inside

### Skills
| Skill | Description |
|-------|-------------|
| `git-commit` | Analyzes staged changes, proposes commit structure (single/multiple), generates messages |
| `skill-creator` | Scaffolds new skills following official spec |
| `pr-review` | Code review for diffs, commits, branches, PRs |
| `note-taking` | Task notes + knowledge base management |
| `planner` | Task capture and organization |
| `codemap` | Generate codebase maps with architecture diagrams (WIP - still testing) |
| `workflow-review` | Reviews CC sessions and proposes workflow improvements (CLAUDE.md updates, new skills, underused features) |
| `codex` | AI peer review via OpenAI Codex CLI — Claude consults Codex for code review, architecture decisions, and trade-off validation |
| `c7` | Fetches up-to-date library docs from Context7, saves to /tmp/context7/ |

### Commands
| Command | Description |
|---------|-------------|
| `git/security_review` | Security review of repository code |
| `myskill` | Skill discovery and execution |
| `review-notes` | Task notes maintenance |
| `review-knowledge` | Knowledge base review |
| `user/context` | Load context from topic folders |
| `pr-respond` | Responds to PR review comments from screenshots |

### Agents
| Agent | Description |
|-------|-------------|
| `knowledge-base-curator` | Enhances knowledge base entries |
| `task-notes-cleaner` | Cleans outdated context from task notes |

### Hooks & Utilities
- `bin/claude-block-sensitive-bash.sh` — Block sensitive bash commands
- `bin/claude-block-sensitive-files.sh` — Block sensitive file access
- `bin/claude_code_statusline.sh` — Statusline integration

### Config Template
`CLAUDE.md.example` — Personal instructions template with:
- ast-grep examples for code navigation
- Git commit style guidelines
- Code comment philosophy
- Communication protocols

## Setup

### 1. Clone

```bash
git clone https://github.com/antoniocascais/claude-code-toolkit.git
cd claude-code-toolkit
```

### 2. Run Setup

```bash
./bin/setup.sh --notes-folder /path/to/your/notes/folder
```

This processes `.example` templates, replacing paths with your config:

```bash
# Examples
./bin/setup.sh --notes-folder ~/Documents/claude
./bin/setup.sh --notes-folder ~/Documents/claude --config-path ~/my-claude-config
```

**Creates:**
- `<CONFIG_PATH>/CLAUDE.md`
- `<CONFIG_PATH>/commands/` — review-notes, review-knowledge, context
- `<CONFIG_PATH>/skills/` — note-taking, planner
- `<CONFIG_PATH>/agents/` — all agents

### 3. Create Data Directories

```bash
mkdir -p /path/to/your/notes/folder/tasks_notes
mkdir -p /path/to/your/notes/folder/knowledge_base
```

### 4. Link to Claude Code (if needed)

If you used a custom `--config-path`:

```bash
ln -s /path/to/your/config/folder/CLAUDE.md ~/.claude/CLAUDE.md
ln -s /path/to/your/config/folder/agents ~/.claude/agents
ln -s /path/to/your/config/folder/commands ~/.claude/commands
ln -s /path/to/your/config/folder/skills ~/.claude/skills
```

## Skill-Specific Setup

### codex (AI Peer Review)

Uses [OpenAI Codex CLI](https://github.com/openai/codex) as a second opinion for code review and technical decisions. Claude consults Codex, they can disagree and argue (up to 3 rounds), then you get a summary of what they agreed/disagreed on.

**Invocation:** `/codex` or `/codex-review`

**Auto-trigger (WIP):** Skill is designed to auto-consult Codex before presenting alternatives or completing significant work, but this isn't reliable yet. Use explicit invocation for now.

**Setup:**
```bash
npm install -g @openai/codex
```

**Example output:**
```
After discussion, updated findings:

| Issue                       | Status                                                | Action             |
|-----------------------------|-------------------------------------------------------|--------------------|
| jq parse error on assignment| Downgraded to low - email-triage.sh validates JSON first | Optional hardening |
| ollama pull retries         | Valid - need until clause                             | Fix required       |
| test-json-parse invalid JSON| False positive - doesn't exit                         | No fix needed      |
| // empty drops false        | NEW BUG - test fails at line 42                       | Fix required       |

Codex found a real bug: jq -r ".$field // empty" treats false as falsy and returns empty string.
```

### workflow-review

Requires hooks in `~/.claude/settings.json` for automatic session tracking.

**If you don't have a `hooks` section yet**, add this entire block:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/skills/workflow-review/scripts/message-counter.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/skills/workflow-review/scripts/session-start.sh"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/skills/workflow-review/scripts/session-end.sh"
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/skills/workflow-review/scripts/pre-compact.sh"
          }
        ]
      }
    ]
  }
}
```

**If you already have a `hooks` section**, add the `UserPromptSubmit`, `SessionStart`, and `SessionEnd` entries inside it.

**Dependencies:** `jq` (scripts check for availability and fail gracefully)

**Error logs:** `/tmp/claude-workflow-review-error.log`

## License

AGPL-3.0
