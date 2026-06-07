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

### 从 skill-advisor.md 提炼的关键信息
- 13 个相关工具按 5 类组织（质量评估、安全审计、仓库健康、已装审计、其他）
- 20+ 框架的信号聚类关系（哪个维度参考了哪些框架）
- 7 个 awesome-lists 全部是被动目录，无分析能力
- 核心缺口：安装前综合评估完全空白
