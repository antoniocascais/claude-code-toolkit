# Obsidian Tasks Plugin Cheatsheet

Reference for using the Tasks community plugin in planner markdown files.

## Writing Tasks

Standard markdown checkboxes work:
```
- [ ] Do something
- [x] Done thing
```

Optional metadata (inline):
```
- [ ] Task with due date 📅 2026-01-20
- [ ] High priority ⏫
- [ ] Task with start date 🛫 2026-01-19
```

## Query Blocks

Add anywhere in a file to show filtered tasks:

````markdown
```tasks
not done
path includes week-plan-2026-01-19
hide backlink
hide edit button
```
````

## Useful Filters

| Filter | Description |
|--------|-------------|
| `not done` | Incomplete only |
| `done` | Completed only |
| `path includes <filename>` | From specific file |
| `path includes planner` | From folder |
| `description includes ⚠️` | Text search |
| `due before 2026-01-25` | By date |

## Display Options

| Option | Effect |
|--------|--------|
| `hide backlink` | Cleaner look |
| `hide edit button` | Remove edit icon |
| `group by heading` | Groups (but alphabetical!) |
| `sort by due` | Sort by due date |
| `limit 10` | Cap results |

## Tips

- **Document order matters**: `group by heading` sorts alphabetically, not chronologically. Keep tasks in chronological order in source file and avoid grouping, or accept alphabetical grouping.
- **Emoji markers**: Use ⚠️, 🔴 etc. for priority filtering via `description includes`
- **Cross-file queries**: Query blocks can pull tasks from multiple files across vault
- **Vault scope**: Tasks plugin indexes from vault root - ensure your planner folder is within the Obsidian vault

## Example: Week Plan Query Block

```markdown
## Tasks View

### All Incomplete
```tasks
not done
path includes week-plan-2026-01-19
hide backlink
hide edit button
```

### Critical Only
```tasks
not done
path includes week-plan-2026-01-19
description includes ⚠️
hide backlink
hide edit button
```
```

## Setup

1. Open vault in Obsidian
2. Settings → Community plugins → Turn on community plugins
3. Browse → search "Tasks" → Install → Enable
4. Plugin creates `.obsidian/plugins/obsidian-tasks-plugin/`
