# tool-evaluator: 安装前 AI 工具评估技能

> **Project Location**: `~/projects/05-tool-evaluator/`（独立 git，已初始化）
> **Skill Install**: `~/.claude/skills/tool-evaluator` → `~/projects/05-tool-evaluator/`（软链接）
> **GitHub Repo**: `pointfish/opencode-tool-evaluator`（待创建）
> **Plan Source**: 本文件先在 openspace/.omo/plans/ 生成，已复制到新项目 .omo/plans/

## TL;DR

> **Quick Summary**: 创建一个 OpenCode skill（`tool-evaluator`），用于评估 GitHub 上的 AI 开发工具（Skill / MCP Server / CLI），输出 6 维度量化评分（0-100）+ 定性说明 + 🟢/🟡/🔴 verdict，帮助用户做"该不该装"决策。
> 
> **Deliverables**:
> - `SKILL.md` 主交付物（6 维度评估框架 + 触发词 + 工作流 + 评分标准）
> - `scripts/github-report.sh` GitHub 元数据抓取
> - `scripts/security-scan.sh` 安全侵入性扫描
> - `templates/report-template.md` 评估报告输出模板
> - `docs/tool-evaluator/` 完整文档树（参考 02-opencode-memory-plugin）
> - 项目工程文件（README、LICENSE、AGENTS.md、.gitignore）
> - 3 个样本项目验证（Headroom、Understand-Anything、第3个待选）
> - GitHub 远程仓库（pointfish/opencode-tool-evaluator）
> - 软链接安装到 ~/.claude/skills/tool-evaluator
> 
> **Estimated Effort**: Medium-Large（2-3 个工作会话）
> **Parallel Execution**: YES - 3 waves
> **Critical Path**: T1 (scaffolding) → T2 (SKILL.md) → T7 (symlink+remote) → T8-T10 (sample validation) → F1-F4

---

## Context

### Original Request
基于两次实操经验（Headroom token 压缩工具、Understand-Anything 知识图谱），用户发现"安装前评估"是 GitHub AI 工具生态的真实空白：30+ 个相关工具中没有任何一个做综合安装决策评估。用户决定创建 `tool-evaluator` skill 填补这个空白。

### Interview Summary

**Key Decisions**:
- 评估对象：Skill + MCP Server + CLI（AI 开发工具链）
- 输出形式：量化评分（6 维度 0-100，加权总分）+ 定性说明 + 🟢/🟡/🔴 verdict
- 输出位置：对话内 200 字概要 + 完整版写入 `{当前项目}/.omo/evaluations/{name}.md`
- 缓存策略：本地缓存（带时间戳，下次查询先检查）
- 触发词：中文（分析/评估/装不装）+ 英文（evaluate/install）+ 疑问句（好用吗/怎么样）
- 工作流：Prometheus 驱动 + 脚本辅助（不是独立 task agent）
- 项目位置：`~/projects/05-tool-evaluator/`，独立 git，发布到 GitHub 公开
- Skill 安装：软链接 `~/.claude/skills/tool-evaluator` → `~/projects/05-tool-evaluator/`
- 交付范围：含样本验证的完整版（SKILL.md + 2 scripts + 文档树 + 模板 + 3 样本）

**Research Findings**:
- GitHub 生态调研 30+ 工具：**安装前综合评估完全空白**
- 评估方法论调研 20+ 框架：OpenSSF Scorecards、AgentRank 五信号、Skill Grader 10 轴等
- 系统内 32 个 skill 中无任何评估/分析类
- `skill-creator` 是创建方向（不冲突）；`hv-analysis` 是"理解"而非"决策"

### Metis Review

**Identified Gaps** (addressed):
- SKILL.md 与 scripts 边界 → **已明确**：脚本只生成原始数据（JSON/stdout），SKILL.md 指导 Prometheus 解读并撰写报告
- OpenCode 兼容性 15% 权重过低 → **Default Applied**：兼容性维度引入"一票否决"机制（< 50 分直接降为 🔴，无论总分多高）
- 评估报告输出位置 → **已明确**：写入当前 cwd 的 `.omo/evaluations/{name}.md`（不是 skill 项目下）
- 项目命名不一致（项目目录 vs GitHub repo vs skill 名）→ **已接受**：GitHub 加 `opencode-` 前缀为清晰描述，本地编号前缀为排序，skill 名简短易用
- 样本验证成功标准 → **已明确**：见 Verification Strategy 节
- Edge cases（rate limit、timeout、错误输入）→ **deferred**：每个 script 的 acceptance criteria 中覆盖

---

## Work Objectives

### Core Objective
在 2-3 个工作会话内交付一个完整可用的 OpenCode skill，能够：
1. 通过中文/英文触发词激活
2. 接受 GitHub URL 输入
3. 自动化抓取 GitHub 元数据 + 安全扫描
4. 按 6 维度框架输出量化评分 + 定性报告
5. 写入本地缓存（.omo/evaluations/）
6. 在 3 个已知样本上验证输出质量

### Concrete Deliverables

**主交付物**：
- `SKILL.md`（~300-500 行）：含触发词、6 维度评分标准、工作流、输出模板、错误处理

**辅助脚本**：
- `scripts/github-report.sh`：调用 gh CLI，输出 stars/issues/contributors/license/last commit/README excerpt 等 JSON
- `scripts/security-scan.sh`：扫描 hooks/launchd/settings.json/文件系统写入/网络外发等风险点

**文档树**（参考 02-opencode-memory-plugin）：
- `README.md`：项目说明 + 安装指南 + 使用示例
- `AGENTS.md`：项目说明（供 OpenCode agent 阅读）
- `LICENSE`：MIT
- `docs/tool-evaluator/README.md`：文档入口
- `docs/tool-evaluator/01-evaluation-framework.md`：6 维度评分标准详解
- `docs/tool-evaluator/02-usage-guide.md`：使用指南 + 触发词 + 工作流
- `docs/tool-evaluator/03-comparative-analysis.md`：与现有 13 个工具对比

**模板**：
- `templates/report-template.md`：评估报告输出模板（含 6 维度表格 + verdict + 定性说明）

**工程文件**：
- `.gitignore`：排除 macOS 系统文件（.DS_Store）+ 临时文件
- 软链接：`~/.claude/skills/tool-evaluator` → `~/projects/05-tool-evaluator/`
- GitHub 远程仓库：`pointfish/opencode-tool-evaluator`

**样本验证**：
- `.omo/evaluations/headroom.md`：Headroom 项目评估报告
- `.omo/evaluations/understand-anything.md`：Understand-Anything 项目评估报告
- `.omo/evaluations/{第3个}.md`：补充样本（待选）

### Definition of Done
- [ ] 3 个样本评估报告都生成且分数符合预期区间
- [ ] SKILL.md 在新 session 中被触发词激活
- [ ] 软链接正常工作（OpenCode 可发现 skill）
- [ ] GitHub 仓库推送成功
- [ ] 文档完整（README + 3 篇 docs）

