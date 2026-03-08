---
name: convention-extractor
description: >
  Reads source files and extracts implicit coding conventions — naming, error handling,
  testing, imports. Used by gap analysis to find conventions not captured in config.
allowed-tools:
  - Read
  - Glob
  - Grep
---

## Task

Read 3-5 representative files from each major directory. Extract the implicit conventions:

1. **Naming patterns** — files, variables, components, functions
2. **Import ordering** — structure and grouping
3. **Error handling** — patterns used per layer
4. **Styling approach** — CSS modules? Tailwind? styled-components?
5. **Testing patterns** — framework, describe/it structure, mocking approach
6. **API patterns** — endpoint structure, auth handling
7. **Undocumented conventions** — patterns consistent across files but NOT documented in `.claude/`

## Approach

- Use Glob to find source files in each major directory
- Read 3-5 representative files per directory (pick files of varying complexity)
- Look for consistent patterns that repeat across files
- Focus on patterns that are non-obvious or easy to break

## Output

Write findings to `./audit/conventions-found.md` with clear sections per convention type.
