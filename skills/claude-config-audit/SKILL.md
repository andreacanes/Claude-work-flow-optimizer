---
name: audit
description: >
  Audit a project's Claude Code architecture — CLAUDE.md, rules, skills, agents, MCPs.
  Use when the user says "audit", "review config", "check my claude setup",
  "is my config correct", "what's wrong with my claude config",
  "quick check", "validate config", "lint my config", "lint config",
  "self-check", "check plugin health", "validate cwfo",
  "incremental audit", "what changed", or "audit recent changes".
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash(wc:*)
  - Bash(git:*)
  - Bash(ls:*)
  - Bash(bash:*)
context:
  - references/audit-checklist-summary.md
  - references/self-check.md
  - references/incremental-audit.md
---

## Setup

Best-practice reference files are cached at `~/.cache/cwfo/best-practice/`. Check if they exist and are recent:

```bash
ls ~/.cache/cwfo/best-practice/*.md 2>/dev/null | head -1
```

If the cache directory is missing or empty, do NOT fetch inline. Tell the user:

> **Best-practice references not found.** Run `/cwfo:update` to fetch them. Without references, Quick Lint Mode is fully functional but Full Audit will check structural correctness only, not best-practice alignment.

If the user wants to proceed without references, continue with structural checks only. If references exist, proceed normally.

## Mode Selection

If the user said "self-check", "check plugin health", or "validate cwfo" → run **Self-Check Mode** below.
If the user said "incremental audit", "what changed", or "audit recent changes" → run **Incremental Audit Mode** below.
If the user said "quick check", "validate config", "lint", or similar → run **Quick Lint Mode** below.
Otherwise → run the **Full Audit Process**.

---

## Self-Check Mode

Validates CWFO's own internal consistency, not a target project. Follow the protocol in `references/self-check.md`. Use `[PASS]`/`[FAIL]`/`[WARN]` output format and end with a summary line.

---

## Incremental Audit Mode

Fast, targeted audit of only the config items affected by recent file changes. Complements (does not replace) full audit. Follow the protocol in `references/incremental-audit.md`. Uses the same `.claude/.cwfo-last-update` watermark as config-updater. Use `[INCREMENTAL][PASS]`/`[INCREMENTAL][FAIL]`/`[INCREMENTAL][WARN]` output format.

---

## Quick Lint Mode

If the cwfo plugin's `scripts/lint.sh` is available, you can run it for fast deterministic validation: `bash <cwfo-plugin-path>/scripts/lint.sh .` — parse and report its output. If the script isn't available, perform the checks manually as described below.

Structural validation only. Skips best-practice comparison.

1. **CLAUDE.md line count:** `wc -l ./CLAUDE.md` — flag if > 200 lines.
2. **Config maintenance:** Check CLAUDE.md has a Config Maintenance section. WARN if missing.
3. **Rule frontmatter:** Read every file in `.claude/rules/`. Verify YAML frontmatter parses correctly.
4. **Rule path resolution:** For each rule with `paths:` globs, verify each glob resolves to at least one file. Flag dead rules.
5. **Rule body length:** Measure body lines (after frontmatter). WARN >15 lines, FAIL >50 lines. Report worst offender and total.
6. **Always-on / broad-glob rules:** Detect rules without `paths:` (WARN if total body >30 lines). Also detect rules with broad globs like `src/**` that are functionally always-on.
7. **Context budget:** Estimate tokens per directory (~10/line). FAIL >5000, WARN >3000. This is the primary overlap metric.
8. **Rule overlap count:** WARN if >15 rules fire simultaneously on any directory (secondary to tokens).
9. **Subdirectory CLAUDE.md size:** WARN if any subdirectory CLAUDE.md exceeds 300 lines.
10. **CLAUDE.md consistency:** Check root CLAUDE.md doesn't contradict actual architecture (e.g., "rules are self-contained" when subdirectory CLAUDE.md files exist).
11. **Skill frontmatter:** Read every `SKILL.md` in `.claude/skills/*/`. Verify YAML frontmatter parses.
12. **Skill preload resolution:** For each skill with `context:` references, verify the referenced files exist.
13. **Agent preload resolution:** For each agent with `skills:` entries, verify the referenced skill directories exist.
14. **Duplicate detection:** Check for duplicate rule filenames across `.claude/rules/`.

