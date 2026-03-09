# Claude Work Flow Optimizer (CWFO)

A Claude Code plugin that **lints, bootstraps, and maintains** your project's Claude Code configuration — `CLAUDE.md`, rules, skills, agents — against current best practices.

## The Problem

Most projects either have no Claude Code config, a copy-pasted `CLAUDE.md` that was never updated, or scattered rules that contradict each other. CWFO scans your actual codebase, figures out what config you need, and keeps it healthy as your code evolves.

## Skills

### `/cwfo:bootstrap` — Setup Wizard

Start here for new projects. Dispatches 4 investigation agents in parallel (codebase mapper, convention extractor, workflow analyzer, config inventory), synthesizes findings into a config plan, then generates everything after your approval. Every generated `CLAUDE.md` includes a Config Maintenance section so the project maintains itself without CWFO installed.

### `/cwfo:audit` — Health Check

Four modes: **Quick Lint** (structural validation — frontmatter, paths, sizes, context budget), **Full Audit** (thorough review against best practices), **Incremental Audit** (only config affected by recent changes), **Self-Check** (validates CWFO's own internal consistency).

### `/cwfo:gap-analysis` — Deep Dive

Sends the same 4 agents to explore your codebase, then compares findings against your current config. Reports what's correct, what's wrong, what's missing, and what's unnecessary. The six-month checkup to the bootstrapper's onboarding.

### `/cwfo:updater` — Drift Detection

Looks at recent git history and proposes config changes where your code has evolved but config hasn't followed. Also triggers on phrases like "save this as a rule" or "add this to the config" (note: "remember this" is Claude's built-in memory, not CWFO).

### `/cwfo:review` — Plan Review

Reviews implementation plans (`.claude/plans/`) across 4 sections: Architecture, Code Quality, Tests, Performance. Presents numbered issues with lettered options. Two modes: **BIG** (up to 4 issues/section) or **SMALL** (1 question/section).

An always-on rule mandates review before `ExitPlanMode` — plans must contain a `## Review: Complete` marker before implementation can proceed. For hard enforcement, add the recommended `PreToolUse` hook (see [Plan Review Enforcement](#plan-review-enforcement)).

## How Config Stays Current

**Self-preserving config:** Every CWFO-generated `CLAUDE.md` includes a Config Maintenance section that teaches Claude when to update config reactively — no plugin needed for day-to-day maintenance.

**Deep periodic maintenance:** `/cwfo:gap-analysis` and `/cwfo:updater` catch systematic drift that reactive maintenance misses.

**Trigger phrase routing:** An always-on rule routes "save this as a rule" / "add this to the config" / "make this a convention" to the config updater automatically.

## Installation

```bash
# Add the marketplace and install
/plugin marketplace add andreacanes/Claude-work-flow-optimizer
/plugin install cwfo@andreacanes-Claude-work-flow-optimizer
```

After installing, enable auto-updates:

```
Settings → Plugins → Marketplace → andreacanes/Claude-work-flow-optimizer → Enable auto-update
```

Installed plugins will then update automatically on each session start.

To refresh the best-practice reference cache manually:

```
/cwfo:update
```

For local development:

```bash
claude --plugin-dir /path/to/Claude-work-flow-optimizer
```

## Plan Review Enforcement

CWFO's plan-review rule provides soft enforcement (mandates `/cwfo:review` before `ExitPlanMode`). For hard enforcement, add a `PreToolUse` hook to your project's `.claude/settings.local.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "ExitPlanMode",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/scripts/plan-review-gate.sh"
          }
        ]
      }
    ]
  }
}
```

Then create `.claude/scripts/plan-review-gate.sh`:

```bash
#!/bin/bash
INPUT=$(cat /dev/stdin)
PLAN_FILE=$(ls -t .claude/plans/*.md 2>/dev/null | head -1)
[ -z "$PLAN_FILE" ] && exit 0
grep -q "## Review: Complete" "$PLAN_FILE" && exit 0
cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Plan not reviewed. Run /cwfo:review first."
  }
}
EOF
exit 0
```

This blocks `ExitPlanMode` until the plan contains a `## Review: Complete` marker, which `/cwfo:review` adds after completing all 4 review sections.

## Investigation Agents

Four agents run in parallel during bootstrap and gap analysis:

| Agent | Scans |
|-------|-------|
| **Codebase Mapper** | Project structure, languages, frameworks, build pipeline |
| **Convention Extractor** | Naming, imports, error handling, testing patterns from source |
| **Workflow Analyzer** | CI/CD, scripts, git hooks, deployment |
| **Config Inventory** | `.claude/`, `CLAUDE.md`, `.mcp.json`, other AI-tool configs |

Agents inherit your current model. Output goes to `./audit/` (cleaned up automatically).

## Commands

| Command | Purpose |
|---------|---------|
| `/cwfo:session-id` | Show current session ID and file path |
| `/cwfo:update` | Refresh best-practice reference cache |

## Best Practices Source

Pulled from [shanraisshan/claude-code-best-practice](https://github.com/shanraisshan/claude-code-best-practice) with 24h cache at `~/.cache/cwfo/best-practice/`. Skills check cache first; if stale, you're prompted to run `/cwfo:update`.

## Context Budget

| Component | Tokens/turn |
|-----------|------------|
| Config awareness rule | ~10 |
| Plan review rule | ~20 |
| Skill descriptions (5) | ~33 |
| **Total always-on** | **~63** |

Everything else loads on demand.
