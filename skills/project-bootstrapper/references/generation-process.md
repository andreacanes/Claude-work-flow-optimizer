# Phase 3: Config Generation Process

Only generate what the user approved in Phase 2.

## 3a. Create directory structure

```bash
mkdir -p .claude/rules .claude/skills .claude/agents
```

## 3b. Generate CLAUDE.md

If a root `CLAUDE.md` already exists:
- Read it and assess quality. If it covers the template sections well, keep it and only supplement gaps.
- If it's over 200 lines, propose trimming path-specific content to rules.
- Never silently overwrite an existing CLAUDE.md — show the user what would change.

If no `CLAUDE.md` exists, follow the template from `references/bootstrap-template.md`. Keep under 200 lines. Include:
- Project name and purpose
- Tech stack (from codebase-map)
- Project structure overview (from codebase-map)
- Development workflow (from workflows-found)
- Quality bar (from conventions-found)
- Skill inventory (if any skills created)

## 3b-2. Add Config Maintenance Section to CLAUDE.md

Every generated CLAUDE.md MUST end with this section (adapt the date):

```markdown
## Config Maintenance

This config was generated to match the codebase as of [DATE]. When the codebase evolves:

- **New directory or module**: Does it need a rule (~5-10 lines, `paths:` scoped) or subdirectory CLAUDE.md (50+ lines, domain context)?
- **New recurring workflow**: Does it need a skill?
- **Changed tech stack or structure**: Update the relevant section of this CLAUDE.md.
- **Rule whose `paths:` no longer matches files**: Delete or update it.

When proposing config changes, explain what and why. Never create config silently.
```

This section is the self-preservation mechanism. Claude reads CLAUDE.md every session, so this teaches the project to maintain its own config without external plugins. It encodes the core placement decision framework in 6 lines that Claude can act on reactively.

## 3c. Generate Rules

For each approved rule:
- Use naming convention: `{domain}-{convention}.md`
- Include appropriate `paths:` glob in frontmatter
- Keep body to ~5-10 lines
- Before writing, verify the `paths:` glob resolves to actual files using the `Glob` tool (not `find`, which uses different glob semantics than Claude Code's `paths:` format). If zero matches, warn the user and adjust the glob.

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
