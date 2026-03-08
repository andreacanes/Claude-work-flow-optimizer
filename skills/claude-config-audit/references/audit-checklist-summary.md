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
- Rule without `paths:` → should be in CLAUDE.md or a skill
- Rule body exceeding 15 lines → probably belongs in a subdirectory CLAUDE.md (rules are always-on for matching paths; dense content should be lazy-loaded)
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

## Structural Lint Checklist (Quick Lint Mode)

Used when user says "quick check", "validate config", "lint my config".

| Check | Pass condition |
|-------|---------------|
| CLAUDE.md length | `wc -l ./CLAUDE.md` < 200 lines |
| Rule frontmatter | All `.claude/rules/*.md` files have valid YAML frontmatter |
| Rule path resolution | Every `paths:` glob matches at least one file |
| Skill frontmatter | All `.claude/skills/*/SKILL.md` files have valid YAML frontmatter |
| Skill context resolution | Every `context:` reference resolves to an existing file |
| Agent skill preloads | Every `skills:` entry maps to an existing `.claude/skills/` directory |
| Agent tool validity | Every `tools:` entry is a recognized tool name pattern |
| No duplicate rules | No duplicate filenames in `.claude/rules/` |
