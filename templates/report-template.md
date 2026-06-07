---
name: {{repo_name}}
github: {{github_url}}
evaluated_at: {{evaluated_at}}
verdict: {{verdict}}
total_score: {{total_score}}
---

## TL;DR

{{tldr}}

## 评分总表

| 维度 | 权重 | 得分 | 加权 | 一句话总结 |
|------|------|------|------|-----------|
| OpenCode 兼容性 | 15% | {{compat_score}} | {{compat_weighted}} | {{compat_summary}} |
| 安全/侵入性 | 25% | {{security_score}} | {{security_weighted}} | {{security_summary}} |
| 维护健康 | 25% | {{maintenance_score}} | {{maintenance_weighted}} | {{maintenance_summary}} |
| 功能价值 | 15% | {{value_score}} | {{value_weighted}} | {{value_summary}} |
| 文档与UX | 10% | {{docs_ux_score}} | {{docs_ux_weighted}} | {{docs_ux_summary}} |
| 运营成本 | 10% | {{cost_score}} | {{cost_weighted}} | {{cost_summary}} |
| **总分** | **100%** | | **{{total_score}}** | |

## 详细评估

### OpenCode 兼容性 — {{compat_score}}/100

{{compat_detail}}

{% if compat_score < 50 %}
> ⚠️ **一票否决触发**: 兼容性得分 {{compat_score}} < 50 → 强制 🔴 Skip
{% endif %}

### 安全/侵入性 — {{security_score}}/100

{{security_detail}}

**检测到的风险点**:

{{risk_points_list}}

### 维护健康 — {{maintenance_score}}/100

{{maintenance_detail}}

### 功能价值 — {{value_score}}/100

{{value_detail}}

### 文档与UX — {{docs_ux_score}}/100

{{docs_ux_detail}}

### 运营成本 — {{cost_score}}/100

{{cost_detail}}

## GitHub 统计

| 指标 | 值 |
|------|------|
| Stars / Forks / Watchers | {{stars}} / {{forks}} / {{watchers}} |
| Issues (Open/Closed) | {{open_issues}} / {{closed_issues}} |
| License / Language | {{license}} / {{language}} |
| Last Commit | {{last_commit_date}} |
| Contributors | {{contributors_count}} |
| Default Branch | {{default_branch}} |
| Created / Updated | {{created_at}} / {{updated_at}} |

## 替代方案

{{alternatives}}

## Verdict 理由

{{verdict_reason}}

## 附录: 评估方法

> 本评估使用 [tool-evaluator](https://github.com/pointfish/opencode-tool-evaluator) 的 6 维度加权评分框架。详见 [评估框架文档](https://github.com/pointfish/opencode-tool-evaluator/blob/main/docs/tool-evaluator/01-evaluation-framework.md)。
