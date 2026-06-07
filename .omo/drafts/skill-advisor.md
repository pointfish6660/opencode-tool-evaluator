# Draft: skill-advisor（暂定名）— 一个分析 skill/tool 并给出建议的技能

## 起源：用户需求
基于两次实操经验（Headroom、Understand-Anything），用户 m0008 提出：
> "总结当前 skill 分析的经验，制作一个分析 skill 并给出建议的技能，github 上应该有很多类似的 skill，现在系统中可能也有类似的 skill，充分收集信息，然后我们展开讨论，如何开展这个项目。"

## 经验提炼（来自 Headroom + UA 两次分析）

### 我们的实战步骤（回顾哪些动作产生了价值）
| 步骤 | 价值产出 | 评级 |
|------|---------|------|
| GitHub 元数据扫描（stars/license/lang/作者） | 快速分类与可信度初判 | ⭐⭐⭐ |
| 核心原理提取（实际工作机制，不是 README 营销话术） | 识别"看起来酷但实际有限"的项目 | ⭐⭐⭐⭐⭐ |
| 实测数据查找（benchmark、token 消耗、issue 反馈） | 戳破 README 的乐观声明 | ⭐⭐⭐⭐⭐ |
| **OpenCode 兼容性检查**（最关键差异化） | 直接决定"能不能用" | ⭐⭐⭐⭐⭐ |
| 社区情绪（HN/Reddit/Issue#XXX） | 看到真实用户的吐槽 | ⭐⭐⭐⭐ |
| 竞品对比（同类型工具） | 提供替代方案 | ⭐⭐⭐⭐ |
| 最终建议（Install/Hold/Skip + 理由） | 用户真正想要的东西 | ⭐⭐⭐⭐⭐ |

### 哪些步骤是冗余的（可裁剪）
- 纵向历史追溯（除非项目本身有重大架构变更）
- 过度的创始人背景调研（除非是高风险安全项目）
- 长篇叙事化写作（用户只要结论）

## 现有同类工具调研（待补充）

### 系统内已有 skill 对比
| Skill | 定位 | 与新 skill 的差异 |
|-------|------|------------------|
| **skill-creator** | 创建/优化 skill | 完全不同方向 |
| **hv-analysis** | 横纵分析法深度研究报告（PDF） | 相似度最高，但产出是"理解"，不是"决策"；时长几小时，PDF 输出 |
| **research-ideation** | 研究启动/文献综述 | 不同领域 |

### GitHub 生态（待 bg_74fe65b0 返回）

### 评估方法论参考（待 bg_8dac96b7 返回）

## 关键差异化（新 skill 的独特价值）

**与 hv-analysis 的本质区别**：
- hv-analysis：**理解** 一个东西（历史、故事、深度洞察）→ PDF 报告
- skill-advisor：**决策** 一个东西（能不能用、好不好用、值不值得装）→ 简短建议 + 证据

**类比**：
- hv-analysis = 长篇深度报道（New Yorker 文章）
- skill-advisor = 消费者报告（Consumer Reports 评级 + 推荐/不推荐）

## ✅ 已决策的范围（用户 m0014 + m0017 回答）

### 分析对象范围
**Skill + MCP Server + CLI 工具** — 覆盖整个 AI 开发工具链

### 输出形态
**详细分析报告**（2000+ 字，类似刚才 Headroom/UA 的输出）

### 技术形态
**允许 Python/Bash 脚本**（GitHub API, HN API 等）

### 平台针对性
**针对用户当前环境定制**（OpenCode on macOS, ~/.claude/skills/）

### 安全检查
**轻量级**（hooks、launchd、settings.json、文件系统写入）

### 成本评估
**包含运营成本**（token、费用、资源占用）

### 项目命名
**`tool-evaluator`**

---

## 调研发现：GitHub 生态全景（bg_74fe65b0 返回）

### 核心缺口识别（最关键发现）
**当前生态系统中没有任何工具做"安装前的综合评估"。** 现有工具都聚焦某一维度：

| 维度 | 现有工具 | 备注 |
|------|---------|------|
| 仓库健康度 | legends-github, repo-insight, github-cloner | 只看仓库本身，不判断适用性 |
| 代码/架构分析 | repo-insight, repo-value-analysis | "Why > What"，不做安装建议 |
| 已装技能冲突/审计 | skill-audit, claude-skill-audit, Skills_Curator | 装了之后才评估 |
| 安全扫描 | skillchecker, skill-seeker | 单维度，不做质量评估 |
| 跨平台兼容性 | skills-compat-manager | 单维度，很早期 |
| **安装前综合评估** | **❌ 完全空白** | **这是我们的机会** |

