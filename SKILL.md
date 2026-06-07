---
name: tool-evaluator
description: |
  评估 GitHub 上的 AI 开发工具（Skill / MCP Server / CLI），输出 6 维度量化评分（0-100）+ 🟢/🟡/🔴 verdict。
  当用户提供 GitHub 链接并询问是否值得安装、工具是否好用、兼容性如何时触发。
  触发词：评估、分析、装不装、值不值得、好不好用、怎么样、能不能装、evaluate、install、should I install。
  也适用于隐含场景：用户问 "X 好用吗"、"X 能在 OpenCode 用吗"、"该不该装 X"。
---

# Tool Evaluator

A consumer-reports-style evaluator for AI development tools hosted on GitHub. Given a repository URL, the skill produces a 6-dimension weighted score (0-100) and a clear Install / Hold / Skip verdict, written to `.omo/evaluations/{repo-name}.md`.

Detailed methodology, comparisons, and usage notes live under `docs/`.

## 触发条件 (Trigger Rules)

Activate this skill whenever the user message matches any of the patterns below. The input must contain (or imply) a GitHub repository identifier — either a full URL or an `owner/repo` slug.

**Explicit Chinese triggers**
- "评估 X" / "分析 X" / "评测 X"
- "X 装不装" / "该不该装 X" / "X 要不要装"
- "X 值不值得" / "X 值得用吗"
- "X 能不能装" / "X 能用吗"

**Explicit English triggers**
- "evaluate X" / "analyze X" / "review X"
- "should I install X" / "is X worth installing"
- "X compatibility" / "X verdict"

**Question-style triggers (Chinese)**
- "X 好用吗" / "X 怎么样"
- "X 能在 OpenCode 用吗" / "X 在 OpenCode 兼容吗"
- "X 在 Claude Code / Cursor 上能用吗"
- "X 安全吗" / "X 有没有风险"

**Implicit triggers**
- User pastes a `https://github.com/...` URL and asks any variant of "feasibility / usability / compatibility / recommendation" — even if the word "evaluate" is absent.
- User references a tool by name and the surrounding context is about installation, compatibility, or trust.

**Do NOT trigger when**
- The user only asks for a feature explanation (route to general explanation).
- The user asks to compare two already-installed tools (multi-tool comparison is out of scope).
- The user asks to author or edit a skill (route to `skill-creator`).

## 工作流 (Workflow)

The evaluator follows five sequential steps. Each step's output feeds the next; do not skip ahead.

### Step 1: 解析输入

- Accept only `https://github.com/{owner}/{repo}` or the shorthand `{owner}/{repo}`.
- Extract `owner` and `repo`. Strip trailing slashes, `.git`, query strings, and fragments.
- Validate that both segments are non-empty and match `^[A-Za-z0-9._-]+$`.
- If the input is a different host (GitLab, Bitbucket, npm) or a bare tool name without a GitHub path, ask the user for the GitHub URL in the correct format (see 错误处理).

### Step 2: 缓存检查

- Compute the cache path: `.omo/evaluations/{repo}.md` (lowercase repo name, slashes replaced by `-` if any).
- If the file exists, read its frontmatter `evaluated_at` field (ISO 8601).
- If `evaluated_at` is within the last 30 days, present the cached verdict to the user and ask: reuse cached report, or refresh?
- If older than 30 days, missing, or the user requests a refresh → proceed to Step 3.
- Never silently overwrite a cached report without first confirming with the user.

### Step 3: 运行脚本

Run the two data-collection scripts in parallel and capture their JSON output.

- `scripts/github-report.sh {owner}/{repo}` — returns repository metadata: stars, forks, open/closed issues, last commit date, contributors, license, primary language, releases, CHANGELOG presence.
- `scripts/security-scan.sh {owner}/{repo}` — returns a shallow clone inspection: hooks/launchd entries, settings.json mutations, filesystem write paths, outbound network calls, dependency manifest risk signals.

Both scripts must emit strict JSON on stdout. If either exits non-zero or emits unparseable JSON, surface the error to the user (see 错误处理) and stop — do not fabricate scores without data.

### Step 4: 6 维度评估

Combine script output with brief web research (community reception on HN / Reddit / GitHub Issues / project CHANGELOG) to score each of the six dimensions described in the next section.

