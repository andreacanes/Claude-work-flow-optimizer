# Phase 3: Config Generation Process

Only generate what the user approved in Phase 2.

## 3a. Create directory structure

```bash
mkdir -p .claude/rules .claude/skills .claude/agents
```

## 3b. Generate CLAUDE.md

Follow the template from `references/bootstrap-template.md`. Keep under 200 lines. Include:
- Project name and purpose
- Tech stack (from codebase-map)
- Project structure overview (from codebase-map)
- Development workflow (from workflows-found)
- Quality bar (from conventions-found)
- Skill inventory (if any skills created)

## 3c. Generate Rules

For each approved rule:
- Use naming convention: `{domain}-{convention}.md`
- Include appropriate `paths:` glob in frontmatter
- Keep body to ~5-10 lines
- Before writing, verify the `paths:` glob resolves to actual files:

```bash
find . -path './.git' -prune -o -path '{glob}' -print | head -5
```

If zero matches, warn the user and adjust the glob.

## 3d. Generate Subdirectory CLAUDE.md (when appropriate)

When investigation agents identify directories with dense, distinct context needs (50+ lines of domain-specific knowledge), generate subdirectory CLAUDE.md files instead of rules. Criteria:

- **Use subdirectory CLAUDE.md when:** the directory has domain-specific knowledge (API patterns, auth flows, framework architecture), the guidance is 50+ lines, and it only matters when working in that directory
- **Use a rule instead when:** the convention is short (5-10 lines), enforcement-style ("always use X"), and applies to a glob pattern
- **Use neither when:** the convention is already covered by root CLAUDE.md or an existing rule

If a subdirectory CLAUDE.md contradicts root CLAUDE.md, the subdirectory instruction wins for files in that directory. Keep root CLAUDE.md general and let subdirectories specialize. Never duplicate root content in subdirectories.

## 3e. Generate Skills (only if clearly needed)

Only create skills for complex, multi-step, recurring workflows. Most projects need zero skills at bootstrap. If created:
- SKILL.md with clear description and allowed-tools
- Reference files if the methodology is complex

## 3f. Generate Agents (only if clearly needed)

Only create agents for genuinely parallelizable or isolatable tasks. Most projects need zero agents at bootstrap.

## 3g. Quick Structural Validation

After generating all config, run a quick validation:
- CLAUDE.md line count < 200
- All rule `paths:` globs resolve to at least one file
- No duplicate rule filenames
- Skill descriptions are 1-2 sentences
- Total estimated always-on context < 5% of context window

Report any issues found.

## 3h. Cleanup

Delete the audit directory:

```bash
rm -rf ./audit
```
