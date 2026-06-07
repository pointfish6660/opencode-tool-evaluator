#!/usr/bin/env bash
# Task 4: security-scan.sh — Scan a GitHub repo for security/intrusiveness signals
# Uses gh API exclusively (no local clone). Outputs valid JSON to stdout.
set -euo pipefail

# --- Constants ---
SELF="$0"
INPUT="${1:-}"

# --- Error / Exit helpers ---
die() {
  echo "Error: $*" >&2
  exit 1
}

# --- Validate gh CLI ---
if ! command -v gh &>/dev/null; then
  echo "Error: gh CLI not found. Install GitHub CLI (brew install gh) and authenticate (gh auth login)." >&2
  exit 2
fi

# --- Validate input format ---
if [[ ! "$INPUT" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9._-]+$ ]]; then
  die "Invalid input format. Expected {owner}/{repo} (e.g., chopratejas/headroom). Got: '$INPUT'"
fi

OWNER="${INPUT%/*}"
REPO="${INPUT#*/}"
GH_BASE="repos/${OWNER}/${REPO}"

# --- Helper: safe gh api call ---
gh_api() {
  local endpoint="$1" jq_filter="${2:-}"
  local result
  if [[ -n "$jq_filter" ]]; then
    result=$(gh api "$endpoint" --jq "$jq_filter" 2>&1) || {
      local ec=$?
      if echo "$result" | grep -qi 'rate limit\|403'; then
        echo "Error: GitHub API rate limited. Try again later." >&2
        exit 3
      fi
      return "$ec"
    }
  else
    result=$(gh api "$endpoint" 2>&1) || {
      local ec=$?
      if echo "$result" | grep -qi 'rate limit\|403'; then
        echo "Error: GitHub API rate limited. Try again later." >&2
        exit 3
      fi
      return "$ec"
    }
  fi
  echo "$result"
}

# --- Helper: fetch file content from repo root ---
fetch_file() {
  local path="$1"
  local content_b64
  content_b64=$(gh_api "${GH_BASE}/contents/${path}" '.content' 2>/dev/null || echo "")
  if [[ -z "$content_b64" || "$content_b64" == "null" ]]; then
    echo ""
    return
  fi
  echo "$content_b64" | base64 -D 2>/dev/null || echo ""
}

# --- Helper: grep content for pattern, return true/false ---
grep_content() {
  local content="$1" pattern="$2"
  [[ -z "$content" ]] && return 1
  echo "$content" | grep -qiE "$pattern" 2>/dev/null && return 0 || return 1
}

# --- Helper: count grep matches ---
grep_count() {
  local content="$1" pattern="$2"
  [[ -z "$content" ]] && echo 0 && return
  echo "$content" | grep -ciE "$pattern" 2>/dev/null || echo 0
}

# --- Helper: join array elements with delimiter ---
join_by() {
  local d="$1" s="" sep=""
  shift
  for e in "$@"; do
    s="${s}${sep}${e}"
    sep="${d}"
  done
  echo "$s"
}

# ======================================================================
# STEP 1: Verify repo exists
# ======================================================================
if ! gh_api "${GH_BASE}" '.full_name' &>/dev/null; then
  die "Repository '${INPUT}' not found or not accessible."
fi

# ======================================================================
# STEP 2: List root files
# ======================================================================
ROOT_JSON=""
ROOT_JSON=$(gh_api "${GH_BASE}/contents/" 2>/dev/null || echo "")
if [[ -z "$ROOT_JSON" || "$ROOT_JSON" == "null" ]]; then
  # Empty repository — no content to scan
  cat <<'EOF'
{
  "hooks_count": 0,
  "launchd_installed": false,
  "modifies_settings_json": false,
  "writes_user_files": false,
  "network_calls": false,
  "elevated_privileges": false,
  "prebuilt_binaries": false,
  "permissions_requested": [],
  "risk_level": "unknown",
  "risk_points": ["Unable to scan: empty repository"]
}
EOF
  exit 0
fi

# Extract root file/directory names
ROOT_NAMES=$(echo "$ROOT_JSON" | jq -r '.[].name' 2>/dev/null || echo "")

# Check if a file (or directory) exists in root
root_has() {
  local name="$1"
  echo "$ROOT_NAMES" | grep -qi "^${name}$" 2>/dev/null && return 0 || return 1
}

