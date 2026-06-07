# Tool Evaluator 文档导航

## 项目定位

> **消费者报告式的 AI 开发工具评估器**：给定一个 GitHub 仓库链接，输出 6 维度量化评分（0-100）、加权总分和 🟢/🟡/🔴 安装决策建议，帮助你在 5 分钟内决定"装不装"。

支持的工具类型：**Skill / MCP Server / CLI**，覆盖 AI 开发工具链的核心形态。

---

## 问题与解决方案

### 问题

当前生态系统中**没有任何工具做"安装前的综合评估"**：

- **Awesome lists**（ComposioHQ 39.2k ⭐、VoltAgent、hesreallyhim 等 7 个）— 全部是被动目录，无分析能力
- **仓库健康度工具**（legends-github、repo-insight）— 只看仓库本身，不判断适用性
- **安全扫描工具**（skillchecker、skill-seeker）— 单维度，不做质量评估
- **已装技能审计**（skill-audit、Skills_Curator）— 装了之后才评估，为时已晚

用户面临的痛点：看到一个新的 Skill / MCP Server / CLI，不知道是否安全、是否兼容 OpenCode、是否值得引入。README 都是营销话术，社区信息分散在 HN / Reddit / GitHub Issues 里，需要花 1-2 小时调研才能做决策。

### 解决方案

**6 维度加权评分 + 一票否决机制**：

| 维度 | 权重 | 一票否决 |
|------|------|---------|
| OpenCode 兼容性 | 15% | ✅ <50 强制 🔴 |
| 安全 / 侵入性 | 25% | — |
| 维护健康 | 25% | — |
| 功能价值 | 15% | — |
| 文档与 UX | 10% | — |
| 运营成本 | 10% | — |

加权总分 ≥80 且兼容性 ≥50 → 🟢 Install；60-79 → 🟡 Hold；<60 或兼容性 <50 → 🔴 Skip。

---

## 设计原则

### 为什么是 6 个维度

调研了 **20+ 个评估框架**后，发现现有框架要么过于宽泛（OpenSSF 18 项检查聚焦通用安全，不针对 AI 工具），要么过于狭窄（AgentRank 5 信号只看仓库健康度）。我们将 20+ 框架的检查项聚类归纳，提炼出 6 个正交维度，覆盖从"能不能用"到"值不值得用"的完整决策链。

**框架来源参考**：

- **OpenSSF Scorecards**（18 项检查）→ 安全维度的基础检查项
- **AgentRank**（5 信号：新鲜度 25% + Issue 健康 25% + 反向依赖 25% + Stars 15% + 贡献者 10%）→ 维护健康维度的信号体系
- **ChatForest**（5 因子：维护/安全/功能/性能/集成）→ 维度划分参考
- **NimbleBrain**（5 维度：来源/功能/安全/维护/文档）→ 安全 + 文档维度的补充
- **Skill Grader**（10 轴 A+ 到 F 等级）→ 功能价值 + 文档 UX 的细粒度参考
- **社区共识**（HN / Reddit）→ 运营成本维度的来源（token 污染、订阅费用等真实痛点）

### 为什么是这些权重

- **安全 25% + 维护 25% = 50%**：这两项是可信度的核心代理指标。一个不安全或无人维护的工具，功能再强也不能装。
- **兼容性 15%**（而非更高）：兼容性是二元门控（veto 机制），不需要在评分中占主导。兼容性差直接 🔴，无需通过权重调节。
- **功能价值 15%**：价值重要但难以客观量化，过高的权重会放大主观偏差。
- **文档 UX 10% + 运营成本 10%**：辅助维度，影响长期体验但不决定生死。

---

## 安装

```bash
ln -s ~/projects/05-tool-evaluator ~/.claude/skills/tool-evaluator
```

前置条件：OpenCode CLI + GitHub CLI（`gh auth login` 用于数据采集）。

---

## 快速开始

三个典型触发场景：

**场景 1：直接评估**
> "评估 chopratejas/headroom 能装吗"

**场景 2：兼容性疑问**
> "Understand-Anything 在 OpenCode 上能用吗"

**场景 3：英文触发**
> "Should I install anthropics/claude-code?"

完整触发词列表见 [02-usage-guide.md](./02-usage-guide.md)。

---

## 文档目录

| # | 文件 | 内容 | 行数 |
|---|------|------|------|
| 1 | [01-evaluation-framework.md](./01-evaluation-framework.md) | 6 维度评分框架详解、一票否决规则、verdict 判定、权重选择依据、9 框架对比表 | ~400 |
| 2 | [02-usage-guide.md](./02-usage-guide.md) | 触发词全表、输入格式、5 步工作流、报告解读、缓存策略、错误处理 | ~200 |
| 3 | [03-comparative-analysis.md](./03-comparative-analysis.md) | 13 个同类工具对比、Awesome Lists vs 活跃评估、OpenSSF 对比、独特价值 | ~300 |

---

## 评估流程概览

```
用户输入 GitHub URL
        │
        ▼
   解析 owner/repo
        │
        ▼
   缓存检查（30 天窗口）
   ┌────┴────┐
   命中       未命中/过期
   │         │
   ▼         ▼
 复用报告   运行脚本
            │
    ┌───────┴───────┐
    ▼               ▼
 github-report   security-scan
    │               │
    └───────┬───────┘
            ▼
     6 维度评分 + 社区调研
            │
            ▼
     加权计算 + veto 检查
            │
            ▼
     🟢 / 🟡 / 🔴 verdict
            │
    ┌───────┴───────┐
    ▼               ▼
 写入缓存文件    对话输出摘要
 (.omo/evaluations/)  (~200字)
```

## 缓存机制

- **位置**：`.omo/evaluations/{repo-name}.md`
- **有效期**：30 天（`evaluated_at` 时间戳）
- **刷新**：用户可随时手动刷新，不自动覆盖

## 与相关 Skill 的关系

| Skill | 定位 | 与 tool-evaluator 的差异 |
|-------|------|------------------------|
| **hv-analysis** | 横纵分析法深度研究报告 | 产出是"理解"（PDF，几小时），我们是"决策"（verdict，几分钟） |
| **skill-creator** | 创建/优化 skill | 完全不同方向：创造 vs 评估 |
| **research-ideation** | 研究启动/文献综述 | 不同领域 |

---

## 快速链接

| 链接 | 用途 |
|------|------|
| [项目 SKILL.md](../../SKILL.md) | 主交付物：触发词、工作流、评分标准、verdict 规则 |
| [报告模板](../../templates/report-template.md) | 评估输出模板 |
| [项目 AGENTS.md](../../AGENTS.md) | 项目结构总览（权威参考） |
| [项目 README.md](../../README.md) | 用户文档 |
| [调研草稿](../../.omo/drafts/skill-advisor.md) | 13 工具 + 20 框架调研原始资料 |
