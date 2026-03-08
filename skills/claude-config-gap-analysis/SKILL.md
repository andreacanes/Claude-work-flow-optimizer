---
name: gap-analysis
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
context:
  - ../shared-references/investigation-phase.md
---

## Setup

Best-practice reference files are cached at `~/.cache/cwfo/best-practice/`. Check if they exist:

```bash
ls ~/.cache/cwfo/best-practice/*.md 2>/dev/null | head -1
```

If the cache directory is missing or empty, do NOT fetch inline. Tell the user:

> **Best-practice references not found.** Run `/cwfo:update` to fetch them. Without references, gap analysis will evaluate structural correctness and codebase-to-config alignment only, not best-practice compliance.

If the user wants to proceed without references, continue with structural analysis only.

## Phase 1: Understand the Codebase (Parallel Subagents)

Follow the investigation phase instructions from the loaded `investigation-phase.md` reference. Dispatch all 4 subagents in parallel and verify all audit files exist before proceeding.

## Phase 2: Gap Analysis (After All Subagents Complete)

Read all four audit files. Then evaluate each system against best-practice references from `~/.cache/cwfo/best-practice/`.

### CLAUDE.md Assessment

Compare `./audit/codebase-map.md` against root CLAUDE.md:
- Does CLAUDE.md accurately describe the tech stack as it actually exists?
- Does it describe the actual project structure or an outdated one?
- Does it mention the actual workflow from `./audit/workflows-found.md`?
- Is there a skill inventory that matches what exists in `.claude/skills/`?
- For each major directory cluster: does this area have enough guidance?

Also evaluate subdirectory CLAUDE.md needs:
- Are there directories with dense domain logic (API patterns, auth flows, framework architecture) but no CLAUDE.md and no rule?
- Are there directories where 50+ lines of context would only matter when working there? → Subdirectory CLAUDE.md candidate
- Do existing subdirectory CLAUDE.md files duplicate root CLAUDE.md content? → Flag for consolidation

### Rules Assessment

Compare `./audit/conventions-found.md` against `.claude/rules/`:
- For every convention found in actual code, is there a rule enforcing it?
- For every file type or directory pattern, would a path-scoped rule help?
- Prioritize rules where conventions are subtle or easy to break
- **Flag overloaded rules:** any rule with body >15 lines should probably be a subdirectory CLAUDE.md instead (rules are always-on for matching paths; dense content belongs in lazy-loaded subdirectory CLAUDE.md)

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
