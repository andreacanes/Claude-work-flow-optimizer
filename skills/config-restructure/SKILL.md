---
name: restructure
description: >
  Fix structural problems in Claude Code config — shrink oversized CLAUDE.md,
  extract overloaded rules to subdirectory CLAUDE.md, de-duplicate content,
  consolidate decision history. Use when audit or gap-analysis reports problems,
  or when the user says "fix my config", "restructure CLAUDE.md",
  "clean up the config", "config is a mess", "CLAUDE.md is bloated",
  "fix the config", or "restructure config".
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(git:*)
  - Bash(ls:*)
  - Bash(wc:*)
  - Bash(bash:*)
context:
  - references/restructure-operations.md
  - references/consolidation-patterns.md
---

## Phase 0: Gather Findings

Check if audit or gap-analysis was just run in this conversation. If so, reuse those findings directly — don't re-scan.

If no recent findings exist, run a quick diagnostic:

1. Run the cwfo lint script for structural checks:
   ```bash
   bash "$(dirname "$(which claude)" 2>/dev/null || echo ~/.claude)/plugins/installed/cwfo/scripts/lint.sh" . 2>/dev/null || echo "lint.sh not available — proceeding with manual scan"
   ```
   If lint.sh isn't available, manually check:
   - `wc -l CLAUDE.md` (target: under 200)
   - Count rule body lines in `.claude/rules/` (target: under 10 each)
   - Check for subdirectory CLAUDE.md files and their sizes

2. Read root CLAUDE.md completely
3. List and sample `.claude/rules/` files (read any over 15 lines fully)
4. List subdirectory CLAUDE.md files and check sizes
5. Check for `.cwfo-last-update` watermark

Build a **problem list** — categorize each finding:

| Category | Meaning |
|---|---|
| SHRINK | CLAUDE.md over 200 lines — sections need extraction |
| EXTRACT | Rule body over 10 lines — needs two-artifact split |
| DEDUPLICATE | Same concept in 2+ locations with different wording |
| CONSOLIDATE | Decision history / reflection chains to collapse |
| REORGANIZE | Monolithic section (30+ bullets) to split by theme |
| DELETE | Stale content (dead references, superseded decisions) |

## Phase 1: Build Restructure Plan

For each problem, design the concrete fix using the operations catalog in `restructure-operations.md`.

**For SHRINK:** Tag each CLAUDE.md section as SKELETON (stays) or CANDIDATE (moves out). Use the "keep the skeleton" list from the operations catalog.

**For EXTRACT:** Draft the two-artifact split — what becomes the 10-line rule summary, what moves to the subdirectory CLAUDE.md. Check if a subdirectory CLAUDE.md already exists (merge, don't create a second one).

**For DEDUPLICATE:** Identify all locations, pick the canonical one per the algorithm in the operations catalog, plan what gets deleted vs replaced with pointers.

**For CONSOLIDATE:** Follow the patterns in `consolidation-patterns.md`. Read all versions chronologically, extract only final-state decisions.

**For REORGANIZE:** Group bullets by theme, plan subsections of 5-15 items each.

**For DELETE:** Verify content is truly stale. Check git blame — recent additions (last 5 commits) get flagged for user confirmation, not auto-deleted.

Estimate line counts: **before and after** for every file that will change.

## Phase 2: Present Plan and Get Approval

**This phase is mandatory and blocking. No writes happen until the user approves.**

Present a summary table:

```
File                          Current    Target    Operations
─────────────────────────────────────────────────────────────
CLAUDE.md                     365        142       SHRINK, CONSOLIDATE, REORGANIZE
.claude/rules/anti-slop.md    53         10        EXTRACT
src/lib/CLAUDE.md             131        155       EXTRACT target (absorbs rule content)
[etc.]
```

Group operations by risk:
- **LOW** — Reorganize sections, add pointers, create new subdirectory CLAUDE.md
- **MEDIUM** — Extract content from rules/CLAUDE.md to new locations, merge duplicates
- **HIGH** — Delete sections, rewrite decision history, remove files

For HIGH-risk operations, show explicit before/after diffs so the user sees exactly what content would be removed or rewritten.

Accept approval at any granularity:
- "approve all" — apply everything
- "approve LOW+MEDIUM" — safe changes only, revisit HIGH later
- Per-operation approval — maximum control

## Phase 3: Execute

Apply approved operations in **dependency order** to avoid broken references:

1. **Create directories** — `mkdir -p` for any new subdirectory CLAUDE.md locations
2. **Create new files** — Write new subdirectory CLAUDE.md files (extraction targets must exist before rules shrink to reference them)
3. **Gut overloaded rules** — Edit rules down to 10-line summaries with pointers to the new subdirectory CLAUDE.md files
4. **Rewrite root CLAUDE.md** — Remove extracted content, consolidate sections, ensure Config Maintenance section exists
5. **Delete stale content** — Only content the user approved for deletion
6. **Update cross-references** — Fix any rule `paths:` globs or pointers that changed

After each major step, verify the affected files are coherent (no broken references, no orphaned pointers).

## Phase 4: Validate and Report

1. Run lint.sh again (or manual checks) to verify the result passes all structural checks
2. Verify all rule `paths:` globs still resolve to actual files
3. Check that no subdirectory CLAUDE.md exceeds 300 lines
4. Check that root CLAUDE.md is under 200 lines

Report the delta:

```
Restructure complete.
  CLAUDE.md:                    365 → 142 lines  (-61%)
  Rules restructured:           3 (anti-slop, react-patterns, css-methodology)
  Subdirectory CLAUDE.md created: 2 (src/components/, src/styles/)
  Subdirectory CLAUDE.md updated: 1 (src/lib/)
  Content deleted:              Architecture Reflections v1-v6 (consolidated)
  Lint result:                  13 passed, 0 failed, 0 warnings
```

List all modified and created files, then ask once: **"Commit these config changes?"**

If lint reveals new issues introduced by the restructure, fix them before reporting to the user.

## Important Safety Rules

1. **Never delete content that exists nowhere else.** Before removing anything, verify it's captured in code, another config file, or git history.
2. **Never overwrite a subdirectory CLAUDE.md without reading it first.** It may contain content added by hand that shouldn't be lost.
3. **Check git status before starting.** If there are uncommitted changes, warn the user: "You have uncommitted changes. Consider committing first so you can review or revert the restructure."
4. **Preserve rationale for surprising decisions.** When consolidating, keep brief "why" notes for counterintuitive rules.
5. **One commit scope.** All restructure changes should be committable as a single atomic change. Don't leave the config in a half-restructured state.
