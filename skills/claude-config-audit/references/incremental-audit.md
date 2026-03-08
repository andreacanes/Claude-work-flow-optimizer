# Incremental Audit Mode

Fast, targeted audit covering only config items affected by recent file changes.

## 1. Determine Scope

```bash
BASE=$(cat .claude/.cwfo-last-update 2>/dev/null || git rev-parse HEAD~10)
git diff --name-only "$BASE"..HEAD
```

Save the file list and `$BASE` for the report summary.

## 2. Filter Relevant Config

For each changed file path, check which config items it affects:

- **Rules**: Read each `.claude/rules/*.md` — if its `paths:` glob matches a changed file, queue that rule for audit.
- **CLAUDE.md sections**: If changed files fall within a directory mentioned in `./CLAUDE.md` or `.claude/CLAUDE.md`, queue those sections.
- **Subdirectory CLAUDE.md**: If a `CLAUDE.md` exists in (or above) a changed file's directory, queue it.
- **Direct config changes**: If changed files are inside `.claude/` (rules, skills, agents edited directly), queue those files for structural checks.

If zero config items are relevant, report: "No config items affected by recent changes. Config is structurally unaffected." and stop.

## 3. Run Targeted Checks

For each queued item, run only the applicable checks:

| Item type | Checks |
|-----------|--------|
| Rule | `paths:` globs still resolve; no contradictions with other rules covering same paths |
| CLAUDE.md section | Sections mentioning changed directories are still accurate |
| Subdirectory CLAUDE.md | Content still reflects current directory state; no duplication with root |
| Skill (modified) | Frontmatter parses; `context:` paths resolve |
| Agent (modified) | `tools:` valid; `skills:` entries map to existing skill dirs |

## 4. Report

Use the standard format but prefix each line with `[INCREMENTAL]`:

```
[INCREMENTAL][PASS] Rule: api-testing.md — paths still resolve (3 files)
[INCREMENTAL][FAIL] Rule: legacy-utils.md — "src/legacy/**" matches 0 files
[INCREMENTAL][WARN] CLAUDE.md section "API layer" may need update — src/api/ had 4 files changed
```

End with:
> **Incremental audit complete**: N config items checked, affected by M file changes since `<BASE>`.
> Run a full audit (`/cwfo:audit`) periodically for comprehensive coverage.

## 5. Watermark Update

After reporting, ask: "Update watermark to current HEAD so the next incremental audit starts from here?"
- If yes: `mkdir -p .claude && git rev-parse HEAD > .claude/.cwfo-last-update`
- If no or no response: leave watermark unchanged.
