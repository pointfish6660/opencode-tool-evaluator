# Extend github-report.sh with Issue/Release/Changelog Signals

## TL;DR

> **Quick Summary**: Extend the existing `github-report.sh` script to fetch 10 new quantitative signals across Issues, Releases, and CHANGELOG via the existing `gh` CLI infrastructure. Upgrades D3 维护健康 (25% weight) and D5 文档与 UX (10% weight) from guesswork to evidence-backed scoring.
> 
> **Deliverables**:
> - Extended `scripts/github-report.sh` with 3 new nested JSON objects (`issues`, `releases`, `changelog`)
> - Updated `templates/report-template.md` with 3-5 new rows in GitHub 统计 table
> - Updated `docs/02-usage-guide.md` 社区信号 field descriptions
> - End-to-end QA validation on 2-3 real repos
> 
> **Estimated Effort**: Short (1-2 hours)
> **Parallel Execution**: YES - 2 waves
> **Critical Path**: Task 1 (script extension) → Task 4 (QA validation)

---

## Context

### Original Request

可行性评估（见 `.omo/notepads/tool-evaluator/learnings.md` "Web Research 功能可行性评估" section）确认了方案 B：只建 Issues + Releases 信号，不建 HN/Reddit。用户确认进入规划。

### Interview Summary

**Key Discussions**:
- JSON 结构 → 分组嵌套（新增 `issues` / `releases` / `changelog` 子对象，原 19 字段保持平铺）
- 回退策略 → null（区分"抓不到" vs "真为 0"）
- 模板范围 → 最小扩展（现有表加行，不新增 section）
- 测试策略 → QA Scenarios only，不建测试文件

**Research Findings**:
- 现有 `github-report.sh` 151 行，已有 `gh api search/issues` 调用模式（L106-107）
- GitHub search API 30 req/min，新增 5-8 query 完全在限额内
- `templates/report-template.md` 当前 9 行 "GitHub 统计" 表，无 Issues/Releases 详情 section
- `docs/02-usage-guide.md` L134 的"社区信号"字段在模板中未实现（doc/template 不一致）

### Metis/Oracle Review

Metis session 失败（system error），由 Oracle phase 1 替代验证。
Oracle **CHECK 5/5 PASS | VERDICT: GO**。

**Key Oracle findings**:
- AGENTS.md 不需要更新（描述足够泛化，不枚举字段）
- Null 回退对 LLM 消费更友好（`null` = 数据缺失 vs `0` = 真为零）
- 速率限制风险低（6-9 calls/评估，远低于 30 req/min）
- Watch items: (1) jq null assembly 语法 (`--argjson field null`) (2) 嵌套对象组装方式（extend `jq -n` 或 post-compose `*=`）

---

## Work Objectives

### Core Objective

把 D3 维护健康（25%）和 D5 文档与 UX（10%）从"瞎猜"升级到"有量化指标"，通过为 `github-report.sh` 新增 10 类 Issue/Release/Changelog 信号。

### Concrete Deliverables

- `scripts/github-report.sh`: 从 151 行扩展到 ~200 行，新增 3 个嵌套 JSON 子对象
- `templates/report-template.md`: "GitHub 统计"表新增 3-5 行
- `docs/02-usage-guide.md`: 更新 Step 4 评分 + 社区信号字段描述

### Definition of Done

- [x] `./scripts/github-report.sh pointfish6660/opencode-tool-evaluator` 输出有效 JSON，包含 `issues`/`releases`/`changelog` 子对象
- [x] 新增字段在抓取失败时显式返回 JSON `null`（不是 `0` 或 `""`）
- [x] 模板 + docs 字段名与脚本输出一致
- [x] 在 2-3 个真实 repo 上 QA 验证通过

### Must Have

- 10 类新增信号全部实现（见 JSON Schema 下方）
- 嵌套 JSON 结构（`issues: {}`, `releases: {}`, `changelog: {}`）
- null 回退策略（所有新增字段）
- 现有 19 个字段输出保持不变（向后兼容）
- 仅依赖 `gh` + `jq`（无新依赖）

### Must NOT Have (Guardrails)

