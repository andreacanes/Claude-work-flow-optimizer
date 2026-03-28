# Consolidation Patterns

## Core Principle

CLAUDE.md captures **current state**, not history. Decision history belongs in git commits, ADR files, or planning docs — never in always-on context that Claude reads every turn.

---

## Pattern 1: Inline Architecture Reflections

**Detection:** Sections named "Architecture Reflection v1", "Architecture Reflection v2", etc., or timestamped decision blocks like "2025-01-15: Changed X to Y".

**Problem:** Each reflection amends the previous one. By v6, the reader must mentally replay all six versions to know the current state. This wastes context and introduces contradictions when earlier versions aren't fully superseded.

**Consolidation Algorithm:**
1. Read all reflection versions in chronological order
2. For each topic (e.g., "border radius tiers", "animation presets", "phase ordering"):
   - Find the **latest** decision that addresses it
   - Record only that decision, not the evolution
3. Write a single "Architecture Decisions" section with one bullet per decision
4. If a decision has important constraints or rationale, add it as a sub-bullet
5. Delete all individual reflection blocks

**Before (90 lines across v1-v6):**
```markdown
## Architecture Reflection v1
- 3 dark mode profiles mapped to archetype
- Section catalog from reference-sections/

## Architecture Reflection v3
- Border radius: 3 tiers by archetype
- Per-form API routes, not catch-all

## Architecture Reflection v5
- Dark mode: lightness values adjusted (was 15/20/25, now 18/22/28)
- Animation presets pinned to exact Motion values

## Architecture Reflection v6
- Dark mode: balanced-only for MVP (defer other profiles)
- Animation: AI overrides only if justified
```

**After (12 lines):**
```markdown
## Architecture Decisions
- Dark mode: balanced profile only for MVP; lightness 18/22/28. Other profiles deferred.
- Border radius: 3 archetype tiers — Sharp+Luxurious → rounded-md, Warm → rounded-lg, Playful+Bold → rounded-xl. Scripted lookup.
- Animation presets: exact Motion values (constant table). AI overrides only if explicitly justified.
- API routes: per-form, not catch-all.
- Section catalog: sourced from reference-sections/ directory.
```

---

## Pattern 2: Accumulated "Notes to Self"

**Detection:** Sections like "Important Notes", "Things to Remember", "Gotchas", or scattered inline comments like "NOTE:", "IMPORTANT:", "REMEMBER:".

**Problem:** These accumulate over conversations without cleanup. Many are resolved, outdated, or captured elsewhere in rules. They bloat CLAUDE.md with one-off reminders that became permanent.

**Consolidation Algorithm:**
1. Collect all "note" items across the file
2. For each note, check:
   - Is it captured in a rule or subdirectory CLAUDE.md? → Delete (duplicate)
   - Is it still accurate? (Check against code) → Keep if yes, delete if no
   - Is it a one-time instruction that's been completed? → Delete
   - Is it a genuine ongoing constraint? → Move to the relevant section or rule
3. If 3+ notes survive about the same topic, they're a rule candidate
4. Delete the "Notes" section entirely — its surviving content now lives in proper locations

**Before:**
```markdown
## Notes
- NOTE: Sub-plans in master-plan/sub-plans/ are STALE
- IMPORTANT: Always seed Sanity content right after schema deploy
- REMEMBER: No Inter font — banned by anti-slop rules
- NOTE: Phase 6.5 runs AFTER Phase 6, not during
- IMPORTANT: Stripe is test mode only until launch
```

**After:** (section deleted entirely)
- Stale sub-plans note → deleted (covered by CLAUDE.md being the source of truth)
- Sanity seeding → already in pipeline section or rule
- No Inter font → already in anti-slop rule
- Phase ordering → already in pipeline section
- Stripe test mode → already in stripe-patterns rule

---

## Pattern 3: Versioned Convention Descriptions

**Detection:** The same convention described differently in multiple places because it was updated over time but not all copies were synced.

**Example:** Animation presets described as "exact values" in one place and "AI can override" in another — because the convention evolved from strict to flexible but the strict version was never updated.

**Consolidation Algorithm:**
1. Identify all locations describing the convention
2. Check git blame to find which is newest
3. Verify the newest version against actual code (if implemented)
4. Write the canonical version in one location (per the deduplication rules)
5. Delete or replace all other versions

---

## Pattern 4: Planning Content in CLAUDE.md

**Detection:** Sections about "Current Status", "Build Checklist", "Phase Progress", "Remaining Work", "TODO", or references to external planning documents.

**Problem:** Planning content changes constantly and belongs in dedicated planning docs (BUILD-CHECKLIST.md, project boards, etc.), not in CLAUDE.md which is a stable specification document. When planning content lives in CLAUDE.md, it rots faster than any other section.

**Consolidation Algorithm:**
1. Identify all planning/status sections in CLAUDE.md
2. Check if the planning content exists elsewhere (e.g., BUILD-CHECKLIST.md, .claude/plans/)
3. If yes → delete from CLAUDE.md, optionally add 1-line pointer ("Task tracking: see BUILD-CHECKLIST.md")
4. If no → move to a dedicated planning doc, then delete from CLAUDE.md
5. CLAUDE.md should say **what** the project is and **how** to work on it, not **where** the project currently is

---

## Safety Rules for All Consolidation

1. **Never discard information that exists nowhere else.** Before deleting, verify the content is captured in code, rules, subdirectory CLAUDE.md, or git history.
2. **When in doubt, ask.** If you can't determine whether a decision is current or superseded, present both versions to the user and ask which is canonical.
3. **Preserve rationale for surprising decisions.** If a decision seems counterintuitive (e.g., "no TypeScript enums" or "no ORM"), keep a brief "why" — it prevents future contributors from reversing it.
4. **Check git blame before deleting.** If content was added in the last 5 commits, the user likely still cares about it. Flag it rather than deleting.