### 13 个最相关的现有工具
1. **bjulius/skill-evaluator** v1.2.3 — skill 质量评估（不是仓库评估）
2. **captkernel/Skills_Curator** v4.5+ — 最接近，含安装前 `--check`，但不做仓库本身分析
3. **AntonioTimo/skillchecker** — 偏执级安全审计（35 CRITICAL 规则）
4. **AliceLJY/repo-insight** — 架构分析最强
5. **esaruoho/github-cloner** — 分析仓库生成自定义 skill
6. **notque/claude-code-toolkit** — 6 阶段管线，仓库采纳价值判断
7. **avalonreset/legends-github** — 0-100 评分体系（6 维度）
8. **MJWNA/github-repo-discovery** — 16 信号评分 + AI-slop 惩罚
9. **runesleo/claude-skill-audit** — 健康检查 + 死技能检测
10. **mmantasrrr/skill-seeker** — 发现+安全，元技能
11. **hnaymyh123-henry/skills-compat-manager** — 跨平台兼容层
12. **scottholdren/skill-audit** — 冲突/重叠/冗余检测
13. **FlorianBruniaux/eval-skills** — 14 分评分（6 维度）

### 7 个 awesome-list（都是纯目录，无分析能力）
ComposioHQ (39.2k)、VoltAgent、hesreallyhim、awesome-opencode、alirezarezvani (16k)、borghei、Chat2AnyLLM (10k+)

---

## 调研发现：评估方法论（bg_8dac96b7 返回）

### 4 大类评估框架

#### A. MCP 服务器评估框架（5 个）
- **ChatForest 五因子**：维护/安全/功能/性能/集成
- **NimbleBrain 五维**：来源/功能/安全/维护/文档，按风险加权
- **AgentRank 五信号**：新鲜度25% + Issue健康25% + 反向依赖25% + Stars15% + 贡献者10%
- **Rhumb 工作流中心**：工作流适配/信任类别/能力形状/运行时现实
- **Kamal 三层决策**：数据层 → 编排层 → 自动化表面

#### B. Claude Skill 评估框架（9 个）
- **Skill Grader**：10 轴 A+ 到 F 等级
- **Claude Skill Auditor**：7 维度 0-10 扣分制
- **skill-evaluator (skillport)**：6 维度 1-5 加权
- **Skill Quality Analyzer (DeepToAI)**：5 维度 100 分制 + 三种输出模式
- **skill-metric / gcamilo / Kentobayashi / eval-layer / review-skills**

#### C. OpenSSF Scorecards — 18 项检查
- **整体安全实践**（9 项）：漏洞、依赖更新、维护、安全策略、许可证、CI测试、模糊测试、SAST
- **源码风险**（5 项）：二进制、分支保护、危险工作流、代码审查、贡献者
- **构建风险**（4 项）：固定依赖、Token权限、打包、签名发布

#### D. 社区共识（HN/Reddit）
- MCP 服务器即使不用也消耗 token（上下文污染）
- Skills 用渐进式披露，更轻量
- 优先官方服务器
- 服务器数量控制在 3-6 个

---

## 推荐的 6 维度评估框架（综合所有来源）

| 维度 | 权重 | 检查内容 | 来源参考 |
|------|------|---------|---------|
| **兼容性** | 15% | OpenCode/Claude Code/Cursor 兼容、依赖检查、平台支持 | ChatForest, NimbleBrain |
| **安全** | 25% | hooks/launchd/settings.json 修改、权限范围、license | skillchecker, OpenSSF |
| **维护健康** | 25% | 最后提交、issue 关闭率、贡献者数、反向依赖 | AgentRank, OpenSSF |
| **功能价值** | 15% | 解决什么问题、替代方案、工具数量 vs 质量 | Rhumb, Skill Grader |
| **文档与UX** | 10% | README 质量、示例可运行、CHANGELOG | Skill Grader, NimbleBrain |
| **成本** | 10% | token 成本、订阅费用、资源占用 | 社区共识 |

---

## ✅ 最终决策（m0022-m0029 用户回答）