- ❌ 不改 SKILL.md 的评分逻辑 / 权重 / 维度定义
- ❌ 不改 security-scan.sh
- ❌ 不改 docs/01-evaluation-framework.md
- ❌ 不建 HN/Reddit 程序化抓取
- ❌ 不新建测试文件（QA Scenarios 替代）
- ❌ 不改现有 19 个字段的输出格式（向后兼容）
- ❌ 不引入 Python/Node 等新运行时依赖
- ❌ 不新增独立的"社区活跃度"section 到模板（只扩展现有表）
- ❌ 不改 AGENTS.md（描述足够泛化）

### Target JSON Schema (新增部分)

```json
{
  "stars": 1234,                              // 原有，保持平铺
  "forks": 56,                                // 原有
  "...": "...所有原有 19 个字段保持不变...",
  "issues": {                                 // 新增子对象
    "close_median_hours": 56.0,               // 最近 N 个 closed issue 的中位关闭时长
    "close_p90_hours": 240.0,                 // P90 关闭时长
    "oldest_open_days": 180,                  // 最老 open issue 的天数
    "bug_count": 12,                          // label:bug 的 open issue 数
    "label_count": 8,                         // repo 的 issue label 总数
    "security_labeled_count": 0               // label:security/vulnerability 的 issue 数
  },
  "releases": {                               // 新增子对象
    "count": 15,                              // 总 release 数（fetch 最近 10 个估算）
    "latest_tag": "v1.2.3",                   // 最新 release tag
    "latest_published_at": "2026-05-15",      // 最新 release 时间
    "cadence_days_avg": 30.5,                 // 最近 5 release 间隔均值
    "latest_body_chars": 1200,                // 最新 release notes 字符数
    "has_breaking": false                     // 最新 release notes 是否含 BREAKING
  },
  "changelog": {                              // 新增子对象
    "exists": true,                           // CHANGELOG.md / CHANGELOG是否存在
    "size_bytes": 5400                        // 文件大小
  }
}
```

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** - ALL verification is agent-executed.

### Test Decision

- **Infrastructure exists**: NO（scripts/ 下无测试文件）
- **Automated tests**: None
- **Framework**: N/A
- **QA Policy**: Agent-executed QA Scenarios on 2-3 real repos

Every task MUST include agent-executed QA scenarios.
Evidence saved to `.omo/evidence/task-{N}-{scenario-slug}.{ext}`.

- **Script/Module**: Use Bash — run script, parse JSON with jq, assert fields exist and types

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately - 3 parallel tasks):
├── Task 1: Extend github-report.sh — Issues + Releases + Changelog [deep]
├── Task 2: Update docs/02-usage-guide.md 社区信号 fields [quick]
└── Task 3: Extend templates/report-template.md GitHub 统计 table [quick]

Wave 2 (After Wave 1 - 1 integration task):
└── Task 4: End-to-end QA validation on real repos [unspecified-high]

Wave FINAL (After ALL tasks — 4 parallel reviews):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA (unspecified-high)
└── Task F4: Scope fidelity check (deep)
-> Present results -> Get explicit user okay

