# Config Placement Decision Matrix

Use this quick reference to determine where configuration belongs:

| Question | Yes → Place here |
|----------|-----------------|
| Permanent project truth (tech stack, structure, workflow)? | CLAUDE.md |
| Always-on, applies to ALL files? | CLAUDE.md |
| Applies ONLY when touching specific file paths? | Rule with `paths:` globs |
| Multi-step methodology/workflow for a complex task? | Skill (SKILL.md) |
| Needs context isolation or parallelism? | Agent |
| Needs persistent state or external API access? | MCP |
| Used by computation Claude can't do by thinking? | Skill `scripts/` |
| Same computation an MCP already handles? | Remove script, use MCP |

## Red Flags

- CLAUDE.md > 200 lines → move path-specific content to rules
- Rule without `paths:` → should be in CLAUDE.md or a skill
- Skill doing simple convention enforcement → should be a rule
- Agent that doesn't need isolation → should be inline or a skill
- MCP replaceable by a bash script → should be a skill script
- `@import` of large files in CLAUDE.md → use skill `context:` instead
- Duplicated content across CLAUDE.md and subdirectory files → consolidate

## Context Budget Targets

- CLAUDE.md + always-on rules + skill descriptions: < 5% of context at startup
- Each rule body: ~5-10 lines (every line costs tokens on every matched turn)
- Skill descriptions: 1-2 sentences (loaded into context even when not invoked)
- Skill body + references: loaded only on invocation, can be longer
