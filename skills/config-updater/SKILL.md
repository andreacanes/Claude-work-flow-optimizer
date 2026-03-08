---
name: config-updater
description: >
  Analyze recent code changes and update Claude Code configuration
  (rules, skills, agents, CLAUDE.md) to match. Use this after completing
  a feature, after a refactor, after adding a new domain or framework,
  or whenever the codebase has evolved and config might be stale.
  Also use when the user says things like "save this as a rule",
  "add this to the config", "make this a convention", "update the rules",
  "add this to the rules", "make sure Claude always does this",
  or "we should always do it this way".
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(git:*)
  - Bash(ls:*)
---

## Process

1. Determine what changed since the last config update:
   - Check if `.claude/.cwfo-last-update` exists. If so, read the stored commit hash and run `git diff --stat $(cat .claude/.cwfo-last-update)..HEAD`
   - If the marker doesn't exist, fall back to `git diff --stat HEAD~10`
2. Read the current `.claude/` config inventory (agents, skills, rules, CLAUDE.md)
3. For each changed area, check:

**New directory or module?**
- Does it need a **rule** with path globs? → Yes when: short convention (5-10 lines), enforcement-style ("always use X"), applies to a glob pattern
- Does it need a **subdirectory CLAUDE.md**? → Yes when: dense context (50+ lines), domain-specific knowledge (API patterns, auth flows, framework architecture), only relevant when working in that directory
- Does it need **neither**? → When the convention is already covered by root CLAUDE.md or an existing rule

**New pattern established?**
- If 3+ files follow the same new convention, that's a rule candidate.
- Write it as a rule in `.claude/rules/` with appropriate path globs.
- Before creating the rule, `Glob` the proposed `paths:` pattern to verify it resolves to actual files. If zero matches, adjust the glob.
- Check existing rules in `.claude/rules/` for overlapping path globs or contradictory instructions. If overlap found, propose merging or scoping more narrowly.

**New multi-step workflow discovered?**
- If you just executed a complex sequence that will recur (adding a new API endpoint, creating a new feature module, running a specific type of analysis), capture it as a skill in `.claude/skills/`.
- Instructions in SKILL.md, any helper scripts in `scripts/`.

**New parallelizable task pattern?**
- If the work involved independent subtasks that could have run simultaneously, consider whether an agent definition would help future runs.
- When creating an agent, verify: (a) any `skills:` preloads reference existing skill directories, (b) `tools:` list is minimal and only includes what the agent needs, (c) the task genuinely benefits from isolation — if not, suggest a skill instead.

**Root CLAUDE.md drift?**
- Has the tech stack, project structure, or workflow changed in ways that make CLAUDE.md inaccurate? Update it.
- Has CLAUDE.md grown past 200 lines? Move path-specific content to rules.

4. For each proposed change, explain to the user:
   - What you want to add/modify
   - Why (what codebase change triggered it)
   - Where it goes (which system and why that system)
5. **Only apply changes the user approves.**
6. After applying changes, record the current commit as a watermark so the next run knows where to start:

```bash
mkdir -p .claude && git rev-parse HEAD > .claude/.cwfo-last-update
```

## Decision Framework — Where to Put Things

Ask in this order:

| Question | → Place here |
|----------|-------------|
| Should Claude ALWAYS know this regardless of what files it's touching? | CLAUDE.md |
| Should Claude know this ONLY when touching specific files? | Rule with `paths:` |
| Is this a METHODOLOGY for a complex task, not a convention? | Skill |
| Does this task need ISOLATION or PARALLELISM? | Agent |
| Does this need PERSISTENT STATE or EXTERNAL API access? | MCP |