### Must Have
- 6 维度评分（OpenCode 兼容性 / 安全侵入性 / 维护健康 / 功能价值 / 文档UX / 运营成本）
- 加权总分（15/25/25/15/10/10）
- 兼容性"一票否决"：兼容性 < 50 分 → 强制 🔴
- Verdict 规则：≥80 → 🟢 Install；60-79 → 🟡 Hold；<60 → 🔴 Skip
- 报告写入 .omo/evaluations/{name}.md（当前项目下）
- 缓存检查（已存在 + 时间戳 < 30 天 → 复用）

### Must NOT Have (Guardrails)
- ❌ 不支持 GitLab/Gitee（仅 GitHub）
- ❌ 不做工具间对比（单工具评估）
- ❌ 不评估非 AI 工具（npm 包、Python 库等）
- ❌ 不保留评估历史（覆盖式更新）
- ❌ 不修改被评估仓库的任何文件
- ❌ 不需要认证 GitHub API（用未认证公开 API，受 60/h rate limit）
- ❌ 不写自动化单元测试（用样本验证）
- ❌ 不做 Web UI / Dashboard
- ❌ 不做动态权重配置（固定在 SKILL.md 中）
- ❌ 不做社区评分整合（仅基于仓库本身）

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** - ALL verification is agent-executed.

### Test Decision
- **Infrastructure exists**: NO（纯 Markdown + Bash 项目）
- **Automated tests**: NO（用样本项目验证）
- **Framework**: none
- **验证方式**：样本项目运行 + 输出对照预期

### QA Policy
每个任务必须包含 agent-executed QA scenarios。
- **脚本类任务**：Bash 执行脚本 + 检查输出格式
- **文档类任务**：Read 检查内容 + grep 验证关键字段
- **集成类任务**：在新 session 中触发 skill + 验证报告生成
- **样本验证任务**：对照已知结论（Headroom 兼容性高、UA 兼容性极低）

### 样本验证成功标准

| 样本项目 | 期望分数区间 | 关键判定 |
|---------|------------|---------|
| **Headroom** | 兼容性 ≥ 85；安全 ≤ 70（侵入性争议）；总分 65-80 | 应为 🟡（Hold） |
| **Understand-Anything** | 兼容性 ≤ 40（Task 工具依赖）；总分 ≤ 55 | 应为 🔴（Skip） |
| **第3个样本**（待选） | 至少 1 个应为 🟢 | 验证 🟢 路径 |

**报告质量标准**：
- 每维度定性说明 100-200 字
- 总报告长度 1500-3000 字
- 包含至少 1 个"反直觉发现"（如 Headroom 压缩率 0%、UA 只产出 14% 结构图）
- 包含至少 1 个"替代方案"推荐

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Foundation - 6 tasks, MAX PARALLEL):
├── Task 1: 项目骨架（README/LICENSE/.gitignore/AGENTS.md）[quick]
├── Task 2: SKILL.md 主文件（含 6 维度评分标准）[deep]
├── Task 3: scripts/github-report.sh [quick]
├── Task 4: scripts/security-scan.sh [quick]
├── Task 5: templates/report-template.md [quick]
└── Task 6: docs/tool-evaluator/ 文档树（README + 3 篇）[deep]

Wave 2 (Integration - 1 task, after Wave 1):
└── Task 7: 软链接 + GitHub 远程仓库创建 [quick]

Wave 3 (Sample Validation - 3 tasks, parallel after Wave 2):
├── Task 8: 样本验证 - Headroom [unspecified-high]
├── Task 9: 样本验证 - Understand-Anything [unspecified-high]
└── Task 10: 样本验证 - 第3个项目 [unspecified-high]

Wave FINAL (4 parallel reviews, then user okay):
├── Task F1: Plan Compliance Audit [oracle]
├── Task F2: Code Quality Review [unspecified-high]
├── Task F3: Real Manual QA [unspecified-high]
└── Task F4: Scope Fidelity Check [deep]

Critical Path: T1 → T7 → T8-T10 → F1-F4
Parallel Speedup: ~60% faster than sequential
Max Concurrent: 6 (Wave 1)
```

### Dependency Matrix

| Task | Depends On | Blocks |
|------|-----------|--------|
| 1-6 | - | 7 |
| 7 | 1-6 | 8, 9, 10 |
| 8 | 2, 3, 4, 5, 7 | F1-F4 |
| 9 | 2, 3, 4, 5, 7 | F1-F4 |
| 10 | 2, 3, 4, 5, 7 | F1-F4 |
| F1-F4 | 1-10 | user okay |

### Agent Dispatch Summary

- **Wave 1 (6 tasks, parallel)**: T1, T3, T4, T5 → `quick`; T2, T6 → `deep`
- **Wave 2 (1 task, sequential)**: T7 → `quick`
- **Wave 3 (3 tasks, parallel)**: T8, T9, T10 → `unspecified-high`
- **Wave FINAL (4 tasks, parallel)**: F1 → `oracle`; F2, F3 → `unspecified-high`; F4 → `deep`

---

## TODOs

> **FORMAT**: Task labels use bare numbers: `1.`, `2.`, etc.
> Final Wave labels use `F1.`, `F2.`, etc.
> (Individual tasks inserted via Edit batches below — executor reads sequentially)

- [x] 1. 项目骨架（README/LICENSE/.gitignore/AGENTS.md）

  **What to do**:
  - 在 `~/projects/05-tool-evaluator/` 下创建以下文件：
    - `README.md`：项目标题（opencode-tool-evaluator）+ 简介 + 安装（软链接命令）+ 使用示例（3 个触发词示例）+ License
    - `LICENSE`：MIT License，版权 `2026 PointFish`
    - `.gitignore`：排除 `.DS_Store`、`*.swp`、`.omo/evidence/`（保留 .omo/evaluations/ 和 .omo/plans/）
    - `AGENTS.md`：项目说明，参考 `~/projects/02-opencode-memory-plugin/AGENTS.md` 结构，描述项目用途、目录结构、工作流。提及 SKILL.md 主文件、scripts/、docs/、templates/ 各目录作用
  - 所有 Markdown 文件必须使用 LF 换行、UTF-8、无 BOM

  **Must NOT do**:
  - 不要写实现细节（SKILL.md 的内容由 Task 2 写）
  - 不要创建 docs/ 或 scripts/ 下的文件（其他任务负责）
  - 不要 commit（commit 在 Task 7 统一）

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 全部是基础文件创建，无复杂逻辑，标准文档写作
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - `doc-coauthoring`: 文档结构已由 plan 定义，不需要协作式文档创作

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1（与 Tasks 2, 3, 4, 5, 6 并行）
  - **Blocks**: Tasks 7, 8, 9, 10
  - **Blocked By**: None（可立即开始）

  **References**:

  **Pattern References**:
  - `~/projects/02-opencode-memory-plugin/README.md` — 完整项目 README 模板（含 Overview/Installation/How It Works/Development/License 章节）
  - `~/projects/02-opencode-memory-plugin/AGENTS.md` — AGENTS.md 模板（含项目用途/目录结构/相关系统）
  - `~/projects/02-opencode-memory-plugin/LICENSE` — MIT License 模板
  - `~/projects/02-opencode-memory-plugin/.gitignore` — 极简 .gitignore 模板

  **External References**:
  - https://choosealicense.com/licenses/mit/ — MIT License 标准文本

  **WHY Each Reference Matters**:
  - README/AGENTS/LICENSE 都参考 02-opencode-memory-plugin 保持风格一致
  - AGENTS.md 是 OpenCode agent 入口，必须描述清楚"这个项目是什么/怎么用"

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: README 完整性
    Tool: Bash (read + grep)
    Preconditions: ~/projects/05-tool-evaluator/ 存在
    Steps:
      1. read ~/projects/05-tool-evaluator/README.md
      2. grep -c "安装\|Install" ~/projects/05-tool-evaluator/README.md → ≥ 1
      3. grep -c "使用\|Usage" ~/projects/05-tool-evaluator/README.md → ≥ 1
      4. grep -c "MIT" ~/projects/05-tool-evaluator/LICENSE → ≥ 1
    Expected Result: 4 个文件都存在，README 含安装/使用章节，LICENSE 含 MIT
    Failure Indicators: 文件缺失，或 README 缺少必备章节
    Evidence: .omo/evidence/task-1-readme-check.txt

  Scenario: AGENTS.md 符合 OpenCode 规范
    Tool: Bash (read + grep)
    Steps:
      1. read ~/projects/05-tool-evaluator/AGENTS.md
      2. grep -c "opencode\|OpenCode" ~/projects/05-tool-evaluator/AGENTS.md → ≥ 1
      3. grep -c "tool-evaluator\|SKILL.md" ~/projects/05-tool-evaluator/AGENTS.md → ≥ 1
    Expected Result: AGENTS.md 提及 OpenCode 和 tool-evaluator skill
    Evidence: .omo/evidence/task-1-agents-check.txt
  ```

  **Commit**: YES（groups with Task 7）
  - Message: `chore: bootstrap project structure`
  - Files: `README.md, LICENSE, .gitignore, AGENTS.md`

