# CWFO Self-Check Protocol

Validate the CWFO plugin's own internal consistency. Resolve all paths relative to the plugin root (the directory containing `.claude-plugin/`).

Find the plugin root first:

```bash
# The plugin is installed — find its location
plugin_root=$(claude plugin list 2>/dev/null | grep -i cwfo | grep -oP '(?<=@).*' || echo "")
```

If that fails, check the known install path or ask the user. All checks below use `$PLUGIN_ROOT` as the plugin directory.

## Checks

### 1. Plugin Manifest
Read `.claude-plugin/plugin.json`. Verify it has `name`, `description`, and `version` fields.

### 2. Context Path Resolution
For every `SKILL.md` in `skills/*/`, parse the `context:` frontmatter entries. For each entry, resolve it relative to that SKILL.md's directory and verify the target file exists. Report each path and its status.

### 3. Shared Reference Integrity
Verify `skills/shared-references/investigation-phase.md` exists. Read it and confirm it references all 4 agents: `codebase-mapper`, `convention-extractor`, `workflow-analyzer`, `config-inventory`. Flag any missing agent reference.

### 4. Agent-Skill Alignment
Read `skills/shared-references/investigation-phase.md` to find which agent files it dispatches. Verify each referenced agent exists in `agents/`. Also verify no agent files exist in `agents/` that are NOT referenced by any skill.

### 5. Generation Process Completeness
Read `skills/project-bootstrapper/references/generation-process.md`. Verify it covers all required steps:
- Directory creation (`.claude/`, `.claude/rules/`, `.claude/skills/`, `.claude/agents/`)
- Root CLAUDE.md generation
- Rules generation
- Subdirectory CLAUDE.md generation
- Skills generation
- Agents generation
- Validation step
- Cleanup step

Flag any missing step.

### 6. Decision Framework Consistency
Read the placement decision matrix from these 4 files:
- `skills/claude-config-audit/references/audit-checklist-summary.md`
- `skills/config-updater/SKILL.md`
- `skills/project-bootstrapper/SKILL.md`
- `skills/project-bootstrapper/references/bootstrap-template.md`

Each should list the same placement options (CLAUDE.md, rules, subdirectory CLAUDE.md, skills, agents, MCPs, scripts) in the same priority order. Flag any file that omits options or reorders them.

### 7. Cache Dependency Check
Find all skills whose SKILL.md references `~/.cache/cwfo/best-practice/`. For each, verify it also contains the graceful degradation message (the "Best-practice references not found" fallback telling users to run `/cwfo:update`). Flag skills that use the cache without a fallback.

### 8. Update Command Cross-Reference
Read `commands/update.md` and extract the list of files it fetches into the cache. Then scan all SKILL.md files for cache file references (`~/.cache/cwfo/best-practice/*.md`). Flag any file referenced by a skill but not fetched by the update command, or fetched but never referenced.

## Output Format

Use the same format as Quick Lint:

```
[PASS] Plugin manifest: name, description, version present
[FAIL] Context path: skills/plan-review/SKILL.md → ../../plan-review-protocol.md not found
[WARN] Decision framework: config-updater/SKILL.md omits "scripts" placement option
```

End with: `X passed, Y failed, Z warnings`.