Critical Path: Task 1 → Task 4 → F1-F4 → user okay
Parallel Speedup: ~40% faster than sequential
Max Concurrent: 3 (Wave 1)
```

### Dependency Matrix

| Task | Depends On | Blocks |
|------|-----------|--------|
| 1 | — | 4 |
| 2 | — | — |
| 3 | — | — |
| 4 | 1, 2, 3 | F1-F4 |
| F1-F4 | 4 | — |

### Agent Dispatch Summary

- **Wave 1**: 3 — T1 → `deep`, T2 → `quick`, T3 → `quick`
- **Wave 2**: 1 — T4 → `unspecified-high`
- **FINAL**: 4 — F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

- [x] 1. Extend github-report.sh with Issues + Releases + Changelog signals

  **What to do**:
  - Extend `scripts/github-report.sh` to add 3 new nested JSON sub-objects: `issues`, `releases`, `changelog`
  - Update the file header comment (L4-12) to document all new output fields
  - **Issues signals** (insert after existing L108 `CLOSED_ISSUES_COUNT`):
    - `close_median_hours` + `close_p90_hours`: Fetch last 100 closed issues via `gh api "search/issues?q=repo:${INPUT}+state:closed&per_page=100&sort=created&order=desc"`, extract `created_at` + `closed_at`, compute median + P90 in seconds then convert to hours. Use `jq` for math or `awk` if jq math is awkward.
    - `oldest_open_days`: `gh api "search/issues?q=repo:${INPUT}+state:open&sort=created&order=asc&per_page=1"` → extract `created_at`, compute days from now.
    - `bug_count`: `gh api "search/issues?q=repo:${INPUT}+state:open+label:bug&per_page=1" --jq '.total_count'`
    - `label_count`: `gh api "repos/${INPUT}/labels?per_page=100" --jq 'length'`
    - `security_labeled_count`: `gh api "search/issues?q=repo:${INPUT}+label:security&per_page=1" --jq '.total_count'` (also try `label:vulnerability`, sum if both queried)
  - **Releases signals** (insert after Issues block):
    - `count` + `latest_tag` + `latest_published_at`: `gh api "repos/${INPUT}/releases?per_page=10"` → extract count, latest tag + date.
    - `cadence_days_avg`: From the 10 releases, compute avg interval between consecutive `published_at` dates.
    - `latest_body_chars`: `gh api "repos/${INPUT}/releases/latest" --jq '.body // "" | length'`
    - `has_breaking`: Check if latest release body contains "BREAKING" (case-insensitive): `echo "$BODY" | grep -qi "breaking" && echo true || echo false`
  - **Changelog signals** (insert after Releases block):
    - `exists` + `size_bytes`: Try `gh api "repos/${INPUT}/contents/CHANGELOG.md"` (also try `CHANGES.md`, `HISTORY.md` as fallbacks). If 200 → `exists=true, size_bytes=N`. If 404 → `exists=false, size_bytes=null`.
  - **JSON assembly** (modify L111-151 `jq -n` block): Extend the existing `jq -n` call to include 3 new sub-objects. For null injection, use `--argjson` with literal `null` value, e.g., `--argjson close_median_hours "${CLOSE_MEDIAN_HOURS:-null}"`. **IMPORTANT**: Bash variables must be either valid JSON numbers or literal `null` string for `--argjson`.
  - **Error handling**: Every new `gh api` call must follow existing pattern: `2>"$GH_ERR" || true`. If any call fails, the corresponding field defaults to `null`.

  **Must NOT do**:
  - Do NOT change existing 19 flat fields or their values
  - Do NOT add Python/Node — pure Bash + `gh` + `jq` only
  - Do NOT create a new script file — extend existing `github-report.sh`
  - Do NOT add `set +e` or remove `set -euo pipefail`
  - Do NOT hardcode repo names or URLs
  - Do NOT use `eval` or `exec`

  **Recommended Agent Profile**:
  > Select category + skills based on task domain.
  - **Category**: `deep`
    - Reason: Bash script extension with non-trivial jq date math + null injection patterns. Requires careful assembly of nested JSON from multiple API calls with proper error handling.
  - **Skills**: []
    - No skill matches Bash scripting domain.

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 2, 3)
  - **Parallel Group**: Wave 1
  - **Blocks**: Task 4 (QA validation needs complete script)
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References** (existing code to follow):
  - `scripts/github-report.sh:44-56` — `gh api repos/${INPUT}` call pattern with error handling via `mktemp` + trap
  - `scripts/github-report.sh:74-86` — Contributors count with `|| true` fallback + secondary fallback (pattern for null injection)
  - `scripts/github-report.sh:106-108` — Existing `search/issues` API call for `CLOSED_ISSUES_COUNT` (extend this pattern)
  - `scripts/github-report.sh:111-151` — `jq -n` JSON assembly with `--arg` / `--argjson` injection (extend this block)

  **API References** (contracts to implement against):
  - Target JSON Schema defined in plan's "Target JSON Schema" section above
  - GitHub Search API: `gh api search/issues?q=...` returns `.total_count` + `.items[]`
  - GitHub Releases API: `gh api repos/{owner}/{repo}/releases` returns array with `.tag_name`, `.published_at`, `.body`
  - GitHub Contents API: `gh api repos/{owner}/{repo}/contents/{path}` returns `.size` or 404

  **External References**:
  - GitHub Search Issues docs: `https://docs.github.com/en/rest/search#search-issues-and-pull-requests`
  - GitHub Releases docs: `https://docs.github.com/en/rest/releases/releases`
  - jq manual (null handling): `https://jqlang.github.io/jq/manual/#basic-filters`

  **WHY Each Reference Matters**:
  - `github-report.sh:44-56` — Teaches the error handling pattern (mktemp trap, error_exit, grep for "not found"/"rate limit"). New API calls must follow this same pattern.
  - `github-report.sh:74-86` — Teaches multi-level fallback pattern. Use similar approach for new fields: try API → fallback to secondary → default to null.
  - `github-report.sh:106-108` — Teaches `search/issues` + `--jq '.total_count'` pattern. New searches (bug, security) follow same 1-liner pattern.
  - `github-report.sh:111-151` — Teaches how to inject Bash variables into `jq -n`. Key insight: `--argjson` for numbers/null, `--arg` for strings. New nested objects extend this same block.

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Happy path — run on a repo with issues + releases + changelog
    Tool: Bash
    Preconditions: `gh auth status` returns authenticated; repo `anthropics/claude-code` exists and has releases + issues + CHANGELOG
    Steps:
      1. Run: `./scripts/github-report.sh anthropics/claude-code > /tmp/test-happy.json 2>/dev/null`
      2. Check exit code: `echo $?` → expected 0
      3. Validate JSON: `jq . /tmp/test-happy.json > /dev/null` → expected success
      4. Check issues sub-object: `jq '.issues.close_median_hours' /tmp/test-happy.json` → expected a number (not null, since repo has closed issues)
      5. Check releases sub-object: `jq '.releases.latest_tag' /tmp/test-happy.json` → expected a non-empty string like "v0.2.94"
      6. Check changelog sub-object: `jq '.changelog.exists' /tmp/test-happy.json` → expected true or false (boolean, not null)
      7. Check backward compat: `jq '.stars' /tmp/test-happy.json` → expected a positive integer (same as before)
    Expected Result: All 6 new sub-object fields populated with correct types; existing 19 fields unchanged
    Failure Indicators: Exit code ≠ 0; jq parse error; new fields missing or wrong type; existing fields changed
    Evidence: .omo/evidence/task-1-happy-path.json

  Scenario: Edge case — repo with no releases
    Tool: Bash
    Preconditions: Find a repo with 0 releases (e.g., a fresh repo or one that only uses tags). Fallback: use `pointfish6660/opencode-tool-evaluator` if it has no GitHub Releases (only tags).
    Steps:
      1. Run: `./scripts/github-report.sh <repo-with-no-releases> > /tmp/test-norelease.json 2>/dev/null`
      2. Check exit code: `echo $?` → expected 0
      3. Validate JSON: `jq . /tmp/test-norelease.json > /dev/null` → expected success
      4. Check releases.count: `jq '.releases.count' /tmp/test-norelease.json` → expected 0 or null
      5. Check releases.latest_tag: `jq '.releases.latest_tag' /tmp/test-norelease.json` → expected null
      6. Check releases.cadence_days_avg: `jq '.releases.cadence_days_avg' /tmp/test-norelease.json` → expected null
      7. Check rest of JSON still valid: `jq '.stars, .issues' /tmp/test-norelease.json` → expected valid values
    Expected Result: Releases fields gracefully return null/0; rest of JSON unaffected
    Failure Indicators: Exit code ≠ 0; jq parse error; releases fields contain error text instead of null
    Evidence: .omo/evidence/task-1-no-release.json

  Scenario: Edge case — API failure graceful degradation
    Tool: Bash
    Preconditions: Temporarily simulate failure by commenting out `gh` path (or test on a private/nonexistent repo that returns 404 on search)
    Steps:
      1. Run: `./scripts/github-report.sh <private-or-404-repo> 2>/dev/null || true`
      2. If script exits non-zero (expected for 404 on repo itself), verify error message goes to stderr
      3. Alternative: test on a valid repo but with `GH_TOKEN=invalid gh api ...` to trigger search API failure → verify issues sub-object fields become null
    Expected Result: Either clean exit with error code 1 (repo not found), or valid JSON with null values in failed sub-objects
    Failure Indicators: Unhandled crash; raw error text in JSON output; script hangs
    Evidence: .omo/evidence/task-1-api-failure.txt
  ```

  **Commit**: YES
  - Message: `feat(scripts): extend github-report.sh with Issues/Releases/Changelog signals`
  - Files: `scripts/github-report.sh`
  - Pre-commit: `./scripts/github-report.sh pointfish6660/opencode-tool-evaluator | jq .`

- [x] 2. Update docs/02-usage-guide.md — 社区信号 field descriptions

  **What to do**:
  - Update `docs/02-usage-guide.md` to document the new JSON fields and how they map to the 6-dimension scoring framework
  - **L117 (Step 4 评分)**: Update the description to reference the new structured fields instead of vague "HN / Reddit / GitHub Issues / CHANGELOG". Example replacement: "结合脚本输出（含 Issue 关闭耗时 / Release 节奏 / CHANGELOG 等结构化字段）+ 简短社区调研（HN / Reddit），为每个维度打分"
  - **Note**: The existing 19 flat fields in github-report.sh have some redundancy (`open_issues` and `open_issues_count` return the same value). This plan treats them as 19 fields (the header comment L8-12 enumerates 19 names).
  - **L134 (社区信号 table row)**: Update from `"社区信号 | HN / Reddit / Issue 中的关键反馈"` to include the new structured signals. Add rows for the new field groups. Example:
    ```
    | **Issue 健康** | `issues.close_median_hours`, `issues.oldest_open_days`, `issues.bug_count` |
    | **Release 节奏** | `releases.cadence_days_avg`, `releases.latest_tag`, `releases.has_breaking` |
    | **文档完整度** | `changelog.exists`, `releases.latest_body_chars` |
    | **社区信号** | HN / Reddit 上的定性反馈（LLM 通过 web 调研获取，非脚本化） |
    ```
  - Keep the existing HN/Reddit mention as "LLM 通过 web 调研获取，非脚本化" to clarify the boundary between scripted vs. non-scripted data

  **Must NOT do**:
  - Do NOT change docs/01-evaluation-framework.md (weights, dimensions, scoring rubrics)
  - Do NOT change docs/03-comparative-analysis.md
  - Do NOT add new sections — only update existing content
  - Do NOT mention implementation details (e.g., "uses gh api search/issues") — keep user-facing

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Pure documentation text update, no code. Single file, ~10 line changes.
  - **Skills**: []
    - No skill needed for plain markdown doc update.

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 1, 3)
  - **Parallel Group**: Wave 1
  - **Blocks**: None (but Task 4 will verify consistency)
  - **Blocked By**: None (field names are defined in plan's JSON Schema section)

  **References**:

  **Pattern References**:
  - `docs/02-usage-guide.md:117` — Existing Step 4 description to update
  - `docs/02-usage-guide.md:130-140` — Existing data fields table to extend

  **API/Type References**:
  - Plan section "Target JSON Schema" — canonical field names and types

  **WHY Each Reference Matters**:
  - `02-usage-guide.md:117` — The exact line where vague "HN/Reddit/Issue" text needs replacement
  - `02-usage-guide.md:130-140` — The existing table structure to match (column count, row format)
  - JSON Schema in plan — Ensures doc field names EXACTLY match script output field names

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Field names match JSON schema
    Tool: Bash
    Preconditions: Plan's JSON Schema section is accessible
    Steps:
      1. Grep all field references in docs/02-usage-guide.md: `grep -oP '(issues|releases|changelog)\.\w+' docs/02-usage-guide.md | sort -u`
      2. Compare with JSON Schema in plan: expected field names are `issues.close_median_hours`, `issues.close_p90_hours`, `issues.oldest_open_days`, `issues.bug_count`, `issues.label_count`, `issues.security_labeled_count`, `releases.count`, `releases.latest_tag`, `releases.latest_published_at`, `releases.cadence_days_avg`, `releases.latest_body_chars`, `releases.has_breaking`, `changelog.exists`, `changelog.size_bytes`
      3. Verify no typos: every grep'd field name must appear in the JSON Schema
    Expected Result: All field names in docs exactly match JSON Schema; no typos; no extra/missing fields
    Failure Indicators: Field name mismatch; typo (e.g., `release` instead of `releases`)
    Evidence: .omo/evidence/task-2-field-names.txt

  Scenario: HN/Reddit boundary clarified
    Tool: Bash
    Preconditions: docs updated
    Steps:
      1. Grep for HN/Reddit mentions: `grep -n 'HN\|Reddit' docs/02-usage-guide.md`
      2. Verify each mention clarifies these are "LLM web 调研" (non-scripted)
    Expected Result: HN/Reddit mentioned with clarification that they're LLM-sourced, not scripted
    Failure Indicators: HN/Reddit mentioned as if they're script outputs
    Evidence: .omo/evidence/task-2-hn-reddit-clarified.txt
  ```

  **Commit**: YES
  - Message: `docs(usage): update 社区信号 field descriptions for new script outputs`
  - Files: `docs/02-usage-guide.md`

