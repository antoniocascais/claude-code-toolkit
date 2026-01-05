# claude-code-knowledge

A comprehensive knowledge management system for Claude Code with intelligent note-taking, knowledge base curation, and automated maintenance workflows.

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/antoniocascais/claude-code-knowledge.git
cd claude-code-knowledge
```

### 2. Run the Setup Script

The setup script will generate your personal configuration files from the `.example` templates:

```bash
./bin/setup.sh --notes-folder /path/to/your/notes/folder
```

**Examples:**
```bash
# Standard location (config goes to ~/.claude by default)
./bin/setup.sh --notes-folder ~/Documents/claude

# Custom config path
./bin/setup.sh --notes-folder ~/Documents/claude --config-path ~/my-claude-config

# Show help
./bin/setup.sh --help
```

**What it does:**
- Reads all `.example` template files in the repository
- Normalizes paths so relative and `~` inputs work everywhere
- Replaces `/path/to/claude` with your `--notes-folder` path
- Creates/updates the following files inside your config directory:
  - `<CONFIG_PATH>/CLAUDE.md` - Main configuration
  - `<CONFIG_PATH>/commands/review-notes.md` - Task notes maintenance command
  - `<CONFIG_PATH>/commands/review-knowledge.md` - Knowledge base review command
  - `<CONFIG_PATH>/commands/user/context.md` - Context loading command
  - `<CONFIG_PATH>/skills/note-taking/SKILL.md` - Note-taking and knowledge management skill
  - `<CONFIG_PATH>/skills/planner/SKILL.md` - Task planning and organization skill
- Copies every file from the repository's `agents/` directory into `<CONFIG_PATH>/agents/`
- Ensures the required subfolders exist before writing each file
- Prompts for confirmation before overwriting any existing destination file
- If `--config-path` differs from `~/.claude`, offers to create symlinks into `~/.claude`

### 3. Create Required Directories

The setup script does not create your working data directories (only the configuration files). Create them once:

```bash
# Replace with your --notes-folder path from step 2
mkdir -p /path/to/your/notes/folder/tasks_notes
mkdir -p /path/to/your/notes/folder/knowledge_base
```

### 4. Configure Claude Code

If you used the default `--config-path` (`~/.claude`), this step is already complete. Otherwise, link your generated files into Claude Code manually:

```bash
# Create symlinks from ~/.claude to your config folder
ln -s /path/to/your/config/folder/CLAUDE.md ~/.claude/CLAUDE.md
ln -s /path/to/your/config/folder/agents ~/.claude/agents
ln -s /path/to/your/config/folder/commands ~/.claude/commands
ln -s /path/to/your/config/folder/skills ~/.claude/skills
```

**Example:**
```bash
# If you ran setup with --config-path ~/my-claude-config
ln -s ~/my-claude-config/CLAUDE.md ~/.claude/CLAUDE.md
ln -s ~/my-claude-config/agents ~/.claude/agents
ln -s ~/my-claude-config/commands ~/.claude/commands
ln -s ~/my-claude-config/skills ~/.claude/skills
```

**Benefits of symlinks:**
- Changes to the repository are immediately available to Claude Code
- Easy to track changes with git
- No need to copy files manually after updates

Refer to [Claude Code documentation](https://docs.claude.com/en/docs/claude-code/overview) for more information on custom commands and agents.
