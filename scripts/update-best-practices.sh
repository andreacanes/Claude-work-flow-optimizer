#!/usr/bin/env bash
# Fetch best-practice reference files from GitHub with 24h cache
set -euo pipefail

REPO="shanraisshan/claude-code-best-practice"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/best-practice"
CACHE_DIR="${HOME}/.cache/cwfo/best-practice"
MAX_AGE=86400  # 24 hours in seconds

FILES=(
  "claude-memory.md"
  "claude-skills.md"
  "claude-subagents.md"
  "claude-mcp.md"
  "claude-commands.md"
  "claude-cli-startup-flags.md"
  "claude-settings.md"
)

mkdir -p "$CACHE_DIR"

# Cross-platform file age check (works on Unix, macOS, Git Bash/MSYS)
file_age() {
  local file="$1"
  local now
  local mtime

  now=$(date +%s)

  if stat --version >/dev/null 2>&1; then
    # GNU stat (Linux, Git Bash on Windows)
    mtime=$(stat -c %Y "$file" 2>/dev/null || echo 0)
  else
    # BSD stat (macOS)
    mtime=$(stat -f %m "$file" 2>/dev/null || echo 0)
  fi

  echo $(( now - mtime ))
}

updated=0
skipped=0
failed=0

for file in "${FILES[@]}"; do
  target="${CACHE_DIR}/${file}"

  if [[ -f "$target" ]]; then
    age=$(file_age "$target")
    if (( age < MAX_AGE )); then
      skipped=$(( skipped + 1 ))
      continue
    fi
  fi

  echo "Fetching ${file}..."
  if curl -sS -f -o "$target" "${BASE_URL}/${file}"; then
    updated=$(( updated + 1 ))
  else
    echo "  WARN: Failed to fetch ${file}" >&2
    failed=$(( failed + 1 ))
  fi
done

echo ""
echo "Best practice cache update complete:"
echo "  Updated: ${updated}"
echo "  Cached (fresh): ${skipped}"
echo "  Failed: ${failed}"
echo ""
echo "Available files:"
ls -1 "$CACHE_DIR" 2>/dev/null || echo "  (none)"
