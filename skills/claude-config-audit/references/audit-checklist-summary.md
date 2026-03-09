# Config Placement Decision Matrix

Use this quick reference to determine where configuration belongs:

| Question | Yes → Place here |
|----------|-----------------|
| Permanent project truth (tech stack, structure, workflow)? | CLAUDE.md |
| Always-on, applies to ALL files? | CLAUDE.md |
| Short convention (5-10 lines) for specific file paths? | Rule with `paths:` globs |
| Dense, directory-specific context (50+ lines) that only matters when working there? | Subdirectory CLAUDE.md (lazy-loaded) |
| Multi-step methodology/workflow for a complex task? | Skill (SKILL.md) |
| Needs context isolation or parallelism? | Agent |
| Needs persistent state or external API access? | MCP |
| Used by computation Claude can't do by thinking? | Skill `scripts/` |
| Same computation an MCP already handles? | Remove script, use MCP |

## Red Flags

- CLAUDE.md missing Config Maintenance section → project config will drift silently (high priority)
- CLAUDE.md > 200 lines → move path-specific content to rules
- Rule without `paths:` → should be in CLAUDE.md or a skill (always-on cost)
- Rule body exceeding 15 lines → needs two-artifact pattern (≤ 10 line rule + subdirectory CLAUDE.md)
- Rule body exceeding 50 lines → CRITICAL: must extract to subdirectory CLAUDE.md immediately
- Rule consolidation without extraction → merged rule is just as expensive as separate rules; the rule file MUST shrink
- 10+ rules firing simultaneously on one directory → context overload, consolidate + extract
- 5000+ estimated rule tokens on a single directory → critical context budget violation
- Skill doing simple convention enforcement → should be a rule
- Agent that doesn't need isolation → should be inline or a skill
- MCP replaceable by a bash script → should be a skill script
- `@import` of large files in CLAUDE.md → use skill `context:` instead
- Duplicated content across CLAUDE.md and subdirectory files → consolidate
- Subdirectory CLAUDE.md that contradicts root without clear specialization intent → resolve conflict

## Context Budget Targets

- CLAUDE.md + always-on rules + skill descriptions: < 5% of context at startup
- Each rule body: ≤ 10 lines (every line costs tokens on every matched turn)
- Skill descriptions: 1-2 sentences (loaded into context even when not invoked)
- Skill body + references: loaded only on invocation, can be longer
- Max rules firing simultaneously on any directory: ≤ 10
- Max estimated tokens from rules on any directory: ≤ 5,000

## Structural Lint Checklist (Quick Lint Mode)

Used when user says "quick check", "validate config", "lint my config".

| Check | Pass condition |
|-------|---------------|
| CLAUDE.md length | `wc -l ./CLAUDE.md` < 200 lines |
| Config maintenance | CLAUDE.md has a Config Maintenance section |
| Rule frontmatter | All `.claude/rules/*.md` files have valid YAML frontmatter |
| Rule path resolution | Every `paths:` glob matches at least one file |
| Rule body length | No rule body exceeds 50 lines ([FAIL]) or 15 lines ([WARN]) |
| Always-on rules | Rules without `paths:` flagged; total body < 30 lines |
| Rule overlap | No directory has 10+ rules firing simultaneously |
| Context budget | Estimated rule tokens < 5,000 on any directory |
| Skill frontmatter | All `.claude/skills/*/SKILL.md` files have valid YAML frontmatter |
| Skill context resolution | Every `context:` reference resolves to an existing file |
| Agent skill preloads | Every `skills:` entry maps to an existing `.claude/skills/` directory |
| No duplicate rules | No duplicate filenames in `.claude/rules/` |

## Remediation Guide

When lint or audit flags issues, here's how to fix them:

### Overloaded Rule (body > 15 lines)

Rules are **always-on** — every line loads into context on every matching file read. Dense rules waste context budget. Fix with the **two-artifact pattern**: a short rule (pointer) + a subdirectory CLAUDE.md (full content).

**The rule file MUST shrink to ≤ 10 lines.** Creating a CLAUDE.md while leaving the rule at 100+ lines accomplishes nothing — the rule still fires every turn at full size.

Steps:

1. Identify which directory the rule's `paths:` targets (e.g., `src/ipc/**`)
2. Create a subdirectory CLAUDE.md at that path (e.g., `src/ipc/CLAUDE.md`) containing the full dense content — can be 50-300 lines, it only lazy-loads when Claude works in that directory
3. **Gut the rule file down to ≤ 10 lines.** Keep ONLY:
   - The 2-3 constraints that break things if violated (the "never do X" items)
   - One-line summaries of the main patterns
   - A pointer: `Full patterns: see src/ipc/CLAUDE.md`
4. If the rule has nothing worth keeping as a short summary, delete it entirely — the CLAUDE.md is sufficient

**Example — WRONG (what consolidation often produces):**
```
# .claude/rules/ipc.md — 235 lines (just concatenated 5 old rules)
# src/ipc/CLAUDE.md — doesn't exist
```
Total always-on cost: 235 lines × every matching read. No improvement.

**Example — RIGHT:**
```
# .claude/rules/ipc.md — 8 lines
---
description: IPC communication patterns
paths: ["src/ipc/**"]
---
ALL handlers return envelope: { success, data?, error?, errorCode? }
Use withIpcHandler() for new handlers. Register in handlers/index.ts barrel.
Naming: IPC channels use camelCase. DB columns use snake_case.
Full patterns: see src/ipc/CLAUDE.md

# src/ipc/CLAUDE.md — 180 lines (lazy-loaded)
[Full handler registration, error patterns, duration tracking, broadcasts...]
```
Total always-on cost: 8 lines. Full detail available when working in src/ipc/.

### Too Many Rules Overlapping (10+ on one directory)

Multiple rules matching the same directory means Claude loads ALL of them simultaneously. Fix by **consolidating + extracting**:

1. List all rules that fire on the problem directory
2. Group by concern (e.g., 3 IPC rules, 5 request rules, 2 error rules)
3. For each group:
   - If combined body ≤ 15 lines → merge into ONE rule file
   - If combined body > 15 lines → apply the **two-artifact pattern**: extract dense content to a subdirectory CLAUDE.md, leave a ≤ 10 line rule summary
4. Target: ≤ 5 rules fire on any single directory, each ≤ 10 lines

**Common mistake:** Merging 5 rules into 1 large rule. This reduces file count but NOT token cost. A 300-line merged rule is worse than 5 × 60-line rules — same tokens, harder to maintain. Always extract to CLAUDE.md when merging produces >15 lines.

### Rule Without `paths:` (always-on)

This rule fires every single turn regardless of what file is being edited. Ask:
- Does this apply to ALL files? → Move content to CLAUDE.md
- Does this apply to specific files? → Add `paths:` frontmatter
- Is this a skill trigger? → Keep as always-on but minimize body (< 5 lines)

### Missing Config Maintenance Section

Add this to the end of CLAUDE.md:

```markdown
## Config Maintenance

This config matches the codebase as of [DATE]. When the codebase evolves:

- **New directory or module**: Does it need a rule (~5-10 lines) or subdirectory CLAUDE.md (50+ lines)?
- **New recurring workflow**: Does it need a skill?
- **Changed tech stack or structure**: Update this CLAUDE.md.
- **Rule whose `paths:` no longer matches files**: Delete or update it.

Rules are short pointers (≤ 10 lines). Dense content belongs in subdirectory CLAUDE.md files (lazy-loaded). Never let a rule file grow past 15 lines — extract to CLAUDE.md instead.

When proposing config changes, explain what and why. Never create config silently.
```
