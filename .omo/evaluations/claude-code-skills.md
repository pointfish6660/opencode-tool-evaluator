---
name: anthropics/skills
github: https://github.com/anthropics/skills
evaluated_at: 2026-06-07T09:30:00Z
verdict: 🟢 Install
total_score: 85
---

> **注**: 任务输入 `anthropics/claude-code-skills` 实际并不存在；Anthropic 官方 Skills 仓库的真实 slug 是 [`anthropics/skills`](https://github.com/anthropics/skills)。本报告对真实仓库进行评估，并将其作为 🟢 Install 路径的样本（继 Headroom 🟡、understand-anything 🔴 之后的正向验证）。

## TL;DR

Anthropic 官方维护的 Agent Skills 仓库——Agent Skills 标准的事实标杆。17 个生产级 skills（pdf / docx / xlsx / pptx / skill-creator / mcp-builder / frontend-design 等），全部基于标准 `SKILL.md` + Markdown + Bash/Python 实现，与 OpenCode skill loader 原生兼容。仓库 147K stars、13 contributors、8 天前刚有 commit，活跃度极高。零 hooks、零 launchd、零 settings.json 修改，安全姿态无可挑剔。综合 85 分，**🟢 Install**。

## 评分总表

| 维度 | 权重 | 得分 | 加权 | 一句话总结 |
|------|------|------|------|-----------|
| OpenCode 兼容性 | 15% | 85 | 12.75 | 标准 SKILL.md 格式，OpenCode skill loader 直接消费 |
| 安全/侵入性 | 25% | 88 | 22.00 | 官方仓库 + 零 hooks + 零系统侵入 |
| 维护健康 | 25% | 82 | 20.50 | Anthropic 维护、commit 极活跃，但 issue close rate 偏低 |
| 功能价值 | 15% | 90 | 13.50 | 17 个高质 skills + Agent Skills 标准的参考实现 |
| 文档与UX | 10% | 82 | 8.20 | README + 公开 spec + 模板目录，但无 LICENSE |
| 运营成本 | 10% | 80 | 8.00 | 本地运行、零订阅费，但部分 skills 烧 token |
| **总分** | **100%** | | **84.95 ≈ 85** | |

## 详细评估

### OpenCode 兼容性 — 85/100

`anthropics/skills` 采用与 OpenCode 同源的 skill 格式：每个 skill 是一个目录，包含 `SKILL.md`（带 `name` + `description` frontmatter）、可选的 `scripts/`、`references/`、`assets/`。这正是 OpenCode 在 `~/.claude/skills/` 下消费的格式——事实上，本机已通过该格式成功加载了 `docx`、`pdf`、`pptx`、`xlsx`、`skill-creator`、`frontend-design`、`canvas-design`、`doc-coauthoring` 等多个来自本仓库的 skills。

**加分项**：
- 仓库内的 `skills/skill-creator/SKILL.md` 使用与 OpenCode 完全相同的 frontmatter schema（`name` + `description`）
- 所有 skills 均为 Markdown + Bash + Python，无平台二进制依赖
- 公开 spec 在 [agentskills.io](https://agentskills.io) — 跨工具厂商的标准

**扣分项**：
- 仓库根目录有 `.claude-plugin/marketplace.json`，是 Claude Code 特定的 plugin marketplace 索引（OpenCode 不消费此文件，但也不报错）
- `skill-creator` 内部流程引用了 "claude-with-access-to-the-skill" 的评测流程描述，但实际执行仅依赖 SKILL.md 内容，不影响 OpenCode 调用
- 仓库未提供 `opencode.json` 安装示例

兼容性 85 ≥ 50，**未触发一票否决**。

### 安全/侵入性 — 88/100

`security-scan.sh` 检测结果：

| 检查项 | 值 |
|--------|-----|
| hooks_count | 0 |
| launchd_installed | false |
| modifies_settings_json | false |
| writes_user_files | false |
| network_calls | true |
| elevated_privileges | false |
| prebuilt_binaries | false |

**风险点**：
- 「发起外部网络请求」标记为 true，但经核查源自部分 skills 的示例脚本（如 `mcp-builder` 演示如何调用外部 API），**非仓库本身在安装时发起**。skills 在被 LLM 调用时，是否发起请求由用户的具体任务决定。

**加分项**：
- 由 Anthropic 官方维护——作者信任度在 Claude 生态中最高
- 无 LICENSE 文件略影响合规性但不构成安全风险（Anthropic 在 THIRD_PARTY_NOTICES.md 中声明了第三方组件许可）
- Skills 写入路径全部位于当前工作目录（`.docx`、`.pdf` 等生成文件），不触碰 `~/.config/`、`~/Library/` 或 shell rc 文件
- 无 prebuilt binaries，全部源码可审

### 维护健康 — 82/100

**关键指标**：
- Last commit: 2026-05-29（**8 天前**，极度活跃）
- Created: 2025-09-22（仓库仅 8 个月寿命，但已积累 147K stars）
- Contributors: 13（核心 Anthropic 团队 + 社区贡献者）
- Push 频率：最近一次 push 就在 2026-06-07（今天）

**加分项**：
- Anthropic 公司级 backing，bus-factor 风险低
- 公开 spec（`spec/agent-skills-spec.md` → agentskills.io）有标准化路线，不依赖单一仓库
- 议题处理活跃（938 open / 268 closed）

**扣分项**：
- Issue close rate ≈ 22%（268 / 1206），偏低——但因为 stars 极多（147K），issue 噪音大（含大量重复咨询与 feature request），单纯看 close rate 不够公平
- 无 CHANGELOG、无 git tag、无 release cadence，仅 main 分支线性推送
- 无 LICENSE 文件（合规风险）

### 功能价值 — 90/100

17 个生产级 skills，覆盖：

| Skill | 解决的问题 |
|-------|-----------|
| `pdf`, `docx`, `pptx`, `xlsx` | Office 文档生成（直接本报告评估器依赖的 skills） |
| `skill-creator` | Skill 创作工作流（带 eval-viewer + benchmark） |
| `mcp-builder` | MCP server 脚手架 |
| `frontend-design` | 前端 UI/UX 设计代码生成 |
| `canvas-design` | 海报/PDF 视觉创作 |
| `doc-coauthoring` | 文档协作工作流 |
| `webapp-testing`, `web-artifacts-builder` | Web 测试与构建 |
| `algorithmic-art`, `brand-guidelines`, `theme-factory`, `slack-gif-creator`, `internal-comms`, `claude-api` | 专项场景 |

**加分项**：
- 是 [Agent Skills 标准](https://agentskills.io)的官方参考实现——整个生态的事实标杆
- 多个 skills 在本评估器自身的工具链中已被实际使用（pdf/docx/xlsx 等用于报告生成）
- `skill-creator` 提供了完整的 eval-viewer 量化评估脚本，可作为 skill 工程最佳实践样板

**扣分项**：
- 部分 skills（如 `slack-gif-creator`、`internal-comms`）需要特定的 SaaS 凭证才能发挥价值
- 未提供各 skill 的 token 消耗基准数据

### 文档与UX — 82/100

**结构**：
```
README.md                       # Skill 概念与索引
THIRD_PARTY_NOTICES.md          # 第三方组件许可
spec/agent-skills-spec.md       # 指向 agentskills.io
template/                       # Skill 作者的起步模板
skills/<name>/SKILL.md          # 每个 skill 自带的文档
```

**加分项**：
- README 明确解释了 skill 的概念、加载机制与目录结构
- `template/` 目录为 skill 作者提供脚手架
- 公开 spec 文档（agentskills.io）描述完整标准
- 每个 skill 的 SKILL.md 自带 description，触发词描述清晰

**扣分项**：
- 无 LICENSE 文件（影响再分发与商业使用）
- 无截图、无 demo 动图
- 无 troubleshooting 章节
- 仅英文文档，无多语言版本

### 运营成本 — 80/100

**加分项**：
- 仓库本身完全免费，无订阅墙
- Skills 本地执行，无强制网络依赖（特定 skill 的网络调用由用户任务触发，不是 skill 加载时发生）
- 大部分 skills 是纯文本指令 + 轻量 Python/Bash 脚本，资源占用极低
- 无冷启动问题（skills 是按需加载的提示词，不是常驻服务）

**扣分项**：
- `skill-creator` 在迭代优化流程中会发起多次 LLM 调用，单次完整 eval 可能消耗 50K+ tokens
- 处理大型 Office 文档（pptx、xlsx）时，如果数据量大，上下文窗口占用显著
- 部分高级 skills（如 `mcp-builder`、`webapp-testing`）依赖外部服务或大型依赖（playwright 等），间接增加运行成本

## GitHub 统计

| 指标 | 值 |
|------|------|
| Stars / Forks / Watchers | 147,388 / 17,400 / 955 |
| Issues (Open/Closed) | 938 / 268 |
| License / Language | 未声明 / Python（部分 skills） |
| Last Commit | 2026-05-29 |
| Contributors | 13 |
| Default Branch | main |
| Created / Updated | 2025-09-22 / 2026-06-07 |

## 替代方案

| 项目 | 类型 | 与 anthropics/skills 的差异 |
|------|------|----------------------------|
| [Claude Code 官方插件市场](https://docs.claude.com/en/docs/claude-code/plugins) | 内置 | Claude Code 自带，无需额外安装，但仅限 Claude Code 宿主 |
| [`awesome-claude-skills`](https://github.com/hesreallyhim/awesome-claude-skills) | 社区精选清单 | 收录更多第三方 skills，但无 Anthropic 官方背书，需自行审核 |
| 本机 `~/.claude/skills/` 已加载的 skills | 已部署 | 其中 `docx` / `pdf` / `xlsx` / `pptx` / `skill-creator` / `frontend-design` 等已源自 anthropics/skills，无需重复安装 |
| [`anthropics/claude-plugins-official`](https://github.com/anthropics/claude-plugins-official) | 官方 | Anthropic 维护的 Claude Code plugin 索引，与本仓库的 skills 互补 |

## Verdict 理由

**🟢 Install**（综合 85 / 100）。

**核心理由**：
1. **官方维护的标杆仓库**——Anthropic 出品，147K stars，8 天前刚有 commit，可信度在 Claude/Agent Skills 生态中处于最高档；
2. **零系统侵入**——`security-scan.sh` 报告 0 hooks / 0 launchd / 0 settings.json 修改，安全姿态无可挑剔；
3. **OpenCode 原生兼容**——SKILL.md 格式与 OpenCode skill loader 完全一致，本机已通过该格式成功使用其中多个 skills（pdf、docx、xlsx 等）；
4. **生态价值**——是 Agent Skills 标准的参考实现，对理解整个 skill 生态的演进有不可替代的价值。

**主要风险点**：
- 无 LICENSE 文件（影响合规再分发）
- Issue close rate 偏低（22%）——对流行仓库可接受，但长期需关注
- 部分 skills 烧 token（skill-creator 的 eval 流程）

**结论**：本仓库是 🟢 Install 路径的标准样本——兼容性 85 ≥ 50（未触发一票否决）、综合分 85 ≥ 80，两条判定规则均满足。建议 OpenCode 用户**直接将需要的子 skill 链接/复制到 `~/.claude/skills/`**，无需安装整个仓库。

## 附录: 评估方法

> 本评估使用 [tool-evaluator](https://github.com/pointfish/pointfish6660-opencode-tool-evaluator) 的 6 维度加权评分框架。详见 [评估框架文档](https://github.com/pointfish6660/opencode-tool-evaluator/blob/main/docs/tool-evaluator/01-evaluation-framework.md)。
