---
name: markserv
github: https://github.com/markserv/markserv
evaluated_at: 2026-06-19T00:00:00+08:00
verdict: 🟡 Hold
total_score: 78
---

## TL;DR

markserv 是一个用 Node.js 写的本地 Markdown 服务器，能将目录下的 `.md` 文件渲染成 GitHub 风格的 HTML，自带目录索引和实时热重载。**对你的场景（替代 `python3 -m http.server`、点击 .md 直接渲染）来说功能完美匹配**，安全性和成本表现极佳。唯一拖分项是维护活跃度中等（3 个月前最后 commit、无正式 release、issue close rate 65%）。但对于一个功能简单稳定的工具，这不影响日常使用。建议直接 `npx markserv` 临时使用，无需永久安装。

## 评分总表

| 维度 | 权重 | 得分 | 加权 | 一句话总结 |
|------|------|------|------|-----------|
| OpenCode 兼容性 | 15% | 85 | 12.75 | 纯 Node CLI，与 OpenCode 零冲突，npx 即跑 |
| 安全/侵入性 | 25% | 90 | 22.50 | MIT、零 hooks、零系统修改，唯一"风险"是本职网络监听 |
| 维护健康 | 25% | 55 | 13.75 | 3 个月前有 commit 但无正式 release，issue 积压 |
| 功能价值 | 15% | 85 | 12.75 | 精准解决"目录列表点击 md 直接渲染"需求 |
| 文档与UX | 10% | 72 | 7.20 | README 有 changelog/gitter，但缺截图和排错指南 |
| 运营成本 | 10% | 90 | 9.00 | 免费、本地运行、资源消耗低 |
| **总分** | **100%** | | **78** | 🟡 Hold |

## 详细评估

### OpenCode 兼容性 — 85/100

markserv 是一个完全独立的 Node.js CLI 工具，不涉及任何 AI host 集成（非 Skill / MCP / 插件），因此"兼容性"在这里的含义是"能否在用户环境正常独立运行"。答案是完全没问题：纯 JavaScript + CSS 实现，无原生二进制依赖，macOS 原生支持，`npx markserv` 或 `npm install -g markserv` 即可启动。它不与 OpenCode、Codex 或任何编辑器产生耦合，也不会修改任何 AI 工具的配置文件。唯一轻微扣分点：它不是为 AI 开发工作流设计的工具，与 OpenCode 生态无协同效应，但对于你的场景（纯本地文件服务）这是优点而非缺点——零侵入。

### 安全/侵入性 — 90/100

安全扫描结果极为干净：`hooks_count: 0`、不安装 launchd/cron、不修改 settings.json、不写用户目录文件、无预编译二进制。MIT 许可证。`network_calls: true` 被标记为 medium risk，但这完全是误报性质——markserv 是 HTTP 服务器，监听端口和响应请求是它的本职工作，不是恶意行为。在 `127.0.0.1` 本地使用场景下，网络暴露面为零。18 位 contributors、603 stars 也提供了基本的社区信任背书。扣 10 分仅因它作为服务器会绑定端口（默认 8080），如果你已有其他服务占用同端口需要手动指定 `-p`。

### 维护健康 — 55/100

这是 markserv 的主要短板。项目创建于 2016 年（9 年历史），最后 commit 在 2026-03-07（约 3 个月前），说明项目还活着但不活跃。关键问题：**正式 release 数为 0**——虽然 npm 上有版本发布，但 GitHub 上没有使用 Releases 功能，缺乏版本管理的正式感。Issue close rate = 91/(91+49) ≈ 65%，处于中等水平；最老的 open issue 已积压 3523 天（近 10 年），说明维护者对老 issue 采取放任态度。中位关闭时长 17.6 天尚可。18 位 contributors 分散了 bus factor 风险。CHANGELOG 存在（6.4KB）。总体属于"功能稳定但维护节奏慢"的类型，对于成熟的简单工具尚可接受，但不适合期望快速 bug 修复的用户。

### 功能价值 — 85/100

markserv 的核心描述是 "serve markdown as html (GitHub style), index directories, live-reload as you edit"——这三句话精准命中你的全部需求：(1) 目录索引让你像 `python3 -m http.server` 一样浏览文件；(2) GitHub 风格的 markdown 渲染让点击 `.md` 文件直接显示格式化页面；(3) live-reload 是额外增值——编辑器里改文件，浏览器自动刷新。底层使用 markdown-it 引擎（成熟稳定），支持 GFM、语法高亮、目录导航。相比 Chrome 插件方案，markserv 从服务器侧解决 Content-Type 问题，不依赖浏览器扩展权限配置，体验更顺滑。扣分点：功能相对单一，且存在替代品（grip 需 GitHub token、docsify 更重）。

### 文档与UX — 72/100

README 包含项目 banner、功能说明、CHANGELOG 链接和 Gitter 社区入口。topics 标签丰富（20 个），便于发现。但文档缺少：(1) 安装后的使用截图或动画 demo；(2) 常见问题排错章节（如端口冲突、Content-Type 问题）；(3) 中文本地化。对于一个 2016 年的老项目，文档停留在"够用"水平，没有持续打磨。安装步骤（npx/npm）是标准的，不需要额外解释。

### 运营成本 — 90/100

完全免费开源，MIT 许可证。本地 Node.js 进程，资源消耗极低（HTTP 静态服务 + markdown 渲染，CPU/内存占用可忽略）。无任何 API 订阅或外部服务依赖。冷启动时间在秒级。唯一成本是需要 Node.js 运行时（但你的环境已有）。`npx markserv` 按需启动，不占用常驻资源。

## GitHub 统计

| 指标 | 值 |
|------|------|
| Stars / Forks / Watchers | 603 / 92 / 9 |
| Issues (Open/Closed) | 49 / 91 |
| License / Language | MIT / CSS |
| Last Commit | 2026-03-07 |
| Contributors | 18 |
| Default Branch | master |
| Created / Updated | 2016-10-04 / 2026-06-12 |
| Issue 中位关闭时长 | 423.3 小时 (~17.6 天) |
| 最老 Open Issue | 3523 天 |
| Release 数 / 最新版本 | 0 / 无 |
| Release 节奏 (平均间隔) | 无正式 release |

## 替代方案

| 工具 | 优势 | 劣势 | 适用场景 |
|------|------|------|---------|
| `grip` (Python) | GitHub 官方风格渲染最准确 | 需要 GitHub API token，依赖网络 | 追求 100% GitHub 一致外观 |
| `docsify` (Node) | 功能最全，SPA 体验，插件生态 | 配置较重，学习曲线 | 长期文档站点 |
| Chrome 插件 (simov/markdown-viewer) | 不换服务器，继续用 python http.server | 需配置 localhost 权限，依赖插件 | 不想换服务器 |
| `http-server` + Chrome 插件 | 服务器正确设 Content-Type | 仍需装插件 | 折中方案 |

## Verdict 理由

**🟡 Hold（总分 78）**——markserv 功能上完美匹配你的需求（serve md as html + 目录索引 + 热重载），安全性和成本表现优秀。Hold 而非 Install 的唯一原因是维护信号中等：无正式 release、issue 积压、commit 节奏慢。

**但针对你的具体场景，实际建议是：直接用。** markserv 解决的问题足够简单稳定（HTTP 服务 + markdown 渲染），"维护不活跃"不等于"不能用"——一个 9 年的老项目如果能跑，说明它已经过了时间检验。用 `npx markserv` 按需启动（不全局安装），零风险验证体验。如果满意再考虑 `npm i -g`。维护健康的权重在这里不应过度焦虑。
