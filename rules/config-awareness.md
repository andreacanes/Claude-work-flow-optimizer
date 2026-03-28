---
description: Route config-update requests to the CWFO updater skill
paths: ["**/*"]
---

When the user asks to "save this as a rule", "add this to the config", "make this a convention", or "update the rules" — apply the config-updater skill to determine the right place for the knowledge (CLAUDE.md, rule, skill, or agent) and propose the change. When the user says "fix my config", "restructure CLAUDE.md", "clean up the config", "config is a mess", or "CLAUDE.md is bloated" — apply the config-restructure skill. Note: "remember this" is Claude Code's built-in memory — do NOT intercept generic memory requests.
