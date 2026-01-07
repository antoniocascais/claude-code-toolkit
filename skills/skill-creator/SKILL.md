---
name: skill-creator
description: Creates new Claude Code skills with proper structure and best practices. Use when user wants to create a skill, add a new command, scaffold a workflow, or asks "how do I make a skill".
allowed-tools: Read Glob Grep AskUserQuestion
---

# Skill Creator

Creates Claude Code skills following official best practices.

**Official spec**: https://agentskills.io/specification (append `.md` for markdown)

## Core Principles

### Only Add What Claude Doesn't Have
Claude is already smart. Only include domain-specific context it lacks:
- API quirks, library gotchas, edge cases
- Your org's conventions and patterns
- Domain knowledge not in training data

### Degrees of Freedom
Match instruction specificity to task fragility:

| Level | When | Example |
|-------|------|---------|
| **High freedom** | Multiple valid approaches | Code review (heuristics, not rigid steps) |
| **Medium freedom** | Preferred pattern exists | Reports (customizable scripts) |
| **Low freedom** | Fragile operations | DB migrations (exact commands, no deviation) |

### Progressive Disclosure
Context loads in 3 levels:
1. **Metadata** (~100 words) - name + description, always in context
2. **SKILL.md body** (<5000 words) - loaded when skill triggers
3. **Resources** (unlimited) - scripts/, references/, templates/ loaded as needed

## Workflow

### Step 1: Gather Requirements

Use AskUserQuestion to collect:

1. **Skill name** - lowercase, hyphens only, ≤64 chars
   - Good: `pdf-processor`, `code-reviewer`, `deploy-helper`
   - Bad: `PDF_Processor`, `my cool skill`

2. **Description** - what it does + when to use it
   - Third person ("Processes...", "Generates...")
   - Include ALL trigger keywords in description (primary discovery mechanism)
   - Example: "Processes PDF files to extract text and tables. Use when working with PDFs, extracting document content, or converting PDF to markdown."

3. **Allowed tools** (optional) - restrict capabilities (space-delimited)
   - Read-only: `Read Glob Grep`
   - With Bash patterns: `Read Write Bash(git:*) Glob Grep`
   - Subcommand restriction: `Bash(git diff:*) Bash(git status:*) Read`
   - Unrestricted: omit field entirely

4. **Complexity** - determines resource structure
   - Simple: SKILL.md only
   - Medium: + references/ for docs
   - Complex: + scripts/ for automation, templates/ for output

### Step 2: Validate Name

```
- Only lowercase letters, numbers, hyphens
- No leading/trailing hyphens
- ≤64 characters
- Not reserved: anthropic, claude, official
```

### Step 3: Generate Skill

**Default location**: `~/.claude/skills/{skill-name}/`

Create `SKILL.md` with:

```yaml
---
name: {skill-name}
description: {description}
allowed-tools: {tools}  # space-delimited, omit if unrestricted
---
```

Generate skill body matching the degree of freedom needed. Use imperative/infinitive form for instructions.

### Step 4: Post-Creation

```
✅ Skill created at: ~/.claude/skills/{skill-name}/

⚠️  Restart Claude Code to load the new skill.
```

### Step 5: Iterate (User)

Inform user of the iteration loop:
1. Test skill on real tasks
2. Note where Claude struggles or produces poor output
3. Return to refine SKILL.md or add references/scripts
4. Repeat until quality is consistent

## Workflow Patterns

**Sequential**: Step 1 → 2 → 3 (most skills)
**Conditional**: Decision trees based on input type or user choice (see `webapp-testing/`)
**Multi-phase**: Plan → validate → execute → verify (for destructive operations)

### Enforcing Phase Gates

Claude tends to rush ahead. To force hard stops between phases, use `AskUserQuestion` as a gate:

```markdown
## Phase 1: Gather Input

**STOP. Use AskUserQuestion before proceeding.**

[phase instructions...]

**Do NOT proceed to Phase 2 until user responds.**

## Phase 2: Confirm Understanding

**STOP. Use AskUserQuestion to confirm before execution.**

[present what you understood, then ask confirmation...]

**Do NOT proceed to Phase 3 until user confirms.**
```

Key elements:
- Bold **STOP** directive at phase start
- Explicit instruction to use `AskUserQuestion`
- Clear "do NOT proceed until..." at phase end

## Resource Types

| Type | Purpose | Context Loading |
|------|---------|-----------------|
| `scripts/` | Executables for deterministic tasks | Run as black-box, don't read into context |
| `references/` | Documentation, API specs | Loaded on-demand when needed |
| `templates/` | Output scaffolds (HTML, PPTX) | Used for generation, not loaded into context |
| `assets/` | Images, fonts, static files | Never loaded into context |

**Anti-patterns**: No README.md, CHANGELOG.md, INSTALLATION_GUIDE.md - only include what Claude needs to execute.

## Skill Spec (Condensed)

### Required Frontmatter
- `name`: lowercase, hyphens, ≤64 chars
- `description`: what + when (triggers), third person, ≤1024 chars

### Optional Frontmatter
- `allowed-tools`: space-delimited pre-approved tools (e.g., `Read Glob Bash(git:*)`)
- `license`: e.g., "MIT"

### Body Guidelines
- Keep under 500 lines
- Use progressive disclosure: split to references/ when approaching limit
- No time-sensitive information
- Consistent terminology

### Directory Structure
```
skill-name/
├── SKILL.md           # Required entry point
├── scripts/           # Executables (run, don't read)
├── references/        # Docs loaded as needed
├── templates/         # Output scaffolds
└── assets/            # Static files (images, fonts)
```

### Reference Files
- Keep one level deep from SKILL.md (no nested references)
- Files >100 lines should include a TOC at the top

## Examples

Clone the official repo for real examples:

```bash
git clone https://github.com/anthropics/skills.git /tmp/claude-skills-examples
```

**Example patterns:**

| Skill | Shows |
|-------|-------|
| `mcp-builder/` | reference/ + scripts/ |
| `algorithmic-art/` | templates/ for HTML output |
| `docx/` | scripts/ + scripts/templates/ + reference docs |
| `pptx/` | Complex: scripts/, ooxml/, multiple reference docs |
| `skill-creator/` | Meta: references/workflows.md, init/package scripts |

**Tooling** (in cloned repo):
- `skill-creator/scripts/init_skill.py` - scaffolds new skill directory
- `skill-creator/scripts/package_skill.py` - validates and packages skill

## Best Practices Checklist

Before finalizing:

- [ ] Description is third person with ALL trigger keywords
- [ ] SKILL.md under 500 lines (split to references/ if needed)
- [ ] Degree of freedom matches task fragility
- [ ] No hardcoded paths or time-sensitive info
- [ ] Consistent terminology throughout
- [ ] Reference files >100 lines have TOC
- [ ] Scripts are black-box (documented inputs/outputs, not read into context)
