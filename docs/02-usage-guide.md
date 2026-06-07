# 使用指南

## 触发词

Tool Evaluator 支持中文、英文及自然语言疑问句三种触发方式。关键要求：输入中必须包含（或隐含）一个 GitHub 仓库标识符。

### 中文触发词

| 触发词 | 示例 |
|--------|------|
| 评估 / 分析 / 评测 | "评估 chopratejas/headroom" |
| 装不装 / 该不该装 / 要不要装 | "anthropics/claude-code 装不装" |
| 值不值得 / 值得用吗 | "Lum1104/understand-anything 值不值得" |
| 能不能装 / 能用吗 | "headroom 能不能装" |
| 好不好用 / 怎么样 | "Skills_Curator 好用吗" |
| 兼容吗 | "skillchecker 在 OpenCode 兼容吗" |

### 英文触发词

| Trigger | Example |
|---------|---------|
| evaluate / analyze / review | "evaluate anthropics/claude-code" |
| should I install / is X worth installing | "should I install Lum1104/understand-anything" |
| X compatibility / X verdict | "headroom compatibility with OpenCode" |
| install / assess | "assess chopratejas/headroom" |

### 疑问句触发

| 句式 | 示例 |
|------|------|
| "X 好用吗" | "Headroom 好用吗" |
| "X 怎么样" | "Understand-Anything 怎么样" |
| "X 能在 OpenCode 用吗" | "Skills_Curator 能在 OpenCode 用吗" |
| "X 在 Claude Code / Cursor 上能用吗" | "skillchecker 在 Cursor 上能用吗" |
| "X 安全吗" / "X 有没有风险" | "repo-insight 安全吗" |

### 隐式触发

- 用户粘贴 `https://github.com/...` URL 并询问任何关于"可行性 / 好用 / 兼容 / 推荐"的问题——即使没有说"评估"
- 用户提到工具名且上下文是关于安装、兼容性或信任

### 不触发的情况

- 用户只问功能解释（路由到通用解释）
- 用户要求比较两个已安装的工具（多工具比较超出范围）
- 用户要求创建或编辑 skill（路由到 `skill-creator`）

---

## 输入格式

### 必须是 GitHub URL

评估器只接受 GitHub 仓库地址，支持两种格式：

| 格式 | 示例 | 说明 |
|------|------|------|
| 完整 URL | `https://github.com/anthropics/claude-code` | 推荐 |
| 简写 slug | `anthropics/claude-code` | 等效 |

### 正确示例

```
评估 https://github.com/chopratejas/headroom
分析 anthropics/claude-code
Should I install Lum1104/understand-anything?
```

### 错误示例

| 错误输入 | 问题 | 正确做法 |
|---------|------|---------|
| `评估 headroom` | 缺少 owner/repo 路径 | 补全为 `chopratejas/headroom` |
| `评估 git@github.com:foo/bar.git` | SSH URL 格式 | 改为 `foo/bar` 或 HTTPS URL |
| `评估 https://gitlab.com/foo/bar` | 非 GitHub | 本评估器只支持 GitHub |
| `评估 https://npmjs.com/package/foo` | 包管理器 URL | 找到对应 GitHub 仓库后输入 |

---

## 工作流

评估器按 5 步顺序执行，每步输出供下一步使用：

### 流程图

```
Step 1: 解析输入
    │  提取 owner/repo，验证格式
    ▼
Step 2: 缓存检查
    │  检查 .omo/evaluations/{repo}.md
    │  ┌── 30 天内有效 → 复用报告
    │  └── 过期/不存在/用户要求刷新 → 继续
    ▼
Step 3: 运行脚本
    │  并行执行：
    │  ├── github-report.sh → 仓库元数据
    │  └── security-scan.sh → 安全扫描
    ▼
Step 4: 6 维度评分
    │  结合脚本输出 + 社区调研
    │  每维度 0-100 分 + 100-200 字证据说明
    ▼
Step 5: 生成报告
    │  ├── 写入 .omo/evaluations/{repo}.md
    │  └── 对话输出 ~200 字摘要
```

### 各步骤说明

**Step 1 解析**：从输入中提取 `owner` 和 `repo`，去除尾部斜杠、`.git` 后缀、查询参数和片段。验证两段均非空且匹配 `^[A-Za-z0-9._-]+$`。

**Step 2 缓存**：读取缓存文件的 `evaluated_at` 时间戳（ISO 8601）。30 天内有效时询问用户：复用还是刷新？

**Step 3 脚本**：两个脚本并行运行，输出严格 JSON。任一脚本失败则停止并报告错误，不编造评分。

