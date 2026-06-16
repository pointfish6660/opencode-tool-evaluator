---
title: Web Research 功能可行性评估
date: 2026-06-07
status: completed
decision: Plan B (Issues + Releases only)
---

# Web Research 功能可行性评估（2026-06-07）

## 背景

当前项目 `SKILL.md` L76 要求"结合脚本输出 + 简短 web 调研（HN / Reddit / GitHub Issues / CHANGELOG）"为 6 维度打分。但 HN/Reddit/CHANGELOG 完全依赖 LLM 自由发挥，脚本只覆盖 GitHub 仓库元数据。

**问题**：要不要把这部分"web 调研"程序化？

## 各数据源 API 实情

| 来源 | 鉴权 | 速率 | 复杂度 | 建议 |
|------|------|------|--------|------|
| HN (Algolia) | 无 | ~10K/hr | Low（curl+jq，~10 行） | 可选 |
| Reddit | OAuth（2023 新政策） | 100 QPM (OAuth) / 10 QPM (无) | High | **不建** |
| GitHub Issues | 已用 `gh api search/issues` | 30 req/min (search) | Very Low（+2 query） | **建** |
| CHANGELOG/Releases | GitHub Releases API（已鉴权） | 现有限额内 | Low（3 调用，~15 行） | **建** |

## 决策：方案 B（只建 Issues + Releases）

- **建**：GitHub Issues 信号（扩展 `github-report.sh`，+2-3 个 `search/issues` query）+ Releases / CHANGELOG 信号（~15 行）
- **不建**：HN / Reddit（LLM 通过训练数据 + web access 已能覆盖）
- **总投入**：≈30-50 行 Bash，无新依赖

## 维度收益矩阵

| 维度 | 权重 | 现有信号数 | 新增后 | 主要受益信号 |
|------|------|----------|--------|------------|
| D1 兼容性 | 15% | 3 | 3 | — |
| D2 安全 | 25% | 7 | 8 | +安全 issue label 搜索 |
| **D3 维护健康** | **25%** | **4** | **9** | **Issue 关闭耗时 / 维护者响应行为 / Release 节奏 / 版本号纪律** ⭐ |
| **D4 功能价值** | **15%** | **1** | **2** | **bug/open 比** |
| **D5 文档与 UX** | **10%** | **1** | **4** | **Release notes 质量 / CHANGELOG 存在 / label 体系** ⭐ |
| D6 运营成本 | 10% | 0 | 0 | —（仍依赖 LLM） |

## 关键新增信号（10 类）

**Issues（6 类）**：
1. Issue 关闭耗时分布（D3，AgentRank 核心要求，当前无数据）
2. bug / open 比（D4）
3. 最老未关闭 Issue（D3，framework L144 评分锚点无数据）
4. 维护者响应行为（D3 + D4）
5. Issue 标签体系存在性（D5）
6. 安全相关 Issue（D2 兜底）

**Releases / CHANGELOG（4 类）**：
7. Release 节奏（D3，framework L141/L145 评分锚点无数据）
8. 版本号纪律（D3 + D1）
9. Release Notes 质量（D5）
10. CHANGELOG 存在性（D5）

## GitHub 参考实现

1. **Varnan-Tech/opendirectory** `skills/map-your-market/scripts/fetch.py` ⭐⭐⭐ — HN Algolia + Reddit 多源聚合
2. **langchain-ai/example-tool-server** `app/server.py` ⭐⭐ — LangChain 官方 example
3. **dmi3/bin** `headlines.sh` ⭐⭐⭐ — 最简纯 Bash HN 实现（<50 行）
4. **fayazara/feedful** `constants/feedtypes.ts` ⭐ — 多源 feed 类型定义

## 方案 B 不解决的缺口

| 维度 | 缺失 | 影响 |
|------|------|------|
| D6 运营成本 | Token 消耗 / 付费 API / 网络依赖 | D6 仍 0 个脚本信号，纯靠 LLM |
| D2 安全 | 社区层面安全事件报告 | 只能靠 issue label 兜底 |
| D4 功能价值 | 真实用户反馈 / benchmark | 仍依赖 LLM 推断 |

**D6 兜底**（可选）：加 1 行 query 搜 issue 文本中 'token' / 'cost' / 'paid' 关键词作为弱信号。

## 后续

如决定实施，工作计划落到 `.omo/plans/extend-community-signals.md`。

---

# learnings.md

## Task 1 — Project Skeleton

