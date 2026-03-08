#!/usr/bin/env bash
# lint.sh — Deterministic structural lint for Claude Code project config
# Usage: bash lint.sh [project-dir]   (defaults to current directory)
set -u

PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
PASS=0; FAIL=0; WARN=0

pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }
warn() { echo "[WARN] $1"; WARN=$((WARN + 1)); }

# Extract YAML frontmatter from a file (between first and second ---)
# Sets FM and FM_END; returns 1 if invalid
extract_fm() {
  local content="$1"
  FM=""; FM_END=""
  echo "$content" | head -1 | grep -q '^---' || return 1
  FM_END=$(echo "$content" | tail -n +2 | grep -n '^---' | head -1 | cut -d: -f1)
  [ -n "$FM_END" ] || return 1
  FM=$(echo "$content" | sed -n "2,${FM_END}p")
  return 0
}

# 1. CLAUDE.md line count
check_claude_md() {
  local found=0
  for f in "$PROJECT_DIR/CLAUDE.md" "$PROJECT_DIR/.claude/CLAUDE.md"; do
    if [ -f "$f" ]; then
      found=1
      local rel="${f#"$PROJECT_DIR/"}" lines
      lines=$(wc -l < "$f" | tr -d '[:space:]')
      if [ "$lines" -ge 200 ]; then fail "$rel: $lines lines (>= 200 limit)"
      else pass "$rel: $lines lines (< 200 limit)"; fi
    fi
  done
  [ "$found" -eq 1 ] || warn "No CLAUDE.md found — consider creating one"
}

# 2. Rule frontmatter validation
check_rule_frontmatter() {
  local d="$PROJECT_DIR/.claude/rules"
  if [ ! -d "$d" ]; then warn "No .claude/rules/ directory found — skipping rule checks"; return; fi
  local total=0 valid=0
  for f in "$d"/*.md; do
    [ -f "$f" ] || continue; total=$((total + 1))
    local name content; name=$(basename "$f"); content=$(cat "$f")
    if ! extract_fm "$content"; then
      fail "Rule frontmatter: $name — invalid frontmatter"; continue; fi
    if ! echo "$FM" | grep -q 'description:'; then
      fail "Rule frontmatter: $name — missing description:"; continue; fi
    valid=$((valid + 1))
  done
  if [ "$total" -eq 0 ]; then warn "No rule files found in .claude/rules/"
  elif [ "$valid" -eq "$total" ]; then pass "Rule frontmatter: $valid/$total rules parse correctly"; fi
}

# 3. Rule path resolution
check_rule_paths() {
  local d="$PROJECT_DIR/.claude/rules"
  if [ ! -d "$d" ]; then return 0; fi
  local all_ok=1 checked=0
  for f in "$d"/*.md; do
    [ -f "$f" ] || continue
    local name content; name=$(basename "$f"); content=$(cat "$f")
    extract_fm "$content" || continue
    local paths_line; paths_line=$(echo "$FM" | grep 'paths:' || true)
    [ -n "$paths_line" ] || continue
    local globs; globs=$(echo "$paths_line" | sed 's/.*\[//;s/\].*//;s/,/ /g' | tr -d '"'"'" | tr -s ' ')
    for g in $globs; do
      checked=$((checked + 1))
      local m; m=$(cd "$PROJECT_DIR" && compgen -G "$g" 2>/dev/null | head -1 || true)
      if [ -z "$m" ]; then m=$(cd "$PROJECT_DIR" && find . -path "./$g" 2>/dev/null | head -1 || true); fi
      if [ -z "$m" ]; then fail "Rule path resolution: $name — \"$g\" matches 0 files"; all_ok=0; fi
    done
  done
  if [ "$checked" -gt 0 ] && [ "$all_ok" -eq 1 ]; then pass "Rule path resolution: all path globs resolve"; fi
}