- Each dimension receives a **0-100 integer score**.
- Each dimension must include a **100-200 word explanation** citing at least one concrete piece of evidence (a metric from Step 3, a quote from an issue thread, a README claim, etc.).
- Compute the weighted total and apply the compatibility veto rule before finalising the verdict.

### Step 5: 生成报告

- Materialise the full evaluation using the format defined in `templates/report-template.md`.
- Write the file to `.omo/evaluations/{repo}.md` with a frontmatter block containing: `repo`, `owner`, `evaluated_at` (ISO 8601), `weighted_total`, `verdict`.
- In the conversation, output a **~200 word summary** containing: repo name, six dimension scores, weighted total, verdict emoji, and the one most-important reason behind the verdict.
- Do not paste the full report into the conversation — the file is the canonical artifact.

## 6 维度评分标准 (Six-Dimension Scoring)

All six dimensions are scored 0-100. Weights sum to 100%.

### Dimension 1: OpenCode 兼容性 — Weight 15%

What to check: dependency on the Task tool (Claude Code specific), hook types used, MCP protocol support, platform requirements (macOS / Linux / Windows), OpenCode-specific API usage, shell assumptions (`bash` vs `zsh` vs `pwsh`).

- 📍 **加分 signals**
  - Uses the standard MCP protocol with no proprietary extensions.
  - Ships an `opencode.json` / `opencode.jsonc` example or documents OpenCode configuration.
  - Platform-agnostic (pure Bash, Node, or Python with no native binaries).
  - Explicitly lists OpenCode / Claude Code / Cursor as supported hosts.
- 📎 **扣分 signals**
  - Imports or invokes the Claude Code `Task` tool with no fallback.
  - Requires platform-specific binaries (`.exe`, `.app`, `.dylib`) without a source build path.
  - Uses undocumented or internal APIs of a specific host.
  - README claims multi-host support but ships host-only hooks.

> ⚠️ **一票否决 (Veto)**: If this dimension scores **< 50**, force the final verdict to 🔴 **Skip** regardless of the weighted total. Compatibility is a hard gate — a tool that cannot run is not installable.

### Dimension 2: 安全 / 侵入性 — Weight 25%

What to check: `settings.json` modification, LaunchAgent / LaunchDaemon installation, filesystem writes outside the project directory, outbound network calls, permission scope escalation, dependency trust (signed releases, verified authors).

- 📍 **加分 signals**
  - Read-only access to the filesystem; writes confined to `.omo/` or an explicit cache dir.
  - Explicit opt-in for any system-level change (no silent install).
  - Sandboxed execution (containers, `nix`, `bwrap`, `seatbelt`).
  - Reproducible builds, signed release artifacts, pinned dependencies.
- 📎 **扣分 signals**
  - Installs system-level hooks (launchd agents, systemd units, cron entries) without consent.
  - Modifies user config files (`~/.config/`, `~/Library/`, `~/.bashrc`, `~/.zshrc`) silently.
  - Makes outbound network calls to non-GitHub hosts without disclosure.
  - Bundles prebuilt binaries of unknown provenance.

### Dimension 3: 维护健康 — Weight 25%

What to check: last commit date, issue close rate, contributor count, dependent repos (via GitHub "Used by"), release cadence, CHANGELOG activity.

- 📍 **加分 signals**
  - Last commit within 1 month; releases at least quarterly.
  - Issue close rate > 80% over the last 100 issues.
  - 10+ contributors or 100+ dependent repos.
  - Maintained CHANGELOG with semver discipline.
- 📎 **扣分 signals**
  - Last commit > 6 months ago (stale).
  - Issue close rate < 50% or many issues remain unanswered > 90 days.
  - Single contributor with no bus-factor mitigation.
  - No CHANGELOG, no releases, only `git push` history.

### Dimension 4: 功能价值 — Weight 15%

What to check: the problem the tool solves, available alternatives, README claims vs measured benchmark data, tool count vs actual quality, novelty of the approach.

- 📍 **加分 signals**
  - Solves a real, well-articulated problem with no direct equivalent.
  - Ships reproducible benchmark data that supports README claims.
  - Multiple demonstrated use cases (not a one-trick tool).
