---
name: update
description: Update the cwfo plugin to the latest version
allowed-tools:
  - Bash(curl:*)
  - Bash(git:*)
  - Bash(claude:*)
  - Bash(mkdir:*)
---

## Update cwfo Plugin

Reinstall the plugin from the latest remote:

```bash
claude plugin uninstall cwfo && claude plugin install cwfo@github.com/andreacanes/Claude-work-flow-optimizer
```

Also refresh the best-practice cache:

```bash
mkdir -p ~/.cache/cwfo/best-practice && for f in claude-memory.md claude-skills.md claude-subagents.md claude-mcp.md claude-commands.md claude-cli-startup-flags.md claude-settings.md; do curl -sS -f -o ~/.cache/cwfo/best-practice/$f "https://raw.githubusercontent.com/shanraisshan/claude-code-best-practice/main/best-practice/$f"; done
```

Report what was updated.