# 4. Skill frontmatter validation
check_skill_frontmatter() {
  local d="$PROJECT_DIR/.claude/skills"
  if [ ! -d "$d" ]; then warn "No .claude/skills/ directory found — skipping skill checks"; return; fi
  local total=0 valid=0
  for f in "$d"/*/SKILL.md; do
    [ -f "$f" ] || continue; total=$((total + 1))
    local sn content; sn=$(basename "$(dirname "$f")"); content=$(cat "$f")
    if ! extract_fm "$content"; then
      fail "Skill frontmatter: $sn — invalid frontmatter"; continue; fi
    local missing=""
    echo "$FM" | grep -q 'name:' || missing="name"
    echo "$FM" | grep -q 'description:' || missing="${missing:+$missing, }description"
    if [ -n "$missing" ]; then fail "Skill frontmatter: $sn — missing $missing"; continue; fi
    valid=$((valid + 1))
  done
  if [ "$total" -eq 0 ]; then warn "No skill files found in .claude/skills/"
  elif [ "$valid" -eq "$total" ]; then pass "Skill frontmatter: $valid/$total skills parse correctly"; fi
}

# 5. Skill context resolution
check_skill_context() {
  local d="$PROJECT_DIR/.claude/skills"
  if [ ! -d "$d" ]; then return 0; fi
  local all_ok=1 checked=0
  for f in "$d"/*/SKILL.md; do
    [ -f "$f" ] || continue
    local sn sd content; sn=$(basename "$(dirname "$f")"); sd=$(dirname "$f"); content=$(cat "$f")
    extract_fm "$content" || continue
    local in_ctx=0
    while IFS= read -r line; do
      if echo "$line" | grep -q '^context:'; then in_ctx=1; continue; fi
      if [ "$in_ctx" -eq 1 ]; then
        if echo "$line" | grep -q '^  - '; then
          checked=$((checked + 1))
          local ref; ref=$(echo "$line" | sed 's/^  - //' | tr -d '"'"'" | tr -d '[:space:]')
          if [ ! -f "$sd/$ref" ]; then fail "Skill context: $sn — \"$ref\" not found"; all_ok=0; fi
        else in_ctx=0; fi
      fi
    done <<< "$FM"
  done
  if [ "$checked" -gt 0 ] && [ "$all_ok" -eq 1 ]; then pass "Skill context resolution: all context references exist"; fi
}

# 6. Agent validation
check_agents() {
  local d="$PROJECT_DIR/.claude/agents"
  if [ ! -d "$d" ]; then warn "No .claude/agents/ directory found — skipping agent checks"; return; fi
  local total=0 valid=0
  for f in "$d"/*.md; do
    [ -f "$f" ] || continue; total=$((total + 1))
    local name content; name=$(basename "$f"); content=$(cat "$f")
    if ! extract_fm "$content"; then
      fail "Agent frontmatter: $name — invalid frontmatter"; continue; fi
    local ok=1 in_skills=0
    while IFS= read -r line; do
      if echo "$line" | grep -q '^skills:'; then in_skills=1; continue; fi
      if [ "$in_skills" -eq 1 ]; then
        if echo "$line" | grep -q '^  - '; then
          local sr; sr=$(echo "$line" | sed 's/^  - //' | tr -d '"'"'" | tr -d '[:space:]')
          if [ ! -d "$PROJECT_DIR/.claude/skills/$sr" ]; then
            fail "Agent skill ref: $name — skill \"$sr\" directory not found"; ok=0; fi
        else in_skills=0; fi
      fi
    done <<< "$FM"
    if [ "$ok" -eq 1 ]; then valid=$((valid + 1)); fi
  done
  if [ "$total" -eq 0 ]; then warn "No agent files found in .claude/agents/"
  elif [ "$valid" -eq "$total" ]; then pass "Agent validation: $valid/$total agents valid"; fi
}

# 7. Duplicate detection
check_duplicates() {
  local d="$PROJECT_DIR/.claude/rules"
  if [ ! -d "$d" ]; then return 0; fi
  local dupes; dupes=$(cd "$d" && ls *.md 2>/dev/null | sort | uniq -d)
  if [ -n "$dupes" ]; then fail "Duplicate rules: $dupes"
  else
    local c; c=$(cd "$d" && ls *.md 2>/dev/null | wc -l | tr -d '[:space:]')
    if [ "$c" -gt 0 ]; then pass "Duplicate detection: no duplicate rule filenames"; fi
  fi
}

# Run all checks
echo "Linting Claude Code config in: $PROJECT_DIR"
echo ""
check_claude_md
check_rule_frontmatter
check_rule_paths
check_skill_frontmatter
check_skill_context
check_agents
check_duplicates
echo ""
echo "---"
echo "Summary: $PASS passed, $FAIL failed, $WARN warnings"
[ "$FAIL" -eq 0 ]
