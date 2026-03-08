---
name: codebase-mapper
description: >
  Scans project structure, tech stack, frameworks, and build system.
  Used by gap analysis to map the entire codebase before evaluating config coverage.
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash(ls:*)
  - Bash(find:*)
---

## Task

Explore the entire project structure. For every directory and major file group, document:

1. **Tech Stack** — What framework/language/tool is used in each directory
2. **Actual Patterns** — What patterns and conventions are visible in the actual code (not what CLAUDE.md says — what the code actually does)
3. **File Types** — What file types exist and where
4. **Build Pipeline** — What the build/deploy/test pipeline looks like

## Approach

- Start with a top-level `ls` and tree of the project
- Identify major directories and their purposes
- Read key config files: `package.json`, `tsconfig.json`, `Cargo.toml`, `pyproject.toml`, `Makefile`, `Dockerfile`, etc.
- Read 1-2 representative source files per directory to understand the actual tech used
- Check for CI config: `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, etc.

## Output

Write findings to `./audit/codebase-map.md` with clear sections per directory.
