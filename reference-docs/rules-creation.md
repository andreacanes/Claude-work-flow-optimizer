You are auditing whether this project's Claude Code configuration actually covers what the codebase needs — not just whether existing config is well-structured, but whether we're MISSING rules, skills, agents, or CLAUDE.md content that the codebase demands.

## Phase 1: Understand the codebase (parallel subagents)

Spawn these 4 investigation subagents simultaneously. Each one explores the codebase independently and writes findings to ./audit/ as a handoff file.

### Subagent 1: Codebase Map

Explore the entire project structure. For every directory and major file group, document:

- What framework/language/tool is used
- What patterns and conventions are visible in the actual code (not what CLAUDE.md says — what the code actually does)
- What file types exist and where
- What the build/deploy/test pipeline looks like
  Write findings to ./audit/codebase-map.md

### Subagent 2: Convention Extraction

Read 3-5 representative files from each major directory. Extract the implicit conventions:

- Naming patterns (files, variables, components, functions)
- Import ordering and structure
- Error handling patterns
- Styling approach (CSS modules? Tailwind? styled-components?)
- Testing patterns (what framework, what's the describe/it structure, how are mocks done)
- API patterns (how are endpoints structured, how is auth handled)
- Any patterns that are consistent across files but NOT documented anywhere in .claude/
  Write findings to ./audit/conventions-found.md

### Subagent 3: Workflow Analysis

Examine package.json scripts, CI configs, Makefiles, Dockerfiles, deploy scripts, git hooks, PR templates, and any workflow documentation. Map out:

- How does code go from local dev to production?
- What linting/formatting is enforced?
- What are the testing stages?
- What external services does this project talk to?
- What manual processes exist that could benefit from automation via agents?
  Write findings to ./audit/workflows-found.md

### Subagent 4: Current Config Inventory

Read every file in .claude/ (agents, skills, rules), all CLAUDE.md files (root, subdirectories, .claude/CLAUDE.md), and .mcp.json. For each one, write a one-line summary of what it covers. Also note what's referenced but doesn't exist (e.g., CLAUDE.md mentions a skill that has no SKILL.md).
Write findings to ./audit/current-config.md

## Phase 2: Gap analysis (after all subagents complete)

Read all four audit files. Then evaluate each system:

### CLAUDE.md Assessment

Compare ./audit/codebase-map.md against root CLAUDE.md:

- Does CLAUDE.md accurately describe the tech stack as it actually exists in the code?
- Does it describe the actual project structure or an outdated/aspirational one?
- Does it mention the actual workflow from ./audit/workflows-found.md?
- Is there a skill inventory that matches what actually exists in .claude/skills/?
- Are there subdirectory CLAUDE.md files where the codebase has distinct domains that would benefit from them?

For each major directory cluster identified in the codebase map, ask: does this area have enough guidance in CLAUDE.md or a subdirectory CLAUDE.md? If a directory has its own framework, conventions, or domain logic that differs from the root, it probably needs its own CLAUDE.md or at minimum dedicated rules.

### Rules Assessment

Compare ./audit/conventions-found.md against .claude/rules/:

- For every convention found in the actual code, is there a rule enforcing it?
- For every file type or directory pattern in the codebase, would a path-scoped rule help maintain consistency?
- Prioritize rules for areas where the conventions are subtle or easy to break — if the codebase has a specific error handling pattern that's non-obvious, that needs a rule more than something obvious like "use TypeScript"

Think about these categories and whether rules exist for each:

- Component/module structure patterns per directory
- Naming conventions per file type
- Import organization
- Error handling per layer (API, UI, data)
- Testing conventions per test type
- Styling methodology per component type
- Accessibility patterns
- Performance patterns (lazy loading, memoization conventions)

### Skills Assessment

Compare ./audit/workflows-found.md and ./audit/codebase-map.md against .claude/skills/:

- What are the complex, multi-step tasks a developer does repeatedly in this codebase? Each one is a candidate skill.
- What specialized domain knowledge does this project require that Claude wouldn't know by default?
- Are there any scripts/ in existing skills doing computation Claude could handle by thinking? (Those should be instructions, not scripts)
- Are there repeated patterns in the codebase where Claude would benefit from a methodology? (e.g., "how to add a new API endpoint in this project" or "how to create a new page/feature")

Think about these common skill candidates:

- Feature scaffolding (new component, new page, new API route — with THIS project's specific patterns)
- Data model changes (migration + types + validation + API update)
- Testing workflows specific to this project
- Code review checklist specific to this codebase's patterns
- Deployment or release procedures
- Any domain-specific logic that requires specialized knowledge

### Agents Assessment

Compare ./audit/workflows-found.md against .claude/agents/:

- What tasks in this project are genuinely independent and would benefit from isolated context?
- What tasks are parallelizable (e.g., building multiple components, running multiple analysis passes)?
- Are existing agents too generic ("code-reviewer") when they should be feature-specific for this codebase?
- Do agents preload the right skills for what they actually need to do?
- Are there manual multi-step workflows identified in the workflow analysis that should be orchestrated by an agent?

Don't over-agent. Only recommend agents for tasks that genuinely benefit from context isolation or parallelism. If something can run inline with a skill, prefer that.

### MCP Quick Check

Just verify:

- Are configured MCPs actually used by agents or referenced in skills?
- Are there external services identified in ./audit/workflows-found.md that would benefit from an MCP but don't have one?
- Any MCPs that could be replaced by skill scripts?

## Output format

For each of the 4 main systems (CLAUDE.md, Rules, Skills, Agents), produce:

**EXISTS AND CORRECT** — config that matches what the codebase actually needs
**EXISTS BUT WRONG** — config that's outdated, inaccurate, or covers the wrong thing  
**MISSING — HIGH PRIORITY** — gaps that will cause Claude to produce incorrect or inconsistent output for common tasks
**MISSING — NICE TO HAVE** — gaps that would improve quality but aren't critical
**UNNECESSARY** — config that exists but the codebase doesn't actually need

End with a concrete action plan: an ordered list of specific files to create or modify, with a one-line description of what each should contain. Order by impact — what will improve Claude's output the most for the least effort.

Reference ./best-practice/ for structural best practices on each system.

Clean up ./audit/ when done.
