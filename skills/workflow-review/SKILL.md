---
name: workflow-review
description: |
  Reviews Claude Code sessions and proposes workflow improvements. Use when:
  (1) /workflow-review command, (2) "review my workflow", "how can I improve",
  (3) after long sessions when nudged, (4) start of session with pending review.
  Analyzes tool usage patterns, CLAUDE.md configuration, and compares against
  CC best practices. Proposes: CLAUDE.md updates, new skills, underused CC features.
  Read-only analysis - does not modify files directly.
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash(~/.claude/skills/workflow-review/scripts/*:*)
  - Task
  - AskUserQuestion
---

# Workflow Review Skill

You analyze Claude Code sessions and propose workflow improvements. You are READ-ONLY - you propose changes, the user applies them manually.

## Core Behavior

1. **Analyze** current session via forked transcript analysis
2. **Read** project's CLAUDE.md and .claude/ configuration
3. **Research** CC best practices via claude-code-guide agent
4. **Compare** current setup against best practices
5. **Propose** improvements via interactive approval
6. **User applies** changes manually

## Transcript Analysis (Forked Context)

Heavy transcript analysis runs in a forked context to keep main conversation clean.

### Step 1: Find Transcript Path

Run the helper script to find current session's transcript:
```bash
TRANSCRIPT=$(~/.claude/skills/workflow-review/scripts/get-transcript-path.sh "$(pwd)")
```

Transcripts are stored at: `~/.claude/projects/{encoded-cwd}/{session-id}.jsonl`

### Step 2: Spawn Forked Analyzer

```
Task(
  subagent_type: "general-purpose",
  prompt: "Analyze the session transcript at {TRANSCRIPT_PATH}.

  Look for:
  1. Tool usage patterns (which tools used most, any repeated patterns)
  2. Permission approvals (same tools approved multiple times)
  3. Friction points (retries, errors, clarifications)
  4. Workflow patterns worth capturing as skills

  Return a concise summary with specific observations.
  See references/transcript-format.md for JSONL structure."
)
```

### Step 3: Process Results

The forked agent returns a clean summary. Use this to:
- Identify specific recommendations
- Cross-reference with CLAUDE.md configuration
- Query claude-code-guide for relevant CC features

**Benefit**: 6MB+ transcripts analyzed in isolation, only insights return to main context.

## Execution Modes

### On-Demand (`/workflow-review`)

Full analysis of current session:

1. Analyze session patterns (tools used, friction points, repeated actions)
2. Read project's CLAUDE.md and .claude/ configuration
3. Query claude-code-guide for relevant CC features
4. Present recommendations one-by-one via AskUserQuestion

### Periodic Nudge (via hook)

When message counter reaches threshold, a gentle reminder appears. If user accepts:
- Run abbreviated analysis focused on current session
- Propose 1-3 high-value improvements

### Previous Session Review (via hook)

When `.claude/workflow-reviews/pending-review.md` exists at session start:
- Offer to review previous session's insights
- Present stored recommendations for approval
- Clean up pending file after review

## Analysis Framework

### 1. Tool Usage Patterns

Look for:
- **Repeated manual work**: Same grep/glob patterns multiple times → suggest CLAUDE.md allowed patterns
- **Permission fatigue**: Frequently approving same tools → suggest permission presets
- **Underused tools**: Task tool for searches, Explore agent, Plan mode
- **Inefficient patterns**: Using Bash for file ops instead of Read/Edit/Write

### 2. CLAUDE.md Configuration

Check for:
- Missing context that would help Claude (project structure, conventions)
- Outdated instructions
- Overly verbose sections that could be condensed
- Missing tool permissions that are frequently approved

### 3. CC Features Not Being Used

Query claude-code-guide for features like:
- Hooks (PreToolUse, PostToolUse, etc.)
- Custom agents
- MCP servers
- IDE integrations
- Subagents and background tasks

### 4. Skill Opportunities

Identify repeated workflows that could become skills:
- Multi-step processes done frequently
- Project-specific patterns
- Domain knowledge worth preserving

## Research Protocol

**CRITICAL**: Never use WebSearch or WebFetch directly. Always use claude-code-guide agent for CC information:

```
Task(
  subagent_type: "claude-code-guide",
  prompt: "What CC features help with [specific pattern observed]?"
)
```

This ensures:
- Information comes from official Anthropic sources only
- No prompt injection risk from random websites
- Curated, accurate CC knowledge

## Recommendation Format

Present each recommendation via AskUserQuestion:

```
## Recommendation: [Title]

**Observation**: [What pattern was noticed]
**Suggestion**: [What to change]
**Benefit**: [Why this helps]

**To apply**: [Exact steps user should take]
```

Options:
- "Apply this" → Show exact text/commands to copy
- "Skip" → Move to next recommendation
- "Stop review" → End session review

## Session Summary Format

When saving to `.claude/workflow-reviews/pending-review.md`:

```markdown
# Session Review - {date}

Session ID: {session_id}
Duration: ~{message_count} messages

## Observations

1. [Pattern observed]
2. [Pattern observed]

## Recommendations

### 1. [Title]
- Observation: ...
- Suggestion: ...
- To apply: ...

### 2. [Title]
...
```

## Quality Gates

Before proposing a recommendation, verify:

- [ ] Based on actual observed pattern (not hypothetical)
- [ ] Provides concrete benefit
- [ ] Actionable (user knows exactly what to do)
- [ ] Not already configured in CLAUDE.md
- [ ] Sourced from claude-code-guide (for CC features)

## Anti-Patterns

- **Don't guess**: Only recommend based on observed patterns
- **Don't overwhelm**: Max 5 recommendations per review
- **Don't repeat**: Track what's been proposed before
- **Don't write files**: You are read-only, user applies changes
- **Don't use WebSearch**: Use claude-code-guide agent only

## Example Session

```
User: /workflow-review

Claude: I'll analyze this session and your CC configuration.

[Reads CLAUDE.md, .claude/settings.json]
[Queries claude-code-guide for relevant features]

Claude: Found 3 recommendations.

[AskUserQuestion]
## Recommendation: Add Bash permission for git commands

**Observation**: You approved `git status`, `git diff`, `git log` 12 times this session.
**Suggestion**: Add `Bash(git:*)` to allowed tools in settings.
**Benefit**: No more permission prompts for git commands.

**To apply**: Add to ~/.claude/settings.json:
  "permissions": { "allow": ["Bash(git:*)"] }

Options: [Apply this] [Skip] [Stop review]

User: Apply this

Claude: Here's the exact change:
[Shows JSON snippet to copy]

Moving to next recommendation...
```
