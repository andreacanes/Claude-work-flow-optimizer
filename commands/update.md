---
name: update
description: Refresh the cwfo best-practice reference cache
allowed-tools:
  - Bash(curl:*)
  - Bash(mkdir:*)
---

## Refresh Best-Practice Cache

Fetch the latest best-practice reference files:

```bash
mkdir -p ~/.cache/cwfo/best-practice && for f in claude-memory.md claude-skills.md claude-subagents.md claude-mcp.md claude-commands.md claude-cli-startup-flags.md claude-settings.md; do curl -sS -f -o ~/.cache/cwfo/best-practice/$f "https://raw.githubusercontent.com/shanraisshan/claude-code-best-practice/main/best-practice/$f"; done
```

Report which files were updated. Plugin updates are handled through the marketplace — no reinstall needed.
