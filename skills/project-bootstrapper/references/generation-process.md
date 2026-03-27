# Phase 3: Config Generation Process

Only generate what the user approved in Phase 2.

## 3a. Create directory structure

```bash
mkdir -p .claude/rules .claude/skills .claude/agents .claude/scripts
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
- Use naming convention: `{domain}.md` (one rule per domain, not per convention)
- Include appropriate `paths:` glob in frontmatter
- **Rule body MUST be ≤ 10 lines.** Rules are always-on for every matching file read — every line costs tokens every turn. If you have more than 10 lines of guidance for a domain, use the **two-artifact pattern** (3c + 3d together).
- Before writing, verify the `paths:` glob resolves to actual files using the `Glob` tool (not `find`, which uses different glob semantics than Claude Code's `paths:` format). If zero matches, warn the user and adjust the glob.

## 3d. Generate Subdirectory CLAUDE.md (when appropriate)

Most non-trivial directories need the **two-artifact pattern**: a short rule (≤ 10 lines, always-on pointer) paired with a subdirectory CLAUDE.md (50-300 lines, lazy-loaded full guide). This is the most common correct answer — not one or the other, but BOTH working together.

**Two-artifact pattern:**
1. `.claude/rules/{domain}.md` — ≤ 10 lines: the 2-3 constraints that break things if violated + a pointer line: `Full patterns: see src/{dir}/CLAUDE.md`
2. `src/{dir}/CLAUDE.md` — 50-300 lines: full domain knowledge, examples, patterns, templates. Only loads when Claude works in that directory.

**Use rule only (no CLAUDE.md) when:** the total guidance fits in ≤ 10 lines
**Use CLAUDE.md only (no rule) when:** there are no critical "break if violated" constraints, just reference material
**Use neither when:** the convention is already covered by root CLAUDE.md or an existing rule

**Common mistake:** Merging multiple rules into one large rule without extracting to CLAUDE.md. A 200-line merged rule has the same token cost as the original 5 separate rules. The point of consolidation is to REDUCE always-on cost by moving content to lazy-loaded CLAUDE.md, not just to reduce file count.

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

## 3i. Plan Review Enforcement

Generate the hard enforcement hook so plan review survives even without CWFO installed.

**1. Create `.claude/scripts/plan-review-gate.sh`:**

```bash
#!/bin/bash
INPUT=$(cat /dev/stdin)
PLAN_FILE=$(ls -t .claude/plans/*.md 2>/dev/null | head -1)
[ -z "$PLAN_FILE" ] && exit 0
grep -q "## Review: Complete" "$PLAN_FILE" && exit 0
cat <<'HOOK'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Plan not reviewed. Run /cwfo:review first."
  }
}
HOOK
exit 0
```

**2. Create or merge `.claude/settings.local.json`:**

If the file does not exist, create it with:

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

If `.claude/settings.local.json` already exists, merge the `ExitPlanMode` entry into the existing `hooks.PreToolUse` array. Do not overwrite other hook entries.
