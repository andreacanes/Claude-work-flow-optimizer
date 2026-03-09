---
description: Mandatory plan review before implementation — gates ExitPlanMode behind structured review
---

When a plan file has been written (in plan mode or loaded from a previous session):
1. BEFORE calling ExitPlanMode, apply /cwfo:review to the plan
2. Do NOT exit plan mode until review is complete and user has addressed findings
3. After review, add "## Review: Complete" to the plan file before ExitPlanMode

If plan was loaded from a previous session (system message about existing plan), review BEFORE implementing. Skip if plan already contains "## Review: Complete".
