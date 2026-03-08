---
description: Route config-update requests to the CWFO updater skill
paths: ["**/*"]
---

When the user asks to "save this as a rule", "add this to the config", "make this a convention", or "update the rules" — apply the config-updater skill to determine the right place for the knowledge (CLAUDE.md, rule, skill, or agent) and propose the change. Note: "remember this" is Claude Code's built-in memory — do NOT intercept generic memory requests.