### 输出形式
**量化评分 + 定性说明**：6 维度每维度 0-100 分，加权总分，给出 🟢/🟡/🔴 verdict + 详细文字说明（消费者报告风格）

### 输出位置
**对话概要 + 文件完整版**：对话中输出 200 字摘要，完整报告写入 `.omo/evaluations/{project-name}.md`

### 缓存策略
**本地缓存 + 时间戳**：分析后写入 `.omo/evaluations/{name}.md`，下次查询先检查是否已存在（带时间戳判断是否需要更新）

### 触发词
- 中文：分析、评估、装不装、值不值得
- 英文：evaluate, install, should I install
- 疑问句：X 好用吗、X 怎么样、X 能在 OpenCode 用吗

### 项目目录结构
- 路径：`~/projects/05-tool-evaluator/`
- 独立 git 仓库
- 参考结构：`~/projects/02-opencode-memory-plugin/`（含完整 docs/ 树和 AGENTS.md）

### Skill 安装方式
**软链接**：`~/.claude/skills/tool-evaluator` → `~/projects/05-tool-evaluator/`（与 khazix-skills 模式一致）

### Git 仓库策略
**GitHub 公开仓库**：`pointfish/opencode-tool-evaluator`，MIT 许可

### 交付物（最终范围）
1. **SKILL.md**（必选）— 主交付物，含触发词、流程、6 维度评估框架、输出模板
2. **scripts/github-report.{sh,py}** — gh CLI 调用，获取 stars/issues/last commit/license/contributors
3. **scripts/security-scan.{sh,py}** — 检查 hooks/launchd/settings.json 修改、文件系统写入、网络外发
4. **项目文档**：README.md、AGENTS.md（参考 02-opencode-memory-plugin）、LICENSE、.gitignore
5. **docs/tool-evaluator/** 文档树（参考 02-opencode-memory-plugin 的 7 文件结构）：
   - 01-evaluation-framework.md（6 维度详解）
   - 02-usage-guide.md
   - 03-comparative-analysis.md（vs 现有工具对比）
   - README.md
6. **templates/report-template.md** — 评估报告输出模板
7. **样本项目验证**：用 Headroom + Understand-Anything 两个已知项目作为测试用例

### 评估工作流
**Prometheus 驱动**：用户说"评估 X" → Prometheus 直接按 SKILL.md 指示执行，重用 Prometheus 现有调研能力，脚本辅助提供原始数据

### 测试策略
**样本项目验证**：用 3-5 个已知项目（Headroom、Understand-Anything 等）作为测试用例，验证 skill 输出质量。不写自动化单元测试。

### 交付范围
**含测试用例的完整版**：一次性交付 SKILL.md + 2 脚本 + 完整文档树 + 报告模板 + 样本验证

---

## 范围边界（最终）

### INCLUDE
- SKILL.md 主文件（6 维度评估框架 + 流程 + 触发词）
- 2 个辅助脚本（GitHub stats + 安全扫描）
- 完整项目文档树（架构/使用/对比分析）
- 报告输出模板
- 软链接到 ~/.claude/skills/
- GitHub 公开仓库 + MIT
- 3-5 个样本项目验证

### EXCLUDE（v2 范围，本计划不包含）
- 自动化 awesome-list 扫描器
- Web UI / Dashboard
- ML 评分模型
- 评分社区共享 / 数据库
- 跨平台支持（非 OpenCode）

---

## 项目目录结构（最终设计）

```
~/projects/05-tool-evaluator/
├── AGENTS.md              # 参考 02-opencode-memory-plugin 的 AGENTS.md
├── README.md              # 项目说明
├── LICENSE                # MIT
├── .gitignore
├── SKILL.md               # 主交付物
├── scripts/
│   ├── github-report.sh   # gh CLI 调用获取仓库元数据
│   └── security-scan.sh   # 仓库 hooks/launchd/settings.json 检查
├── templates/
│   └── report-template.md # 评估报告输出模板
├── docs/
│   └── tool-evaluator/
│       ├── README.md
│       ├── 01-evaluation-framework.md
│       ├── 02-usage-guide.md
│       └── 03-comparative-analysis.md
└── .omo/
    └── evaluations/       # 评估报告缓存
        ├── README.md
        ├── headroom.md
        └── understand-anything.md
```

软链接：`~/.claude/skills/tool-evaluator` → `~/projects/05-tool-evaluator/`