**Created 4 files:**
- `README.md` (77 lines) — Followed 02-opencode-memory-plugin pattern: H1 + blockquote + Overview + Installation + Usage + How It Works + Project Structure + License
- `LICENSE` (21 lines) — Standard MIT, copyright 2026 PointFish
- `.gitignore` (3 lines) — Excludes `.DS_Store`, `*.swp`, `.omo/evidence/`
- `AGENTS.md` (51 lines) — Followed 02-opencode-memory-plugin structure: title + purpose + directory tree + key files table + conventions + common tasks

**Pattern notes:**
- AGENTS.md structure: 3 sections (Structure tree, Key Files table, Conventions, Common Tasks). No principles table needed for a skill project (vs plugin).
- README blockquote describes project type + purpose concisely.
- `.gitignore` must explicitly keep `.omo/evaluations/` and `.omo/plans/` tracked by omitting them from ignore list.

## Task 2 — SKILL.md

**Created:** `SKILL.md` (212 lines).

**Authoritative script/template paths (note: diverges from earlier AGENTS.md draft):**
- `scripts/github-report.sh` (NOT `github-scrape.sh`)
- `scripts/security-scan.sh` (NOT `cache.sh` or `evaluate-tool.sh`)
- `templates/report-template.md` (NOT `evaluation-report.md`)
- Cache location: `.omo/evaluations/{repo}.md` with ISO 8601 `evaluated_at` frontmatter field, 30-day TTL.

**Structure (7 sections):** frontmatter → # Tool Evaluator intro → 触发条件 → 工作流 (5 steps) → 6 维度评分标准 → Verdict 规则 → 错误处理 → 输出模板引用.

**Key design choices:**
- Verdict ordered list: Install (≥80 AND compat≥50) → Hold (60-79, or rescued veto) → Skip (<60 OR compat<50). First match wins.
- Veto is explicit in both Verdict section and Dimension 1; report must name the veto rather than imply from score.
- Step 3 mandates strict JSON output and stops on parse failure — no fabricated scores.
- All five error rows (URL format, gh CLI missing, rate limit, 404/private, not an AI tool) use canonical verbatim responses.
- "Do NOT trigger" block added to disambiguate from skill-creator and from multi-tool comparison (out of scope).
- No first-person voice; uses imperative / "the skill" / "Prometheus".

## Task 3 — `scripts/github-report.sh` (GitHub Metadata Scraper)

**Created:** `scripts/github-report.sh` (167 lines)

**Behavior:**
- Input: `owner/repo` → outputs pure JSON to stdout
- Uses `gh api` for all data fetching (public API, no auth needed beyond `gh auth`)
- Extracts 19 fields: stars, forks, watchers, open_issues, closed_issues_count, license, language, created_at, updated_at, pushed_at, default_branch, size_kb, description, topics, contributors_count, last_commit_sha, last_commit_date, open_issues_count, readme_excerpt

**Key implementation decisions:**
- `set -euo pipefail` with careful `|| true` fallbacks for commands that may fail (README fetch, contributors count)
- Error capture via temp file (`mktemp`) to read `gh` stderr for error classification (Not Found vs rate limit vs other API error)
- Contributors count uses `x-total-count` header (efficient, avoids fetching all), falls back to full fetch + count
- README fetched via `gh api .../readme --jq '.content' | base64 -D | head -c 500`; missing README → empty string
- Closed issues count via search API `/search/issues?q=repo:{owner}/{repo}+state:closed`
- All errors to stderr with structured JSON `{"error": "..."}`; exit codes: 0=success, 1=API error, 2=bad input/missing deps, 3=rate limited
- Input validated with regex `^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$`
- `trap` cleanup for temp file on EXIT

**Pattern notes:**
- Bash error handling: use conditional blocks (`if ! cmd; then`) rather than `||` succession for structured error classification
- `--include` flag on `gh api` exposes HTTP response headers (useful for `x-total-count` to get pagination totals without fetching all pages)

## Task 4 — `scripts/security-scan.sh` (Security Scanning)

**Created:** `scripts/security-scan.sh` (207 lines)

**Behavior:**
- Input: `owner/repo` → outputs pure JSON to stdout with security risk assessment
- Uses `gh api` exclusively for all data (no local clone, no npm/pip audit)
- Scans: hooks_count, launchd_installed, modifies_settings_json, writes_user_files, network_calls, elevated_privileges, prebuilt_binaries

