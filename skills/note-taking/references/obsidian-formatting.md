# Obsidian Formatting Standards

Reference guide for formatting knowledge base entries in Obsidian.

## Table of Contents
- [[#Required Structure]]
- [[#Wikilinks]]
- [[#Callouts]]
- [[#Tables]]
- [[#Code Blocks]]
- [[#Cross-Referencing]]

## Required Structure

**Every knowledge base entry MUST follow this structure:**

```markdown
# Title

## Metadata
- **Created**: YYYY-MM-DD
- **Last Updated**: YYYY-MM-DD
- **Tags**: #domain #content-type
- **Related**: [[Related Note 1]], [[Related Note 2]]

## Overview
Brief description with key [[wikilinks]] to related concepts.

> [!info] Key Concepts
> Summary callout highlighting main points.

## Table of Contents
- [[#Section 1]]
- [[#Section 2]]
- [[#Section 3]]

## [Content sections...]

## Related Topics
- [[Note Name]] - Brief description
- [[Another Note]] - Brief description

## External References
- [Official Documentation](https://example.com)
- [Related Resource](https://example.com)
```

## Wikilinks

- **Internal references**: Use `[[Note Name]]` for all cross-references
- **Section links**: Use `[[Note Name#Section]]` for specific sections
- **Same-document**: Use `[[#Section Name]]` for internal navigation
- **Concepts**: Link related concepts even if notes don't exist yet

**Examples:**
```markdown
See [[Project Setup]] for initial configuration.
Configure [[Claude Code#Notification System]] for alerts.
Jump to [[#Troubleshooting]] section below.
```

## Callouts

Use Obsidian callouts to highlight important information:

| Callout | Purpose |
|---------|---------|
| `> [!info]` | Key concepts, definitions, overviews |
| `> [!tip]` | Recommended approaches, best practices |
| `> [!warning]` | Cautions, limitations, potential issues |
| `> [!success]` | Confirmed working solutions, positive outcomes |
| `> [!bug]` | Known issues, troubleshooting sections |
| `> [!check]` | Checklists, verification steps |
| `> [!note]` | Additional context, side notes |

**Example:**
```markdown
> [!tip] Recommended Approach
> Use hooks for reliable notifications with minimal performance impact.

> [!warning] Breaking Changes
> Version 2.0 introduces incompatible API changes.
```

## Tables

Use tables for:
- Command references
- Configuration options
- Comparison matrices
- Event/trigger mappings

**Example:**
```markdown
| Command | Description | Use Case |
|---------|-------------|----------|
| `git status` | Show working tree status | Daily workflow |
| `git diff` | Show changes | Code review |
```

## Table of Contents

**Always include** for documents with 3+ main sections:
```markdown
## Table of Contents
- [[#Installation]]
- [[#Configuration]]
- [[#Troubleshooting]]
- [[#Best Practices]]
```

## Metadata Standards

**Required fields:**
- **Created**: Initial creation date
- **Last Updated**: Most recent content change
- **Tags**: Domain + content type tags (see SKILL.md for tag list)
- **Related**: Key cross-references

## Code Blocks

- **Language specification**: Always specify language for syntax highlighting
- **Context**: Provide setup context before code blocks
- **Working examples**: Ensure all code examples are functional

## Cross-Referencing

**Enhance graph connectivity:**
- Link to related tools: `[[Git]]`, `[[VS Code]]`
- Link to techniques: `[[Troubleshooting]]`, `[[Configuration]]`
- Link to concepts: `[[Authentication]]`, `[[Caching]]`
- Create hub pages for major topics

**Example:**
```markdown
This [[API Client]] configuration works with [[Authentication]] setup.
See [[Troubleshooting#Network Issues]] for connectivity problems.
Related: [[Caching]] and [[Configuration Management]].
```

**From Task Notes to Knowledge Base:**
- Reference existing knowledge: "See [[Best Practices]] for recommended patterns"
- Identify new knowledge: "This solution could enhance [[Tools]] section"
- Link discoveries: "Related to previous work in [[Performance Optimization]]"
