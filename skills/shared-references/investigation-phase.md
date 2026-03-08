# Investigation Phase — Parallel Subagent Dispatch

Spawn these 4 investigation subagents simultaneously. Each explores the codebase independently and writes findings to `./audit/` as a handoff file.

Create `./audit/` directory first:

```bash
mkdir -p ./audit
```

## Subagent 1: Codebase Map

Use the `codebase-mapper` agent. It will explore the entire project structure and document:
- What framework/language/tool is used per directory
- What patterns and conventions are visible in the actual code (not what CLAUDE.md says)
- What file types exist and where
- What the build/deploy/test pipeline looks like

Output: `./audit/codebase-map.md`

## Subagent 2: Convention Extraction

Use the `convention-extractor` agent. It will read 3-5 representative files from each major directory and extract:
- Naming patterns (files, variables, components, functions)
- Import ordering and structure
- Error handling patterns
- Styling approach
- Testing patterns
- API patterns
- Consistent patterns NOT documented in `.claude/`

Output: `./audit/conventions-found.md`

## Subagent 3: Workflow Analysis

Use the `workflow-analyzer` agent. It will examine package.json scripts, CI configs, Makefiles, Dockerfiles, deploy scripts, git hooks, PR templates. Maps out:
- How code goes from local dev to production
- What linting/formatting is enforced
- Testing stages
- External services
- Manual processes that could benefit from automation

Output: `./audit/workflows-found.md`

## Subagent 4: Current Config Inventory

Use the `config-inventory` agent. It will read every file in `.claude/`, all CLAUDE.md files, and `.mcp.json`. Produces:
- One-line summary per config file (if any exist)
- References that don't resolve
- Coverage gaps

Output: `./audit/current-config.md`

## Verification

After all 4 subagents complete, verify all audit files exist before proceeding:

```bash
ls ./audit/codebase-map.md ./audit/conventions-found.md ./audit/workflows-found.md ./audit/current-config.md
```

If any file is missing, the corresponding subagent failed. Re-run the failed subagent(s) before continuing.
