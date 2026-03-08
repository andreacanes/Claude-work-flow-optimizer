---
name: config-inventory
description: >
  Reads all .claude/ files, CLAUDE.md files, and .mcp.json.
  Summarizes current config coverage for gap analysis comparison.
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash(ls:*)
---

## Task

Read every file in `.claude/` (agents, skills, rules), all CLAUDE.md files (root, subdirectories, `.claude/CLAUDE.md`), `.mcp.json`, and any other AI-tool config files. For each one, produce:

1. **One-line summary** of what it covers
2. **References** — anything referenced that doesn't exist (broken links, missing skills, etc.)
3. **Coverage map** — what areas of the codebase each config file addresses

## Approach

- Find all CLAUDE.md files: root, `.claude/CLAUDE.md`, subdirectory CLAUDE.md files
- List all files in `.claude/rules/`, `.claude/skills/`, `.claude/agents/`
- Read `.mcp.json` if it exists
- Scan for other AI-tool configs that may contain conventions to migrate:
  - `.cursor/rules/*.mdc` or `.cursor/rules/*.md`
  - `.windsurfrules`
  - `.aider*` config files
  - `.continue/` directory
- Read each file and write a one-line summary
- Check for cross-references that don't resolve (e.g., CLAUDE.md mentions a skill that has no SKILL.md)
- Note which conventions from other AI tools could be migrated to Claude Code format

## Output

Write findings to `./audit/current-config.md` with:
- Summary table of all config files
- Broken references list
- Coverage gaps (areas of codebase with no config coverage)