- [x] 2. SKILL.md 主文件（含 6 维度评分标准）

  **What to do**:
  - 创建 `~/projects/05-tool-evaluator/SKILL.md`（~300-500 行）
  - **frontmatter description**（决定触发率，必须覆盖所有触发词场景）：
    - 中文：分析、评估、装不装、值不值得、好不好用、怎么样
    - 英文：evaluate, install, should I install
    - 场景：用户提供 GitHub 链接 + 问可行性；用户问"X 好用吗"；用户问"该不该装 X"
  - **章节结构**：
    1. **触发条件**：详细列出所有触发场景（含隐含场景）
    2. **工作流**（5 步）：
       - Step 1: 解析输入（必须是 GitHub URL `https://github.com/{owner}/{repo}`）
       - Step 2: 缓存检查（如果 `.omo/evaluations/{name}.md` 存在且 mtime < 30 天，提示用户是否复用）
       - Step 3: 调用 scripts（并行运行 github-report.sh + security-scan.sh，输出 JSON）
       - Step 4: 6 维度评估（Prometheus 读取脚本输出 + 调研社区评价 + 给出每维度 0-100 分 + 100-200 字说明）
       - Step 5: 生成报告（按 templates/report-template.md 格式，写入 `.omo/evaluations/{repo-name}.md`，对话内输出 200 字摘要 + verdict）
    3. **6 维度评分标准**（每维度列出扣分项与加分项）：
       - **OpenCode 兼容性（15%）**：检查 Task 工具依赖、hooks 类型、MCP 协议、平台依赖。⚠️ 一票否决：< 50 分 → 强制 🔴
       - **安全/侵入性（25%）**：检查 settings.json 修改、LaunchAgent 安装、文件系统写入、网络外发、权限范围
       - **维护健康（25%）**：检查最后提交时间（>6月 扣分）、Issue 关闭率、贡献者数、反向依赖、CHANGELOG 活跃度
       - **功能价值（15%）**：解决问题、替代方案、README 声明 vs 实测数据
       - **文档与UX（10%）**：README 完整性、示例可运行、CHANGELOG、安装指南
       - **运营成本（10%）**：token 消耗、订阅费用、资源占用
    4. **Verdict 规则**：
       - 🟢 Install：加权总分 ≥ 80 且兼容性 ≥ 50
       - 🟡 Hold：加权总分 60-79 或兼容性 ≥ 50 但其他维度有红旗
       - 🔴 Skip：加权总分 < 60 或兼容性 < 50（一票否决）
    5. **错误处理**：
       - GitHub URL 格式错误 → 提示正确格式
       - gh CLI 未安装 → 提示安装
       - GitHub API rate limit → 提示等待 1 小时
       - 仓库不存在/私有 → 提示用户检查
       - 仓库非 AI 工具 → 提示"非目标范围"
    6. **输出模板引用**：`参见 templates/report-template.md`

  **Must NOT do**:
  - 不要在 SKILL.md 中写脚本逻辑（脚本的实现在 Task 3、4）
  - 不要硬编码样本项目信息（Headroom/UA 是验证用，不是 SKILL.md 的内容）
  - 不要包含多工具对比逻辑（明确 Must NOT Have）
  - 不要超过 500 行（保持 skill 简洁）

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: 这是项目核心交付物，需要深度思考评分标准的合理性，每个维度的扣分加分项需要参考 OpenSSF Scorecards / AgentRank 等框架
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - `skill-creator`: 用于创建 skill 的元 skill，但本项目结构已由 plan 定义，skill-creator 的迭代循环（draft→test→review→improve）会在 Final Wave 验证

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1（与 Tasks 1, 3, 4, 5, 6 并行）
  - **Blocks**: Tasks 8, 9, 10（样本验证需要 SKILL.md 的评分标准）
  - **Blocked By**: None（可立即开始）

  **References**:

  **Pattern References**:
  - `~/.claude/skills/skill-creator/SKILL.md` — Skill 文件格式参考（frontmatter description、章节结构、触发词设计）
  - `~/.claude/skills/hv-analysis/SKILL.md` — 长篇调研类 skill 的写法（本项目更简短）
  - `~/.claude/skills/research-ideation/SKILL.md` — 工作流式 skill 的写法

  **API/Type References**:
  - `.omo/drafts/skill-advisor.md` 节"6 维度评估框架"（已设计的权重与维度定义）
  - `.omo/drafts/skill-advisor.md` 节"调研发现：评估方法论"（20+ 框架的具体内容）

  **External References**:
  - OpenSSF Scorecards 文档：18 项检查的设计原理
  - AgentRank 五信号：新鲜度 25% + Issue 健康 25% + 反向依赖 25% + Stars 15% + 贡献者 10%

  **WHY Each Reference Matters**:
  - skill-creator 教会 SKILL.md 的 frontmatter description 设计（决定触发率）
  - 草稿已经完成 6 维度评分框架的设计，直接用
  - 调研结果中 OpenSSF/AgentRank 提供客观评分依据

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: SKILL.md 格式正确
    Tool: Bash (read + grep)
    Preconditions: Task 1 完成
    Steps:
      1. read ~/projects/05-tool-evaluator/SKILL.md 前 30 行
      2. grep "^---" SKILL.md | wc -l → ≥ 2（frontmatter 边界）
      3. grep -c "name:" SKILL.md（frontmatter 内）→ = 1
      4. grep -c "description:" SKILL.md → = 1
    Expected Result: frontmatter 存在，包含 name 和 description
    Evidence: .omo/evidence/task-2-skill-format.txt

  Scenario: 6 维度评分标准完整
    Tool: Bash (grep)
    Steps:
      1. grep -c "兼容性" SKILL.md → ≥ 3（章节标题 + 扣分项 + 一票否决说明）
      2. grep -c "安全" SKILL.md → ≥ 2
      3. grep -c "维护健康" SKILL.md → ≥ 2
      4. grep -c "功能价值" SKILL.md → ≥ 2
      5. grep -c "文档" SKILL.md → ≥ 2
      6. grep -c "运营成本" SKILL.md → ≥ 2
      7. grep -c "一票否决" SKILL.md → ≥ 1
      8. grep -c "Install\|Hold\|Skip" SKILL.md → ≥ 3
    Expected Result: 所有 6 维度都有章节，一票否决规则存在，verdict 规则存在
    Evidence: .omo/evidence/task-2-six-dimensions.txt

  Scenario: 触发词覆盖
    Tool: Bash (grep)
    Steps:
      1. grep -E "评估|分析|装不装|好用吗|怎么样" SKILL.md → 至少命中 3 个
      2. grep -E "evaluate|install" SKILL.md → 至少命中 1 个
    Expected Result: 中英文触发词都覆盖
    Evidence: .omo/evidence/task-2-triggers.txt
  ```

  **Commit**: YES（groups with Task 7）
  - Message: `feat(skill): add SKILL.md with 6-dimension framework`
  - Files: `SKILL.md`

- [x] 3. scripts/github-report.sh（GitHub 元数据抓取）

  **What to do**:
  - 创建 `~/projects/05-tool-evaluator/scripts/github-report.sh`
  - 输入：`$1` = `{owner}/{repo}`（如 `chopratejas/headroom`）
  - 输出：JSON 到 stdout，字段包括：
    - `stars`, `forks`, `watchers`
    - `open_issues`, `closed_issues_count`（如果 API 返回）
    - `license`（SPDX ID，如 MIT、Apache-2.0）
    - `language`（主语言）
    - `created_at`, `updated_at`, `pushed_at`
    - `default_branch`
    - `size_kb`
    - `description`
    - `topics`（数组）
    - `contributors_count`（需要单独 API 调用）
    - `last_commit_sha`, `last_commit_date`
    - `readme_excerpt`（前 500 字符）
  - 实现：
    - 用 `gh api repos/{owner}/{repo}` 获取基础信息
    - 用 `gh api repos/{owner}/{repo}/contributors | jq length` 获取贡献者数
    - 用 `gh api repos/{owner}/{repo}/commits?per_page=1` 获取最新 commit
    - 用 `gh api repos/{owner}/{repo}/readme | jq -r .content | base64 -D | head -c 500` 获取 README
    - 用 `jq` 合并所有字段为单一 JSON 输出
  - 错误处理：
    - 仓库不存在 → 输出 `{"error": "repo not found"}` 到 stderr，退出码 1
    - gh 未安装 → 提示安装，退出码 2
    - API rate limit → 提示等待，退出码 3
  - 在脚本顶部加 `set -euo pipefail`

  **Must NOT do**:
  - 不要调用需要认证的 GitHub API（用未认证公开 API，限制 60/h）
  - 不要扫描仓库内容（安全扫描在 Task 4）
  - 不要写评分逻辑（评分在 Prometheus 中执行）
  - 不要输出 Markdown（输出纯 JSON 供 SKILL.md 解析）

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 单一脚本，调用标准 gh CLI + jq，模式成熟
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1（与 Tasks 1, 2, 4, 5, 6 并行）
  - **Blocks**: Tasks 8, 9, 10（样本验证需要此脚本）
  - **Blocked By**: None

  **References**:

  **External References**:
  - `gh api repos/{owner}/{repo}` 官方文档：https://docs.github.com/en/rest/repos/repos
  - `jq` 手册：https://stedolan.github.io/jq/manual/

  **WHY Each Reference Matters**:
  - gh CLI 是 GitHub 官方工具，文档明确字段返回值
  - jq 用于合并多 API 调用的结果，必须语法正确

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: 正常仓库
    Tool: Bash
    Preconditions: gh CLI 已安装并认证
    Steps:
      1. bash ~/projects/05-tool-evaluator/scripts/github-report.sh chopratejas/headroom > /tmp/headroom.json
      2. jq .stars /tmp/headroom.json → 数字（≥ 0）
      3. jq .license /tmp/headroom.json → 非空字符串
      4. jq .last_commit_date /tmp/headroom.json → ISO 8601 日期
      5. jq .readme_excerpt /tmp/headroom.json → 字符串（可能为空）
    Expected Result: 所有字段都存在，格式正确
    Failure Indicators: 退出码非 0，或字段缺失
    Evidence: .omo/evidence/task-3-headroom.json（保存 stdout）

  Scenario: 不存在的仓库
    Tool: Bash
    Steps:
      1. bash ~/projects/05-tool-evaluator/scripts/github-report.sh nonexistent/fakerepo 2>/tmp/err.txt
      2. echo $? → 1
      3. grep "not found" /tmp/err.txt
    Expected Result: 退出码 1，stderr 含 "not found"
    Evidence: .omo/evidence/task-3-error.txt

  Scenario: 错误输入（非 owner/repo 格式）
    Tool: Bash
    Steps:
      1. bash ~/projects/05-tool-evaluator/scripts/github-report.sh "invalid-format" 2>/tmp/err.txt
      2. echo $? → 非 0
      3. grep "format\|invalid\|owner/repo" /tmp/err.txt → 命中
    Expected Result: 友好错误提示
    Evidence: .omo/evidence/task-3-format-error.txt
  ```

  **Commit**: YES（groups with Task 4）
  - Message: `feat(scripts): add github-report and security-scan`
  - Files: `scripts/github-report.sh`

