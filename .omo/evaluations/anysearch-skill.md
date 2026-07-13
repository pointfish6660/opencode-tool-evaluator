---
name: anysearch-skill
github: https://github.com/anysearch-ai/anysearch-skill
evaluated_at: 2026-07-13T19:50:00+08:00
verdict: 🟡 Hold
total_score: 74
---

## TL;DR

AnySearch 是一个为 AI agent 设计的统一实时搜索引擎 skill，支持通用 web 搜索、垂直领域搜索、并行批量搜索和全文页面提取，提供 Python/Node/PowerShell/Bash 四种运行时（从单一数据源生成）。项目极度活跃（4136 stars / 12 contributors / 3 天前提交），OpenCode 兼容性优秀且有专门的修复 PR。**但核心搜索能力绑定专有后端 `api.anysearch.com`，且安装流程要求 AI agent 自动用用户邮箱注册第三方账号**——这两点把安全/侵入性与运营成本拉低，使总分停在 Hold 区间（74/100）。功能与维护都很强，但专有后端依赖与自动注册设计是主要顾虑。

## 评分总表

| 维度 | 权重 | 得分 | 加权 | 一句话总结 |
|------|------|------|------|-----------|
| OpenCode 兼容性 | 15% | 90 | 13.5 | 明确支持 OpenCode，PR #5 专门修复安装路径，多运行时跨平台 |
| 安全/侵入性 | 25% | 58 | 14.5 | 自动邮箱注册第三方账号 + 专有后端数据流，侵入性偏高 |
| 维护健康 | 25% | 84 | 21.0 | 4136 stars、12 contributors、issue 关闭率 85%，但项目仅 2.5 个月 |
| 功能价值 | 15% | 70 | 10.5 | 统一搜索四合一、混合排序，但替代品多且无 benchmark 证据 |
| 文档与UX | 10% | 86 | 8.6 | README 极完整（多平台安装/配置/验证/错误表），双语 release notes |
| 运营成本 | 10% | 60 | 6.0 | skill 免费，但依赖专有 API（匿名限额低，付费定价不透明） |
| **总分** | **100%** | | **74** | |

## 详细评估

### OpenCode 兼容性 — 90/100

兼容性是 AnySearch 的强项。README 明确列出 OpenCode 安装路径（`~/.config/opencode/skills/anysearch`），与 Claude Code、Cursor/Windsurf、Generic、共享 `~/.agents/skills/`（Codex/Cursor/OpenClaw）并列支持。PR #5 "Fix OpenCode skill install path" 由 @cagedbird043 贡献，显示有人专门维护 OpenCode 兼容性。skill 采用标准 `SKILL.md` 接口，不依赖 Claude Code 的 `Task` 工具，也没有任何专有 host API 调用。运行时检测覆盖 Python（推荐，需 `requests`）、Node.js（无外部依赖）、PowerShell、Bash 四种，优先级 Python > Node > Shell，跨平台（macOS/Linux/Windows）且平台无关（纯脚本，无原生二进制）。这是典型的"装上即用"型 skill，无兼容性否决风险。

### 安全/侵入性 — 58/100

这是 AnySearch 的主要短板，扣分集中在设计层面的侵入性而非恶意行为。**第一，自动注册第三方账号**：README 指示 AI agent 调用 `POST https://api.anysearch.com/v1/auth/email/register` 用用户邮箱自动注册 `anysearch.com` 账号，无需验证码，密码通过邮件发送——agent 在用户仅提供邮箱的情况下就完成账号创建并落盘明文 API key 到 `.env`。这种"agent 代为注册第三方服务"的模式侵入性显著高于常规 skill。**第二，专有后端数据流**：所有搜索请求发往 `api.anysearch.com`，用户查询内容流经第三方专有服务（非 GitHub 托管），数据去向与留存策略 README 未披露。**第三，明文 key 存储**：API key 以 `ANYSEARCH_API_KEY` 明文写入项目 `.env`。积极信号是：无 launchd/systemd 注入、不修改 `settings.json`、无提权、无预编译二进制、无系统级 hook（security-scan 报告的 "1 个 hook" 属 skill 内部触发器而非系统级）。综合来看无恶意，但"自动注册 + 专有后端"组合使其在 25% 权重维度上得分偏低。

**检测到的风险点**:

- 写入用户目录文件（`.env`、`runtime.conf`，均在 skill 目录内）
- 发起外部网络请求（`api.anysearch.com` 专有后端，搜索查询数据外流）
- 注册了 1 个 hook（skill 内部触发器，非系统级 launchd/systemd）
- ⚠️ 设计层面：AI agent 自动用邮箱注册第三方账号并落盘明文 key

### 维护健康 — 84/100

维护状态非常健康，唯一不确定性来自项目年龄。4136 stars / 291 forks / 12 contributors，对 2026-04-30 才创建的项目（约 2.5 个月）是极高人气。最后一次提交在 2026-07-10（3 天前），issue 关闭率约 85%（23 closed / 4 open），中位关闭时长 76.5 小时（响应迅速），最老 open issue 仅 14 天，无 security 标签 issue。已发布 v2.1.0（2026-06-02），release notes 详尽（3346 字符，中英双语），且 v2.1.0 引入了实质性改进（域重构、混合排序、智能路由）。扣分项：仅 1 个 release 无法计算发布节奏、无 `CHANGELOG.md` 文件（依赖 release notes）、项目太年轻（2.5 个月）长期可持续性有待验证、issue 总量偏少（27 个）样本有限。总体活跃度优异，但年轻项目的"高活跃"需时间验证。

### 功能价值 — 70/100

