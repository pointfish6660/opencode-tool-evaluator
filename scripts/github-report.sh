#!/bin/bash
set -euo pipefail

# github-report.sh — Scrape GitHub repo metadata via gh CLI, output JSON to stdout
#
# Usage: ./github-report.sh owner/repo
#
# Output: Valid JSON with flat fields: stars, forks, watchers, open_issues,
#         closed_issues_count, license, language, created_at, updated_at,
#         pushed_at, default_branch, size_kb, description, topics,
#         contributors_count, last_commit_sha, last_commit_date,
#         open_issues_count, readme_excerpt
#
#         Plus nested sub-objects:
#         issues: { close_median_hours, close_p90_hours, oldest_open_days,
#                   bug_count, label_count, security_labeled_count }
#         releases: { count, latest_tag, latest_published_at,
#                     cadence_days_avg, latest_body_chars, has_breaking }
#         changelog: { exists, size_bytes }
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

# --- Issues signals ---
CLOSE_MEDIAN_HOURS=null
CLOSE_P90_HOURS=null
OLDEST_OPEN_DAYS=null
BUG_COUNT=null
LABEL_COUNT=null
SECURITY_LABELED_COUNT=null

CLOSED_ITEMS_JSON=$(gh api "search/issues?q=repo:${INPUT}+is:issue+state:closed&per_page=100&sort=created&order=desc" 2>"$GH_ERR" || true)
if [[ -n "$CLOSED_ITEMS_JSON" ]] && [[ "$CLOSED_ITEMS_JSON" != "null" ]]; then
  DURATIONS=$(echo "$CLOSED_ITEMS_JSON" | jq -r '
    [.items[] |
      (try (.closed_at | fromdateiso8601) catch null) as $end |
      (try (.created_at | fromdateiso8601) catch null) as $start |
      select($end != null and $start != null and $end > $start) |
      ($end - $start) / 3600.0
    ] | sort | .[]
  ' 2>/dev/null || true)
  if [[ -n "$DURATIONS" ]]; then
    DUR_COUNT=$(printf '%s\n' "$DURATIONS" | grep -c . || true)
    if [[ "${DUR_COUNT:-0}" -ge 5 ]]; then
      CLOSE_MEDIAN_HOURS=$(printf '%s\n' "$DURATIONS" | grep . | awk '{a[NR]=$1} END {
        if (NR % 2 == 1) printf "%.1f", a[(NR+1)/2]
        else printf "%.1f", (a[NR/2] + a[NR/2+1]) / 2
      }')
      CLOSE_P90_HOURS=$(printf '%s\n' "$DURATIONS" | grep . | awk '{a[NR]=$1} END {
        n = int(0.9 * NR + 0.999999)
        if (n < 1) n = 1; if (n > NR) n = NR
        printf "%.1f", a[n]
      }')
    fi
  fi
fi

OLDEST_CREATED=$(gh api "search/issues?q=repo:${INPUT}+is:issue+state:open&sort=created&order=asc&per_page=1" \
  --jq '.items[0].created_at // ""' 2>"$GH_ERR" || true)
if [[ -n "$OLDEST_CREATED" ]]; then
  OLDEST_EPOCH=$(jq -rn --arg d "$OLDEST_CREATED" '($d | fromdateiso8601)' 2>/dev/null || true)
  if [[ -n "$OLDEST_EPOCH" ]] && [[ "$OLDEST_EPOCH" != "null" ]]; then
    NOW_EPOCH=$(date +%s)
    OLDEST_OPEN_DAYS=$(( (NOW_EPOCH - OLDEST_EPOCH) / 86400 ))
  fi
fi

BUG_RAW=$(gh api "search/issues?q=repo:${INPUT}+is:issue+state:open+label:bug&per_page=1" \
  --jq '.total_count' 2>"$GH_ERR" || true)
[[ "$BUG_RAW" =~ ^[0-9]+$ ]] && BUG_COUNT="$BUG_RAW"

LABEL_RAW=$(gh api "repos/${INPUT}/labels?per_page=100" --jq 'length' 2>"$GH_ERR" || true)
[[ "$LABEL_RAW" =~ ^[0-9]+$ ]] && LABEL_COUNT="$LABEL_RAW"

SEC_S=$(gh api "search/issues?q=repo:${INPUT}+is:issue+label:security&per_page=1" \
  --jq '.total_count' 2>"$GH_ERR" || true)
SEC_V=$(gh api "search/issues?q=repo:${INPUT}+is:issue+label:vulnerability&per_page=1" \
  --jq '.total_count' 2>"$GH_ERR" || true)
if [[ "$SEC_S" =~ ^[0-9]+$ ]] && [[ "$SEC_V" =~ ^[0-9]+$ ]]; then
  SECURITY_LABELED_COUNT=$((SEC_S + SEC_V))
fi

# --- Releases signals ---
REL_COUNT=null
REL_LATEST_TAG=null
REL_LATEST_PUBLISHED=null
REL_CADENCE_DAYS=null
REL_BODY_CHARS=null
REL_HAS_BREAKING=false

RELEASES_JSON=$(gh api "repos/${INPUT}/releases?per_page=10" 2>"$GH_ERR" || true)
if [[ -n "$RELEASES_JSON" ]] && [[ "$RELEASES_JSON" != "null" ]]; then
  REL_ARR_COUNT=$(echo "$RELEASES_JSON" | jq 'length' 2>/dev/null || echo 0)
  REL_COUNT="$REL_ARR_COUNT"
  if [[ "${REL_ARR_COUNT:-0}" -ge 1 ]]; then
    REL_COUNT="$REL_ARR_COUNT"
    REL_LATEST_TAG=$(echo "$RELEASES_JSON" | jq '.[0].tag_name' 2>/dev/null || echo null)
    REL_LATEST_PUBLISHED=$(echo "$RELEASES_JSON" | jq '.[0].published_at' 2>/dev/null || echo null)
    if [[ "$REL_ARR_COUNT" -ge 2 ]]; then
      REL_CADENCE_DAYS=$(echo "$RELEASES_JSON" | jq '
        [.[] | try (.published_at | fromdateiso8601) catch null] as $dates |
        [range(0; length-1) | select($dates[.] != null and $dates[.+1] != null) | ($dates[.] - $dates[.+1]) / 86400.0] as $intervals |
        if ($intervals | length) == 0 then null else ($intervals | add / length) end
      ' 2>/dev/null || echo null)
    fi
  fi
fi

if LATEST_BODY=$(gh api "repos/${INPUT}/releases/latest" --jq '.body // ""' 2>"$GH_ERR"); then
  REL_BODY_CHARS=${#LATEST_BODY}
  if [[ -n "$LATEST_BODY" ]] && echo "$LATEST_BODY" | grep -qi "breaking"; then
    REL_HAS_BREAKING=true
  fi
fi

# --- Changelog signals ---
CHANGELOG_EXISTS=false
CHANGELOG_SIZE=null
for CL_FILE in CHANGELOG.md CHANGES.md HISTORY.md; do
  CL_RESP=$(gh api "repos/${INPUT}/contents/${CL_FILE}" 2>"$GH_ERR" || true)
  if [[ -n "$CL_RESP" ]] && [[ "$CL_RESP" != "null" ]]; then
    CL_SIZE=$(echo "$CL_RESP" | jq -r '.size // ""' 2>/dev/null || true)
    if [[ -n "$CL_SIZE" ]] && [[ "$CL_SIZE" != "null" ]]; then
      CHANGELOG_EXISTS=true
      CHANGELOG_SIZE="$CL_SIZE"
      break
    fi
  fi
done

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
  --argjson close_median_hours "$CLOSE_MEDIAN_HOURS" \
  --argjson close_p90_hours "$CLOSE_P90_HOURS" \
  --argjson oldest_open_days "$OLDEST_OPEN_DAYS" \
  --argjson bug_count "$BUG_COUNT" \
  --argjson label_count "$LABEL_COUNT" \
  --argjson security_labeled_count "$SECURITY_LABELED_COUNT" \
  --argjson rel_count "$REL_COUNT" \
  --argjson rel_latest_tag "$REL_LATEST_TAG" \
  --argjson rel_latest_published "$REL_LATEST_PUBLISHED" \
  --argjson rel_cadence_days "$REL_CADENCE_DAYS" \
  --argjson rel_body_chars "$REL_BODY_CHARS" \
  --argjson rel_has_breaking "$REL_HAS_BREAKING" \
  --argjson changelog_exists "$CHANGELOG_EXISTS" \
  --argjson changelog_size "$CHANGELOG_SIZE" \
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
    readme_excerpt: $readme_excerpt,
    issues: {
      close_median_hours: $close_median_hours,
      close_p90_hours: $close_p90_hours,
      oldest_open_days: $oldest_open_days,
      bug_count: $bug_count,
      label_count: $label_count,
      security_labeled_count: $security_labeled_count
    },
    releases: {
      count: $rel_count,
      latest_tag: $rel_latest_tag,
      latest_published_at: $rel_latest_published,
      cadence_days_avg: $rel_cadence_days,
      latest_body_chars: $rel_body_chars,
      has_breaking: $rel_has_breaking
    },
    changelog: {
      exists: $changelog_exists,
      size_bytes: $changelog_size
    }
  }'
