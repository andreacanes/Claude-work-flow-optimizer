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

Read every file in `.claude/` (agents, skills, rules), all CLAUDE.md files (root, subdirectories, `.claude/CLAUDE.md`), and `.mcp.json`. For each one, produce:

1. **One-line summary** of what it covers
2. **References** — anything referenced that doesn't exist (broken links, missing skills, etc.)
3. **Coverage map** — what areas of the codebase each config file addresses

## Approach

- Find all CLAUDE.md files: root, `.claude/CLAUDE.md`, subdirectory CLAUDE.md files
- List all files in `.claude/rules/`, `.claude/skills/`, `.claude/agents/`
- Read `.mcp.json` if it exists
- Read each file and write a one-line summary
- Check for cross-references that don't resolve (e.g., CLAUDE.md mentions a skill that has no SKILL.md)

## Output

Write findings to `./audit/current-config.md` with:
- Summary table of all config files
- Broken references list
- Coverage gaps (areas of codebase with no config coverage)
