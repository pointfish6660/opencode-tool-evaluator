#!/bin/bash
set -euo pipefail

# github-report.sh — Scrape GitHub repo metadata via gh CLI, output JSON to stdout
#
# Usage: ./github-report.sh owner/repo
#
# Output: Valid JSON with fields: stars, forks, watchers, open_issues,
#         closed_issues_count, license, language, created_at, updated_at,
#         pushed_at, default_branch, size_kb, description, topics,
#         contributors_count, last_commit_sha, last_commit_date,
#         open_issues_count, readme_excerpt
#
# Exit codes:
#   0 — success
#   1 — repo not found / API error
#   2 — invalid input / missing dependency
#   3 — rate limited

SCRIPT_NAME=$(basename "$0")

# Cleanup on exit
GH_ERR=$(mktemp /tmp/gh_report_err.XXXXXX)
trap 'rm -f "$GH_ERR"' EXIT

error_exit() {
  echo "$1" >&2
  exit "$2"
}

# --- Dependency check ---
command -v gh >/dev/null 2>&1 || error_exit '{"error": "gh CLI not installed"}' 2
command -v jq >/dev/null 2>&1 || error_exit '{"error": "jq not installed"}' 2

# --- Argument validation ---
[[ $# -ne 1 ]] && error_exit "{\"error\": \"usage: ${SCRIPT_NAME} owner/repo\"}" 2

INPUT="$1"

# Validate owner/repo format: alphanumeric, hyphen, dot, underscore
[[ ! "$INPUT" =~ ^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$ ]] && \
  error_exit '{"error": "invalid format, expected owner/repo"}' 2

# --- Fetch main repo info ---
if ! REPO_JSON=$(gh api "repos/${INPUT}" 2>"$GH_ERR"); then
  GH_MSG=$(cat "$GH_ERR")
  if echo "$GH_MSG" | grep -qi "not found"; then
    error_exit '{"error": "repo not found"}' 1
  elif echo "$GH_MSG" | grep -qi "rate limit"; then
    error_exit '{"error": "GitHub API rate limit exceeded"}' 3
  else
    # Use a safe error message
    ERR_MSG=$(echo "$GH_MSG" | head -1 | tr -d '"' | tr -d '\n')
    error_exit "{\"error\": \"API error: ${ERR_MSG}\"}" 1
  fi
fi

# --- Extract fields from repo JSON ---
STARS=$(echo "$REPO_JSON" | jq '.stargazers_count // 0')
FORKS=$(echo "$REPO_JSON" | jq '.forks_count // 0')
WATCHERS=$(echo "$REPO_JSON" | jq '.subscribers_count // 0')
OPEN_ISSUES=$(echo "$REPO_JSON" | jq '.open_issues_count // 0')
LICENSE=$(echo "$REPO_JSON" | jq -r '.license.spdx_id // ""')
LANGUAGE=$(echo "$REPO_JSON" | jq -r '.language // ""')
CREATED_AT=$(echo "$REPO_JSON" | jq -r '.created_at // ""')
UPDATED_AT=$(echo "$REPO_JSON" | jq -r '.updated_at // ""')
PUSHED_AT=$(echo "$REPO_JSON" | jq -r '.pushed_at // ""')
DEFAULT_BRANCH=$(echo "$REPO_JSON" | jq -r '.default_branch // ""')
SIZE_KB=$(echo "$REPO_JSON" | jq '.size // 0')
DESCRIPTION=$(echo "$REPO_JSON" | jq -r '.description // ""')
TOPICS=$(echo "$REPO_JSON" | jq -c '.topics // []')

# --- Contributors count (via x-total-count header) ---
CONTRIBUTORS_COUNT=$(gh api "repos/${INPUT}/contributors?per_page=1&anon=true" \
  --include 2>"$GH_ERR" \
  | grep -i "^x-total-count:" \
  | tr -d '\r' \
  | awk '{print $2}' \
  || true)

# Fallback: fetch all and count
if [[ -z "$CONTRIBUTORS_COUNT" || "$CONTRIBUTORS_COUNT" -eq 0 ]] 2>/dev/null; then
  CONTRIBUTORS_COUNT=$(gh api "repos/${INPUT}/contributors?anon=true" \
    --jq 'length' 2>"$GH_ERR" || true)
fi
CONTRIBUTORS_COUNT="${CONTRIBUTORS_COUNT:-0}"

# --- Last commit ---
LAST_COMMIT_JSON=$(gh api "repos/${INPUT}/commits?per_page=1" \
  --jq '.[0] | {sha: .sha, date: .commit.committer.date}' 2>"$GH_ERR" || true)
if [[ -n "$LAST_COMMIT_JSON" ]] && [[ "$LAST_COMMIT_JSON" != "null" ]]; then
  LAST_COMMIT_SHA=$(echo "$LAST_COMMIT_JSON" | jq -r '.sha // ""')
  LAST_COMMIT_DATE=$(echo "$LAST_COMMIT_JSON" | jq -r '.date // ""')
else
  LAST_COMMIT_SHA=""
  LAST_COMMIT_DATE=""
fi

# --- README excerpt (base64 decoded, first 500 chars) ---
README_EXCERPT=$(gh api "repos/${INPUT}/readme" --jq '.content' 2>"$GH_ERR" \
  | base64 -D 2>/dev/null \
  | head -c 500 \
  || true)

# --- Closed issues count (via search API) ---
CLOSED_ISSUES_COUNT=$(gh api "search/issues?q=repo:${INPUT}+state:closed&per_page=1" \
  --jq '.total_count' 2>"$GH_ERR" || true)
CLOSED_ISSUES_COUNT="${CLOSED_ISSUES_COUNT:-0}"

# --- Assemble final JSON ---
jq -n \
  --argjson stars "$STARS" \
  --argjson forks "$FORKS" \
  --argjson watchers "$WATCHERS" \
  --argjson open_issues "$OPEN_ISSUES" \
  --argjson closed_issues_count "$CLOSED_ISSUES_COUNT" \
  --arg license "$LICENSE" \
  --arg language "$LANGUAGE" \
  --arg created_at "$CREATED_AT" \
  --arg updated_at "$UPDATED_AT" \
  --arg pushed_at "$PUSHED_AT" \
  --arg default_branch "$DEFAULT_BRANCH" \
  --argjson size_kb "$SIZE_KB" \
  --arg description "$DESCRIPTION" \
  --argjson topics "$TOPICS" \
  --argjson contributors_count "$CONTRIBUTORS_COUNT" \
  --arg last_commit_sha "$LAST_COMMIT_SHA" \
  --arg last_commit_date "$LAST_COMMIT_DATE" \
  --argjson open_issues_count "$OPEN_ISSUES" \
  --arg readme_excerpt "$README_EXCERPT" \
  '{
    stars: $stars,
    forks: $forks,
    watchers: $watchers,
    open_issues: $open_issues,
    closed_issues_count: $closed_issues_count,
    license: $license,
    language: $language,
    created_at: $created_at,
    updated_at: $updated_at,
    pushed_at: $pushed_at,
    default_branch: $default_branch,
    size_kb: $size_kb,
    description: $description,
    topics: $topics,
    contributors_count: $contributors_count,
    last_commit_sha: $last_commit_sha,
    last_commit_date: $last_commit_date,
    open_issues_count: $open_issues_count,
    readme_excerpt: $readme_excerpt
  }'
