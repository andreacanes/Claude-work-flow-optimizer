---
description: Nudge to consider Claude Code config when establishing new patterns
paths: ["**/*"]
---

When you create a new directory, file type, or pattern not seen elsewhere in the codebase — pause and consider whether it needs a new rule (path-scoped convention), skill (recurring workflow), or CLAUDE.md update (project-wide truth). Only propose config when the pattern WILL recur. Tell the user what you'd add and why — never create config silently.

When the user asks to "save this as a rule", "add this to the config", "make this a convention", or "update the rules" — this is a config-updater request. Apply the config-updater skill to determine the right place for the knowledge (CLAUDE.md, rule, skill, or agent) and propose the change. Note: "remember this" is Claude Code's built-in memory — do NOT intercept generic memory requests.