# ======================================================================
# STEP 3: Read README content
# ======================================================================
README_CONTENT=""
if root_has "README.md" || root_has "README"; then
  README_CONTENT=$(gh_api "${GH_BASE}/readme" '.content' 2>/dev/null | base64 -D 2>/dev/null || echo "")
fi

# ======================================================================
# STEP 4: Scan for risk signals
# ======================================================================

# --- hooks_count ---
HOOKS_COUNT=0
DIR_HOOK_EXISTS=0
if root_has "hooks" || root_has ".hooks"; then
  DIR_HOOK_EXISTS=1
fi
README_HOOK_COUNT=$(grep_count "$README_CONTENT" 'hook|hooks/')
HOOKS_COUNT=$((README_HOOK_COUNT + DIR_HOOK_EXISTS))

# --- launchd_installed ---
LAUNCHD_INSTALLED=false
if grep_content "$README_CONTENT" 'launchd|LaunchAgent|LaunchDaemon|\.plist'; then
  LAUNCHD_INSTALLED=true
fi
for f in install.sh setup.sh; do
  if root_has "$f"; then
    content=$(fetch_file "$f")
    if grep_content "$content" 'launchd|LaunchAgent|LaunchDaemon|\.plist'; then
      LAUNCHD_INSTALLED=true
    fi
  fi
done

# --- modifies_settings_json ---
MODIFIES_SETTINGS_JSON=false
if grep_content "$README_CONTENT" 'settings\.json|config\.json|claude_desktop_config'; then
  MODIFIES_SETTINGS_JSON=true
fi
for f in install.sh setup.sh; do
  if root_has "$f"; then
    content=$(fetch_file "$f")
    if grep_content "$content" 'settings\.json|config\.json|claude_desktop_config'; then
      MODIFIES_SETTINGS_JSON=true
    fi
  fi
done

# --- writes_user_files ---
WRITES_USER_FILES=false
# Match both ~/.config and $HOME/.config as user directory writes
WRITES_USER_FILES_PATTERN='~/\.config|\$HOME/\.config|~/Library|~/\.claude|/etc/|/usr/local/'
if grep_content "$README_CONTENT" "$WRITES_USER_FILES_PATTERN"; then
  WRITES_USER_FILES=true
fi
for f in install.sh setup.sh; do
  if root_has "$f"; then
    content=$(fetch_file "$f")
    if grep_content "$content" "$WRITES_USER_FILES_PATTERN"; then
      WRITES_USER_FILES=true
    fi
  fi
done

# --- network_calls ---
NETWORK_CALLS=false
CHECK_FILES="install.sh setup.sh pyproject.toml setup.py setup.cfg"
if grep_content "$README_CONTENT" 'https?://|fetch\(|curl |requests\.|axios|wget'; then
  NETWORK_CALLS=true
fi
for f in $CHECK_FILES; do
  if root_has "$f"; then
    content=$(fetch_file "$f")
    if grep_content "$content" 'https?://|fetch\(|curl |requests\.|axios|wget'; then
      NETWORK_CALLS=true
    fi
  fi
done
# Check package.json for postinstall scripts or deps with network
if root_has "package.json"; then
  content=$(fetch_file "package.json")
  if grep_content "$content" 'https?://|fetch|curl|axios|wget|postinstall'; then
    NETWORK_CALLS=true
  fi
fi

# --- elevated_privileges ---
ELEVATED_PRIVILEGES=false
if grep_content "$README_CONTENT" 'sudo |chmod 777|chown root|osascript.*admin'; then
  ELEVATED_PRIVILEGES=true
fi
for f in install.sh setup.sh; do
  if root_has "$f"; then
    content=$(fetch_file "$f")
    if grep_content "$content" 'sudo |chmod 777|chown root|osascript.*admin'; then
      ELEVATED_PRIVILEGES=true
    fi
  fi
done

# --- prebuilt_binaries ---
PREBUILT_BINARIES=false
if echo "$ROOT_NAMES" | grep -qiE '\.(dylib|exe|so|bin|wasm)$'; then
  PREBUILT_BINARIES=true
fi
if echo "$ROOT_NAMES" | grep -qiE '^(bin|prebuilt|binary)$'; then
  PREBUILT_BINARIES=true
fi

