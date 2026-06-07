# 竞品对比分析

## 概述

本文件将 Tool Evaluator 与 GitHub 生态中的 13 个相关工具、7 个 awesome-lists、以及 3 个相关 OpenCode skill 进行系统对比，明确我们的定位和独特价值。

所有对比数据来源于 `.omo/drafts/skill-advisor.md` 中的调研结果（13 个最相关工具 + 20+ 评估框架）。

---

## GitHub 工具生态全景

### 13 个相关工具对比

| # | 工具 | 评估类型 | 维度数 | 安装决策 | 平台针对性 | 开源 |
|---|------|---------|--------|---------|-----------|------|
| **0** | **Tool Evaluator (本项目)** | **安装前综合评估** | **6 加权** | **✅ 🟢🟡🔴** | **✅ OpenCode** | **✅** |
| 1 | bjulius/skill-evaluator | Skill 质量评估 | 6 (1-5分) | ❌ | ❌ 通用 | ✅ |
| 2 | captkernel/Skills_Curator | 安装前/后检查 | 技能质量 + `--check` | 部分 | Claude Code | ✅ |
| 3 | AntonioTimo/skillchecker | 安全审计 | 35 CRITICAL 规则 | ❌ | Claude Code | ✅ |
| 4 | AliceLJY/repo-insight | 架构分析 | 深度分析 | ❌ | 通用 | ✅ |
| 5 | esaruoho/github-cloner | 仓库分析→生成 skill | — | ❌ | 通用 | ✅ |
| 6 | notque/claude-code-toolkit | 6 阶段管线 | 仓库采纳价值 | 部分 | Claude Code | ✅ |
| 7 | avalonreset/legends-github | 健康度评分 | 6 维度 (0-100) | ❌ | 通用 | ✅ |
| 8 | MJWNA/github-repo-discovery | 评分 + AI-slop 惩罚 | 16 信号 | ❌ | 通用 | ✅ |
| 9 | runesleo/claude-skill-audit | 健康检查 | 死技能检测 | ❌ | Claude Code | ✅ |
| 10 | mmantasrrr/skill-seeker | 发现 + 安全 | 元技能 | ❌ | 通用 | ✅ |
| 11 | hnaymyh123-henry/skills-compat-manager | 跨平台兼容层 | 单维度 | ❌ | 通用（早期） | ✅ |
| 12 | scottholdren/skill-audit | 冲突/重叠/冗余检测 | — | ❌ | Claude Code | ✅ |
| 13 | FlorianBruniaux/eval-skills | 14 分评分 | 6 维度 | ❌ | 通用 | ✅ |

### 核心缺口

**GitHub 生态中没有任何工具做"安装前的综合评估"**。现有工具分布在以下单维度：

| 维度 | 现有工具 | 缺失 |
|------|---------|------|
| 仓库健康度 | legends-github, repo-insight, github-cloner | 不判断适用性 |
| 代码/架构分析 | repo-insight, repo-value-analysis | "Why > What"，不做安装建议 |
| 已装技能审计 | skill-audit, claude-skill-audit, Skills_Curator | **装了之后才评估** |
| 安全扫描 | skillchecker, skill-seeker | 单维度，不做质量评估 |
| 跨平台兼容性 | skills-compat-manager | 单维度，很早期 |
| **安装前综合评估** | **❌ 完全空白** | **这是我们的机会** |

### 工具分类详解

**质量评估类**（3 个）：
- **bjulius/skill-evaluator** — 6 维度 1-5 分制，聚焦 Skill 质量但不做仓库评估，不输出安装建议
- **FlorianBruniaux/eval-skills** — 14 分制（6 维度），通用 skill 评估，无平台针对性
- **AliceLJY/repo-insight** — 架构深度分析最强，但输出是"理解"而非"决策"

**安全审计类**（2 个）：
- **AntonioTimo/skillchecker** — 35 条 CRITICAL 规则，偏执级安全扫描，但完全不看质量/价值
- **mmantasrrr/skill-seeker** — 发现 + 安全双功能，元技能（评估其他技能），但覆盖面窄

**仓库健康类**（2 个）：
- **avalonreset/legends-github** — 0-100 评分，6 维度（与我们最接近的评分体系），但不针对 AI 工具
- **MJWNA/github-repo-discovery** — 16 信号评分 + AI-slop 惩罚机制（创新点），但仅做发现不做决策

**已装工具审计类**（3 个）：
- **captkernel/Skills_Curator** — 最接近本项目，含安装前 `--check`，但不做仓库本身分析
- **runesleo/claude-skill-audit** — 健康检查 + 死技能检测，安装后审计
- **scottholdren/skill-audit** — 冲突/重叠/冗余检测，安装后审计

**其他类**（3 个）：
- **esaruoho/github-cloner** — 分析仓库后生成自定义 skill，不同方向
- **notque/claude-code-toolkit** — 6 阶段管线，含仓库采纳价值判断，最接近但范围过广
- **hnaymyh123-henry/skills-compat-manager** — 跨平台兼容层，很早期

---

## Awesome Lists vs 活跃评估

GitHub 上有 **7 个 awesome-lists** 收集 AI 开发工具：

