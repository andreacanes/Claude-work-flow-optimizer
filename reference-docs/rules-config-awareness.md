---
description: Evaluate whether new code needs Claude Code configuration
paths: ["**/*"]
---

When you create a new directory, file type, or pattern that doesn't exist
elsewhere in the codebase, pause and consider:

- Does this directory introduce a new domain or framework that needs its
  own CLAUDE.md or rules with path globs?
- Does this file follow conventions that aren't captured in any existing
  rule? If you're making choices about structure, naming, or patterns
  that future work should follow — propose a new rule.
- Is this a multi-step workflow you're executing that would benefit from
  being captured as a skill for next time?
- If you're doing work that would benefit from context isolation or
  parallelism, would an agent definition help for future similar tasks?

Don't create config speculatively. Only propose additions when the code
you just wrote establishes a pattern that WILL recur. When you do propose,
tell the user what you'd add and why — don't create config silently.
