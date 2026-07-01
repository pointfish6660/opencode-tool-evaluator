---
name: MinerU 评估与对比分析
evaluated_at: 2026-06-29T00:00:00Z
sources:
  - .omo/evaluations/mineru.md
  - .omo/evaluations/mineru-vs-markitdown.md
---

# MinerU 评估与对比分析

> 本文档整合了两份 MinerU 相关评估：
> 1. **MinerU 独立评估**（[tool-evaluator](https://github.com/pointfish/opencode-tool-evaluator) 6 维度框架，88/100，🟢 Install）
> 2. **MinerU vs MarkItDown 对比评估**（场景决策矩阵与共存方案）

---

## 第一部分：MinerU 独立评估

### TL;DR

MinerU 是上海人工智能实验室 (Shanghai AI Lab / OpenDataLab) 开源的文档解析工具，诞生于 InternLM（书生·浦语）大模型预训练过程，专门解决科学文献的版面解析与符号转换问题。它将 PDF / 图片 / DOCX / PPTX / XLSX 转换为 LLM 可用的 Markdown / JSON，在中文学术 PDF、公式识别、表格结构化还原方面处于开源 SOTA 水平。当前版本 3.4.0（2026-06-18），OmniDocBench v1.6 跑分：pipeline 后端 86.47，hybrid-high 后端 95.39。71.7K Stars、30 位贡献者、Issue 中位关闭时长仅 3.3 小时，维护极其健康。许可证已从 AGPL-3.0 升级为 Apache-2.0（含附加条款），并移除了 PyMuPDF 依赖，商业可用性大幅提升。

**Verdict：🟢 值得安装**——尤其适合中文学术 PDF 解析、RAG 知识库构建场景。

### 评分总表

| 维度 | 权重 | 得分 | 加权 | 一句话总结 |
|------|------|------|------|-----------|
| OpenCode 兼容性 | 15% | 78 | 11.7 | 标准 CLI/Python 工具，平台无关，可被任意 host 调用，但 torch 依赖较重 |
| 安全/侵入性 | 25% | 88 | 22.0 | 零 hook、零系统侵入，仅下载模型文件，许可证已转 Apache-2.0 |
| 维护健康 | 25% | 96 | 24.0 | 71.7K stars、Issue 中位关闭 3.3h、平均 3.9 天一个 release，顶级维护 |
| 功能价值 | 15% | 92 | 13.8 | 中文学术 PDF + 公式/表格 SOTA，多后端架构，OmniDocBench 95.39 |
| 文档与UX | 10% | 90 | 9.0 | 双语文档、CLI+FastAPI+Gradio 三接口、在线 Demo、可视化 |
| 运营成本 | 10% | 72 | 7.2 | 免费本地运行，但模型大(2-20GB)、CPU 慢、内存需求高 |
| **总分** | **100%** | | **88** | |

### 详细评估

#### OpenCode 兼容性 — 78/100

MinerU 是一个标准 Python CLI / 库工具，不依赖任何特定 AI host（Claude Code / Cursor / OpenCode）的私有 API，也不使用 Task 工具或 host-only hook。它通过 `pip install mineru` 安装，提供 `mineru` 命令行入口、FastAPI 服务端（`mineru-api`）和 Gradio WebUI，因此可以被任意 host 上的 skill / MCP server / 脚本通过子进程或 HTTP 调用，移植性极强。代码是纯 Python，跨平台支持 Linux（2019+）/ Windows / macOS 14.0+，无原生二进制绑定（`.exe`/`.dylib`）。

扣分点在于依赖链：MinerU 依赖 PyTorch（2.2~2.6）、CUDA（11.8/12.4/12.6）以及一系列检测/OCR 模型，安装时需拉取约 2–20GB 模型权重，在资源受限或无 GPU 的环境（如纯 CPU Mac）上安装与运行成本较高，且 torch 生态可能与项目既有依赖冲突。它本身不修改任何 host 配置（`opencode.json` / `settings.json`），只在自身缓存目录写模型文件。综合看，它不是为 OpenCode 量身定制的 skill/MCP，但作为 CLI 工具完全可被 OpenCode 工作流编排调用，兼容性良好。

#### 安全/侵入性 — 88/100

安全扫描结果非常干净：`hooks_count = 0`、`launchd_installed = false`、`modifies_settings_json = false`、`writes_user_files = false`、`elevated_privileges = false`、`prebuilt_binaries = false`。MinerU 不安装任何系统级 hook、守护进程或定时任务，不修改用户 shell 配置（`~/.zshrc` / `~/.bashrc`），不写入项目目录之外的任何用户文件。文件输出严格限定在用户指定的输出目录与模型缓存目录。

唯一的运行时信号是 `network_calls = true`：首次运行需从 HuggingFace / ModelScope（均为可信源）下载模型权重，属于可预期的、显式的网络行为，且官方明确支持「离线部署流程」（成功部署后无需联网）。更重要的积极变化是：v3.1.0（2026-04-14 提交 `e148afa`）起，**许可证从 AGPL-3.0 升级为 Apache-2.0（含附加条款），并彻底移除了 PyMuPDF（AGPL）依赖**，消除了此前最大的商业合规顾虑。代码库无预编译二进制，模型权重来自机构自有训练。风险等级评定为 medium，仅因外部网络请求，实际侵入性极低。

**检测到的风险点**:
- 发起外部网络请求（首次下载模型权重，来自 HuggingFace / ModelScope，可信源；支持离线部署）
- 无 hook / launchd / 系统配置修改 / 用户文件写入 / 提权操作（均为阴性）

#### 维护健康 — 96/100

MinerU 是目前开源文档解析领域维护最活跃的项目之一，数据全面优异：

- **Stars / Forks**：71,773 / 6,022，远超同类（Marker 约 20K、Docling 约 10K 量级）。
- **Issue 响应**：累计 3,877 closed / 29 open（关闭率 99.3%），**中位关闭时长 3.3 小时**，P90 为 149.7 小时——这在万人级开源项目中极为罕见，说明核心维护者（@myhloli 等）持续在场且响应极快。
- **Release 节奏**：10 个 release，**平均间隔仅 3.86 天**，最新 `mineru-3.4.0-released`（2026-06-18），从 1.x（magic-pdf）到 3.x（mineru）一路快速迭代，持续引入新能力（VLM 后端、hybrid 解析、DOCX/PPTX/XLSX 原生解析）。
- **贡献者**：30 位，机构背书明确（上海 AI Lab / OpenDataLab，InternLM 团队），非单人项目，bus-factor 风险低。
- **仓库活跃度**：最近一次 push 2026-06-27（评估前 2 天），处于高度活跃状态。

唯一小瑕疵：仓库无独立 CHANGELOG 文件，但 GitHub Release Notes 记录详尽（含中英双语、破坏性变更标注），可作替代。

#### 功能价值 — 92/100

MinerU 解决的核心问题——把复杂版面文档（尤其学术 PDF）高保真转成 LLM 可用结构化数据——是一个被反复验证的真实刚需，且在中文学术、公式密集场景下至今没有完全等价的开源替代。能力清单扎实且经基准验证：

- **多格式**：PDF / 图片 / DOCX / PPTX / XLSX 原生解析（DOCX 端到端解析无幻觉，比「先转 PDF 再解析」快数十倍）。
- **版面解析**：去除页眉/页脚/脚注/页码，支持单栏、多栏、复杂版面的人类阅读顺序输出；doclayout_yolo 模型持续升级。
- **公式/表格**：公式自动转 LaTeX（unimernet 模型），表格转 HTML，扫描件下尝试结构化还原；支持表内图片/公式、印章文字、竖排文字、跨页表格合并。
- **OCR**：自动检测扫描件/乱码 PDF 并启用 OCR，支持 109 种语言。
- **图片处理**：自动识别图片区域、裁剪导出并嵌入 Markdown。
- **多后端**：pipeline（纯 CPU 可跑，86.47 分）/ hybrid（VLM，medium 95.26 / high 95.39 分）/ vllm / http-client，适配不同硬件。
- **基准验证**：OmniDocBench v1.6 上 hybrid-high 达 95.39，SOTA 水平；EulerAI 第三方测评结论为「最佳工具」，英文 edit distance 0.15、中文 0.357 均领先；公式场景平衡性优于 olmOCR。

轻微扣分：相比 Marker，MinerU 在纯速度上不占优（EulerAI 测试中耗时最长），Marker 在表格版面渲染上略胜；但这些场景下 MinerU 的精度和中文优势更突出。

#### 文档与UX — 90/100

文档体系完整且双轨：

- **官方文档站**（opendatalab.github.io/MinerU）+ GitHub README，覆盖项目介绍、快速开始、详细用法、安装指南、许可证，六大基本章节齐备。
- **中英双语**：README、Release Notes、部分文档均有中文版，对中文学术用户极为友好。
- **多入口**：内置 CLI（`mineru` 命令）、FastAPI 服务（`mineru-api`，含同步/异步任务端点）、Gradio WebUI，以及面向多服务多 GPU 统一路由的 `mineru-router`，适配本地/服务端/集群多种部署形态。
- **在线 Demo**：mineru.net / HuggingFace / ModelScope 提供零安装试用。
- **可视化**：支持版面可视化、span 可视化，便于质检。
- **UX 细节**：1.3.0 起加入实时进度条，等待不再痛苦；3.x 大量参数可直接命令行/API 设置，无需手改 JSON 配置。

扣分点：安装环节涉及 torch/CUDA 版本矩阵（Python 3.10–3.13、torch 2.2–2.6、CUDA 11.8/12.4/12.6），对新手存在一定摩擦；Windows 上 Python 3.13 因 `ray` 依赖受限至 3.10–3.12。

#### 运营成本 — 72/100

MinerU 完全免费、本地运行，无任何付费 API 订阅，这是显著优点。但「重模型工具」的资源代价不可忽视：

- **磁盘**：pipeline 后端需 ≥20GB（SSD 推荐），模型权重体积大；hybrid/vlm 的 http-client 模式仅需 2GB。
- **内存**：最低 16GB RAM，推荐 32GB+。
- **GPU**：pipeline 需 Volta 及以上 4GB VRAM；vlm 需 8GB（Turing+）；http-client 不需要本地 GPU。Apple Silicon（MPS）加速已优化。
- **CPU 模式**：支持纯 CPU，但速度慢——276 页约 1–3 小时（pipeline 后端）。3.3 起 `effort=medium` 模式可提速 35%–220%（macOS 文本 PDF 提速达 220%）。
- **冷启动**：模型加载耗时长，不适合频繁短任务；建议用 FastAPI 常驻服务模式。

综合：对个人/学术用户（有 Mac 或中端 GPU）成本可接受；对无 GPU 的笔记本，CPU 全量解析长文档会显著拖慢工作流。

### GitHub 统计

| 指标 | 值 |
|------|------|
| Stars / Forks / Watchers | 71,773 / 6,022 / 261 |
| Issues (Open/Closed) | 29 / 3,877 |
| License / Language | MinerU Open Source License (Apache-2.0 + 附加条款) / Python |
| Last Commit | 2026-06-18 |
| Contributors | 30 |
| Default Branch | master |
| Created / Updated | 2024-02-29 / 2026-06-29 |
| Issue 中位关闭时长 | 3.3 小时 |
| 最老 Open Issue | 548 天 |
| Release 数 / 最新版本 | 10 / mineru-3.4.0-released |
| Release 节奏 (平均间隔) | 3.86 天 |

### 替代方案

| 工具 | 定位 | 优势 | 劣势 | 许可证 |
|------|------|------|------|--------|
| **MinerU** | 中文学术 PDF + 多格式 | 中文/公式 SOTA、多后端、机构维护 | CPU 慢、依赖重 | Apache-2.0（附加条款） |
| **Marker** | 通用 PDF 解析 | 速度快（H100 上 0.18s/页）、质量高 | GPL-3.0 + 模型 CC-BY-NC-SA（商用受限） | GPL-3.0 |
| **Docling** (IBM) | 多格式文档解析 | MIT 许可、格式覆盖广（含 JATS/USPTO XML） | 复杂表格/中文略弱 | MIT |
| **olmOCR** (AI2) | PDF/图片 OCR | 公式识别强、Apache-2.0 | 中文公式弱、单一格式 | Apache-2.0 |
| **MarkItDown** (微软) | 多格式转 MD | 最快、覆盖音视频/YouTube | 图片/表格/公式识别最差、版面乱 | MIT |

> 选型建议：中文学术 PDF / 公式密集 → MinerU；追求速度且能接受 GPL → Marker；需 MIT 许可商用 → Docling；仅需快速文本提取 → MarkItDown。

### Verdict 理由

🟢 **Install（88/100）**。MinerU 在六个维度上均无短板：兼容性 78（>50，未触发一票否决）、安全 88、维护 96、功能 92、文档 90、成本 72，加权 88。

**最决定性的理由**：它是中文学术 PDF 解析领域目前精度最高、维护最活跃、且已解除 AGPL 商用枷锁（转 Apache-2.0）的开源方案——OmniDocBench 95.39 分、71.7K stars、Issue 中位关闭 3.3 小时，三项指标在同类中均无对手。对于 RAG 知识库构建、学术文献数字化、论文公式/表格提取等场景，它几乎是默认选择。

**需注意的前提**：CPU 全量解析长文档较慢（276 页 1–3 小时），且有 16GB+ 内存、2–20GB 磁盘的硬件门槛；建议在有 GPU 或 Apple Silicon 的机器上使用 hybrid 后端，或用 FastAPI 常驻服务 + batch 模式摊薄冷启动成本。若环境受限且只需英文文档，Marker / Docling 是更轻量的备选。

---

## 第二部分：MinerU vs MarkItDown 对比评估

### TL;DR

MinerU 和 MarkItDown 不是同一赛道的竞品，而是**精度优先 vs 速度优先**的两端。

- **MarkItDown（已装 v0.1.6）**：微软出品，MIT 许可，纯 Python 轻量依赖（6 个包），秒级转换任何格式，但对复杂版面、公式、表格、图片的识别能力弱——它本质是"格式转换器"，不是"文档理解引擎"。
- **MinerU（v3.4.0 未装）**：上海 AI Lab 出品，Apache-2.0，重模型依赖（torch + 2-20GB 权重），分钟到小时级转换，但复杂学术 PDF 的版面、公式、表格解析达到 SOTA——它是"文档理解引擎"。

**结论：两者互补**。日常轻量提取继续用 MarkItDown；中文学术 PDF、公式密集、RAG 高质量知识库场景加装 MinerU。不必二选一。

### 本地实测环境对比

| 项目 | MarkItDown（已装） | MinerU（未装） |
|------|-------------------|----------------|
| 本地版本 | 0.1.6（2024 年底） | 3.4.0（2026-06-18） |
| 安装路径 | `~/projects/skills/khazix-skills/markitdown/.venv` | — |
| 许可证 | MIT | Apache-2.0（附加条款） |
| 依赖体积 | ~6 个纯 Python 包 | PyTorch + 2-20GB 模型权重 |
| 磁盘占用 | <50MB | 2GB（http-client）/ 20GB（pipeline） |
| 运行时内存 | <100MB | 16GB+（推荐 32GB） |
| GPU 需求 | 不需要 | 可选（CPU 可跑，GPU 大幅提速） |
| 冷启动 | 秒级 | 分钟级（模型加载） |

### 六维度横向对比

| 维度 | MarkItDown | MinerU | 差异解读 |
|------|-----------|--------|---------|
| **OpenCode 兼容性** | 95 | 78 | MarkItDown 依赖极轻、纯 Python、零 GPU 依赖，任何环境秒装秒用；MinerU 的 torch+CUDA 依赖链在受限环境下是负担 |
| **安全/侵入性** | 98 | 88 | 两者都零侵入（无 hook/守护进程/配置修改）。MarkItDown 连模型下载都不需要，网络请求最少 |
| **维护健康** | 85 | 96 | MarkItDown 背靠微软（microsoft/markitdown，~50K stars），维护稳定但本地版本较旧（0.1.6）；MinerU 71.7K stars、Issue 中位关闭 3.3h、3.9 天/release，更活跃 |
| **功能价值** | 60 | 92 | **核心差距在此**。MarkItDown 覆盖格式广（含音频/YouTube）但解析浅；MinerU 深度理解版面、公式、表格，精度 SOTA |
| **文档与UX** | 80 | 90 | MarkItDown 文档简洁但够用、CLI 一行搞定；MinerU 双语文档 + CLI/API/WebUI 三接口 + 在线 Demo + 可视化 |
| **运营成本** | 95 | 72 | MarkItDown 零成本（秒级、<100MB）；MinerU 高成本（分钟级、16GB+ RAM、2-20GB 磁盘） |

> 注：MarkItDown 分数为对比中的相对评估值，非独立 tool-evaluator 跑出的完整报告。

### 第三方实测数据（EulerAI 基准）

EulerAI 用 9 页英文 + 中文 PDF 对 MinerU、Marker、Docling、MarkItDown、olmOCR 做了横向测评，结论清晰：

| 指标 | MarkItDown | MinerU | Marker | Docling |
|------|-----------|--------|--------|---------|
| **速度** | 🥇 最快 | 🐢 最慢 | 中等 | 中等 |
| **图片/表格/公式识别** | ❌ 最差 | ✅ 优秀 | ✅ 优秀 | ⚠️ 复杂表格弱 |
| **版面还原** | ❌ 混乱、不宜读 | ✅ 高保真 | ✅ 良好 | ⚠️ 一般 |
| **中文场景 edit distance** | — | 🥇 0.357（最佳） | 中等 | — |
| **英文场景 edit distance** | — | 🥇 0.15（最佳） | 中等 | — |
| **公式识别** | ❌ 无 | ✅ LaTeX SOTA | ✅ 良好 | ⚠️ 一般 |

**EulerAI 原话**："MarkItDown was the fastest, but its recognition performance was the poorest, especially for images, tables, and formulas. The layout of the extracted content was messy and not suitable for human reading."

### 场景决策矩阵

| 你的场景 | 推荐 | 理由 |
|---------|------|------|
| 快速提取 PPTX/DOCX/XLSX 文字喂给 LLM | **MarkItDown** | 秒级完成，结构化文档原生解析已够用 |
| 音频转文字、YouTube 链接提取 | **MarkItDown** | MinerU 不支持这些格式 |
| 中文学术 PDF 转 Markdown（含公式/表格） | **MinerU** | 公式→LaTeX、表格→HTML，SOTA 精度，MarkItDown 此场景几乎不可用 |
| 构建高质量 RAG 知识库（学术文献） | **MinerU** | 版面理解 + 阅读顺序 + 图片裁剪嵌入，下游检索质量碾压级差距 |
| 扫描件 / 图片型 PDF OCR | **MinerU** | 109 语言 OCR + 版面还原，MarkItDown 无 OCR 能力 |
| 批量处理大量短文档（<10 页） | **MarkItDown** | MinerU 冷启动成本高，短文档不划算 |
| 无 GPU 的 MacBook 轻量使用 | **MarkItDown** | MinerU CPU 模式 276 页需 1-3 小时 |
| 有 GPU / Apple Silicon 的深度文档处理 | **MinerU** | hybrid 后端 + effort=medium 提速 35-220%，精度无损 |
| 需要图片内容描述（alt text） | **两者配合** | MarkItDown 调 GLM-4.6V 描述图片；MinerU 负责版面/公式/表格 |

### 能力边界速查

#### MarkItDown 0.1.6 能做的

- ✅ PDF / DOCX / PPTX / XLSX / HTML / CSV / JSON / XML / ZIP / EPub → Markdown
- ✅ 音频转文字（需 transcription 后端）
- ✅ YouTube 链接提取字幕
- ✅ 图片描述（需接 GLM-4.6V，Python API 调用，非 CLI 原生）
- ✅ 秒级处理，资源占用极低

#### MarkItDown 0.1.6 做不到的

- ❌ 公式识别（不转 LaTeX，公式变乱码或丢失）
- ❌ 表格结构化还原（复杂表格变扁平文本）
- ❌ 版面阅读顺序还原（多栏文档顺序混乱）
- ❌ OCR（扫描件 / 图片型 PDF 无法处理）
- ❌ 图片区域自动裁剪导出
- ❌ 数学符号 / 化学方程式保真

#### MinerU 3.4.0 能做的（MarkItDown 做不到的）

- ✅ 公式 → LaTeX（unimernet 模型）
- ✅ 表格 → HTML（含扫描件结构化还原）
- ✅ 复杂版面阅读顺序（单栏/多栏/混排）
- ✅ 扫描件 / 乱码 PDF 自动 OCR（109 语言）
- ✅ 图片区域自动识别、裁剪、嵌入 Markdown
- ✅ DOCX 端到端原生解析（无幻觉，比转 PDF 快数十倍）
- ✅ OmniDocBench 95.39 分（SOTA）

#### MinerU 做不到的（MarkItDown 能做的）

- ❌ 音频处理
- ❌ YouTube 链接提取
- ❌ HTML / CSV / JSON / XML / ZIP 原生解析
- ❌ 秒级轻量转换

### 是否需要加装 MinerU？——决策建议

**如果你的主要痛点是以下任一，值得加装**：

1. 中文学术 PDF（论文、教材）需要转成可读 Markdown，且含大量公式/表格
2. 正在构建 RAG 知识库，文档解析质量直接影响检索效果
3. 需要处理扫描件 / 图片型 PDF（MarkItDown 完全无能为力）
4. 有 GPU 或 Apple Silicon 机器，愿意承担一次性 2-20GB 模型下载

**如果以下描述更像你，维持现状即可**：

1. 主要处理原生 PPTX / DOCX / XLSX（非扫描件），只需提取文字
2. 对公式 / 表格精度无要求
3. 机器资源受限（无 GPU、内存 <16GB、磁盘紧张）
4. 需要处理音频 / YouTube / HTML 等 MinerU 不支持的格式

### 共存方案（推荐）

两者不冲突，可按场景自动路由：

```
输入文件类型判断：
├─ 音频 / YouTube / HTML / CSV / JSON → MarkItDown
├─ 原生 DOCX/PPTX/XLSX 且无公式表格 → MarkItDown（快）
├─ 学术 PDF / 扫描件 / 公式密集 / 多栏版面 → MinerU（准）
└─ 不确定 → 先 MarkItDown 秒出，质量不够再用 MinerU 重跑
```

在 OpenCode skill 层，可以写一个 `pdf-to-markdown` 路由 skill：检测输入特征（是否扫描件、是否含公式、页数），自动选择后端。

---

## 附录

### 评估方法

- 第一部分使用 [tool-evaluator](https://github.com/pointfish/opencode-tool-evaluator) 的 6 维度加权评分框架。详见[评估框架文档](https://github.com/pointfish/opencode-tool-evaluator/blob/main/docs/01-evaluation-framework.md)。
- 第二部分基于 MinerU 独立评估（88/100，🟢 Install）+ MarkItDown 本地 v0.1.6 实测 + microsoft/markitdown 仓库。

### 评估依据

- MinerU GitHub: https://github.com/opendatalab/MinerU
- MarkItDown GitHub: https://github.com/microsoft/markitdown
- 第三方基准：EulerAI doc-parser-benchmark（2025）
- MinerU 官方基准：OmniDocBench v1.6
