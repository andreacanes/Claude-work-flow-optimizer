---
name: review
description: >
  Interactive plan review protocol. Use when the user says "review this plan",
  "check my plan", "plan review", or after completing a plan in .claude/plans/.
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash(git:*)
  - Bash(ls:*)
context:
  - references/plan-review-protocol.md
---

## Quick Start

Check for plan content in the conversation first — Claude Code loads active plans via system reminders ("A plan file exists from plan mode..."). If plan content is already in context, review that plan directly.

Otherwise, find the most recently modified plan file across both project and user directories:

```bash
ls -t .claude/plans/*.md ~/.claude/plans/*.md 2>/dev/null | head -1
```

If no plans exist, ask the user which file to review.

## Plan Mode Awareness

If operating during active plan mode (before ExitPlanMode):
- Review the plan file directly (it is writable during plan mode)
- After completing all 4 review sections, append `## Review: Complete` with a one-line summary to the plan file
- Only THEN should ExitPlanMode be called — do NOT exit plan mode until the review marker is written

## Before Starting

Ask the user which review mode they want:

**1/B) BIG change:** Work through interactively, one section at a time (Architecture → Code Quality → Tests → Performance) with at most 4 top issues per section.

**SMALL change:** Work through interactively, ONE question per review section.

## Review Sections

Work through each section sequentially, pausing for user feedback after each:

1. **Architecture Review** — system design, component boundaries, dependency graph, coupling, data flow, scaling, security
2. **Code Quality Review** — organization, DRY violations (be aggressive), error handling, edge cases, tech debt, over/under-engineering
3. **Test Review** — coverage gaps, test quality, assertion strength, missing edge cases, untested failure modes
4. **Performance Review** — N+1 queries, memory usage, caching opportunities, slow code paths

## Issue Format

For each issue found:

1. Describe the problem concretely with file and line references
2. Present 2-3 options (including "do nothing" where reasonable)
3. For each option: implementation effort, risk, impact, maintenance burden
4. Give recommended option and why

**NUMBER** issues and give **LETTERS** for options. Make the recommended option always the **first** option. When asking the user, clearly label each issue NUMBER and option LETTER.

## Engineering Preferences (Apply These)

- DRY is important — flag repetition aggressively
- Well-tested code is non-negotiable
- "Engineered enough" — not hacky, not over-abstracted
- Err on handling more edge cases, not fewer
- Bias toward explicit over clever
