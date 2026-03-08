Review this project's Claude Code architecture and tell me if each piece is correctly placed. Use the reference files in ./best-practice/ for current best practices on each system. Specifically:

## What to audit

1. **CLAUDE.md** — Read ./CLAUDE.md and any .claude/CLAUDE.md. Is it under 200 lines? Does it contain ONLY permanent project-wide truths (tech stack, workflow, quality bar, file conventions, skill inventory)? Flag anything that should be a rule, skill, or agent instruction instead. Check for @imports that should be lazy-loaded references instead. Reference: ./best-practice/claude-memory.md

2. **Subdirectory CLAUDE.md files** — Find all CLAUDE.md files in subdirectories. Are they being used where .claude/rules/ with path globs would be more reliable? Is there content duplicated from root CLAUDE.md? Reference: ./best-practice/claude-memory.md

3. **Rules (.claude/rules/)** — Read every rule file. Does each one have appropriate `paths:` globs? Are there rules without paths that should just be in CLAUDE.md? Are there instructions in CLAUDE.md that are path-specific and should be rules instead? Are there overlapping or contradictory rules? Reference: ./best-practice/claude-memory.md

4. **Skills (.claude/skills/)** — Read every SKILL.md. For each skill ask:
   - Is the description "pushy" enough for auto-invocation?
   - Is anything in the skill that should be a rule (always-on convention) instead?
   - Is anything in the skill that should be an MCP (persistent state, external API) instead?
   - Are scripts/ being used for computation that Claude can't do by thinking alone?
   - Are scripts/ duplicating what an MCP already provides?
   - Is SKILL.md under 500 lines with clear pointers to references/?
     Reference: ./best-practice/claude-skills.md

5. **Agents (.claude/agents/)** — Read every agent file. For each agent ask:
   - Does it need isolation or could this run inline in the main conversation?
   - Is the description clear enough for automatic delegation?
   - Does it preload the right skills via `skills:` frontmatter?
   - Does it have appropriate tool restrictions (not too broad, not too narrow)?
   - Would file-based handoffs between agents work, and are they documented?
   - Is the agent doing work that could be parallelized but isn't, or is parallelized but shouldn't be?
     Reference: ./best-practice/claude-subagents.md

6. **MCPs (.mcp.json)** — Read the MCP config. For each server ask:
   - Does this provide a capability Claude genuinely cannot do by thinking + skill scripts?
   - Is it here for persistent state, external API access, or cross-tool portability?
   - Could this be replaced by a skill with scripts/?
   - Is it configured at the right scope (project vs user)?
     Reference: ./best-practice/claude-mcp.md

7. **Cross-cutting concerns:**
   - Is there logic split across CLAUDE.md + rules + skills that should live in one place?
   - Are agents referencing skills they don't preload?
   - Are there MCPs that no agent or skill references?
   - Is the overall context budget reasonable? (CLAUDE.md + rules + skill descriptions should fit comfortably under 5% of context at startup)

## Output format

For each system, give me:

- CORRECT: things properly placed
- MISPLACED: things that belong somewhere else (say where)
- MISSING: things that should exist but don't
- REDUNDANT: things duplicated across systems

End with a prioritized list of specific changes to make.