**Risk level logic:**
- Count active flags (0→low, 1-2→medium, ≥3→high)
- Bump to high if launchd_installed + modifies_settings_json both true (system-level mods)
- Special case: empty repo → "unknown" (exit 0, not error)

**Key implementation decisions:**
- Wrapper `gh_api()` for centralized rate limit detection before every API call
- `grep_content()` / `grep_count()` helpers with `|| echo 0` fallback for safe scanning
- File presence detected from root tree JSON (`jq -r '.[].name'`), then fetched via `/contents/{path}`
- `join_by()` helper for constructing JSON arrays from bash arrays
- Exit codes: 0=success/empty-repo, 1=not-found/bad-input, 2=gh-missing, 3=rate-limited

**Pattern notes:**
- Risk points returned in Chinese (spec requirement for user-facing output)
- permissions_requested array derived from active flags (filesystem, network, admin, system)
- regex patterns use `grep -qiE` (case-insensitive ERE) with `\` escaping for literal dots in JSON/config paths
- Rate limiting detected via `grep -qi 'rate limit\|403'` on gh API stderr output

## Task 7: github-report.sh Issues + Releases + Changelog 信号扩展 (2026-06-07)

**Modified:** `scripts/github-report.sh` (151 → 299 lines)

**Added 14 new fields in 3 nested JSON sub-objects:**
- `issues: { close_median_hours, close_p90_hours, oldest_open_days, bug_count, label_count, security_labeled_count }`
- `releases: { count, latest_tag, latest_published_at, cadence_days_avg, latest_body_chars, has_breaking }`
- `changelog: { exists, size_bytes }`

**Key implementation decisions:**
- jq `fromdateiso8601` for all date parsing (cross-platform, no GNU `date -d` dependency on macOS)
- `try-catch` in jq for safe date parsing on null/malformed timestamps
- awk for percentile computation (median + P90 via nearest-rank method: `ceil(0.9 * N)`)
- `jq` without `-r` for values going to `--argjson` — produces JSON-encoded strings (with quotes) and raw numbers/nulls, all valid JSON
- `if cmd; then` pattern for releases/latest API call to distinguish "no body" (→ 0) from "API failure" (→ null)
- `for` loop with `break` for changelog detection (CHANGELOG.md → CHANGES.md → HISTORY.md, first match wins)
- `grep -c .` for line counting with `|| true` to handle `set -e` exit code 1 on empty input
- Empty releases array → `count: 0` (valid signal), other fields → null

**Pattern notes:**
- `set -euo pipefail` with `|| true` for all new `gh api` calls — same pattern as existing L79/L103/L107
- `2>"$GH_ERR"` on every new API call for error capture (shared temp file, `trap` cleanup)
- Numeric regex validation (`=~ ^[0-9]+$`) before assigning API results to prevent invalid `--argjson` values
- Tested with `pointfish6660/opencode-tool-evaluator` (small repo, 0 releases) and `cli/cli` (10 releases, 256 bug issues)

## Task 6: docs/tool-evaluator/ 文档树创建 (2026-06-07)

### 完成内容
创建了 4 个文件的文档树，参考 02-opencode-memory-plugin 的结构（README.md 作为导航中心 + 编号深度文件）：

| 文件 | 行数 | 内容 |
|------|------|------|
| README.md | 162 | 导航中心：问题/方案、设计原则、安装、快速开始、文档目录 |
| 01-evaluation-framework.md | 380 | 6 维度详解、一票否决、verdict 规则、9 框架对比表、权重选择依据 |
| 02-usage-guide.md | 208 | 触发词全表、输入格式、5 步工作流、报告解读、缓存策略、错误处理 |
| 03-comparative-analysis.md | 283 | 13 工具对比表、7 awesome-lists 对比、OpenSSF 对比、独特价值 |

### 关键设计决策
1. **中文标题**：所有章节标题使用中文，匹配 SKILL.md 的语言风格
2. **不复制 02-opencode-memory-plugin 内容**：只参考结构（README 导航 + 编号文件），内容完全原创
3. **客观对比**：03 文件对竞品保持客观描述，不贬低
4. **交叉引用**：所有 4 个文件通过相对链接互相引用
5. **数据来源**：13 工具 + 20 框架数据均引用 .omo/drafts/skill-advisor.md 调研结果

## Task 9 — Extend report-template.md GitHub 统计表

**Updated:** `templates/report-template.md` — Added 4 new rows to the existing "GitHub 统计" table (after L69):

| 新指标 | 变量名 | 意义 |
|--------|--------|------|
| Issue 中位关闭时长 | `{{issue_close_median_hours}}` | 维护响应速度（D3） |
| 最老 Open Issue | `{{oldest_open_days}}` | 是否积压 |
| Release 数 / 最新版本 | `{{release_count}} / {{latest_tag}}` | 发布活跃度 |
| Release 节奏 (平均间隔) | `{{cadence_days_avg}}` | 发布频率纪律性 |

**Pattern notes:**
- Variable names flat (not nested), matching JSON Schema mapping: `issues.close_median_hours` → `issue_close_median_hours`
- Chose 4 most user-facing rows; skipped `changelog_exists` (boolean, least informative)
- Table grew from 7 to 11 rows — within 10-12 range recommended
- Frontmatter, TL;DR, 评分总表, 详细评估, 替代方案, Verdict 理由, 附录 all untouched

**Updated:**
- `docs/02-usage-guide.md` L117 — Step 4 评分 description now references structured fields (`Issue 关闭耗时、Release 节奏、CHANGELOG 存在性等结构化字段`) and clarifies HN/Reddit as `LLM 通过 web 调研获取，非脚本化`
- `docs/02-usage-guide.md` L134 — Replaced single "社区信号" row with 4 rows:
  - **Issue 健康**: `issues.close_median_hours`, `issues.oldest_open_days`, `issues.bug_count`
  - **Release 节奏**: `releases.cadence_days_avg`, `releases.latest_tag`, `releases.has_breaking`
  - **文档完整度**: `changelog.exists`, `releases.latest_body_chars`
  - **社区信号**: HN / Reddit (LLM web 调研，非脚本化)
- Field paths match plan's JSON Schema in `.omo/plans/extend-community-signals.md`

### 从 skill-advisor.md 提炼的关键信息
- 13 个相关工具按 5 类组织（质量评估、安全审计、仓库健康、已装审计、其他）
- 20+ 框架的信号聚类关系（哪个维度参考了哪些框架）
- 7 个 awesome-lists 全部是被动目录，无分析能力
- 核心缺口：安装前综合评估完全空白

## Task 10: End-to-End QA Validation (2026-06-07)

**Scope:** Validate extended `scripts/github-report.sh` (commit 39d4039) across 3 real repos with field consistency + backward compat checks.

**Repos tested:**
1. `pointfish6660/opencode-tool-evaluator` (self, 0 releases) — small repo baseline
2. `cli/cli` (large active repo, 10 releases) — full-data path
3. `aadarshahuja99/leetcode` (small repo, 0 releases) — independent no-release verification

**Results — Overall VERDICT: PASS (6/6 acceptance criteria met)**

| Check | Result | Notes |
|-------|--------|-------|
| JSON validity (all 3 repos) | PASS | `jq .` parsed OK, exit 0 |
| Sub-objects present | PASS | `issues`, `releases`, `changelog` all present in all 3 |
| Null fallback (no-release repos) | PASS | `releases.count=0` (numeric), other releases fields null; `changelog.exists=false` |
| Field name consistency | PASS | 5 template flat-vars map to nested JSON paths; 8 docs paths match script exactly |
| Backward compat (19 orig fields) | PASS | All 19 present at top level across all 3 repos; total = 22 keys (19 + 3 sub-objects) |

**Evidence:** `.omo/evidence/final-qa/{self,large-repo,no-release}.json`, `field-consistency.txt`, `backward-compat.txt`, `summary.txt`

**Pattern notes:**
- Null fallback design: `count: 0` is a valid numeric signal (not null); other fields are null. This lets downstream scoring treat "0 releases" as a legitimate data point without distinguishing missing-data.
- Bash grep loop with `for x in $EXPECTED; do echo $PRESENT | grep -qw $x` was unreliable when fields overlapped — switched to `jq` set subtraction `($expected - $present)` for accurate diff.
- One pre-existing legacy mismatch (`{{closed_issues}}` template vs `closed_issues_count` script) noted but NOT introduced by Tasks 1-3; out of scope for this QA.

**Reusable decision:**
- For future field consistency checks: extract paths via `jq -r 'paths | map(tostring) | join(".")'` from a `large-repo.json` output (it has the most populated fields), then compare against template vars (extract with `grep -oE '\{\{[a-z_]+\}\}'`) and docs refs (extract with `grep -oE '`[a-z_]+\.[a-z_]+`'`).