| List | Stars | 特点 |
|------|-------|------|
| ComposioHQ/awesome-mcp-servers | 39.2k | 最大 MCP 服务器目录 |
| Chat2AnyLLM/AI_Intelligence_Learning | 10k+ | 综合 AI 学习资源 |
| alirezarezvani/awesome-opencode | 16k | OpenCode 相关工具 |
| VoltAgent/awesome-dclm-cli-tools | — | CLI 工具集 |
| hesreallyhim/awesome-claude-code | — | Claude Code 工具 |
| borghei/awesome-tool | — | 综合工具 |
| Chat2AnyLLM/AI_Intelligence | 10k+ | AI 智能工具 |

### 关键区别

| 特性 | Awesome Lists | Tool Evaluator |
|------|--------------|----------------|
| 形态 | 被动目录 | 活跃评估器 |
| 评估 | 无（仅收录） | 6 维度量化评分 |
| 决策 | 用户自行判断 | 🟢🟡🔴 verdict |
| 更新 | 人工维护 | 按需评估 + 30 天缓存 |
| 质量 | 参差不齐 | 统一标准 |
| 用途 | 发现工具 | 决定是否安装 |

**互补关系**：用户在 awesome-list 中发现工具 → 用 Tool Evaluator 决定是否安装。

### Awesome Lists 的局限性

- **无质量过滤**：收录标准宽松，star 数和工具质量不成正比
- **无安全检查**：不会识别含有恶意代码的工具
- **无兼容性信息**：不告诉你工具能不能在你的平台运行
- **维护滞后**：人工维护，已废弃工具可能仍留在列表中
- **重复严重**：同一工具可能出现在多个 list 中，增加筛选负担

---

## OpenSSF Scorecards 对比

OpenSSF Scorecards 是开源安全基金会的仓库安全评分系统，是本领域最权威的框架。

### 检查项对比

| OpenSSF Scorecards（18 项） | 我们的对应维度 |
|-----------------------------|--------------|
| **整体安全实践**（9 项） | |
| 漏洞扫描 | 安全 / 侵入性 |
| 依赖更新 | 安全 / 侵入性 |
| 维护活跃度 | 维护健康 |
| 安全策略 | 安全 / 侵入性 |
| 许可证 | 安全 / 侵入性 |
| CI 测试 | 维护健康 |
| 模糊测试 | 安全 / 侵入性 |
| SAST 静态分析 | 安全 / 侵入性 |
| 代码审查 | 维护健康 |
| **源码风险**（5 项） | |
| 二进制文件 | 安全 / 侵入性 |
| 分支保护 | 安全 / 侵入性 |
| 危险工作流 | 安全 / 侵入性 |
| 代码审查策略 | 维护健康 |
| 贡献者多样性 | 维护健康 |
| **构建风险**（4 项） | |
| 固定依赖 | 安全 / 侵入性 |
| Token 权限 | 安全 / 侵入性 |
| 打包 | 安全 / 侵入性 |
| 签名发布 | 安全 / 侵入性 |

### 关键差异

| 维度 | OpenSSF Scorecards | Tool Evaluator |
|------|-------------------|----------------|
| **定位** | 通用开源项目安全 | AI 开发工具安装前评估 |
| **检查数** | 18 项 | 6 维度 |
| **AI 特化** | ❌ | ✅（兼容性、token 成本） |
| **安装决策** | ❌ | ✅（🟢🟡🔴） |
| **平台针对** | ❌ | ✅（OpenCode / Claude Code / Cursor） |
| **缓存** | 每日扫描 | 30 天按需评估 |
| **权重透明** | ✅ 公开 | ✅ 公开（15/25/25/15/10/10） |
| **自动化** | GitHub Action | OpenCode skill（半自动） |

### OpenSSF Scorecards 的优势

- **覆盖广**：18 项检查覆盖安全、源码、构建三大类
- **权威性**：开源安全基金会背书，行业参考标准
- **自动化**：GitHub Action 集成，无需手动触发
- **数据驱动**：每项检查都有明确的通过/失败标准

### 我们的补充

- **AI 工具特化**：OpenSSF 不检查 MCP 协议合规、Skill hook 类型、token 消耗——这些是 AI 工具特有的风险
- **安装决策**：OpenSSF 给出原始分数，用户需自行判断；我们直接输出 🟢🟡🔴
- **平台针对**：OpenSSF 是平台无关的，我们专门检查 OpenCode 兼容性

**互补关系**：OpenSSF 关注通用安全实践 → 我们在其基础上增加 AI 工具特有的兼容性、成本、文档质量维度，并产出安装决策。

---

## 相关 Skill 对比

### hv-analysis vs tool-evaluator

| 特性 | hv-analysis（横纵分析法） | Tool Evaluator |
|------|------------------------|----------------|
| **核心目标** | **理解** 一个东西 | **决策** 一个东西 |
| **产出形式** | 长篇 PDF 研究报告 | 结构化 verdict + 评分 |
| **典型时长** | 数小时 | 数分钟 |
| **输出导向** | 深度洞察、叙事故事 | 安装 / 观望 / 拒绝 |
| **类比** | New Yorker 长篇报道 | Consumer Reports 评级 |
| **维度** | 纵轴（历史）+ 横轴（竞品） | 6 维度量化 |
| **适用场景** | 想全面了解一个产品/公司 | 想快速决定是否安装 |

