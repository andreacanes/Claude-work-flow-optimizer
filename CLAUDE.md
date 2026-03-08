# Claude Work Flow Optimizer (cwfo)

Private Claude Code plugin for auditing, generating, and maintaining Claude Code configuration against best practices.

## Tech Stack

- Pure markdown + YAML frontmatter (Claude Code plugin format)
- Bash scripts for cache management and deterministic linting
- No build system, no package manager, no compiled code

## Project Structure

- `.claude-plugin/plugin.json` — Plugin manifest (namespace: `cwfo`)
- `skills/` — 5 skills, each with `SKILL.md` + optional `references/` subdirectory
- `skills/shared-references/` — Context files loaded by multiple skills via `context:` frontmatter
- `agents/` — 4 investigation agents (used by gap-analysis & bootstrapper)
- `rules/` — 2 rules: config-awareness (always-on), plan-review (plan files only)
- `commands/` — 2 commands: session-id, update
- `scripts/` — `update-best-practices.sh` (cache fetch), `lint.sh` (structural validation)

## Key Conventions

- **Skills**: `SKILL.md` with YAML frontmatter (`name`, `description`, `allowed-tools`, optional `context:`)
- **Agents**: `{name}.md` with YAML frontmatter (`name`, `description`, `allowed-tools`); no `model:` field (inherits user's model)
- **Rules**: YAML frontmatter (`description`, `paths:`); body ~3-5 lines max (always-on cost)
- **Shared references**: Files in `skills/shared-references/` loaded via relative `context:` paths (e.g., `../shared-references/investigation-phase.md`)
- **Skill references**: Dense conditional knowledge in `references/` subdirectory, loaded via `context:` frontmatter
- **Cache**: Best-practice files cached at `~/.cache/cwfo/best-practice/` (not in project dir — skills run in target project CWD)
- Skills do NOT inline fetch — they check cache and tell user to run `/cwfo:update` if missing

## Important: Plugin vs .claude/ Structure

This project IS a plugin — files live at `skills/`, `agents/`, `rules/`, `commands/` (NOT under `.claude/`). The `plugin.json` registers namespace `cwfo`. Skills and agents are designed to run AGAINST other projects, not this one.

## Skill Inventory

- `claude-config-audit` — Audit config (quick lint, full audit, self-check, incremental audit)
- `claude-config-gap-analysis` — Deep gap analysis: 4-agent investigation + comparison
- `config-updater` — Detect code changes and propose config updates (explicit invocation only)
- `plan-review` — Interactive plan review with 4 sections, BIG/SMALL modes
- `project-bootstrapper` — Generate initial config from scratch: investigate, design, generate

## Development Notes

- Total always-on context cost: ~48 tokens/turn
- `config-updater` uses `.claude/.cwfo-last-update` watermark in target projects
- Run `bash scripts/lint.sh .` against any project for fast structural validation
