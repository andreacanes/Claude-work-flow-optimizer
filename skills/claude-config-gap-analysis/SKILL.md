---
name: claude-config-gap-analysis
description: >
  Deep gap analysis of Claude Code config vs what the codebase actually needs.
  Use when the user says "gap analysis", "deep audit", "comprehensive review",
  "what config am I missing", or "analyze my project for claude config".
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash(git:*)
  - Bash(ls:*)
  - Bash(wc:*)
  - Bash(find:*)
  - Bash(bash:*)
  - Agent
---

## Setup

Best-practice reference files are cached at `~/.cache/cwfo/best-practice/`. Check if they exist:

```bash
ls ~/.cache/cwfo/best-practice/*.md 2>/dev/null | head -1
```

If missing or you want to refresh, fetch them:

```bash
mkdir -p ~/.cache/cwfo/best-practice && for f in claude-memory.md claude-skills.md claude-subagents.md claude-mcp.md claude-commands.md claude-cli-startup-flags.md claude-settings.md; do curl -sS -f -o ~/.cache/cwfo/best-practice/$f "https://raw.githubusercontent.com/shanraisshan/claude-code-best-practice/main/best-practice/$f"; done
```

## Phase 1: Understand the Codebase (Parallel Subagents)

Spawn these 4 investigation subagents simultaneously. Each explores the codebase independently and writes findings to `./audit/` as a handoff file.

Create `./audit/` directory first:

```bash
mkdir -p ./audit
```

### Subagent 1: Codebase Map

Use the `codebase-mapper` agent. It will explore the entire project structure and document:
- What framework/language/tool is used per directory
- What patterns and conventions are visible in the actual code (not what CLAUDE.md says)
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
- Consistent patterns NOT documented in `.claude/`

Output: `./audit/conventions-found.md`

### Subagent 3: Workflow Analysis

Use the `workflow-analyzer` agent. It will examine package.json scripts, CI configs, Makefiles, Dockerfiles, deploy scripts, git hooks, PR templates. Maps out:
- How code goes from local dev to production
- What linting/formatting is enforced
- Testing stages
- External services
- Manual processes that could benefit from automation

Output: `./audit/workflows-found.md`

### Subagent 4: Current Config Inventory

Use the `config-inventory` agent. It will read every file in `.claude/`, all CLAUDE.md files, and `.mcp.json`. Produces:
- One-line summary per config file
- References that don't resolve
- Coverage gaps

Output: `./audit/current-config.md`

## Phase 2: Gap Analysis (After All Subagents Complete)

Read all four audit files. Then evaluate each system against best-practice references from `~/.cache/cwfo/best-practice/`.

### CLAUDE.md Assessment

Compare `./audit/codebase-map.md` against root CLAUDE.md:
- Does CLAUDE.md accurately describe the tech stack as it actually exists?
- Does it describe the actual project structure or an outdated one?
- Does it mention the actual workflow from `./audit/workflows-found.md`?
- Is there a skill inventory that matches what exists in `.claude/skills/`?
- For each major directory cluster: does this area have enough guidance?

### Rules Assessment

Compare `./audit/conventions-found.md` against `.claude/rules/`:
- For every convention found in actual code, is there a rule enforcing it?
- For every file type or directory pattern, would a path-scoped rule help?
- Prioritize rules where conventions are subtle or easy to break

Consider rules for: component structure, naming conventions, import organization, error handling per layer, testing conventions, styling methodology, accessibility patterns, performance patterns.

### Skills Assessment

Compare `./audit/workflows-found.md` and `./audit/codebase-map.md` against `.claude/skills/`:
- What complex, recurring multi-step tasks exist? Each is a candidate skill.
- What specialized domain knowledge does the project require?
- Are any `scripts/` doing computation Claude could handle by thinking?
- Are there repeated patterns where Claude would benefit from a methodology?

Consider: feature scaffolding, data model changes, testing workflows, code review checklists, deployment procedures, domain-specific logic.

### Agents Assessment

Compare `./audit/workflows-found.md` against `.claude/agents/`:
- What tasks genuinely benefit from isolated context?
- What tasks are parallelizable?
- Are existing agents too generic?
- Do agents preload the right skills?
- Don't over-agent — prefer inline skills when isolation isn't needed.

### MCP Quick Check

- Are configured MCPs actually used by agents or referenced in skills?
- Are there external services that would benefit from an MCP but don't have one?
- Any MCPs replaceable by skill scripts?

## Output Format

For each of the 4 main systems (CLAUDE.md, Rules, Skills, Agents):

- **EXISTS AND CORRECT** — config that matches what the codebase actually needs
- **EXISTS BUT WRONG** — config that's outdated, inaccurate, or covers the wrong thing
- **MISSING — HIGH PRIORITY** — gaps that will cause incorrect or inconsistent output
- **MISSING — NICE TO HAVE** — gaps that would improve quality but aren't critical
- **UNNECESSARY** — config that exists but the codebase doesn't need

End with a **concrete action plan**: ordered list of specific files to create or modify, with a one-line description of what each should contain. Order by impact.

## Cleanup

Delete `./audit/` directory when analysis is complete:

```bash
rm -rf ./audit
```