**边界**：需要"理解"用 hv-analysis；需要"决策"用 tool-evaluator。

### skill-creator vs tool-evaluator

| 特性 | skill-creator | Tool Evaluator |
|------|-------------|----------------|
| **核心目标** | **创建** 新 skill | **评估** 已有工具 |
| **方向** | 生产 | 消费 |
| **输入** | 需求描述 | GitHub URL |
| **输出** | SKILL.md + 脚本 | 评估报告 + verdict |
| **关系** | 互补（无重叠） | 互补（无重叠） |

**协同**：skill-creator 创建 → tool-evaluator 评估是否值得装。

### legends-github vs tool-evaluator

| 特性 | legends-github | Tool Evaluator |
|------|---------------|----------------|
| **定位** | 通用仓库健康度评分 | AI 工具安装前评估 |
| **维度数** | 6（与我们相同） | 6 |
| **评分范围** | 0-100 | 0-100 |
| **AI 特化** | ❌ | ✅ |
| **安全检查** | 部分 | 深度（7 项扫描清单） |
| **安装决策** | ❌ | ✅ |

**定位差异**：legends-github 适合评估任何 GitHub 仓库的健康度；我们专精 AI 工具（Skill / MCP / CLI），覆盖兼容性、token 成本等特有维度。

### research-ideation vs tool-evaluator

| 特性 | research-ideation | Tool Evaluator |
|------|-----------------|----------------|
| **领域** | 学术研究启动 | AI 工具评估 |
| **产出** | 研究计划、文献综述 | 评分 + verdict |
| **重叠** | 无 | 无 |

---

## 我们的独特价值

### 1. OpenCode 专属兼容性检查

唯一一个针对 OpenCode 生态做兼容性检查的评估器。检查 Task 工具依赖、hook 类型、MCP 协议、平台二进制、shell 假设等 OpenCode 特有问题。

### 2. 一票否决机制

兼容性维度得分 <50 时强制 🔴 Skip，无论加权总分多高。避免"其他维度极高分补偿兼容性低分"的误判。这是所有评估框架中唯一的硬性门控设计。

### 3. 6 维度综合评分

覆盖从"能不能用"（兼容性）到"值不值得用"（功能 / 文档 / 成本）的完整决策链，而非聚焦单一维度（如 skillchecker 只看安全、legends-github 只看健康度）。

### 4. 30 天缓存

评估结果缓存到 `.omo/evaluations/`，30 天内复用，避免重复评估。其他工具大多每次重新运行。

### 5. 可操作的 Verdict

直接输出 🟢 / 🟡 / 🔴 + 决定性理由，而非让用户自行解读数字分数。大多数现有工具只给分数不给建议。

### 6. AI 工具特化维度

包含 AI 生态特有的检查项：token 消耗、MCP 协议合规、Skill hook 类型——这些在通用评估框架（OpenSSF、legends-github）中完全缺失。

### 7. 消费者报告式输出

输出风格参考 Consumer Reports：量化评分 + 简明 verdict + 决定性理由。而非学术论文式的深度分析（那是 hv-analysis 的定位）。用户需要的是"5 分钟决策"，不是"30 分钟理解"。

### 8. 权重公开可调

6 维度权重（15/25/25/15/10/10）完全公开，用户可根据自身偏好调整。大多数现有框架要么不公开权重（黑箱），要么不支持自定义。

---

## 按使用场景选择工具

| 场景 | 推荐工具 | 理由 |
|------|---------|------|
| 想知道是否安装某个 AI 工具 | **Tool Evaluator** | 唯一做安装前综合评估的 |
| 想深度了解一个产品/公司 | hv-analysis | 横纵分析法，深度洞察 |
| 想创建新的 skill | skill-creator | 专业创建工具 |
| 想审计已安装的 skill | skill-audit / Skills_Curator | 安装后审计 |
| 想检查 skill 安全性 | skillchecker | 35 条 CRITICAL 规则 |
| 想评估通用仓库健康度 | legends-github | 6 维度 0-100 评分 |
| 想浏览可用工具 | awesome-lists（7 个） | 被动目录 |

---

## 总结

Tool Evaluator 填补了 GitHub AI 工具生态中的**安装前综合评估**空白。我们不是要替代任何现有工具——legends-github、skillchecker、Skills_Curator 各自在单维度上做得很好——而是提供一个更高层次的**决策框架**，将多维度信号综合为一个可操作的安装建议。

我们的差异化在于：**OpenCode 平台针对性 + 一票否决机制 + 综合评分 + 可操作 verdict**。

---

## 参考链接

- [README.md — 文档导航](./README.md)
- [01-evaluation-framework.md — 6 维度详解](./01-evaluation-framework.md)
- [02-usage-guide.md — 使用指南](./02-usage-guide.md)
- [调研草稿 — 13 工具 + 20 框架原始资料](../../.omo/drafts/skill-advisor.md)
