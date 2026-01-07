---
description: Generate security review report of repository code
argument-hint: SCOPE (diff|staged|all)
allowed-tools: Read Glob Grep Bash
thinking-triggers:
  - complexity: simple → standard budget (small repos, <20 files)
  - complexity: complex → "think hard" (medium repos, multiple languages/vulnerabilities)
  - complexity: critical → "ultrathink" (large codebases, complex attack vectors)
---

Perform a comprehensive security review of the current repository.

**IMPORTANT**: Execute immediately without asking for confirmation. Do not present a plan or ask "does this look good?" - proceed directly with the analysis.

## Workflow

### Step 1: Complexity Detection
Auto-detect and apply thinking budget:
- Large codebase (>50 files) + multiple languages = ultrathink
- Medium codebase (20-50 files) + potential vulnerabilities = think hard
- Small codebase (<20 files) = standard

### Step 1.5: Scope Detection
Determine review scope from $ARGUMENTS:
- **diff**: Only review files in `git diff` (uncommitted changes). Use `git diff --name-only` to get file list.
- **staged**: Only review files in `git diff --staged` (staged changes). Use `git diff --staged --name-only` to get file list.
- **commit:\<SHA\>**: Only review files changed in the specified commit. Use `git diff-tree --no-commit-id --name-only -r <SHA>` to get file list.
- **all** or empty: Review entire repository (default behavior)

### Step 2: Repository Scan
Based on the detected scope:
- **For diff/staged**: Read only the files returned by the respective `git diff` command
- **For commit:\<SHA\>**: Read only the files changed in that commit (use `git diff-tree --no-commit-id --name-only -r <SHA>`)
- **For all**: Read the current working directory and **respect `.gitignore`** (skip ignored files and typical build artifacts)

Use Bash to check gitignore status and get file lists, Glob to identify file patterns, Grep to search for security issues, and Read to analyze content.

### Step 3: Security Analysis Focus Areas

Focus on:
- **Attack vectors:** input handling, auth/authz, insecure defaults, injection (SQL/NoSQL/OS/LDAP), SSRF, path traversal, deserialization, RCE, weak crypto, insecure file perms
- **Secrets/PII & repo hygiene:** .env files, keys/certs, tokens, service-account JSON, API keys, dumps, credentials, .aws/credentials, *.pem/*.p12/*.keystore, and other files that should not be public
- **Dependency risks:** flag potentially vulnerable versions from manifest/lockfiles by name+version (no web lookups)
- **Misconfigurations:** Dockerfiles, CI/CD, IaC, security headers, debug flags, permissive CORS

### Step 4: Finding Documentation

For **each finding**, provide:
- **Severity:** Critical/High/Medium/Low
- **Location:** file path and approximate line(s)
- **Issue:** one-line title
- **Why risky:** 1–2 lines; cite obvious OWASP/CWE where applicable
- **Fix:** concrete remediation steps (or safer code pattern)
- **Snippet:** ≤6 lines; **redact secrets** (show first/last 4 chars only)

### Step 5: Generate Report

Output Markdown report with:
1. Table with columns: Severity | Location | Issue | Why Risky | Fix
2. **Top Risks (≤5)** — quick wins to tackle first
3. **Repo Hygiene checklist** — items to remove/rotate/move to secrets manager and any `.gitignore` additions
4. If nothing found, say "No issues from static review" and list 3–5 hardening suggestions

## Constraints
- Don't execute code or install packages
- Respect `.gitignore`; skip huge/binary files (note them if skipped)
- Keep the report concise (≤400 lines)
- Begin from current folder
- **Repository-only scope**: Only analyze files within the current repository. Do NOT consult external notes, knowledge base entries, or any files outside the repository being reviewed
