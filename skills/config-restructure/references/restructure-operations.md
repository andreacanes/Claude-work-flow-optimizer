# Restructure Operations Catalog

## Operation Types

Every finding maps to exactly one operation. Apply them in the order listed (dependencies flow downward).

---

## 1. SHRINK — Reduce Oversized CLAUDE.md

**Trigger:** CLAUDE.md exceeds 200 lines.

**Strategy — "Keep the Skeleton"**

These sections belong in root CLAUDE.md (the skeleton):
- Project identity (1-2 sentences: what this is)
- Tech stack (table or short list)
- Project structure (directory tree, ~10-20 lines)
- Development workflow (how to run, build, test, deploy)
- Quality bar (key conventions, anti-patterns — 10-15 lines max)
- Skill/agent inventory (table with name + one-line purpose)
- Config Maintenance section (mandatory, ~5 lines)

Everything else is an **extraction candidate**:
- Detailed architecture decisions → subdirectory CLAUDE.md or dedicated rule
- Domain-specific conventions → rules with `paths:` globs
- Multi-step workflows → skills
- Reference data (tables, mappings, tier lists) → subdirectory CLAUDE.md in the relevant directory
- Planning/status content → separate planning docs (not CLAUDE.md)

**Process:**
1. Read full CLAUDE.md and tag each section as SKELETON or CANDIDATE
2. For each CANDIDATE, determine destination (rule, subdirectory CLAUDE.md, skill, or delete)
3. Move content out, replace with 1-line pointer if needed
4. Target: CLAUDE.md under 150 lines (buffer below the 200-line hard limit)

---

## 2. EXTRACT — Two-Artifact Pattern for Dense Content

**Trigger:** Rule body exceeds 10 lines, OR CLAUDE.md section contains 20+ lines of path-specific content.

**The Two-Artifact Pattern:**
- **Artifact 1 — Rule file** (`.claude/rules/`): Short pointer, max 10 lines body. Contains the constraint/enforcement statement and a reference to where the full guide lives.
- **Artifact 2 — Subdirectory CLAUDE.md**: Full dense content, 50-300 lines. Lazy-loaded only when Claude works in that directory.

**Step-by-step:**
1. Identify the target directory (use the rule's `paths:` glob, or the directory the content is about)
2. Check if a subdirectory CLAUDE.md already exists there — if yes, merge into it rather than creating a new one
3. Write the subdirectory CLAUDE.md with the full content (50-300 lines)
4. Rewrite the rule to a 10-line summary with a pointer: `Full guide: see [directory]/CLAUDE.md`
5. Verify the rule's `paths:` glob still resolves to actual files

**WRONG — Overloaded rule (45 lines):**
```markdown
---
description: React component conventions
paths: ["src/components/**/*"]
---
Use server components by default. Only add "use client" when...
[40 more lines of detailed patterns, examples, edge cases]
```

**RIGHT — Two-artifact split:**
```markdown
# .claude/rules/react-patterns.md (8 lines body)
---
description: React component patterns — pointer to full guide
paths: ["src/components/**/*"]
---
Server components by default; "use client" only for interactivity.
Use cn() for conditional classes. Section wrapper for all page sections.
Full patterns and examples: see src/components/CLAUDE.md
```
```markdown
# src/components/CLAUDE.md (80 lines)
# React Component Patterns
[Full content with examples, edge cases, props conventions, etc.]
```

---

## 3. DEDUPLICATE — Single Source of Truth

**Trigger:** Same concept described in 2+ locations with different wording or detail levels.

**Canonical Location Algorithm:**

| Content type | Canonical home | Other locations get |
|---|---|---|
| Project-wide truth (tech stack, conventions that apply everywhere) | Root CLAUDE.md | Nothing — delete the duplicate |
| Path-specific enforcement ("always do X in this directory") | Rule with `paths:` | Nothing — delete the duplicate |
| Dense domain context (50+ lines of API patterns, framework guide) | Subdirectory CLAUDE.md | Rule gets a 1-line pointer, root CLAUDE.md gets nothing |
| Multi-step workflow | Skill | Nothing — delete the duplicate |

**Process:**
1. For each duplicated concept, identify all locations
2. Determine which location is canonical (use table above)
3. Ensure the canonical copy is complete and correct (merge any unique details from duplicates into it)
4. In non-canonical locations: delete the content entirely, or replace with a 1-line pointer if the reader needs to know the concept exists
5. Never leave two locations with substantive descriptions of the same thing

**Common duplication chains to watch for:**
- Border radius / color / typography values repeated in CLAUDE.md + rule + subdirectory CLAUDE.md
- Deployment steps repeated in CLAUDE.md + skill + rule
- API patterns repeated in CLAUDE.md "Key Rules" section + domain-specific rule + subdirectory CLAUDE.md

---

## 4. CONSOLIDATE — Collapse Decision History

**Trigger:** Multiple timestamped or versioned entries about the same topic (e.g., "Architecture Reflection v1" through "v6").

See `consolidation-patterns.md` for detailed patterns and examples.

**Quick algorithm:**
1. Read all versions chronologically
2. Extract only the **final-state decisions** (what was actually adopted)
3. Write a single clean section with current architecture/decisions
4. Delete all intermediate versions — history belongs in git, not CLAUDE.md

---

## 5. REORGANIZE — Split Monolithic Sections

**Trigger:** A single section contains 30+ bullet points or 50+ lines of mixed concerns.

**Process:**
1. Read all bullets/items in the section
2. Tag each by theme (e.g., "deployment", "content", "auth", "styling", "error handling")
3. Group into themed subsections of 5-15 items each
4. If a themed group has 15+ items, it's a candidate for extraction to a rule or subdirectory CLAUDE.md
5. Give each subsection a clear H3 heading

**Example — Before:**
```markdown
## Key Rules
- Deploy to Vercel Pro
- Content before composition
- Sanity seeds at Phase 7 step 3
- No em dashes in copy
- Use server components by default
- [70 more mixed bullets]
```

**Example — After:**
```markdown
## Key Rules

### Deployment
- Deploy to Vercel Pro with ISR
- Environment variables in Vercel dashboard, not committed

### Content Pipeline
- Content before composition — text exists before layout decisions
- Sanity seeds immediately after schema deployment (Phase 7 step 3)

### Code Style
- Server components by default; "use client" only for interactivity
- [etc.]
```

---

## 6. DELETE — Remove Stale Content

**Trigger:** Content references files/features/docs that no longer exist, or has been explicitly superseded.

**Safe to delete (no approval needed):**
- References to files that don't exist (verify with Glob)
- "TODO" or "TBD" items that have been completed (verify with git log or file existence)

**Requires user approval:**
- Entire sections marked as "stale" or "outdated" by the user or by previous analysis
- Planning/status content that's moved to other docs
- External doc references where the external doc is no longer relevant
- Decision history (covered by CONSOLIDATE, but user must approve the final-state summary)

**Never delete without asking:**
- Content whose purpose you don't understand
- Aspirational/future specs (they might be intentional placeholders)
- Content the user wrote recently (check git blame)
