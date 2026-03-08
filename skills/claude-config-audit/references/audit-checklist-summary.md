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
- Rule body exceeding 15 lines → probably belongs in a subdirectory CLAUDE.md
- Rule body exceeding 50 lines → MUST be converted to subdirectory CLAUDE.md
- 10+ rules firing simultaneously on one directory → context overload, consolidate
- 5000+ estimated rule tokens on a single directory → critical context budget violation
- Skill doing simple convention enforcement → should be a rule
- Agent that doesn't need isolation → should be inline or a skill
- MCP replaceable by a bash script → should be a skill script
- `@import` of large files in CLAUDE.md → use skill `context:` instead
- Duplicated content across CLAUDE.md and subdirectory files → consolidate
- Subdirectory CLAUDE.md that contradicts root without clear specialization intent → resolve conflict

## Context Budget Targets

- CLAUDE.md + always-on rules + skill descriptions: < 5% of context at startup
- Each rule body: ~5-10 lines (every line costs tokens on every matched turn)
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

The rule is too dense for always-on loading. Convert it to a **subdirectory CLAUDE.md**:

1. Identify which directory the rule's `paths:` targets (e.g., `src/modules/**`)
2. Create `src/modules/CLAUDE.md` with the rule's content (can be much longer — subdirectory CLAUDE.md lazy-loads only when working there)
3. Replace the original rule with a 3-5 line summary that covers only the critical constraints (the things that would break if violated)
4. Delete the rule entirely if the subdirectory CLAUDE.md covers everything

**Example:** A 108-line `naming.md` rule with `paths: ["src/**/*.ts"]` becomes:
- `src/CLAUDE.md` (full naming guide, 108 lines — only loaded when working in src/)
- `.claude/rules/naming.md` reduced to 5 lines: file naming convention, function casing, the 2-3 patterns that cause the most mistakes

### Too Many Rules Overlapping (10+ on one directory)

Multiple rules matching the same directory means Claude loads all of them simultaneously. Fix by **consolidating**:

1. List all rules that fire on the problem directory
2. Group them by concern (e.g., 3 IPC rules → 1 IPC rule, 5 request rules → 1 request CLAUDE.md)
3. For each group: merge into ONE rule (if combined body ≤ 15 lines) or ONE subdirectory CLAUDE.md (if longer)
4. The goal: ≤ 5 rules fire on any single directory

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

When proposing config changes, explain what and why. Never create config silently.
```
