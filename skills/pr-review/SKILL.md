---
name: pr-review
description: Reviews code changes before merging. Use when reviewing PRs, checking staged changes, reviewing diffs, code review, merge readiness check, or validating changes before commit/push.
allowed-tools: Read Glob Grep Bash(git diff:*) Bash(git status:*) Bash(git log:*) Bash(git show:*) Bash(git branch:*) Bash(gitleaks:*) Bash(trufflehog:*) Bash(trivy:*) Bash(shellcheck:*) AskUserQuestion
---

# PR Review Skill

Reviews code changes with focus on quality, security, and consistency.

## Default Assumption: Public Repository

Unless explicitly stated otherwise, assume the repository is **publicly available on the internet**. This means:
- Any secret, credential, or API key pushed is considered compromised
- Internal URLs, IPs, hostnames should not be exposed
- Comments with sensitive internal context should be flagged
- Error messages should not leak internal architecture
- Be extra cautious with .env files, config files, CI/CD configs

## Phase 1: Determine Scope

**STOP. Use AskUserQuestion before anything else.**

Ask user to choose review scope:
- Staged files only
- Current branch vs main (PR-style)
- Specific commit range
- Other (specify)

**Do NOT run any git commands or tools until user responds.**

After user selects, get the diff:
- Staged: `git diff --cached`
- Branch vs main: `git diff main...HEAD`
- Commit range: `git diff <from>..<to>`

## Phase 2: Understand the Problem

**STOP. Use AskUserQuestion to confirm before proceeding to review.**

First, infer intent from:
1. Branch name: `git branch --show-current`
2. Commit messages: `git log main..HEAD --oneline` (or relevant range)

Then use AskUserQuestion to confirm:
> "Based on branch `feature/xyz` and commits, this PR appears to [inferred description]. Is this correct?"
> - Yes, proceed with review
> - No, let me explain

**Do NOT proceed to Phase 3 until user confirms the problem statement.**

## Phase 3: Review

### 3.1 Code Quality
- Best practices for the language/framework
- Readability and maintainability
- Error handling appropriateness
- Test coverage (if tests exist)

### 3.2 Codebase Consistency
- Match existing patterns in the repo
- Naming conventions alignment
- File organization consistency
- Don't introduce a 10th way of doing something

### 3.3 Security Review

**Automated scans** - only run tools relevant to changed files:

| File types | Tool | Command |
|------------|------|---------|
| Any | gitleaks | `gitleaks detect --source . --verbose --no-git` |
| Any | trufflehog | `trufflehog filesystem . --only-verified` |
| *.tf, *.tfvars | trivy | `trivy config <dir>` |
| *.yaml, *.yml (k8s) | trivy | `trivy config <dir>` |
| *.sh, *.bash | shellcheck | `shellcheck <file>` |

**Manual checks:**
- Hardcoded secrets, API keys, passwords
- SQL injection, XSS, command injection vectors
- Auth/authz bypasses
- Insecure defaults (http vs https, weak crypto)
- Sensitive data exposure in logs/errors

### 3.4 Bug Detection
- Obvious logic errors
- Off-by-one, null/undefined handling
- Race conditions
- Resource leaks
- Breaking changes to existing APIs

## Phase 4: Report

Output a succinct markdown report:

```markdown
## PR Review: [brief title]

**Problem:** [1-2 sentences on what this PR solves]

**Scope:** [staged/branch/commits reviewed]

### Security Scans
| Tool | Result |
|------|--------|
| gitleaks | [clean/N findings] |
| ... | ... |

### Findings

#### [Category: Security/Quality/Consistency/Bug]
- **[severity]** [file:line] - [issue with brief context]

### Rating: X/20
[One sentence justification]

### Suggestions
| Priority | Suggestion |
|----------|------------|
| blocker | ... |
| high | ... |
| medium | ... |
| minor | ... |
```

## Rating Scale

| Score | Meaning | Action |
|-------|---------|--------|
| 0-10 | Blocker issues | Reject, needs significant rework |
| 11-15 | Acceptable | Merge after addressing medium/minor fixes |
| 16-17 | Good | Ready to merge, minor suggestions optional |
| 18-20 | Excellent | High quality, merge immediately |

## Style Guidelines

Keep findings concise but contextual:
- Bad: "should use https here"
- Good: "using http exposes data in transit. upgrade to https"

- Bad: "fix this null check"
- Good: "user.email accessed without null check - crashes if user not found"

Don't write a 50-page report. Focus on what matters.