- 📎 **扣分 signals**
  - README overstates capabilities ("agentic", "autonomous") without evidence.
  - Measured data (issue threads, benchmark plots) contradict marketing claims.
  - Single-purpose tool for a niche problem already covered by existing tools.
  - Tool count is inflated by trivial wrappers around the same primitive.

### Dimension 5: 文档与 UX — Weight 10%

What to check: README completeness (problem / install / usage / examples / config / license), runnable examples, CHANGELOG, installation guide quality, screenshot / demo availability.

- 📍 **加分 signals**
  - README covers all six canonical sections with screenshots or animated demos.
  - Examples are copy-paste runnable on a fresh checkout.
  - Bilingual docs (at minimum English + one other) or a clear translation policy.
  - Troubleshooting section that addresses known issues.
- 📎 **扣分 signals**
  - Missing README sections (no install step, no usage examples).
  - Examples reference branches, tokens, or paths that no longer exist.
  - Chinese-only or English-only docs with no translation pathway.
  - No installation guide; user must reverse-engineer setup from issues.

### Dimension 6: 运营成本 — Weight 10%

What to check: token consumption per invocation, subscription or API fees, resource usage (CPU / memory / disk), cold-start time, network dependencies.

- 📍 **加分 signals**
  - Free and open source with no paid upstream service.
  - Runs locally with no network dependency after install.
  - Low resource footprint (completes in seconds, < 100 MB resident memory).
- 📎 **扣分 signals**
  - Requires a paid API subscription (OpenAI, Anthropic, GitHub Enterprise) without a free tier.
  - High token consumption (> 50K tokens per request) due to large context loads.
  - Heavy CPU / GPU / disk usage that would degrade a laptop workload.

### Weighted total

`total = 0.15 * D1 + 0.25 * D2 + 0.25 * D3 + 0.15 * D4 + 0.10 * D5 + 0.10 * D6` (rounded to integer).

## Verdict 规则

Apply in order; the first matching rule wins.

- 🟢 **Install** — weighted total ≥ 80 **AND** Dimension 1 (兼容性) ≥ 50.
- 🟡 **Hold** — weighted total between 60 and 79 (inclusive), **OR** total ≥ 80 but 兼容性 < 50 has been rescued by a planned fork / wrapper (rare; must cite the plan in the report).
- 🔴 **Skip** — weighted total < 60, **OR** 兼容性 < 50 (一票否决 / hard veto).

The verdict emoji and the **single most decisive reason** must appear in both the file report and the conversation summary. If a veto applies, the report must state the veto explicitly rather than implying it from the score.

## 错误处理

Each failure mode has a single canonical response. Use it verbatim and stop the workflow.

| Failure | Response |
|---------|----------|
| GitHub URL format error (not `https://github.com/owner/repo`, unknown host, missing owner or repo segment) | "请提供合法的 GitHub 仓库地址，格式：`https://github.com/owner/repo`，例如 `https://github.com/anthropics/claude-code`。" |
| `gh` CLI not installed / not authenticated | "未检测到 GitHub CLI。请先安装并登录：`brew install gh && gh auth login`，然后重新触发评估。" |
| GitHub API rate limit hit (HTTP 403 with `X-RateLimit-Remaining: 0`) | "已触发 GitHub API 速率限制（未认证 60 次/小时）。请等待约 1 小时，或运行 `gh auth login` 后重试。" |
| Repo not found (HTTP 404) or private (HTTP 403 without rate-limit headers) | "无法访问仓库 `{owner}/{repo}`。请确认：1) 仓库地址拼写正确；2) 仓库为公开；3) 如为私有仓库，请先 `gh auth login` 并确保账号有访问权限。" |
| Repo is not an AI development tool (no Skill / MCP / CLI markers in README, `package.json`, `pyproject.toml`, or language set) | "`{owner}/{repo}` 不像是一个 AI 开发工具（Skill / MCP Server / CLI）。本评估器只覆盖这三类项目，请确认目标仓库类型后重试。" |

For any other unexpected error (network timeout, script crash, unparseable JSON), surface the raw error and ask the user whether to retry or abort. Do not fabricate scores to mask the failure.

## 输出模板引用

The canonical report layout — sections, ordering, evidence slots — lives in `templates/report-template.md`. Always use that template; do not improvise a new structure per evaluation.