Use this output format for each check:

```
[PASS] CLAUDE.md: 142 lines (< 200 limit)
[FAIL] Rule path resolution: api-testing.md → "src/api-tests/**" matches 0 files
[PASS] Skill frontmatter: 3/3 skills parse correctly
[WARN] Agent tool restriction: codebase-mapper allows Bash(find:*) — consider restricting
```

- `[PASS]` — check passed
- `[FAIL]` — structural problem that must be fixed
- `[WARN]` — not broken but worth reviewing

End with a summary line: `X passed, Y failed, Z warnings`.

---

## Full Audit Process

Review this project's Claude Code architecture and report whether each piece is correctly placed. For each section, read the corresponding best-practice reference file from `~/.cache/cwfo/best-practice/` BEFORE evaluating.

### 1. CLAUDE.md

**Read first:** `~/.cache/cwfo/best-practice/claude-memory.md`

Read `./CLAUDE.md` and any `.claude/CLAUDE.md`. Evaluate:
- Is it under 200 lines?
- Does it contain ONLY permanent project-wide truths (tech stack, workflow, quality bar, file conventions, skill inventory)?
- Flag anything that should be a rule, skill, or agent instruction instead.
- Check for `@imports` that should be lazy-loaded references instead.

### 2. Subdirectory CLAUDE.md files

**Read first:** `~/.cache/cwfo/best-practice/claude-memory.md`

Find all CLAUDE.md files in subdirectories. Evaluate:
- Are they being used where `.claude/rules/` with path globs would be more reliable?
- Is there content duplicated from root CLAUDE.md?

### 3. Rules (.claude/rules/)

**Read first:** `~/.cache/cwfo/best-practice/claude-memory.md`

Read every rule file. Evaluate:
- Does each one have appropriate `paths:` globs?
- Do `paths:` globs resolve to at least one actual file? (Glob each pattern to verify. Flag dead rules.)
- Are there rules without paths that should just be in CLAUDE.md?
- Are there instructions in CLAUDE.md that are path-specific and should be rules instead?
- Are there overlapping or contradictory rules?

### 4. Skills (.claude/skills/)

**Read first:** `~/.cache/cwfo/best-practice/claude-skills.md`

Read every SKILL.md. For each skill:
- Is the description "pushy" enough for auto-invocation?
- Is anything in the skill that should be a rule (always-on convention) instead?
- Is anything in the skill that should be an MCP (persistent state, external API) instead?
- Are `scripts/` being used for computation that Claude can do by thinking alone?
- Are `scripts/` duplicating what an MCP already provides?
- Is SKILL.md under 500 lines with clear pointers to `references/`?

### 5. Agents (.claude/agents/)

**Read first:** `~/.cache/cwfo/best-practice/claude-subagents.md`

Read every agent file. For each agent:
- Does it need isolation or could this run inline in the main conversation?
- Is the description clear enough for automatic delegation?
- Does it preload the right skills via `skills:` frontmatter? Do `skills:` entries map to existing skill directories?
- Does it have appropriate tool restrictions (not too broad, not too narrow)? Are `tools:` entries valid tool names?
- Would file-based handoffs between agents work, and are they documented?
- Is the agent doing work that could be parallelized but isn't, or is parallelized but shouldn't be?

### 6. MCPs (.mcp.json)

**Read first:** `~/.cache/cwfo/best-practice/claude-mcp.md`

Read the MCP config. For each server:
- Does this provide a capability Claude genuinely cannot do by thinking + skill scripts?
- Is it here for persistent state, external API access, or cross-tool portability?
- Could this be replaced by a skill with `scripts/`?
- Is it configured at the right scope (project vs user)?

### 7. Cross-cutting concerns

- Is there logic split across CLAUDE.md + rules + skills that should live in one place?
- Are agents referencing skills they don't preload?
- Are there MCPs that no agent or skill references?
- Is the overall context budget reasonable? (CLAUDE.md + rules + skill descriptions should fit comfortably under 5% of context at startup)

## Output Format

For each system, report:

- **CORRECT:** things properly placed
- **MISPLACED:** things that belong somewhere else (say where)
- **MISSING:** things that should exist but don't
- **REDUNDANT:** things duplicated across systems

End with a **prioritized list of specific changes** to make, ordered by impact.
