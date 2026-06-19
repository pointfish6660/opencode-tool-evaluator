---
title: Chrome 插件渲染本地 Markdown 文件调研
date: 2026-06-18
session_id: ses_123878060ffe1lcIBose40yOrU
---

## 第1轮 · Chrome插件渲染本地MD

**用户：**

调研一下，有什么chrome插件，能够实现， 在打开http://127.0.0.1:8080/ 查看到有md文件时，网页中点击md文件，直接就能再浏览器新页面中，查看这个md文档，而且是人类友好的md阅读体验

**回答：**

研究/调研意图 — 用户在找一个 Chrome 插件，能让本地文件服务器（127.0.0.1:8080 的目录列表）上的 .md 文件在点击时自动渲染成可读格式。我的方法：并行 websearch 多个角度，综合推荐。

# Chrome 插件调研：本地 HTTP 服务器上的 Markdown 渲染

你的场景有个关键细节需要注意：**`http://127.0.0.1:8080/` 是 HTTP 协议，不是 `file://`**。很多 Markdown 渲染插件默认只处理 `file://` 或特定远程域名（如 `raw.githubusercontent.com`），对 `127.0.0.1` 需要额外配置。另外，如果你用的是 `python3 -m http.server`，`.md` 文件默认会被当成 `application/octet-stream`，浏览器会**下载而不是打开**——所以插件必须能基于 URL 扩展名拦截，而不只依赖 Content-Type。

基于这两点筛选，推荐如下：

## 🥇 首选：Markdown Viewer (simov)

- 商店：[ckkdlimhmcjmikdlpkmbgfkaikojcbjk](https://chromewebstore.google.com/detail/markdown-viewer/ckkdlimhmcjmikdlpkmbgfkaikojcbjk)
- 开源：[github.com/simov/markdown-viewer](https://github.com/simov/markdown-viewer)
- **唯一在文档里明确写明支持 localhost 的插件**：
  > any host that resolves to localhost IPv4 `127.0.0.1` or IPv6 `::1`
  > Access to a specific port can be enabled by adding `http://localhost:3000`
- **Content-Type 检测 + URL 扩展名检测双保险**——即使服务器返回 octet-stream，也能通过 `.md` 扩展名拦截渲染
- 功能最全：30+ 主题、GFM、Mermaid、MathJax、ToC、自动重载（支持本地文件秒级刷新）、Prism 语法高亮、多解析器（markdown-it/marked/remark 可切换）、开源

**配置步骤**：
1. 安装后进入 `chrome://extensions` → 详情 → 勾选「Allow access to file URLs」
2. 点击插件图标 → Options → Compat → 在 host 白名单加上 `http://127.0.0.1:8080`（或 `http://localhost:8080`）
3. 访问目录列表，点 `.md` 文件即自动渲染

## 🥈 次选：MarkView

- 商店：[cfopbpknalachedpcddhgbgjoigklien](https://chromewebstore.google.com/detail/markview-markdown-viewer/cfopbpknalachedpcddhgbgjoigklien)
- 支持「Any URL ending in .md/.markdown/.mkd/.mdx served as plain text」
- 100% 隐私（零数据收集）、DOCX/HTML 导出、KaTeX、Mermaid（可缩放下载）、目录导航、原始视图切换、文件变化自动刷新
- **注意**：它只渲染「以 raw 形式提供的 .md」，对 localhost 同样需要在扩展详情开启对应 host 权限

## 🥉 备选：Markdown Reader

- 商店：[medapdbncneneejhbgcjceippjlfkmkg](https://chromewebstore.google.com/detail/markdown-reader/medapdbncneneejhbgcjceippjlfkmkg)
- 明确支持 `file://`、`http://`、`https://` 三种协议
- 暗亮主题、实时刷新、图片预览、快捷键

---

## 一个绕开插件的根本性建议

你的目录服务器如果是 `python3 -m http.server 8080`，它的 `.md` Content-Type 处理是问题根源。**换一个能正确设置 `text/markdown` 的服务器**，体验会好很多，甚至可以不依赖插件：

| 方案 | 命令 | 特点 |
|------|------|------|
| [`grip`](https://github.com/joeyespo/grip) | `grip` | GitHub 风格渲染，需 GitHub token（高配） |
| [`markserv`](https://github.com/markserv/markserv) | `npx markserv -p 8080` | 实时渲染 MD，自带目录列表，**点击 .md 直接渲染** |
| [`http-server`](https://github.com/http-party/http-server) | `npx http-server -p 8080` | 正确识别 `.md` 为 `text/markdown`，配合插件最稳 |

**最省心组合**：`npx markserv`（开箱即用，连插件都不用装）或 `Markdown Viewer (simov) + python http.server`（需要插件但服务器零依赖）。

需要我帮你验证某个插件在你的具体服务器上能不能跑，或者帮你配一下 markserv 吗？

---

## 第2轮 · tool-evaluator评估markserv

**用户：**

调用skill 调研一下 markserv 是否适合我使用

**回答：**

用户意图：评估 markserv 是否适合安装使用。这是 tool-evaluator skill 的标准触发场景（GitHub CLI 工具评估）。直接调用。

Skill 已加载。按工作流执行评估。先做 Step 1-2：解析输入 + 缓存检查。

**Step 1: 解析输入** — `owner=markserv`, `repo=markserv`，合法。

并行执行：检查缓存 + 确认脚本存在。

缓存不存在，脚本就绪。**Step 3：并行运行两个数据采集脚本**。

数据采集完成。两个脚本返回完整 JSON。**Step 4：6 维度评估** — 先查看报告模板，然后基于数据评分。

数据齐全。完成 6 维度评分并生成报告。

**评分结果：**

| 维度 | 权重 | 得分 | 加权 |
|------|------|------|------|
| 兼容性 | 15% | 85 | 12.75 |
| 安全/侵入性 | 25% | 90 | 22.50 |
| 维护健康 | 25% | 55 | 13.75 |
| 功能价值 | 15% | 85 | 12.75 |
| 文档与UX | 10% | 72 | 7.20 |
| 运营成本 | 10% | 90 | 9.00 |
| **总分** | | | **78** |

78 → 🟡 **Hold**。用 heredoc 写入报告（>5KB）：

**Step 5：评估完成。报告已写入 `.omo/evaluations/markserv.md`。**

---

## markserv 评估摘要

| 维度 | 权重 | 得分 |
|------|------|------|
| 兼容性 | 15% | 85 |
| 安全/侵入性 | 25% | 90 |
| 维护健康 | 25% | 55 |
| 功能价值 | 15% | 85 |
| 文档与UX | 10% | 72 |
| 运营成本 | 10% | 90 |
| **总分** | | **78 → 🟡 Hold** |

**最关键理由**：markserv 功能上完美命中你的需求（serve markdown as GitHub-style html + 目录索引 + live-reload），安全性和成本表现极佳（MIT、零 hooks、零系统侵入、免费本地运行）。唯一拖分项是维护健康度——3 个月前最后 commit、0 个正式 release、issue close rate 65%、最老 issue 积压 3523 天。

**但对你来说，这个 Hold 应该被理性看待**：markserv 解决的问题足够简单稳定，9 年项目说明已经过了时间检验，"维护不活跃" ≠ "不能用"。

**实际建议**：
```bash
# 临时验证（零风险，不安装）
npx markserv

# 满意后全局安装
npm i -g markserv
```

启动后在浏览器访问 `http://localhost:8080/`，目录列表里的 `.md` 文件点击即渲染成 GitHub 风格页面，编辑器改文件还会自动热重载。

完整报告：`.omo/evaluations/markserv.md`