- [x] 4. scripts/security-scan.sh（仓库安全/侵入性扫描）

  **What to do**:
  - 创建 `~/projects/05-tool-evaluator/scripts/security-scan.sh`
  - 输入：`$1` = `{owner}/{repo}`（如 `chopratejas/headroom`）
  - 输出：JSON 到 stdout，字段包括：
    - `hooks_count`（grep SKILL.md/settings.json/manifest 中的 hooks 注册）
    - `launchd_installed`（grep `launchd\|LaunchAgent\|LaunchDaemon`）
    - `modifies_settings_json`（README 或代码中提到修改用户配置）
    - `writes_user_files`（grep `~/.config`, `~/.claude`, `~/Library`）
    - `network_calls`（grep `http://`, `https://`, `fetch`, `requests`）
    - `elevated_privileges`（grep `sudo`, `chmod 777`, `chown`）
    - `prebuilt_binaries`（检查 releases 页面或 .dylib/.exe/.so 文件）
    - `permissions_requested`（数组：filesystem/network/notification 等）
    - `risk_level`（"low"/"medium"/"high"）
    - `risk_points`（数组：具体风险点描述）
  - 实现：
    - 用 `gh api repos/{owner}/{repo}/contents` 列出根目录文件
    - 用 `gh api repos/{owner}/{repo}/readme | base64 -D` 抓 README 文本
    - 用 grep 扫描上述风险信号
    - 如果仓库有 install.sh / setup.py / pyproject.toml，抓取内容扫描
    - 如果仓库有 hooks/ 或 .hooks/ 目录，扫描注册项
    - 综合判断 risk_level（命中 ≥3 个红旗 → high；1-2 → medium；0 → low）
  - 错误处理：
    - 仓库不存在 → 退出码 1
    - gh 未安装 → 退出码 2
    - 主分支读不到内容 → 输出 `risk_level: "unknown"`，不中断

  **Must NOT do**:
  - 不要执行任何远程脚本（仅扫描文本）
  - 不要 clone 仓库到本地（用 GitHub API 而非 git clone）
  - 不要写评分逻辑（仅提供原始数据 + 风险等级，评分由 Prometheus）
  - 不要做深度依赖扫描（npm audit / pip-audit 在 v2）

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 单一脚本，模式成熟（grep + gh api）
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1（与 Tasks 1, 2, 3, 5, 6 并行）
  - **Blocks**: Tasks 8, 9, 10（样本验证需要此脚本）
  - **Blocked By**: None

  **References**:

  **External References**:
  - AntonioTimo/skillchecker 的 35 CRITICAL 规则（GitHub 搜索）
  - OpenSSF Scorecards 文档：安全实践的 9 项检查定义

  **WHY Each Reference Matters**:
  - skillchecker 是最严格的同类工具，参考其规则集以确保覆盖
  - OpenSSF 提供业界共识的安全实践定义

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: 正常仓库（低风险，如 mit LICENSE 的轻量 skill）
    Tool: Bash
    Preconditions: gh CLI 已安装
    Steps:
      1. bash ~/projects/05-tool-evaluator/scripts/security-scan.sh Lum1104/understand-anything > /tmp/ua-security.json
      2. jq .risk_level /tmp/ua-security.json → "low" | "medium" | "high"
      3. jq .hooks_count /tmp/ua-security.json → 数字
      4. jq '.risk_points | length' /tmp/ua-security.json → ≥ 0
    Expected Result: JSON 格式正确，risk_level 是枚举值
    Failure Indicators: 退出码非 0，或 risk_level 不是 low/medium/high
    Evidence: .omo/evidence/task-4-ua-security.json

  Scenario: 高风险仓库（带 hooks 或 launchd）
    Tool: Bash
    Steps:
      1. bash ~/projects/05-tool-evaluator/scripts/security-scan.sh chopratejas/headroom > /tmp/headroom-security.json
      2. jq .risk_level /tmp/headroom-security.json → "medium" | "high"（Headroom 修改 settings.json）
      3. jq .modifies_settings_json /tmp/headroom-security.json → true 或有相关风险点
    Expected Result: Headroom 的侵入性被检测出来
    Evidence: .omo/evidence/task-4-headroom-security.json

  Scenario: 不存在的仓库
    Tool: Bash
    Steps:
      1. bash ~/projects/05-tool-evaluator/scripts/security-scan.sh nonexistent/fakerepo 2>/tmp/err.txt
      2. echo $? → 1
    Expected Result: 退出码 1
    Evidence: .omo/evidence/task-4-error.txt
  ```

  **Commit**: YES（groups with Task 3）
  - Message: `feat(scripts): add github-report and security-scan`
  - Files: `scripts/security-scan.sh`

- [x] 5. templates/report-template.md（评估报告输出模板）

  **What to do**:
  - 创建 `~/projects/05-tool-evaluator/templates/report-template.md`
  - 报告结构（~200 行，参考 Headroom/UA 报告样式）：
    1. **Frontmatter**：`name`、`github`、`evaluated_at`、`verdict` (🟢/🟡/🔴)、`total_score`
    2. **TL;DR**（200 字摘要，对话内回显用）
    3. **Score Table**（6 维度表格 + 权重 + 得分 + 一句话总结）
    4. **详细评估**（每维度 100-200 字说明 + 引用证据）
       - 兼容性（含一票否决提示）
       - 安全/侵入性（列出风险点）
       - 维护健康（GitHub 数据）
       - 功能价值（解决什么 + 实测数据）
       - 文档与UX
       - 运营成本
    5. **GitHub Stats**（脚本输出原始数据，便于查阅）
    6. **替代方案**（2-3 个竞品，1 行简介）
    7. **Verdict 理由**（为何 🟢/🟡/🔴）
    8. **附：评估方法**（链接到 docs/01-evaluation-framework.md）
  - 使用占位符（`{{repo_name}}`, `{{stars}}` 等）方便脚本/Prometheus 替换

  **Must NOT do**:
  - 不要硬编码任何项目信息（Headroom/UA 信息在样本报告里，不在模板里）
  - 不要超过 200 行（保持简洁）
  - 不要把评分逻辑写进模板（模板只管展示）

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 单一 Markdown 模板，参考 Headroom 报告格式即可
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1（与 Tasks 1, 2, 3, 4, 6 并行）
  - **Blocks**: Tasks 8, 9, 10（样本报告需要模板）
  - **Blocked By**: None

  **References**:

  **Pattern References**:
  - 用户在前次对话中产出的 Headroom 分析报告（实际就是 desired output）
  - 用户在前次对话中产出的 Understand-Anything 分析报告

  **WHY Each Reference Matters**:
  - 那两份报告就是用户期望的输出形态，模板要复刻这个感觉

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: 模板包含必要占位符
    Tool: Bash (grep)
    Steps:
      1. grep -c "{{repo_name}}" templates/report-template.md → ≥ 1
      2. grep -c "{{verdict}}" templates/report-template.md → ≥ 1
      3. grep -c "{{total_score}}" templates/report-template.md → ≥ 1
      4. grep -c "兼容性" templates/report-template.md → ≥ 1
      5. grep -c "安全" templates/report-template.md → ≥ 1
      6. grep -c "维护健康" templates/report-template.md → ≥ 1
      7. grep -c "功能价值" templates/report-template.md → ≥ 1
      8. grep -c "运营成本" templates/report-template.md → ≥ 1
      9. grep -c "替代方案" templates/report-template.md → ≥ 1
    Expected Result: 所有占位符和 6 维度章节都存在
    Evidence: .omo/evidence/task-5-template.txt

  Scenario: 模板长度合理
    Tool: Bash (wc)
    Steps:
      1. wc -l templates/report-template.md → 100-300 行
    Expected Result: 模板简洁，不超过 300 行
    Evidence: .omo/evidence/task-5-template-lines.txt
  ```

  **Commit**: YES（groups with Task 6）
  - Message: `feat(docs): add evaluation framework and usage guide`
  - Files: `templates/report-template.md`