AnySearch 提供四合一搜索能力：通用 web 搜索、垂直领域搜索（含 social_media 等多个 sub_domain）、并行批量搜索（batch_search）、全文页面提取（extract 转 Markdown）。v2.1.0 引入混合排序（语义相关性 + 实时时效信号），并将垂直搜索设为默认路径，通用搜索作为例外——设计上比较成熟。四种运行时从单一数据源（`scripts/shared/`）生成，消除了约 400 行跨实现重复代码，工程实践良好。扣分点：**README 称"结果质量显著提升"但未提供任何 benchmark 数据或与竞品的量化对比**；替代方案众多（Tavily MCP、Brave Search MCP、WebSearch、exa、Jina 等），AnySearch 非独创；最关键的是**核心能力完全绑定专有后端 `anysearch.com`**——skill 本身只是 CLI 包装层，真正的搜索逻辑在第三方服务上，功能价值与该服务的可用性/持续性强绑定。

### 文档与UX — 86/100

文档质量优秀。README 覆盖完整：问题说明、多平台下载安装（含 curl/wget 双选项）、API key 配置（含 key 优先级顺序）、安装后验证（runtime 检测 → 入口测试 → 持久化配置 → 可选真实验证四步流程）、常规用法示例、社交媒体工作流、文件结构图、下载历史。错误处理表格详尽（列出 5 类注册错误及对应处理），release notes 中英双语。另附 `SECURITY.md`（安全策略）和 `TEST_PLAN.md`（端到端测试计划）。扣分项：无截图或动画 demo、无独立 `CHANGELOG.md` 文件（依赖 GitHub release notes）、定价信息缺失（免费限额与付费档位未在 README 说明，需到 console 查询）。

### 运营成本 — 60/100

skill 本身 Apache-2.0 开源免费，本地运行轻量（Python 仅需 `requests` 库，单次调用秒级返回，内存占用低）。但**核心依赖专有 API 服务 `anysearch.com`**，这是成本评估的主要扣分点。匿名访问可用但限额低（README 明确"lower rate limits and quota"），注册账号后免费 tier 为 `rate_limit: 100`（单位未明，推测每分钟/每小时）、`quota_limit: 0`（0 可能表示无额外配额或需付费）。**付费定价 README 完全未披露**，需到 `anysearch.com/console/api-keys` 自行查询，成本不透明。token 消耗方面，skill 调用本身不加载大量上下文，但每次搜索返回的结果数据会进入 agent 上下文，高频使用会增加 token 开销。综合：本地零成本，但第三方 API 的限额/定价不透明，长期使用成本存在不确定性。

## GitHub 统计

| 指标 | 值 |
|------|------|
| Stars / Forks / Watchers | 4136 / 291 / 43 |
| Issues (Open/Closed) | 4 / 23 |
| License / Language | Apache-2.0 / Python |
| Last Commit | 2026-07-10 |
| Contributors | 12 |
| Default Branch | main |
| Created / Updated | 2026-04-30 / 2026-07-13 |
| Issue 中位关闭时长 | 76.5 小时 |
| 最老 Open Issue | 14 天 |
| Release 数 / 最新版本 | 1 / v2.1.0 |
| Release 节奏 (平均间隔) | N/A（仅 1 个 release） |

## 替代方案

| 替代方案 | 类型 | 关键差异 |
|---------|------|---------|
| **Tavily MCP** | MCP Server | 专为 LLM 设计的搜索 API，有成熟定价，MCP 原生协议 |
| **Brave Search MCP** | MCP Server | 隐私导向，独立索引，MCP 协议 |
| **WebSearch (内置)** | 内置工具 | OpenCode/agent 内置，无需安装，但能力有限 |
| **exa (websearch_web_search_exa)** | API + Skill | 语义搜索，已有 OpenCode 集成 |
| **Jina Reader** | API | 专注页面提取（AnySearch 的 extract 功能竞品） |
| **Serper / SerpAPI** | API | Google SERP 抓取，成熟定价 |

AnySearch 的差异化在于"四合一 + 垂直领域 + 多运行时统一生成"，但每个子功能都有更成熟的专一竞品，且多数替代方案的数据流更透明或定价更清晰。

## Verdict 理由

**🟡 Hold（74/100）** — 兼容性无否决（90 ≥ 50），总分落在 60-79 区间。

**最关键的决策原因**：核心搜索能力完全绑定专有后端 `api.anysearch.com`，且安装流程设计要求 AI agent 自动用用户邮箱注册第三方账号——这两点把权重最高的安全/侵入性（25%）压到 58、运营成本（10%）压到 60，抵消了兼容性（90）、维护（84）、文档（86）的优势。

**建议**：
- 如果你已接受 Tavily/Brave 等专有搜索 API 且数据流透明度可接受，AnySearch 的"四合一 + 垂直领域"整合有实际便利价值，可以安装试用。
- 安装时**手动完成账号注册**（不要让 agent 自动用邮箱注册），先到 `anysearch.com/console/api-keys` 查清免费限额与付费定价再决定。
- 若对数据流向敏感（查询内容流经第三方），优先考虑自建或开源索引方案。

功能、维护、兼容性、文档都很强，唯一让它在"Install"门槛前停下的是专有后端依赖与自动注册设计的侵入性——这是设计取向问题而非质量缺陷。

## 附录: 评估方法

> 本评估使用 [tool-evaluator](https://github.com/pointfish6660/opencode-tool-evaluator) 的 6 维度加权评分框架。详见 [评估框架文档](https://github.com/pointfish6660/opencode-tool-evaluator/blob/main/docs/01-evaluation-framework.md)。
