# Task Type Taxonomy

Routing rules for classifying tasks into typed folders.

## Contents
- Type Definitions: work, learning, product, content, career, admin
- Classification Algorithm
- Priority Inference
- Ambiguous Cases

## Type Definitions

### work
**Folder:** `work/`
**Description:** Job-related deliverables, meetings, professional responsibilities

**Trigger Keywords:**
- job, work, sprint, standup
- meeting, 1:1, sync, review
- PR, deploy, release, hotfix
- deliverable, deadline, ticket
- oncall, incident, page

**Examples:**
- "Fix prod auth bug"
- "1:1 with manager"
- "Review PR #234"
- "Deploy v2.3 to staging"
- "Write design doc for caching"

---

### learning
**Folder:** `learning/`
**Description:** Skill development, courses, experiments, reading

**Trigger Keywords:**
- learn, study, practice
- course, tutorial, workshop
- read, paper, book
- experiment, try, explore
- certificate, certification

**Examples:**
- "RAG tutorial from LangChain docs"
- "Read Attention is All You Need paper"
- "Practice Go concurrency patterns"
- "Complete AWS Solutions Architect module 3"
- "Experiment with vector DBs"

---

### product
**Folder:** `product/`
**Description:** Personal projects, side builds, apps

**Trigger Keywords:**
- build, ship, launch
- app, feature, MVP
- side project, personal project
- prototype, demo
- startup, product

**Examples:**
- "Legal helper MVP"
- "Add auth to habit tracker"
- "Ship v1 of CLI tool"
- "Build Discord bot for server"
- "Prototype AI writing assistant"

---

### content
**Folder:** `content/`
**Description:** Content creation - writing, videos, social

**Trigger Keywords:**
- blog, post, article
- tweet, thread, social
- video, demo, screencast
- newsletter, write
- publish, share

**Examples:**
- "Write RAG blog post"
- "Record demo video for tool"
- "Twitter thread on LLM agents"
- "Newsletter issue #5"
- "LinkedIn post about new job"

---

### career
**Folder:** `career/`
**Description:** Job search, networking, professional growth

**Trigger Keywords:**
- job search, apply, application
- interview, prep, mock
- resume, CV, portfolio
- network, connect, coffee chat
- LinkedIn, recruiter
- salary, negotiate, offer

**Examples:**
- "Update LinkedIn profile"
- "Apply to 3 SRE roles"
- "Mock interview with friend"
- "Coffee chat with ex-colleague"
- "Research company X salary bands"

---

### admin
**Folder:** `admin/`
**Description:** Life admin, errands, miscellaneous

**Trigger Keywords:**
- errand, appointment
- pay, bill, renew
- schedule, book
- misc, other
- call, email (personal)
- buy, order

**Examples:**
- "Dentist appointment"
- "Renew driver's license"
- "Pay electricity bill"
- "Book flight for vacation"
- "Order new keyboard"

## Classification Algorithm

1. **Exact match:** Check if task contains type name ("work task" → work)
2. **Keyword scan:** Match trigger keywords (case-insensitive)
3. **Context inference:** Use surrounding conversation context
4. **Ask user:** If ambiguous, ask for classification
5. **Default:** If truly unknown, use `_inbox`

## Priority Inference

- "urgent", "asap", "critical", "blocker" → high
- "soon", "this week", "important" → high
- "when you can", "backlog", "someday" → low
- Default → medium

## Ambiguous Cases

**Learning vs Product:**
- "Build X to learn Y" → learning (skill focus)
- "Build X to ship" → product (outcome focus)

**Work vs Career:**
- Current job tasks → work
- Future job tasks → career

**Content vs Learning:**
- "Write about X to share" → content
- "Write about X to understand" → learning (notes)
