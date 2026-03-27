---
name: bootstrap
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
  - Agent
context:
  - references/bootstrap-template.md
  - ../shared-references/investigation-phase.md
  - references/generation-process.md
---

## Pre-check

Before starting, check if the project already has AI-tool config:

```bash
ls CLAUDE.md 2>/dev/null
ls .claude/ 2>/dev/null && ls .claude/rules/ 2>/dev/null && ls .claude/skills/ 2>/dev/null && ls .claude/agents/ 2>/dev/null
ls .cursor/rules/ 2>/dev/null
ls .windsurfrules 2>/dev/null
```

- If `.claude/` has rules, skills, or agents already → tell the user this project already has config and suggest `/cwfo:gap-analysis` (for deep analysis) or `/cwfo:updater` (for incremental updates) instead. **Stop here.**
- If a root `CLAUDE.md` already exists (but no `.claude/` directory) → warn the user: "This project has an existing CLAUDE.md but no `.claude/` config directory. Bootstrap will preserve the existing CLAUDE.md and build `.claude/` config around it. Proceed?" Wait for confirmation.
- If `.cursor/rules/` or `.windsurfrules` exist → note: "Found existing AI-tool config. The investigation phase will analyze these for conventions to migrate to Claude Code format."
- If none of the above exist → proceed with bootstrapping.

## Setup

Best-practice reference files are cached at `~/.cache/cwfo/best-practice/`. Check if they exist:

```bash
ls ~/.cache/cwfo/best-practice/*.md 2>/dev/null | head -1
```

If the cache directory is missing or empty, do NOT fetch inline. Tell the user:

> **Best-practice references not found.** Run `/cwfo:update` to fetch them. Without references, bootstrap will generate config based on codebase analysis only, not best-practice alignment.

If the user wants to proceed without references, continue with codebase analysis only.

## Phase 1: Investigate (Parallel Subagents)

Follow the investigation phase instructions from the loaded `investigation-phase.md` reference. Dispatch all 4 subagents in parallel and verify all audit files exist before proceeding.

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
2. **Path-specific convention, short** (5-10 lines, enforcement-style, glob pattern) → Rule with `paths:`
3. **Dense directory-specific context** (50+ lines, domain knowledge, only relevant when working there) → Subdirectory CLAUDE.md
4. **Complex recurring multi-step workflow** → Skill
5. **Parallelizable or isolatable task** → Agent
6. **External API or persistent state** → MCP (note only, don't configure)

### Present Plan to User

Before generating anything, present the complete plan:

- Proposed CLAUDE.md outline with estimated line count (target < 200)
- List of proposed rules with their `paths:` globs and one-line descriptions
- List of proposed subdirectory CLAUDE.md files (if any) with directory and rationale
- List of proposed skills (if any) with descriptions
- List of proposed agents (if any) with descriptions
- Estimated context budget (CLAUDE.md lines + rule count + skill description tokens)

**Wait for user approval before proceeding to Phase 3.**

## Phase 3: Generate Config (User-Approved)

Follow the generation process instructions from the loaded `generation-process.md` reference. This covers directory creation, CLAUDE.md generation, rules, subdirectory CLAUDE.md files, skills, agents, validation, and cleanup.

## Key Constraint

Err on the side of LESS config. A project is better served by a lean, accurate CLAUDE.md + a few precise rules than by comprehensive but noisy configuration. The maintenance loop (`config-awareness` rule → `config-updater` → `audit`) handles drift going forward. Bootstrap should create the minimum viable config.

## Finish

After all config is generated and validated, list all created files — including `.claude/scripts/plan-review-gate.sh` and `.claude/settings.local.json` — and ask once: "Commit these config changes?" — then stop.
