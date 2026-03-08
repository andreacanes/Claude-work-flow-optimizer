---
name: project-bootstrapper
description: >
  Generate initial Claude Code config for a project from scratch.
  Use when the user says "bootstrap", "initialize claude config",
  "set up claude for this project", "create claude config",
  or when working in a project with no .claude/ directory.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(git:*)
  - Bash(ls:*)
  - Bash(mkdir:*)
  - Bash(wc:*)
  - Bash(find:*)
  - Bash(bash:*)
  - Bash(curl:*)
  - Agent
context:
  - references/bootstrap-template.md
---

## Pre-check

Before starting, check if `.claude/` already has substantial config:

```bash
ls .claude/ 2>/dev/null && ls .claude/rules/ 2>/dev/null && ls .claude/skills/ 2>/dev/null && ls .claude/agents/ 2>/dev/null
```

- If `.claude/` has rules, skills, or agents already → tell the user this project already has config and suggest `/cwfo:claude-config-gap-analysis` (for deep analysis) or `/cwfo:config-updater` (for incremental updates) instead. **Stop here.**
- If `.claude/` is empty or doesn't exist → proceed with bootstrapping.

## Setup

Best-practice reference files are cached at `~/.cache/cwfo/best-practice/`. Check if they exist:

```bash
ls ~/.cache/cwfo/best-practice/*.md 2>/dev/null | head -1
```

If missing or you want to refresh, fetch them:

```bash
mkdir -p ~/.cache/cwfo/best-practice && for f in claude-memory.md claude-skills.md claude-subagents.md claude-mcp.md claude-commands.md claude-cli-startup-flags.md claude-settings.md; do curl -sS -f -o ~/.cache/cwfo/best-practice/$f "https://raw.githubusercontent.com/shanraisshan/claude-code-best-practice/main/best-practice/$f"; done
```

## Phase 1: Investigate (Parallel Subagents)

Spawn these 4 investigation subagents simultaneously. Each explores the codebase independently and writes findings to `./audit/` as a handoff file.

Create `./audit/` directory first:

```bash
mkdir -p ./audit
```

### Subagent 1: Codebase Map

Use the `codebase-mapper` agent. It will explore the entire project structure and document:
- What framework/language/tool is used per directory
- What patterns and conventions are visible in the actual code
- What file types exist and where
- What the build/deploy/test pipeline looks like

Output: `./audit/codebase-map.md`

### Subagent 2: Convention Extraction

Use the `convention-extractor` agent. It will read 3-5 representative files from each major directory and extract:
- Naming patterns (files, variables, components, functions)
- Import ordering and structure
- Error handling patterns
- Styling approach
- Testing patterns
- API patterns

Output: `./audit/conventions-found.md`

### Subagent 3: Workflow Analysis

Use the `workflow-analyzer` agent. It will examine package.json scripts, CI configs, Makefiles, Dockerfiles, deploy scripts, git hooks, PR templates. Maps out:
- How code goes from local dev to production
- What linting/formatting is enforced
- Testing stages
- External services

Output: `./audit/workflows-found.md`

### Subagent 4: Current Config Inventory

Use the `config-inventory` agent. It will read every file in `.claude/`, all CLAUDE.md files, and `.mcp.json`. Produces:
- One-line summary per config file (if any exist)
- Coverage gaps
- Starting point assessment

Output: `./audit/current-config.md`

## Phase 2: Design Config Plan

After all 4 subagents complete, read their outputs:

```
./audit/codebase-map.md
./audit/conventions-found.md
./audit/workflows-found.md
./audit/current-config.md
```

Also read the best-practice references from `~/.cache/cwfo/best-practice/`:
- `claude-memory.md` — for CLAUDE.md and rules design
- `claude-skills.md` — for skill design
- `claude-subagents.md` — for agent design

### Apply Decision Framework

For each finding from the agents, categorize using this order:

1. **Permanent project truth** (tech stack, structure, workflow, quality bar) → CLAUDE.md
2. **Path-specific convention** (naming, imports, patterns per directory) → Rule with `paths:`
3. **Complex recurring multi-step workflow** → Skill
4. **Parallelizable or isolatable task** → Agent
5. **External API or persistent state** → MCP (note only, don't configure)

### Present Plan to User

Before generating anything, present the complete plan:

- Proposed CLAUDE.md outline with estimated line count (target < 200)
- List of proposed rules with their `paths:` globs and one-line descriptions
- List of proposed skills (if any) with descriptions
- List of proposed agents (if any) with descriptions
- Estimated context budget (CLAUDE.md lines + rule count + skill description tokens)

**Wait for user approval before proceeding to Phase 3.**

## Phase 3: Generate Config (User-Approved)

Only generate what the user approved.

### 3a. Create directory structure

```bash
mkdir -p .claude/rules .claude/skills .claude/agents
```

### 3b. Generate CLAUDE.md

Follow the template from `references/bootstrap-template.md`. Keep under 200 lines. Include:
- Project name and purpose
- Tech stack (from codebase-map)
- Project structure overview (from codebase-map)
- Development workflow (from workflows-found)
- Quality bar (from conventions-found)
- Skill inventory (if any skills created)

### 3c. Generate Rules

For each approved rule:
- Use naming convention: `{domain}-{convention}.md`
- Include appropriate `paths:` glob in frontmatter
- Keep body to ~5-10 lines
- Before writing, verify the `paths:` glob resolves to actual files:

```bash
find . -path './.git' -prune -o -path '{glob}' -print | head -5
```

If zero matches, warn the user and adjust the glob.

### 3d. Generate Skills (only if clearly needed)

Only create skills for complex, multi-step, recurring workflows. Most projects need zero skills at bootstrap. If created:
- SKILL.md with clear description and allowed-tools
- Reference files if the methodology is complex

### 3e. Generate Agents (only if clearly needed)

Only create agents for genuinely parallelizable or isolatable tasks. Most projects need zero agents at bootstrap.

### 3f. Quick Structural Validation

After generating all config, run a quick validation:
- CLAUDE.md line count < 200
- All rule `paths:` globs resolve to at least one file
- No duplicate rule filenames
- Skill descriptions are 1-2 sentences
- Total estimated always-on context < 5% of context window

Report any issues found.

### 3g. Cleanup

Delete the audit directory:

```bash
rm -rf ./audit
```

## Key Constraint

Err on the side of LESS config. A project is better served by a lean, accurate CLAUDE.md + a few precise rules than by comprehensive but noisy configuration. The maintenance loop (`config-awareness` rule → `config-updater` → `audit`) handles drift going forward. Bootstrap should create the minimum viable config.
