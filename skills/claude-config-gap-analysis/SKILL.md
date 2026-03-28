---
name: gap-analysis
description: >
  Deep gap analysis of Claude Code config vs what the codebase actually needs.
  Use when the user says "gap analysis", "deep audit", "comprehensive review",
  "what config am I missing", or "analyze my project for claude config".
allowed-tools:
  - Read
  - Write
  - Edit
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
  - ../config-restructure/references/restructure-operations.md
  - ../config-restructure/references/consolidation-patterns.md
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

**Root CLAUDE.md is a routing table, not a knowledge store.** Every section must pass: "Does Claude need this on EVERY turn, regardless of what files it's touching?" If no, it belongs in a subdirectory CLAUDE.md, rule, or skill instead.

Compare `./audit/codebase-map.md` against root CLAUDE.md:
- Does it accurately describe the tech stack (names + versions, not usage patterns)?
- Does it have a project structure section (directory tree with 1-line descriptions)?
- Does it have a skill/agent inventory that matches what exists?
- Does it include a **Config Maintenance section**? If missing → HIGH PRIORITY gap.
- **Flag any section that is path-specific** — conventions for specific directories, authoring guides for specific artifact types, detailed architecture, multi-step workflows, reference data. These must be extracted regardless of line count.

Also evaluate subdirectory CLAUDE.md needs:
- Are there directories with dense domain logic but no CLAUDE.md and no rule?
- Are there directories where 50+ lines of context would only matter when working there? → Subdirectory CLAUDE.md candidate
- Do existing subdirectory CLAUDE.md files duplicate root CLAUDE.md content? → Flag for consolidation

### Rules Assessment

Compare `./audit/conventions-found.md` against `.claude/rules/`:
- For every convention found in actual code, is there a rule enforcing it?
- For every file type or directory pattern, would a path-scoped rule help?
- Prioritize rules where conventions are subtle or easy to break
- **Flag overloaded rules:** any rule with body >15 lines needs the **two-artifact pattern**: extract the dense content to a subdirectory CLAUDE.md (lazy-loaded), reduce the rule to a ≤ 10 line summary with a pointer to the CLAUDE.md. A 200-line merged rule is NOT an improvement over 5 × 40-line rules — same token cost, harder to maintain. The rule file MUST shrink.
- **Check for merge-without-extract:** if rules were recently consolidated (fewer files than before), verify the merged rules actually shrank. Concatenation without extraction is the most common failure mode.

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

Then proceed directly to Phase 3.

## Phase 3: Apply Fixes

**Do NOT stop after the report. Do NOT ask the user to run a separate command. Fix the problems you just found.**

### Step 1 — Categorize findings from Phase 2

Map every finding to an operation type:

| Category | Meaning |
|---|---|
| SHRINK | CLAUDE.md over 200 lines — sections need extraction |
| EXTRACT | Rule body over 10 lines — needs two-artifact split |
| DEDUPLICATE | Same concept in 2+ locations with different wording |
| CONSOLIDATE | Decision history / reflection chains to collapse |
| REORGANIZE | Monolithic section (30+ bullets) to split by theme |
| DELETE | Stale content (dead references, superseded decisions) |

Use the loaded `restructure-operations.md` reference for detailed algorithms per operation type. Use `consolidation-patterns.md` for collapsing decision history.

### Step 2 — Build restructure plan

For each finding, design the concrete fix:
- **SHRINK:** For each CLAUDE.md section, ask: "Is this needed every turn regardless of what files Claude is touching?" Tag as SKELETON (yes) or CANDIDATE (no). Skeleton = project identity, tech stack list, directory tree, skill inventory, config maintenance. Anything path-specific, detailed, or workflow-oriented is an extraction candidate regardless of length.
- **EXTRACT:** Draft the two-artifact split — 10-line rule summary + subdirectory CLAUDE.md. Check if subdirectory CLAUDE.md already exists (merge, don't duplicate).
- **DEDUPLICATE:** Pick canonical location per the algorithm in restructure-operations.md, plan deletions/pointer replacements.
- **CONSOLIDATE:** Read all versions chronologically, extract only final-state decisions.
- **REORGANIZE:** Group bullets by theme, plan subsections of 5-15 items.
- **DELETE:** Verify stale with git blame — recent additions (last 5 commits) get flagged, not auto-deleted.

Estimate before/after line counts for every file.

### Step 3 — Present plan and get approval (mandatory, blocking)

Show a summary table:

```
File                          Current    Target    Operations
─────────────────────────────────────────────────────────────
CLAUDE.md                     365        142       SHRINK, CONSOLIDATE, REORGANIZE
.claude/rules/anti-slop.md    53         10        EXTRACT
src/lib/CLAUDE.md             131        155       EXTRACT target (absorbs rule content)
```

Group by risk:
- **LOW** — Reorganize sections, add pointers, create new subdirectory CLAUDE.md
- **MEDIUM** — Extract content from rules/CLAUDE.md to new locations, merge duplicates
- **HIGH** — Delete sections, rewrite decision history, remove files

For HIGH-risk operations, show before/after diffs. **No writes until user approves.**

### Step 4 — Execute approved fixes

Apply in dependency order:
1. `mkdir -p` for new directories
2. Create new subdirectory CLAUDE.md files (extraction targets must exist before rules shrink)
3. Gut overloaded rules to 10-line summaries with pointers
4. Rewrite root CLAUDE.md — remove extracted content, consolidate, ensure Config Maintenance section
5. Delete approved stale content
6. Update cross-references (broken `paths:` globs, pointers)

### Step 5 — Validate and report

Run lint checks: `wc -l` on CLAUDE.md (must be <200), rule bodies (<10 lines each), subdirectory CLAUDE.md (<300 lines each). Verify all `paths:` globs resolve.

Report the delta:
```
Restructure complete.
  CLAUDE.md:                    365 → 142 lines  (-61%)
  Rules restructured:           3
  Subdirectory CLAUDE.md created: 2
  Lint result:                  all passing
```

List all modified/created files, then ask once: **"Commit these config changes?"**

## Cleanup

Delete `./audit/` directory after Phase 3 is complete:

```bash
rm -rf ./audit
```