- [x] 3. Extend templates/report-template.md — GitHub 统計 table

  **What to do**:
  - Extend the existing "GitHub 统计" table in `templates/report-template.md` (L59-69) to add 3-5 new rows surfacing the new scripted signals
  - **Minimal approach** (per user decision): Add rows to the EXISTING table — do NOT create a new section. Example rows to add after L69 (`| Created / Updated | {{created_at}} / {{updated_at}} |`):
    ```
    | Issue 中位关闭时长 | {{issue_close_median_hours}} |
    | 最老 Open Issue | {{oldest_open_days}} 天 |
    | Release 数 / 最新版本 | {{release_count}} / {{latest_tag}} |
    | Release 节奏 (平均间隔) | {{cadence_days_avg}} 天 |
    | CHANGELOG | {{changelog_exists}} |
    ```
  - **Variable naming**: Use flat variable names (e.g., `{{issue_close_median_hours}}`) rather than nested paths (e.g., `{{issues.close_median_hours}}`), since the template engine (likely Jinja2 or simple replacement) may not support nested access. The orchestrating LLM will flatten the JSON when filling the template.
  - **Null rendering**: If a field is null, the template should display "N/A" — add a note in template comment or use the Jinja2 `{{ x if x is not none else "N/A" }}` pattern if applicable, otherwise let the LLM handle null→"N/A" conversion during template filling.

  **Must NOT do**:
  - Do NOT add a new section — only extend existing "GitHub 统計" table
  - Do NOT change the existing frontmatter or other sections (TL;DR, 评分总表, 详细评估, etc.)
  - Do NOT add complex Jinja2 logic — keep it simple for LLM-based template filling
  - Do NOT add rows for every single new field — pick the 3-5 most user-facing ones

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Pure template text update, no code. Single file, ~5-10 line additions to an existing table.
  - **Skills**: []
    - No skill needed for template markdown editing.

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Tasks 1, 2)
  - **Parallel Group**: Wave 1
  - **Blocks**: None (but Task 4 will verify rendering)
  - **Blocked By**: None (field names are defined in plan's JSON Schema section)

  **References**:

  **Pattern References**:
  - `templates/report-template.md:59-69` — Existing "GitHub 统計" table to extend (match column count, row format)
  - `templates/report-template.md:1-7` — Frontmatter pattern (do NOT change)

  **API/Type References**:
  - Plan section "Target JSON Schema" — canonical field names

  **WHY Each Reference Matters**:
  - `report-template.md:59-69` — Exact table to extend. Must match existing 2-column format (`| 指标 | 值 |`). New rows go after the last existing row.
  - JSON Schema — Ensures template variables exactly match script output field names (flattened).

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: New rows present in table
    Tool: Bash
    Preconditions: Template updated
    Steps:
      1. Grep for new rows: `grep -c 'issue_close_median_hours\|oldest_open_days\|release_count\|cadence_days_avg\|changelog_exists' templates/report-template.md`
      2. Expected: count ≥ 3 (at least 3 of the 5 suggested new rows)
    Expected Result: At least 3 new rows added to GitHub 统計 table
    Failure Indicators: 0 matches; new rows outside the table
    Evidence: .omo/evidence/task-3-new-rows.txt

  Scenario: Existing sections unchanged
    Tool: Bash
    Preconditions: Template updated
    Steps:
      1. Check frontmatter unchanged: `head -7 templates/report-template.md` → expected same structure
      2. Check TL;DR section exists: `grep -c '## TL;DR' templates/report-template.md` → expected 1
      3. Check 评分总表 section exists: `grep -c '## 评分总表' templates/report-template.md` → expected 1
    Expected Result: All existing sections preserved; only GitHub 统計 table extended
    Failure Indicators: Missing section; changed frontmatter
    Evidence: .omo/evidence/task-3-existing-intact.txt
  ```

  **Commit**: YES
  - Message: `feat(templates): add Issue/Release/Changelog rows to GitHub 統計 table`
  - Files: `templates/report-template.md`

- [x] 4. End-to-end QA validation on real repos

  **What to do**:
  - Run the complete evaluation flow on 3 real repos to verify: (1) script JSON output, (2) template field name consistency, (3) docs field name consistency, (4) null fallback behavior
  - **Test repos** (cover different repo profiles):
    1. `pointfish6660/opencode-tool-evaluator` — small repo, self-reference, likely few issues/releases
    2. `anthropics/claude-code` or `anthropics/anthropic-cookbook` — large repo with many issues + releases + CHANGELOG
    3. A repo with NO GitHub Releases section (only tags, or brand new) — test null fallback on releases sub-object
  - For each repo:
    1. Run `./scripts/github-report.sh <owner>/<repo> > .omo/evidence/final-qa/<repo-slug>.json`
    2. Validate JSON: `jq . <file>` must succeed
    3. Check all new fields present: `jq '.issues, .releases, .changelog' <file>` — all 3 must be objects (not null, not missing)
    4. Check null semantics: identify which fields are null vs. 0/false in each repo
    5. Compare existing 19 fields with pre-change output (if available) to verify backward compat
  - Cross-check field names:
    - `grep -oP '(issues|releases|changelog)\.\w+' .omo/evidence/final-qa/*.json scripts/github-report.sh templates/report-template.md docs/02-usage-guide.md | sort -t: -k2 | uniq`
    - Verify consistent naming across all 4 sources
  - Test template rendering: manually substitute one repo's JSON output into the template and verify it renders coherently

  **Must NOT do**:
  - Do NOT modify any source files — this is validation only
  - Do NOT skip the null-fallback test repo
  - Do NOT use a private repo (requires auth, may hit different API behavior)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: QA validation requires running scripts, parsing JSON, cross-referencing multiple files. Moderate complexity, needs accuracy.
  - **Skills**: []
    - No skill needed.

  **Parallelization**:
  - **Can Run In Parallel**: NO (depends on all 3 prior tasks)
  - **Parallel Group**: Wave 2 (sequential after Wave 1)
  - **Blocks**: F1-F4 (Final Verification Wave)
  - **Blocked By**: Tasks 1, 2, 3

  **References**:

  **Pattern References**:
  - `.omo/evidence/task-1-happy-path.json` — Output from Task 1's QA (reference for expected shape)

  **API/Type References**:
  - Plan's "Verification Commands" section — canonical test commands
  - Plan's "Target JSON Schema" — field name source of truth

  **WHY Each Reference Matters**:
  - Task 1 evidence — Baseline for comparison. If Task 1's QA passed, Task 4 validates the FULL flow including template + docs consistency.

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Full flow on 3 repos
    Tool: Bash
    Preconditions: Tasks 1-3 completed; gh auth working; .omo/evidence/final-qa/ directory exists
    Steps:
      1. mkdir -p .omo/evidence/final-qa
      2. Run on repo 1: `./scripts/github-report.sh pointfish6660/opencode-tool-evaluator > .omo/evidence/final-qa/self.json 2>/dev/null`; `echo $?` → expected 0
      3. Validate: `jq . .omo/evidence/final-qa/self.json > /dev/null` → expected success
      4. Check new sub-objects: `jq 'has("issues") and has("releases") and has("changelog")' .omo/evidence/final-qa/self.json` → expected true
      5. Repeat steps 2-4 for repo 2 (large repo) → save as `.omo/evidence/final-qa/large-repo.json`
      6. Repeat steps 2-4 for repo 3 (no releases) → save as `.omo/evidence/final-qa/no-release.json`
      7. For no-release repo: `jq '.releases.latest_tag' .omo/evidence/final-qa/no-release.json` → expected null
    Expected Result: All 3 repos produce valid JSON with all new sub-objects; null fallback confirmed on no-release repo
    Failure Indicators: Any repo fails to produce JSON; missing sub-objects; null fallback not working
    Evidence: .omo/evidence/final-qa/{self,large-repo,no-release}.json

  Scenario: Field name consistency across script + template + docs
    Tool: Bash
    Preconditions: All evidence files generated
    Steps:
      1. Extract field names from script: `grep -oP '(issues|releases|changelog)\.\w+' scripts/github-report.sh | sort -u`
      2. Extract from template: `grep -oP '(issues|releases|changelog)\.\w+|issue_close_median_hours|oldest_open_days|release_count|cadence_days_avg|changelog_exists' templates/report-template.md | sort -u`
      3. Extract from docs: `grep -oP '(issues|releases|changelog)\.\w+' docs/02-usage-guide.md | sort -u`
      4. Compare: all field names referenced in template/docs must exist in script output
    Expected Result: Zero field name mismatches; every template/doc reference has a corresponding script field
    Failure Indicators: Template/doc references a field not in script output; typo causing mismatch
    Evidence: .omo/evidence/final-qa/field-consistency.txt

  Scenario: Backward compatibility — existing 19 fields unchanged
    Tool: Bash
    Preconditions: Pre-change JSON output available (or compare against known field list)
    Steps:
      1. Run: `jq 'keys | sort' .omo/evidence/final-qa/self.json`
      2. Verify ALL of: stars, forks, watchers, open_issues, closed_issues_count, license, language, created_at, updated_at, pushed_at, default_branch, size_kb, description, topics, contributors_count, last_commit_sha, last_commit_date, open_issues_count, readme_excerpt are present at top level
      3. Verify new keys (issues, releases, changelog) are also present
    Expected Result: All 19 original keys + 3 new sub-object keys = 22 top-level keys
    Failure Indicators: Missing original key; original key moved into sub-object; extra unexpected key
    Evidence: .omo/evidence/final-qa/backward-compat.json
  ```

  **Commit**: NO (evidence files only, typically not committed)

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [x] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, run script, check JSON output). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in .omo/evidence/. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [x] F2. **Code Quality Review** — `unspecified-high`
  Review `scripts/github-report.sh` for: `set -euo pipefail` preserved, error handling on all `gh api` calls (use existing `|| true` + `mktemp` pattern), null injection via `--argjson` (not string interpolation), no hardcoded URLs, no `eval`/`exec`, jq expressions tested. Check for AI slop: excessive comments, over-abstraction, unused variables.
  Output: `Error Handling [PASS/FAIL] | Null Injection [PASS/FAIL] | Style [PASS/FAIL] | VERDICT`

- [x] F3. **Real Manual QA** — `unspecified-high`
  Run `./scripts/github-report.sh` on 3 repos: (1) `pointfish6660/opencode-tool-evaluator` (self, small repo), (2) `anthropics/claude-code` (large repo with many issues/releases), (3) a repo with NO releases (edge case). For each: verify JSON valid via `jq .`, check all new fields present, verify null fallback on no-release repo, compare existing 19 fields unchanged. Save outputs to `.omo/evidence/final-qa/`.
  Output: `Repos [3/3 pass] | JSON Validity [PASS] | Null Fallback [PASS] | Backward Compat [PASS] | VERDICT`

- [x] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff (`git log --oneline`, `git diff`). Verify 1:1 — everything in spec was built, nothing beyond spec was built. Check Must NOT Have compliance. Verify `SKILL.md`, `security-scan.sh`, `docs/01-evaluation-framework.md`, `AGENTS.md` are UNCHANGED. Flag unaccounted changes.
  Output: `Tasks [N/N compliant] | Forbidden Files [CLEAN/N modified] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

- **1** (after Task 1): `feat(scripts): extend github-report.sh with Issues/Releases/Changelog signals`
  - Files: `scripts/github-report.sh`
  - Pre-commit: `./scripts/github-report.sh pointfish6660/opencode-tool-evaluator | jq .`
- **2** (after Task 2): `docs(usage): update 社区信号 field descriptions for new script outputs`
  - Files: `docs/02-usage-guide.md`
- **3** (after Task 3): `feat(templates): add Issue/Release/Changelog rows to GitHub 统計 table`
  - Files: `templates/report-template.md`
- **4** (after Task 4): typically no commit (evidence files only)

---

## Success Criteria

### Verification Commands

```bash
# 1. Script produces valid JSON with all new fields
./scripts/github-report.sh pointfish6660/opencode-tool-evaluator | jq '.issues, .releases, .changelog'
# Expected: three non-null objects with expected fields

# 2. Null fallback works on edge cases (repo with no releases)
./scripts/github-report.sh <repo-with-no-releases> | jq '.releases.count'
# Expected: null (not 0)

# 3. Existing fields unchanged (backward compat)
./scripts/github-report.sh pointfish6660/opencode-tool-evaluator | jq '.stars, .forks, .open_issues'
# Expected: same values as before

# 4. Field names consistent across script + template + docs
grep -oP '(issues|releases|changelog)\.\w+' scripts/github-report.sh templates/report-template.md docs/02-usage-guide.md | sort -t: -k2
# Expected: same field names across all 3 files
```

### Final Checklist

- [x] All "Must Have" present
- [x] All "Must NOT Have" absent
- [x] Script runs without errors on 3 different repos
- [x] JSON output validates with `jq .`
- [x] Template renders correctly with new fields
- [x] Field names consistent across script + template + docs
