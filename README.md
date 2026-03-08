# Claude Work Flow Optimizer (CWFO)

Your Claude Code projects have configuration -- `CLAUDE.md` files, rules, skills, agents, MCP servers. But are they set up well? Are they complete? Are they drifting out of date as your code evolves?

CWFO is a Claude Code plugin that acts as a **linter, setup wizard, and maintenance assistant** for your Claude Code project configuration. It knows the current best practices, it can scan your codebase to figure out what config you actually need, and it keeps that config healthy over time.

---

## What Problem Does This Solve?

When you set up Claude Code for a project, you make a bunch of decisions: what goes in `CLAUDE.md`, which rules to write, whether you need custom skills or agents. Most people either:

- Copy some config from another project and hope it fits
- Write a minimal `CLAUDE.md` and never touch it again
- Have no idea that rules, skills, and agents even exist

CWFO fixes all three. It examines your actual codebase, compares what you have against what you need, and helps you build and maintain a config that actually matches your project.

---

## The Skills

CWFO gives you five skills. Here is what each one does and when to use it.

### 1. Project Bootstrapper

**Invoke:** `/cwfo:bootstrap` or just say "bootstrap my project"

This is where you start on a new project (or one that has never had proper Claude Code config).

When you run it, CWFO sends four investigation agents out in parallel to explore your codebase. One maps your project structure and tech stack. One reads your source code to extract the coding conventions your team actually follows. One analyzes your CI/CD pipelines, scripts, and deployment setup. One inventories whatever Claude Code config you already have (if any).

Once all four agents report back, CWFO synthesizes their findings into a complete configuration plan: a `CLAUDE.md` tailored to your project, rules that encode your team's conventions, skills for your common workflows, and agents for your recurring multi-step tasks.

Nothing gets created until you review and approve the plan. Think of it as an onboarding wizard that actually understands what your project does.

### 2. Config Audit

**Invoke:** `/cwfo:audit` or just say "audit my config" or "lint"

This is a health check. You run it periodically to make sure your config is still in good shape. It has four modes:

- **Quick Lint** -- A fast structural scan. Are your file paths valid? Is your frontmatter formatted correctly? Is your `CLAUDE.md` under 200 lines (the recommended limit)? Are your rules loading the way you think they are? This takes seconds and catches the most common mistakes.

- **Full Audit** -- A thorough review against current best practices. Checks everything the quick lint does, plus evaluates whether your config content is well-written, whether your rules are scoped properly, whether your skills follow the recommended patterns, and more.

- **Self-Check** -- Validates the CWFO plugin itself. Useful if you are contributing to CWFO or want to verify the plugin is installed correctly.

- **Incremental Audit** -- Only checks config files that have been touched by recent changes. Useful in CI or after a batch of edits.

### 3. Gap Analysis

**Invoke:** `/cwfo:gap-analysis` or just say "run a gap analysis"

This is the deep dive. While the audit checks whether your existing config is well-formed, the gap analysis asks a harder question: **does your config actually cover what your project needs?**

It sends the same four investigation agents to explore your codebase, then compares their findings against your current config. The output is a structured report that tells you:

- What your config gets right
- What your config gets wrong (rules that contradict your actual conventions, for example)
- What is missing (conventions you follow that have no rule, workflows you repeat that could be a skill)
- What is unnecessary (config for tools or patterns you do not actually use)

If the bootstrapper is your setup wizard, the gap analysis is your six-month checkup.

### 4. Config Updater

**Invoke:** `/cwfo:updater` or say things like:
- "save this as a rule"
- "add this to the config"
- "make this a convention"
- "update the rules"
- "we should always do it this way"

Code changes. Config should change with it. The config updater looks at your recent git history and figures out whether your Claude Code config has fallen behind.

Maybe you added a new API layer following a specific pattern and there is no rule teaching Claude about it. Maybe you renamed a directory that a skill references. Maybe you adopted a new testing convention three weeks ago and your `CLAUDE.md` still describes the old one.

The updater detects these kinds of drift and proposes specific config changes. It figures out the right place for each piece of knowledge — `CLAUDE.md` for project-wide truths, a rule for path-specific conventions, a skill for recurring workflows. You review each proposal and decide what to apply. Nothing changes without your approval.