- [x] 6. docs/tool-evaluator/ 文档树（参考 02-opencode-memory-plugin 结构）

  **What to do**:
  - 创建 4 个文档文件，组成完整的项目文档：
  - **docs/tool-evaluator/README.md**（~150 行）：
    - 项目介绍（What & Why）
    - 设计原则（6 维度框架的来源、权重选择的理由）
    - 安装与使用（参考 SKILL.md 触发词）
    - 文档导航（链接到 01/02/03）
  - **docs/tool-evaluator/01-evaluation-framework.md**（~400 行）：
    - 6 维度评分标准详解（每维度 50-70 行：定义/检查项/扣分加分/参考来源）
    - 评分公式（加权总分）
    - Verdict 规则（🟢/🟡/🔴 阈值）
    - 一票否决规则（兼容性 < 50 → 强制 🔴）
    - 6 维度权重选择的理由（参考 OpenSSF/AgentRank）
    - 与 9 个评估框架的对比表格（ChatForest/NimbleBrain/AgentRank/Rhumb/Skill Grader 等）
  - **docs/tool-evaluator/02-usage-guide.md**（~200 行）：
    - 触发词清单（中英文 + 疑问句 + 隐含场景）
    - 输入格式（GitHub URL 必填）
    - 工作流（5 步流程图，从 SKILL.md 提取）
    - 报告解读（如何阅读 6 维度评分）
    - 缓存策略（30 天后自动失效）
    - 常见错误处理（rate limit、私有仓库、非 AI 工具）
  - **docs/tool-evaluator/03-comparative-analysis.md**（~300 行）：
    - vs 现有的 13 个 GitHub 工具对比表（功能矩阵：维度/输入/输出/平台）
    - 与 7 个 awesome-list 的区别（"主动评估 vs 被动列表"）
    - 与 OpenSSF Scorecards 的区别（"AI 工具特化 vs 通用仓库健康"）
    - 与 hv-analysis 的区别（"决策报告 vs 理解报告"）
    - 与 skill-creator 的区别（"评估 vs 创建"）
    - 我们的独特价值（OpenCode 兼容性 + 一票否决 + 6 维度综合）

  **Must NOT do**:
  - 不要复制 02-opencode-memory-plugin 的内容（仅参考结构，不抄文本）
  - 不要写代码示例（这是文档，不是教程）
  - 不要在 03-comparative-analysis.md 中贬低其他工具（保持客观对比）

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: 需要消化草稿中 20+ 评估框架的研究结果，转化为可读的对比分析文档
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1（与 Tasks 1, 2, 3, 4, 5 并行）
  - **Blocks**: None
  - **Blocked By**: None（草稿已有所有材料）

  **References**:

  **Pattern References**:
  - `~/projects/02-opencode-memory-plugin/docs/opencode-memory-plugin/README.md` — 文档树导航格式
  - `~/projects/02-opencode-memory-plugin/docs/opencode-memory-plugin/01-architecture.md` — 架构文档的章节组织
  - `~/projects/02-opencode-memory-plugin/docs/opencode-memory-plugin/06-lessons-learned.md` — 对比分析文档的写法

  **API/Type References**:
  - `.omo/drafts/skill-advisor.md` 节"GitHub 生态全景"（13 个工具的对比材料）
  - `.omo/drafts/skill-advisor.md` 节"评估方法论"（20+ 框架的来源）

  **WHY Each Reference Matters**:
  - 02-opencode-memory-plugin 的文档树是用户明确指定的参考结构
  - 草稿里已积累全部对比内容，01-evaluation-framework 和 03-comparative-analysis 直接复用

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: 4 文件齐全
    Tool: Bash
    Steps:
      1. ls ~/projects/05-tool-evaluator/docs/tool-evaluator/
      2. 确认存在：README.md, 01-evaluation-framework.md, 02-usage-guide.md, 03-comparative-analysis.md
    Expected Result: 4 个文件都在
    Evidence: .omo/evidence/task-6-docs-list.txt

  Scenario: 01-evaluation-framework.md 内容完整
    Tool: Bash (grep)
    Steps:
      1. grep -c "兼容性" 01-evaluation-framework.md → ≥ 3
      2. grep -c "安全" 01-evaluation-framework.md → ≥ 3
      3. grep -c "维护健康" 01-evaluation-framework.md → ≥ 3
      4. grep -c "功能价值" 01-evaluation-framework.md → ≥ 3
      5. grep -c "文档" 01-evaluation-framework.md → ≥ 3
      6. grep -c "运营成本" 01-evaluation-framework.md → ≥ 3
      7. grep -c "一票否决" 01-evaluation-framework.md → ≥ 1
      8. grep -E "🟢|🟡|🔴" 01-evaluation-framework.md → ≥ 3
    Expected Result: 6 维度 + verdict + 一票否决完整
    Evidence: .omo/evidence/task-6-framework.txt

  Scenario: 03-comparative-analysis.md 有对比表
    Tool: Bash (grep)
    Steps:
      1. grep -c "Skills_Curator\|skillchecker\|repo-insight" 03-comparative-analysis.md → ≥ 3
      2. grep -c "OpenSSF\|hv-analysis\|skill-creator" 03-comparative-analysis.md → ≥ 3
      3. grep -c "|" 03-comparative-analysis.md → ≥ 10（markdown 表格行）
    Expected Result: 与 13 个工具 + OpenSSF + 4 个相关 skill 都有对比
    Evidence: .omo/evidence/task-6-comparative.txt
  ```

  **Commit**: YES（groups with Task 5）
  - Message: `feat(docs): add evaluation framework and usage guide`
  - Files: `docs/tool-evaluator/*.md`

- [ ] 7. 软链接 + GitHub 远程仓库创建 + 首次推送

  **What to do**:
  - 创建软链接：`ln -s ~/projects/05-tool-evaluator ~/.claude/skills/tool-evaluator`
  - 验证软链接：`ls -la ~/.claude/skills/tool-evaluator` → 应指向源目录
  - 创建 GitHub 仓库：`gh repo create pointfish/opencode-tool-evaluator --public --source=. --remote=origin --description "OpenCode skill: evaluate AI dev tools (Skill/MCP/CLI) across 6 weighted dimensions with Install/Hold/Skip verdicts"`
  - 验证仓库创建：`gh repo view pointfish/opencode-tool-evaluator`
  - 首次推送：`git add -A && git commit -m "feat: initial release of tool-evaluator" && git push -u origin main`
  - 验证推送：`gh api repos/pointfish/opencode-tool-evaluator | jq .html_url`
  - 在 README.md 添加 GitHub 仓库链接（如果 Task 1 还未加）

  **Must NOT do**:
  - 不要 force push（这是首次推送，正常 push 即可）
  - 不要在 push 前测试触发 skill（skill 触发在 Wave 2 验证）
  - 不要修改 ~/.claude/skills/ 下其他 skill 的软链接

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 4 步命令行操作
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2（在 Wave 1 全部 commit 后执行）
  - **Blocks**: Tasks 8, 9, 10（样本验证依赖 skill 已安装）
  - **Blocked By**: Tasks 1, 2, 3, 4, 5, 6（全部交付物完成后才能 push）

  **References**:

  **External References**:
  - `gh repo create` 文档：https://cli.github.com/manual/gh_repo_create
  - OpenCode skills 软链接约定：参考 ~/.claude/skills/ 下其他软链接

  **WHY Each Reference Matters**:
  - gh CLI 创建仓库的标准方式
  - 软链接确保 OpenCode 能发现 skill

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: 软链接创建
    Tool: Bash
    Steps:
      1. ls -la ~/.claude/skills/tool-evaluator
      2. readlink ~/.claude/skills/tool-evaluator → 应是 ~/projects/05-tool-evaluator 或绝对路径
      3. ls ~/.claude/skills/tool-evaluator/SKILL.md → 文件存在
    Expected Result: 软链接正确指向源目录，SKILL.md 可读
    Failure Indicators: 软链接断开，或 SKILL.md 不存在
    Evidence: .omo/evidence/task-7-symlink.txt

  Scenario: GitHub 仓库存在
    Tool: Bash (gh)
    Steps:
      1. gh repo view pointfish/opencode-tool-evaluator
      2. gh api repos/pointfish/opencode-tool-evaluator | jq .private → false
      3. gh api repos/pointfish/opencode-tool-evaluator | jq .license.spdx_id → MIT
    Expected Result: 仓库 public、MIT 许可
    Evidence: .omo/evidence/task-7-github-repo.txt

  Scenario: 首次推送成功
    Tool: Bash
    Steps:
      1. git -C ~/projects/05-tool-evaluator log --oneline → ≥ 1 commit
      2. git -C ~/projects/05-tool-evaluator remote -v → origin 指向 GitHub
      3. gh api repos/pointfish/opencode-tool-evaluator/commits | jq length → ≥ 1
    Expected Result: 本地有 commit，远程仓库已同步
    Evidence: .omo/evidence/task-7-push.txt
  ```

  **Commit**: YES（项目首次提交）
  - Message: `feat: initial release of tool-evaluator`
  - Files: all files
  - Pre-commit: 确认 Tasks 1-6 全部完成

- [ ] 8. 样本验证 1: Headroom（chopratejas/headroom）

  **What to do**:
  - 在新 OpenCode session 中（确保 skill 已通过软链接发现），触发评估：
    - 输入："评估 chopratejas/headroom 这个工具能不能装"
  - 验证输出包含：
    - 对话内 200 字摘要 + 🟡 verdict（暂缓）
    - 文件 `.omo/evaluations/headroom.md` 被创建，按 templates 格式
  - 期望分数区间（参考前次分析）：
    - OpenCode 兼容性：60-80（MCP 协议可用但库模式有安全闸门问题）
    - 安全/侵入性：50-70（修改 settings.json 是已知风险点）
    - 维护健康：70-90（活跃维护）
    - 功能价值：50-70（实测压缩率与宣传有差距）
    - 文档与UX：70-85
    - 运营成本：60-80（本地运行，无订阅）
    - 总分：60-75 → 🟡 Hold
  - 对照前次 Prometheus 实操分析的结果，验证是否覆盖相同洞察（hooks 侵入性、库模式 0% 压缩率、MCP 默认配置问题）

  **Must NOT do**:
  - 不要"修复"任何发现的问题（这是评估，不是修复）
  - 不要修改 Headroom 仓库（只读评估）
  - 不要把分析写成 marketing copy（保持客观，列出风险）

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 样本验证需要严格执行 SKILL.md 流程，验证评分逻辑是否合理
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3（与 Tasks 9, 10 并行）
  - **Blocks**: Final Verification Wave
  - **Blocked By**: Tasks 1-7（skill + 脚本 + 模板 + 软链接全部就绪）

  **References**:

  **Pattern References**:
  - 前次会话中对 Headroom 的分析（参见 Compressed conversation section b1 的结论）

  **WHY Each Reference Matters**:
  - 前次分析就是 ground truth，本次评估应能复现相同洞察

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: Headroom 评估报告生成
    Tool: Bash
    Preconditions: Skill 已软链接，OpenCode 新 session 已加载
    Steps:
      1. ls ~/projects/05-tool-evaluator/.omo/evaluations/headroom.md → 文件存在
      2. wc -l headroom.md → ≥ 100 行
      3. grep -E "🟢|🟡|🔴" headroom.md → ≥ 1（含 verdict）
      4. grep -c "兼容性" headroom.md → ≥ 2
      5. grep -c "安全" headroom.md → ≥ 2
      6. grep -c "settings.json\|LaunchAgent" headroom.md → ≥ 1（侵入性被发现）
    Expected Result: 报告齐全，识别了 Headroom 的侵入性
    Evidence: .omo/evidence/task-8-headroom-report.txt

  Scenario: Headroom 分数在期望区间
    Tool: Bash (grep + 比较)
    Steps:
      1. 提取 total_score（frontmatter 或 TL;DR）
      2. 验证 60 ≤ total_score ≤ 75
      3. 验证 verdict = "🟡" Hold
    Expected Result: 分数合理，与前次分析一致
    Evidence: .omo/evidence/task-8-headroom-score.txt
  ```

  **Commit**: YES（groups with Tasks 9, 10）
  - Message: `feat(evaluations): add Headroom, UA, {3rd} sample reports`
  - Files: `.omo/evaluations/headroom.md`

- [ ] 9. 样本验证 2: Understand-Anything（Lum1104/understand-anything）

  **What to do**:
  - 在新 OpenCode session 中触发评估："评估 Lum1104/understand-anything"
  - 验证输出：
    - 对话内摘要 + 🔴 verdict（不推荐，因 OpenCode 缺 Task 工具）
    - 文件 `.omo/evaluations/understand-anything.md` 被创建
  - 期望分数区间（参考前次分析）：
    - OpenCode 兼容性：30-50（依赖 Claude Code 的 Task 工具，OpenCode 没有）
    - 安全/侵入性：70-90（本身不侵入）
    - 维护健康：80-95（53.7K stars，活跃）
    - 功能价值：60-80（功能强但不兼容 OpenCode）
    - 文档与UX：75-90
    - 运营成本：30-60（200K token/次，$2-50）
    - 总分：55-70 → 🟡 Hold 或 🔴 Skip（如果兼容性 < 50 触发一票否决）
  - 验证一票否决规则：兼容性 < 50 → 强制 🔴
  - 对照前次 Prometheus 实操分析（Task 工具缺失、200K token/次、14% 结构图谱）

  **Must NOT do**:
  - 不要因为 stars 多就给高分（兼容性是关键）
  - 不要推荐用户装（前次结论已确认不兼容 OpenCode）

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 验证一票否决规则是否触发
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3（与 Tasks 8, 10 并行）
  - **Blocks**: Final Verification Wave
  - **Blocked By**: Tasks 1-7

  **References**:

  **Pattern References**:
  - 前次会话中对 Understand-Anything 的分析（参见 Compressed conversation section b1 的结论）

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: UA 评估报告生成
    Tool: Bash
    Steps:
      1. ls ~/projects/05-tool-evaluator/.omo/evaluations/understand-anything.md
      2. grep -E "🟢|🟡|🔴" understand-anything.md → ≥ 1
      3. grep -c "Task 工具\|Task tool" understand-anything.md → ≥ 1（兼容性问题被识别）
      4. grep -c "200K\|token" understand-anything.md → ≥ 1（成本被发现）
    Expected Result: 报告识别 Task 工具依赖 + token 消耗
    Evidence: .omo/evidence/task-9-ua-report.txt

  Scenario: UA 一票否决触发
    Tool: Bash
    Steps:
      1. 提取兼容性分数
      2. 如分数 < 50，验证 verdict = "🔴"
      3. 如分数 ≥ 50，verdict 可能是 🟡，但也合理（因 token 成本）
    Expected Result: 一票否决规则正确触发
    Evidence: .omo/evidence/task-9-ua-veto.txt
  ```

  **Commit**: YES（groups with Tasks 8, 10）
  - Message: `feat(evaluations): add Headroom, UA, {3rd} sample reports`
  - Files: `.omo/evaluations/understand-anything.md`

- [ ] 10. 样本验证 3: 第三个项目（用户选择或自动选择高 stars 项目）

  **What to do**:
  - 选择第 3 个验证项目（建议从 GitHub Trending 或 awesome-claude-skills 中挑一个高 stars 的 MCP Server，如 `anthropics/claude-code-skills` 或 `modelcontextprotocol/servers` 下的某个）
  - 如果用户未指定，自动选 `anthropics/claude-code-skills`（官方仓库，作为基准）
  - 触发评估，验证：
    - 对话内摘要 + verdict
    - 报告文件生成
    - 分数合理（官方仓库应该高评分：兼容性 90+、维护 90+）
  - 这第 3 个样本的作用：验证 skill 在"正常推荐安装"的场景下能给出 🟢 verdict

  **Must NOT do**:
  - 不要刻意挑低质量项目（这是验证 🟢 路径）
  - 不要预设 verdict（让评估自然进行）

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 验证 🟢 路径
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3（与 Tasks 8, 9 并行）
  - **Blocks**: Final Verification Wave
  - **Blocked By**: Tasks 1-7

  **References**:

  **External References**:
  - GitHub Trending: https://github.com/trending
  - anthropics/claude-code-skills（候选）

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY)**:

  ```
  Scenario: 第 3 样本报告生成
    Tool: Bash
    Steps:
      1. ls ~/projects/05-tool-evaluator/.omo/evaluations/ → 至少 3 个 .md 文件
      2. 验证新报告包含 6 维度
    Expected Result: 报告齐全
    Evidence: .omo/evidence/task-10-third-report.txt

  Scenario: 3 样本覆盖 3 种 verdict
    Tool: Bash (grep)
    Steps:
      1. 在 3 个报告文件中 grep verdict
      2. 验证至少出现 2 种 verdict（Headroom=🟡, UA=🔴/🟡, 第3=🟢）
    Expected Result: 3 种 verdict 都被覆盖（或至少 2 种）
    Evidence: .omo/evidence/task-10-verdicts.txt
  ```

  **Commit**: YES（groups with Tasks 8, 9）
  - Message: `feat(evaluations): add Headroom, UA, {3rd} sample reports`
  - Files: `.omo/evaluations/{third}.md`

---

## Final Verification Wave

> 4 review agents run in PARALLEL. ALL must APPROVE. Present consolidated results to user and get explicit "okay" before completing.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, run command). For each "Must NOT Have": search codebase for forbidden patterns. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `shellcheck` on all scripts. Review SKILL.md / docs for grammar, formatting, completeness. Check .omo/evaluations/ reports for quality.
  Output: `Shellcheck [PASS/FAIL] | Docs [N/N] | Reports [N/N] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high`
  Start from clean state. Execute EVERY QA scenario from EVERY task. Test cross-task integration (skill triggers, generates report). Save to `.omo/evidence/final-qa/`.
  Output: `Scenarios [N/N pass] | Integration [N/N] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff. Verify 1:1 — everything in spec was built, nothing beyond spec was built. Check "Must NOT do" compliance.
  Output: `Tasks [N/N compliant] | VERDICT`

---

## Commit Strategy

| Commit | Message | Files | Pre-commit |
|--------|---------|-------|-----------|
| C1 | `chore: bootstrap project structure` | README.md, LICENSE, .gitignore, AGENTS.md | - |
| C2 | `feat(skill): add SKILL.md with 6-dimension framework` | SKILL.md | - |
| C3 | `feat(scripts): add github-report and security-scan` | scripts/*.sh | shellcheck |
| C4 | `feat(docs): add evaluation framework and usage guide` | docs/**/*.md, templates/*.md | - |
| C5 | `chore: add symlink + push to GitHub` | (no commit, just symlink) | - |
| C6 | `feat(evaluations): add Headroom, UA, {3rd} sample reports` | .omo/evaluations/*.md | - |

---

## Success Criteria

### Verification Commands
```bash
# 1. Skill 可发现
ls -la ~/.claude/skills/tool-evaluator
# Expected: symlink to ~/projects/05-tool-evaluator/

# 2. 脚本可执行
bash ~/projects/05-tool-evaluator/scripts/github-report.sh chopratejas/headroom
# Expected: JSON output with stars/issues/license fields

bash ~/projects/05-tool-evaluator/scripts/security-scan.sh chopratejas/headroom
# Expected: list of risk points

# 3. 样本报告存在
ls ~/projects/05-tool-evaluator/.omo/evaluations/
# Expected: headroom.md, understand-anything.md, {3rd}.md

# 4. GitHub 仓库存在
gh repo view pointfish/opencode-tool-evaluator
# Expected: repo info
```

### Final Checklist
- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent
- [ ] 3 个样本报告都符合期望分数区间
- [ ] SKILL.md 在新 session 中可被触发
- [ ] GitHub 仓库推送成功
- [ ] 文档完整（README + 3 篇 docs）
