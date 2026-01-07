# claude-code-toolkit

My Claude Code configs — grab what you need.

## What's Inside

### Skills
| Skill | Description |
|-------|-------------|
| `git-commit` | Analyzes staged changes, proposes commit structure (single/multiple), generates messages |
| `skill-creator` | Scaffolds new skills following official spec |
| `reviewing-code-changes` | Code review for diffs, commits, branches, PRs — security, best practices, performance |
| `note-taking` | Task notes + knowledge base management |
| `planner` | Task capture and organization |

### Commands
| Command | Description |
|---------|-------------|
| `git/security_review` | Security review of repository code |
| `myplanner` | Task planning proxy |
| `myskill` | Skill discovery and execution |
| `review-notes` | Task notes maintenance |
| `review-knowledge` | Knowledge base review |
| `user/context` | Load context from topic folders |

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

## License

AGPL-3.0
