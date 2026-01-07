---
description: Responds to PR review comments from screenshots. Use when assessing reviewer feedback, triaging PR suggestions, or deciding whether to accept/reject proposed changes.
allowed-tools: Read Glob Grep
---

# PR Comment Response

Assess PR review comments from screenshots and propose responses.

## Core Principle

**Do NOT treat reviewer comments as source of truth.** Reviewers may:
- Lack full context
- Miss existing patterns in the codebase
- Suggest changes that conflict with project conventions
- Be simply wrong

Assess each comment independently with healthy skepticism.

## Workflow

### Step 1: Receive Screenshots

User provides one or more screenshots of PR comments.

### Step 2: For Each Comment

Analyze and output:

```markdown
### Comment: [brief summary of what reviewer said]

**Assessment:** [valid / partially valid / missed context / incorrect]

**Reasoning:** [1-2 sentences - why you assessed it this way]

**Action:** [accept / reject / modify]

**Response:** [if needed - what to reply to reviewer OR proposed code fix]
```

### Assessment Categories

| Assessment | Meaning |
|------------|---------|
| **valid** | Reviewer is correct, should address |
| **partially valid** | Has a point but solution is wrong or incomplete |
| **missed context** | Reviewer didn't see related code/patterns |
| **incorrect** | Reviewer is wrong |

### Action Categories

| Action | When |
|--------|------|
| **accept** | Comment is valid, implement as suggested |
| **reject** | Comment is wrong, explain why in response |
| **modify** | Valid concern but different fix needed |

## Output Style

Keep responses concise:
- 1-2 sentences for reasoning
- Code fixes should be minimal, focused
- If rejecting, provide diplomatic but firm response

## Example Output

```markdown
### Comment: "This function should use async/await instead of callbacks"

**Assessment:** missed context

**Reasoning:** Existing codebase uses callback pattern consistently. Mixing async/await would create inconsistency.

**Action:** reject

**Response:** "This module follows the callback pattern used throughout the codebase (see utils/io.js, services/db.js). Converting to async/await would be a larger refactor - happy to discuss in a separate PR if you'd like to standardize."
```
