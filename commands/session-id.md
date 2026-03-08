---
name: session-id
description: Show the current Claude Code session ID and file path
allowed-tools:
  - Bash(ls:*)
  - Bash(stat:*)
  - Bash(cat:*)
---

## Find Session ID

Locate the current session file by checking known paths.

### Unix / macOS

```bash
SESSION_DIR="$HOME/.claude/sessions"
if [ -d "$SESSION_DIR" ]; then
  LATEST=$(ls -t "$SESSION_DIR" 2>/dev/null | head -1)
  if [ -n "$LATEST" ]; then
    echo "Session ID: ${LATEST%.json}"
    echo "Path: $SESSION_DIR/$LATEST"
  fi
fi
```

### Windows (Git Bash / MSYS)

```bash
SESSION_DIR="$APPDATA/claude/sessions"
if [ -d "$SESSION_DIR" ]; then
  LATEST=$(ls -t "$SESSION_DIR" 2>/dev/null | head -1)
  if [ -n "$LATEST" ]; then
    echo "Session ID: ${LATEST%.json}"
    echo "Path: $SESSION_DIR/$LATEST"
  fi
fi
```

If neither path exists, report that no session directory was found and suggest the user check their Claude Code installation.
