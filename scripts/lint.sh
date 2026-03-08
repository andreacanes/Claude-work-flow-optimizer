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

# Extract paths from frontmatter — handles both inline [a, b] and multi-line YAML arrays
# Returns space-separated list of glob patterns
extract_paths() {
  local fm="$1"
  local result=""
  # Check for inline format: paths: ["a", "b"] or paths: [a, b]
  local inline; inline=$(echo "$fm" | grep 'paths:.*\[' || true)
  if [ -n "$inline" ]; then
    result=$(echo "$inline" | sed 's/.*\[//;s/\].*//;s/,/ /g' | tr -d '"'"'" | tr -s ' ')
  else
    # Multi-line format:
    # paths:
    #   - glob1
    #   - glob2
    local in_paths=0
    while IFS= read -r line; do
      if echo "$line" | grep -q '^paths:'; then in_paths=1; continue; fi
      if [ "$in_paths" -eq 1 ]; then
        if echo "$line" | grep -q '^  - '; then
          local p; p=$(echo "$line" | sed 's/^  - //' | tr -d '"'"'" | tr -d '[:space:]')
          result="${result:+$result }$p"
        else
          in_paths=0
        fi
      fi
    done <<< "$fm"
  fi
  echo "$result"
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
    local globs; globs=$(extract_paths "$FM")
    [ -n "$globs" ] || continue
    for g in $globs; do
      checked=$((checked + 1))
      # Use bash globstar for ** patterns, compgen for simple globs
      local m=""
      if [[ "$g" == *"**"* ]]; then
        m=$(cd "$PROJECT_DIR" && bash -O globstar -c "ls -d $g 2>/dev/null | head -1" 2>/dev/null || true)
      else
        m=$(cd "$PROJECT_DIR" && compgen -G "$g" 2>/dev/null | head -1 || true)
      fi
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

# 7. Rule body length check
check_rule_body_length() {
  local d="$PROJECT_DIR/.claude/rules"
  if [ ! -d "$d" ]; then return 0; fi
  local overloaded=0 total_body=0 worst_name="" worst_lines=0
  for f in "$d"/*.md; do
    [ -f "$f" ] || continue
    local name content; name=$(basename "$f"); content=$(cat "$f")
    extract_fm "$content" || continue
    # Body = everything after the frontmatter (line FM_END+2 onward, +1 for 0-index, +1 for second ---)
    local total_lines body_lines
    total_lines=$(echo "$content" | wc -l | tr -d '[:space:]')
    body_lines=$((total_lines - FM_END - 1))
    [ "$body_lines" -lt 0 ] && body_lines=0
    total_body=$((total_body + body_lines))
    if [ "$body_lines" -gt "$worst_lines" ]; then worst_name="$name"; worst_lines=$body_lines; fi
    if [ "$body_lines" -gt 50 ]; then
      fail "Rule body length: $name — $body_lines lines (>50, convert to subdirectory CLAUDE.md)"
      overloaded=$((overloaded + 1))
    elif [ "$body_lines" -gt 15 ]; then
      warn "Rule body length: $name — $body_lines lines (>15, consider subdirectory CLAUDE.md)"
      overloaded=$((overloaded + 1))
    fi
  done
  if [ "$overloaded" -eq 0 ] && [ "$total_body" -gt 0 ]; then
    pass "Rule body length: all rules ≤ 15 lines"
  fi
  if [ "$worst_lines" -gt 0 ]; then
    echo "  [INFO] Largest rule: $worst_name ($worst_lines lines). Total rule body: $total_body lines"
  fi
}

# 8. Always-on rule detection
check_always_on_rules() {
  local d="$PROJECT_DIR/.claude/rules"
  if [ ! -d "$d" ]; then return 0; fi
  local always_on=0 always_on_lines=0 names=""
  for f in "$d"/*.md; do
    [ -f "$f" ] || continue
    local name content; name=$(basename "$f"); content=$(cat "$f")
    extract_fm "$content" || continue
    local rule_paths; rule_paths=$(extract_paths "$FM")
    if [ -z "$rule_paths" ]; then
      always_on=$((always_on + 1))
      local total_lines body_lines
      total_lines=$(echo "$content" | wc -l | tr -d '[:space:]')
      body_lines=$((total_lines - FM_END - 1))
      [ "$body_lines" -lt 0 ] && body_lines=0
      always_on_lines=$((always_on_lines + body_lines))
      names="${names:+$names, }$name(${body_lines}L)"
    fi
  done
  if [ "$always_on" -gt 0 ]; then
    if [ "$always_on_lines" -gt 30 ]; then
      warn "Always-on rules: $always_on rules without paths: ($names) — $always_on_lines total body lines loaded every turn"
    else
      pass "Always-on rules: $always_on rules without paths: ($always_on_lines total body lines)"
    fi
  fi
}

# 9. Rule overlap analysis
check_rule_overlap() {
  local d="$PROJECT_DIR/.claude/rules"
  if [ ! -d "$d" ]; then return 0; fi

  # Discover actual top-level directories under src/ (or project root) for bucket mapping
  local -A dir_counts dir_lines
  local actual_dirs=""
  if [ -d "$PROJECT_DIR/src" ]; then
    actual_dirs=$(cd "$PROJECT_DIR/src" && find . -maxdepth 1 -type d ! -name '.' 2>/dev/null | sed 's|^\./||' | sort)
  fi

  for f in "$d"/*.md; do
    [ -f "$f" ] || continue
    local name content; name=$(basename "$f"); content=$(cat "$f")
    extract_fm "$content" || continue
    local globs; globs=$(extract_paths "$FM")
    local total_lines body_lines
    total_lines=$(echo "$content" | wc -l | tr -d '[:space:]')
    body_lines=$((total_lines - FM_END - 1))
    [ "$body_lines" -lt 0 ] && body_lines=0

    if [ -z "$globs" ]; then
      # Always-on: matches everything — add to all buckets
      for ad in $actual_dirs; do
        dir_counts["src/$ad"]=$(( ${dir_counts["src/$ad"]:-0} + 1 ))
        dir_lines["src/$ad"]=$(( ${dir_lines["src/$ad"]:-0} + body_lines ))
      done
      # Also track root-level
      dir_counts["(root)"]=$(( ${dir_counts["(root)"]:-0} + 1 ))
      dir_lines["(root)"]=$(( ${dir_lines["(root)"]:-0} + body_lines ))
      continue
    fi

    for g in $globs; do
      # Extract the directory prefix from the glob to determine which buckets it hits
      # e.g. "src/modules/**/*.ts" → "src/modules"
      # e.g. "src/**/*.ts" → broad, hits all src/ subdirs
      local prefix; prefix=$(echo "$g" | sed 's|\*.*||;s|/$||')

      if [ "$prefix" = "src" ] || [ "$prefix" = "src/" ] || [ -z "$prefix" ]; then
        # Broad glob — hits all src/ subdirectories
        for ad in $actual_dirs; do
          dir_counts["src/$ad"]=$(( ${dir_counts["src/$ad"]:-0} + 1 ))
          dir_lines["src/$ad"]=$(( ${dir_lines["src/$ad"]:-0} + body_lines ))
        done
      else
        # Specific directory prefix — find which top-level bucket(s) it matches
        local matched=0
        for ad in $actual_dirs; do
          if [[ "$prefix" == "src/$ad"* ]]; then
            dir_counts["src/$ad"]=$(( ${dir_counts["src/$ad"]:-0} + 1 ))
            dir_lines["src/$ad"]=$(( ${dir_lines["src/$ad"]:-0} + body_lines ))
            matched=1
          fi
        done
        if [ "$matched" -eq 0 ]; then
          # Non-src path or unmatched prefix
          dir_counts["$prefix"]=$(( ${dir_counts["$prefix"]:-0} + 1 ))
          dir_lines["$prefix"]=$(( ${dir_lines["$prefix"]:-0} + body_lines ))
        fi
      fi
    done
  done

  # Report
  local worst_dir="" worst_count=0 worst_lines=0 any_problem=0
  for key in "${!dir_counts[@]}"; do
    local c=${dir_counts[$key]} l=${dir_lines[$key]}
    if [ "$c" -gt "$worst_count" ]; then worst_dir="$key"; worst_count=$c; worst_lines=$l; fi
    if [ "$c" -gt 10 ]; then
      fail "Rule overlap: $key/ — $c rules fire simultaneously (~$l body lines)"
      any_problem=1
    fi
  done
  # Estimate tokens for worst case (rough: 1 line ≈ 10 tokens)
  if [ "$worst_count" -gt 0 ]; then
    local est_tokens=$((worst_lines * 10))
    echo "  [INFO] Worst overlap: $worst_dir/ — $worst_count rules, ~$worst_lines body lines (~$est_tokens est. tokens)"
    if [ "$est_tokens" -gt 5000 ]; then
      fail "Context budget: ~$est_tokens estimated tokens from rules alone in $worst_dir/ (>5000)"
    elif [ "$est_tokens" -gt 3000 ]; then
      warn "Context budget: ~$est_tokens estimated tokens from rules in $worst_dir/ (>3000)"
    elif [ "$any_problem" -eq 0 ]; then
      pass "Rule overlap: max $worst_count rules on $worst_dir/ (~$est_tokens est. tokens)"
    fi
  fi
}

# 10. Config maintenance section check
check_config_maintenance() {
  local found=0
  for f in "$PROJECT_DIR/CLAUDE.md" "$PROJECT_DIR/.claude/CLAUDE.md"; do
    if [ -f "$f" ]; then
      if grep -qi 'config.maintenance\|## config maintenance\|## maintaining.*config\|when.*codebase.*evolves' "$f" 2>/dev/null; then
        pass "Config maintenance: CLAUDE.md has self-preservation section"
        found=1
      else
        warn "Config maintenance: CLAUDE.md missing Config Maintenance section — config will drift silently"
        found=1
      fi
    fi
  done
}

# 11. Duplicate detection
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
check_config_maintenance
check_rule_frontmatter
check_rule_paths
check_rule_body_length
check_always_on_rules
check_rule_overlap
check_skill_frontmatter
check_skill_context
check_agents
check_duplicates
echo ""
echo "---"
echo "Summary: $PASS passed, $FAIL failed, $WARN warnings"
[ "$FAIL" -eq 0 ]