**Important:** This is different from Claude Code's built-in memory. Saying "remember this" saves to Claude's personal memory (notes to itself). Saying "save this as a rule" triggers CWFO's config updater, which writes to your project's `.claude/` configuration — rules, `CLAUDE.md`, skills — so the knowledge is shared with anyone who works on the project, not just stored in one session.

### 5. Plan Review

**Invoke:** `/cwfo:review` or just say "review this plan"

When Claude creates implementation plans (stored in `.claude/plans/`), this skill reviews them for architecture issues, code quality concerns, missing tests, and performance problems.

It presents each issue as a numbered item with lettered options so you can quickly decide: fix it, skip it, or modify the approach. This keeps plans from turning into technical debt before the first line of code is written.

A background rule also watches for plan files, so if Claude creates a plan during your session, the review protocol can trigger automatically.

---

## The Self-Maintaining Config Loop

Three pieces of CWFO work together to keep your config healthy over time:

**Config Awareness Rule (always on, passive).** This is a lightweight rule that runs every turn. It costs about 15 tokens and does one thing: when you create new patterns, conventions, or workflows during a session, it nudges you to consider whether your config should be updated. It also catches phrases like "save this as a rule" or "add this to the config" and routes them to the config updater. It never modifies anything on its own.

**Config Updater (auto-triggers or manual).** Activates when you say "save this as a rule", "make this a convention", etc. -- or when you explicitly run `/cwfo:updater`. It scans your recent git changes, figures out the right config placement, and proposes fixes. You approve each one. (Note: "remember this" goes to Claude's built-in memory, not CWFO. Use config-specific language like "add this to the rules" to trigger CWFO instead.)

**Config Audit (you trigger, periodic health check).** Every so often, run an audit to catch structural issues, formatting problems, or deviations from best practices that the updater would not catch.

Together: awareness spots the moment, the updater proposes the fix, and the audit makes sure everything stays clean.

---

## Installation

```bash
# 1. Add the marketplace
/plugin marketplace add andreacanes/Claude-work-flow-optimizer

# 2. Install the plugin
/plugin install cwfo@andreacanes-Claude-work-flow-optimizer
```

### Local Development

```bash
claude --plugin-dir /path/to/Claude-work-flow-optimizer
```

### Updating

Plugin updates flow through the marketplace. To refresh the best-practice reference cache:

```
/cwfo:update
```

---

## Other Commands

| Command | What it does |
|---------|-------------|
| `/cwfo:session-id` | Shows your current Claude Code session ID and file path |
| `/cwfo:update` | Refreshes the plugin and best-practice reference cache |

---

## How Best Practices Stay Current

CWFO does not hardcode best practices. It pulls them from [shanraisshan/claude-code-best-practice](https://github.com/shanraisshan/claude-code-best-practice) and caches them locally at `~/.cache/cwfo/best-practice/` with a 24-hour expiry.

When a skill needs reference material, it checks the cache first. If the cache is stale or missing, you get a prompt to run `/cwfo:update`. This means CWFO's advice evolves as the community's understanding of Claude Code best practices evolves.

---

## The Investigation Agents

Four agents power the bootstrapper and gap analysis skills. You do not interact with them directly -- they are dispatched automatically and run in parallel:

- **Codebase Mapper** -- Scans your project structure, identifies languages, frameworks, and the overall tech stack.
- **Convention Extractor** -- Reads your actual source code to find the implicit conventions your team follows (naming patterns, error handling style, module organization, etc.).
- **Workflow Analyzer** -- Maps your CI/CD pipelines, build scripts, deployment processes, and development workflows.
- **Config Inventory** -- Catalogs everything that currently exists in your `.claude/` directory.

These agents inherit your current model (Opus by default), so the investigation quality matches whatever you are running.

---

## Context Budget

CWFO is designed to be lightweight when idle. The always-on cost breaks down like this:

| Component | Always loaded? | Estimated tokens/turn |
|-----------|---------------|----------------------|
| Config awareness rule | Yes (all files) | ~15 |
| Plan review rule | Yes (all files) | ~20 |
| Skill descriptions (5) | Yes (descriptions only) | ~33 |
| **Total always-on** | | **~68** |

Everything else -- the agents, the best-practice references, the full skill logic -- loads on demand only when you invoke a skill. Sixty-eight tokens per turn is the standing cost of having CWFO installed.
