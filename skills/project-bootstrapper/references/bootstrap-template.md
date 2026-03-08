# Bootstrap Config Template

Quick-reference for Phase 2 config generation decisions.

## CLAUDE.md Structure Checklist

Target: < 200 lines. Include only what applies.

```
# {Project Name}

## Tech Stack
- Language(s) and version(s)
- Framework(s)
- Package manager
- Key dependencies

## Project Structure
- Top-level directory layout (one line per directory)
- Entry points
- Where tests live

## Development Workflow
- How to install dependencies
- How to run the dev server
- How to run tests
- How to build for production
- How to deploy (if applicable)

## Quality Bar
- What "done" looks like for a PR
- Required checks (lint, test, type-check)
- Code style essentials (only what's NOT enforced by tooling)

## Skill Inventory
- One line per skill describing when to use it

## Config Maintenance
- When to update CLAUDE.md, create rules, or add skills
- Decision framework for new patterns (always included — see generation-process.md 3b-2)
```

## Subdirectory CLAUDE.md Guidelines

**When to use subdirectory CLAUDE.md instead of rules:**
- Dense, directory-specific context (50+ lines) — API patterns, auth flows, framework architecture
- Domain knowledge that only matters when working in that directory
- Content too large for a rule (rules should be ~5-10 lines; anything >15 lines is a smell)

**When to use a rule instead:**
- Short convention (5-10 lines), enforcement-style ("always use X"), applies to a glob pattern

**In-between (15-49 lines):** Content too large for a rule but not quite 50 lines. Use a rule if the content can be compressed to ~10 lines without losing meaning. Otherwise use a subdirectory CLAUDE.md — the 50-line threshold is a guideline, not a hard cutoff. A 30-line CLAUDE.md with dense domain context is better than a 30-line always-on rule.

**Conflict resolution:** If a subdirectory CLAUDE.md contradicts root CLAUDE.md, the subdirectory instruction wins for files in that directory. Keep root CLAUDE.md general and let subdirectories specialize. Never duplicate root content in subdirectories.

**Nesting depth:** 2 levels (root + component) is the norm. 3+ levels are justified only for genuinely distinct sub-domains (e.g., `packages/payments/providers/stripe/CLAUDE.md` where Stripe-specific patterns differ from other payment providers). If you find yourself at 4+ levels, the directory structure itself may need flattening.

## Rule Naming Convention

Format: `{domain}-{convention}.md`

Examples:
- `react-component-structure.md`
- `api-error-handling.md`
- `testing-naming-convention.md`
- `css-methodology.md`

## Rule Structure

```yaml
---
description: One-line summary of what this enforces
paths:
  - "src/components/**/*.tsx"  # Be specific
---
```

Body: ~5-10 lines. State the convention clearly and concisely.

## Skill Structure Requirements

- SKILL.md frontmatter: `name`, `description` (1-2 sentences), `allowed-tools` (minimal)
- Description must include trigger phrases for auto-invocation
- Body: step-by-step process, < 500 lines
- Complex reference material: separate files in `references/`
- Scripts: only for computation Claude cannot do by thinking

## Agent Structure Requirements

- Frontmatter: `name`, `description` (clear enough for auto-delegation)
- No `model:` field (inherits user's model)
- `tools:` restricted to what the agent actually needs
- `skills:` preloads only if the agent uses those skills

## Context Budget Targets

| Component | Target |
|-----------|--------|
| CLAUDE.md | < 200 lines |
| Each rule body | ~5-10 lines |
| Skill descriptions | 1-2 sentences each |
| Total always-on (CLAUDE.md + rules + descriptions) | < 5% of context |

## Bootstrap Minimalism Principle

At bootstrap time, prefer:
- 1 accurate CLAUDE.md over 5 speculative rules
- 0 skills over 1 skill that might not recur
- 0 agents over 1 agent that doesn't need isolation
- A rule that covers 80% of cases over 3 rules that cover 95%

The maintenance loop fills gaps over time. Bootstrap creates the floor, not the ceiling.

## Research-Backed Guidance

Apply these findings when generating config:

- **Context budget rationale:** The < 200 line CLAUDE.md limit isn't arbitrary — smart retrieval (rules, skills, `context:`) outperforms brute-force loading. Even with 1M context windows, loading everything upfront degrades signal-to-noise.
- **File-based handoffs:** For multi-step workflows, write intermediate results to files rather than passing through conversation context. This enables parallel execution and prevents context bloat.
- **Task sizing:** Skills and agents work best when scoped to 15-45 minute tasks. Larger tasks should be decomposed into phases with file-based handoffs between them.
- **Self-preserving config:** Every generated CLAUDE.md must include the Config Maintenance section (see generation-process.md step 3b-2). This teaches the project to maintain its own config without requiring an external plugin. Claude reads CLAUDE.md every session and follows the maintenance guidance reactively. Do NOT generate a separate config-awareness rule — the CLAUDE.md section is more reliable (always loaded, never path-gated).
- **Subagent guidance:** Use agents for simplification (independent parallel tasks) and verification (isolated validation), not for orchestration. The main conversation should orchestrate; agents should execute.