# ======================================================================
# STEP 5: Determine risk_level
# ======================================================================
RISK_FLAGS_COUNT=0
[[ "$HOOKS_COUNT" -gt 0 ]] && RISK_FLAGS_COUNT=$((RISK_FLAGS_COUNT + 1))
[[ "$LAUNCHD_INSTALLED" == true ]] && RISK_FLAGS_COUNT=$((RISK_FLAGS_COUNT + 1))
[[ "$MODIFIES_SETTINGS_JSON" == true ]] && RISK_FLAGS_COUNT=$((RISK_FLAGS_COUNT + 1))
[[ "$WRITES_USER_FILES" == true ]] && RISK_FLAGS_COUNT=$((RISK_FLAGS_COUNT + 1))
[[ "$NETWORK_CALLS" == true ]] && RISK_FLAGS_COUNT=$((RISK_FLAGS_COUNT + 1))
[[ "$ELEVATED_PRIVILEGES" == true ]] && RISK_FLAGS_COUNT=$((RISK_FLAGS_COUNT + 1))
[[ "$PREBUILT_BINARIES" == true ]] && RISK_FLAGS_COUNT=$((RISK_FLAGS_COUNT + 1))

if [[ "$RISK_FLAGS_COUNT" -ge 3 ]]; then
  RISK_LEVEL="high"
elif [[ "$RISK_FLAGS_COUNT" -ge 1 ]]; then
  RISK_LEVEL="medium"
else
  RISK_LEVEL="low"
fi

# Bump to high if system-level modifications combined
if [[ "$LAUNCHD_INSTALLED" == true && "$MODIFIES_SETTINGS_JSON" == true ]]; then
  RISK_LEVEL="high"
fi

# ======================================================================
# STEP 6: Build risk_points array
# ======================================================================
RISK_POINTS=()
if [[ "$MODIFIES_SETTINGS_JSON" == true ]]; then
  RISK_POINTS+=('"修改 settings.json / 配置文件"')
fi
if [[ "$LAUNCHD_INSTALLED" == true ]]; then
  RISK_POINTS+=('"安装 LaunchAgent / LaunchDaemon"')
fi
if [[ "$WRITES_USER_FILES" == true ]]; then
  RISK_POINTS+=('"写入用户目录文件"')
fi
if [[ "$ELEVATED_PRIVILEGES" == true ]]; then
  RISK_POINTS+=('"需要管理员权限"')
fi
if [[ "$PREBUILT_BINARIES" == true ]]; then
  RISK_POINTS+=('"包含预编译二进制文件"')
fi
if [[ "$NETWORK_CALLS" == true ]]; then
  RISK_POINTS+=('"发起外部网络请求"')
fi
if [[ "$HOOKS_COUNT" -gt 0 ]]; then
  RISK_POINTS+=("\"注册了 ${HOOKS_COUNT} 个 hook\"")
fi

# ======================================================================
# STEP 7: Build permissions_requested array
# ======================================================================
PERMS=()
if [[ "$MODIFIES_SETTINGS_JSON" == true || "$WRITES_USER_FILES" == true ]]; then
  PERMS+=('"filesystem"')
fi
if [[ "$NETWORK_CALLS" == true ]]; then
  PERMS+=('"network"')
fi
if [[ "$ELEVATED_PRIVILEGES" == true ]]; then
  PERMS+=('"admin"')
fi
if [[ "$LAUNCHD_INSTALLED" == true ]]; then
  PERMS+=('"system"')
fi

RISK_POINTS_JSON=$(join_by ", " "${RISK_POINTS[@]:-}")
PERMS_JSON=$(join_by ", " "${PERMS[@]:-}")

# ======================================================================
# STEP 8: Output valid JSON
# ======================================================================
cat <<EOF
{
  "hooks_count": $HOOKS_COUNT,
  "launchd_installed": $LAUNCHD_INSTALLED,
  "modifies_settings_json": $MODIFIES_SETTINGS_JSON,
  "writes_user_files": $WRITES_USER_FILES,
  "network_calls": $NETWORK_CALLS,
  "elevated_privileges": $ELEVATED_PRIVILEGES,
  "prebuilt_binaries": $PREBUILT_BINARIES,
  "permissions_requested": [${PERMS_JSON}],
  "risk_level": "${RISK_LEVEL}",
  "risk_points": [${RISK_POINTS_JSON}]
}
EOF
