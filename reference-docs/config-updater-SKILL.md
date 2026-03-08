---
name: config-updater
description: >
  Analyze recent code changes and update Claude Code configuration 
  (rules, skills, agents, CLAUDE.md) to match. Use this after completing 
  a feature, after a refactor, after adding a new domain or framework, 
  or whenever the codebase has evolved and config might be stale. 
  Also use when the user says things like "save this pattern", 
  "remember this for next time", or "we should always do it this way".
---

## Process

1. Run `git diff --stat HEAD~10` to see what changed recently
2. Read the current .claude/ config inventory (agents, skills, rules, CLAUDE.md)
3. For each changed area, check:

**New directory or module?**
→ Does it need a subdirectory CLAUDE.md? (Only if it has distinct
conventions from the rest of the project)
→ Does it need new rules with path globs?

**New pattern established?**
→ If 3+ files follow the same new convention, that's a rule candidate.
→ Write it as a rule in .claude/rules/ with appropriate path globs.
→ Before creating the rule, Glob the proposed paths: pattern to verify it resolves to actual files. If zero matches, adjust the glob.
→ Check existing rules in .claude/rules/ for overlapping path globs or contradictory instructions. If overlap found, propose merging or scoping more narrowly.

**New multi-step workflow discovered?**
→ If you just executed a complex sequence that will recur (adding a new
API endpoint, creating a new feature module, running a specific type
of analysis), capture it as a skill in .claude/skills/.
→ Instructions in SKILL.md, any helper scripts in scripts/.

**New parallelizable task pattern?**
→ If the work involved independent subtasks that could have run
simultaneously, consider whether an agent definition would help
future runs.
→ When creating an agent, verify: (a) any skills: preloads reference existing skill directories, (b) tools: list is minimal and only includes what the agent needs, (c) the task genuinely benefits from isolation — if not, suggest a skill instead.

**Root CLAUDE.md drift?**
→ Has the tech stack, project structure, or workflow changed in ways
that make CLAUDE.md inaccurate? Update it.
→ Has CLAUDE.md grown past 200 lines? Move path-specific content
to rules.

4. For each proposed change, explain to the user:
   - What you want to add/modify
   - Why (what codebase change triggered it)
   - Where it goes (which system and why that system)
5. Only apply changes the user approves.

## Decision framework for WHERE to put things

Ask in this order:

- Should Claude ALWAYS know this regardless of what files it's touching? → CLAUDE.md
- Should Claude know this ONLY when touching specific files? → Rule with paths
- Is this a METHODOLOGY for a complex task, not a convention? → Skill
- Does this task need ISOLATION or PARALLELISM? → Agent
- Does this need PERSISTENT STATE or EXTERNAL API access? → MCP

```

You invoke this with `/config-updater` after finishing a chunk of work. Or Claude auto-invokes it when it notices it just established a new pattern — the description is written to catch phrases like "remember this" or "always do it this way."

---
```