**Step 4 评分**：结合脚本输出（含 Issue 关闭耗时、Release 节奏、CHANGELOG 存在性等结构化字段）+ 简短社区调研（HN / Reddit，LLM 通过 web 调研获取，非脚本化），为每个维度打分并撰写证据说明。

**Step 5 报告**：按 `templates/report-template.md` 格式生成完整报告，写入缓存文件。对话中只输出 ~200 字摘要（repo 名、六维度分数、加权总分、verdict emoji、最重要的一条理由）。

---

## 阅读评估报告

### 报告结构

评估报告（`.omo/evaluations/{repo}.md`）包含以下部分：

| 部分 | 内容 |
|------|------|
| **Frontmatter** | `repo`、`owner`、`evaluated_at`、`weighted_total`、`verdict` |
| **摘要表** | 六维度分数 + 加权总分 + verdict emoji |
| **维度详解** | 每维度 100-200 字说明 + 具体证据 |
| **Issue 健康** | `issues.close_median_hours`、`issues.oldest_open_days`、`issues.bug_count` |
| **Release 节奏** | `releases.cadence_days_avg`、`releases.latest_tag`、`releases.has_breaking` |
| **文档完整度** | `changelog.exists`、`releases.latest_body_chars` |
| **社区信号** | HN / Reddit 上的定性反馈（LLM 通过 web 调研获取，非脚本化） |
| **结论** | verdict 决定性理由 + 一票否决说明（如适用） |

### Verdict 含义

| Verdict | 含义 | 建议行动 |
|---------|------|---------|
| 🟢 **Install** | 综合表现优秀，推荐安装 | 按 README 指引安装 |
| 🟡 **Hold** | 存在不确定因素，观望 | 关注 issue 列表，等待改进或替代 |
| 🔴 **Skip** | 不推荐安装 | 不安装；如已安装考虑移除 |

### 解读示例

```
加权总分: 72
Verdict: 🟡 Hold

维度明细:
  兼容性: 85  ✅ 标准 MCP 协议
  安全:   60  ⚠️ 需要修改 settings.json
  维护:   75  ✅ 上月有提交
  功能:   70  ✅ 解决真实问题
  文档:   65  ⚠️ 缺少配置示例
  成本:   80  ✅ 免费本地运行

决定性理由: 安全维度（60 分）因未声明的网络请求被扣分，
建议等待开发者补充权限声明后再安装。
```

---

## 缓存策略

### 缓存位置与格式

- **路径**：`.omo/evaluations/{repo-name}.md`
- **命名**：repo 名称小写，斜杠替换为 `-`
- **时间戳**：frontmatter 中的 `evaluated_at`（ISO 8601 格式）

### 30 天有效期

- 缓存在 **30 天内**视为有效，评估器会询问用户是否复用
- 超过 30 天的缓存**自动刷新**，重新执行完整评估
- 用户可**随时手动刷新**——即使缓存仍在有效期内

### 不会自动覆盖

评估器绝不静默覆盖已有报告。刷新时总是先与用户确认。

---

## 错误处理

| 错误 | 原因 | 解决方案 |
|------|------|---------|
| GitHub URL 格式错误 | 不是 `https://github.com/owner/repo`、未知域名、缺少 owner 或 repo 段 | "请提供合法的 GitHub 仓库地址，格式：`https://github.com/owner/repo`。" |
| `gh` CLI 未安装 / 未认证 | 无法调用 GitHub API | `brew install gh && gh auth login` 后重试 |
| GitHub API 速率限制 | 未认证 60 次/小时（HTTP 403 + `X-RateLimit-Remaining: 0`） | 等待约 1 小时，或 `gh auth login` 后重试（5000 次/小时） |
| 仓库未找到（404）或私有（403） | 地址错误、仓库已删除、或需权限 | 确认拼写、仓库公开、或 `gh auth login` 确保访问权限 |
| 非 AI 开发工具 | README / `package.json` / `pyproject.toml` 中无 Skill / MCP / CLI 标记 | 确认目标仓库类型是 Skill / MCP Server / CLI 后重试 |
| 网络超时 / 脚本崩溃 | 未知错误 | 展示原始错误，询问用户重试或中止 |

### 不会发生的事

评估器**不会编造评分掩盖错误**。任何数据采集失败都会显式报告，不会用猜测数据继续评分。

---

## 参考链接

- [README.md — 文档导航](./README.md)
- [01-evaluation-framework.md — 6 维度详解](./01-evaluation-framework.md)
- [03-comparative-analysis.md — 竞品对比](./03-comparative-analysis.md)
- [项目 SKILL.md — 完整规范](../../SKILL.md)
- [报告模板 — 输出格式](../../templates/report-template.md)
