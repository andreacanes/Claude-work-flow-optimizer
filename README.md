# Claude Work Flow Optimizer (cwfo)

A private Claude Code plugin that audits and maintains Claude Code configuration (CLAUDE.md, rules, skills, agents, MCPs) against current best practices.

## Installation

```bash
# 1. Add the marketplace
/plugin marketplace add andreacanes/Claude-work-flow-optimizer

# 2. Install the plugin
/plugin install cwfo@andreacanes-Claude-work-flow-optimizer
```

### Local development

```bash
claude --plugin-dir /path/to/Claude-work-flow-optimizer
```

### Updating

Plugin updates flow through the marketplace. To refresh best-practice reference cache:

```
/cwfo:update
```

## Available Skills

| Skill | Trigger | Description |
|-------|---------|-------------|
| `/cwfo:claude-config-audit` | "audit", "review config", "lint my config" | Full architecture audit or quick structural lint |
| `/cwfo:claude-config-gap-analysis` | "gap analysis", "deep audit", "comprehensive review" | Deep gap analysis with 4 parallel investigation streams |
| `/cwfo:config-updater` | "update config", "save this pattern" | Git-aware config drift detector (explicit invocation only) |
| `/cwfo:plan-review` | "review this plan", "plan review" | Interactive plan review with numbered issues and options |
| `/cwfo:project-bootstrapper` | "bootstrap", "initialize claude config", "set up claude" | Generate initial Claude Code config from scratch |

## Available Commands

| Command | Description |
|---------|-------------|
| `/cwfo:session-id` | Show current Claude Code session ID and file path |
| `/cwfo:update` | Update the plugin to the latest version + refresh best-practice cache |

## Rules (Always-on)

- **config-awareness** — Nudges when you create new patterns that might need config
- **plan-review** — Auto-triggers review protocol when working in `.claude/plans/`

## Agents (Used by Gap Analysis & Bootstrapper)

- `codebase-mapper` — Scans project structure and tech stack
- `convention-extractor` — Extracts implicit coding conventions from source
- `workflow-analyzer` — Maps CI/CD, scripts, and deployment workflows
- `config-inventory` — Inventories all current `.claude/` config files

## Best Practice Auto-Update

The plugin references best-practice docs from [shanraisshan/claude-code-best-practice](https://github.com/shanraisshan/claude-code-best-practice). These are fetched and cached at `~/.cache/cwfo/best-practice/` with a 24-hour TTL.

Skills check for cached references and prompt you to run `/cwfo:update` if missing. You can also manually refresh:

```bash
bash scripts/update-best-practices.sh
```

## Context Budget

| Component | Always loaded? | Est. tokens/turn |
|-----------|---------------|-----------------|
| config-awareness rule | Yes (all files) | ~15 |
| plan-review rule | Only on plan files | ~15 when active |
| Skill descriptions (5) | Yes (descriptions only) | ~33 |
| **Total always-on** | | **~48** |

Everything else loads on-demand only when skills are invoked.
