# opencode-tool-evaluator

> OpenCode skill for evaluating AI dev tools (Skill/MCP Server/CLI) across 6 weighted dimensions with Install/Hold/Skip verdicts.

[![GitHub](https://img.shields.io/badge/GitHub-pointfish6660%2Fopencode--tool--evaluator-181717?logo=github)](https://github.com/pointfish6660/opencode-tool-evaluator) [![MIT License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

## Overview

The Tool Evaluator is an OpenCode skill that helps developers assess whether an AI development tool (Skill, MCP Server, or CLI tool) is worth installing. It scores tools across 6 weighted dimensions and produces a clear Install / Hold / Skip verdict with actionable rationale.

### Key features

- **6-dimension scoring** - evaluates tools on OpenCode compatibility, security/intrusiveness, maintenance health, functional value, docs/UX, and operating cost
- **Weighted verdict system** - fixed weights (15/25/25/15/10/10) produce an overall 0-100 score with 🟢 Install / 🟡 Hold / 🔴 Skip verdict
- **GitHub data scraping** - fetches stars, issues, contributors, last commit, license, and README excerpt via `gh` CLI
- **Security intrusion scanning** - checks for hooks, launchd, settings.json modifications, network calls, elevated privileges
- **Dual-write caching** - each evaluation is written to two locations: a canonical store at the skill source (`$SKILL_ROOT/.omo/evaluations/<repo>.md`, the cross-project history archive and single source of truth) plus a mirror copy in the current project's `<cwd>/.omo/evaluations/<repo>.md`. 30-day freshness window; cache checks read only the canonical store.
- **Evidence-backed output** - each dimension score is supported by concrete evidence and references

## Installation

```bash
ln -s ~/projects/05-tool-evaluator ~/.claude/skills/tool-evaluator
```

## Usage

Trigger the skill with a tool name or GitHub repo URL:

> "评估 chopratejas/headroom 能装吗"

> "Should I install Lum1104/understand-anything?"

> "Headroom 在 OpenCode 上能用吗"

The evaluator will:
1. Scrape GitHub for repository metadata
2. Score across 6 dimensions
3. Generate a weighted verdict
4. Cache the result for future queries

## How It Works

1. **Parse input** - Extract owner/repo from GitHub URL
2. **Cache check** - Reuse existing report if evaluated within 30 days
3. **Run scripts** - Execute github-report.sh and security-scan.sh in parallel
4. **Score 6 dimensions** - Score each dimension 0-100 with evidence-based explanations
5. **Generate report** - Write to `$SKILL_ROOT/.omo/evaluations/<repo>.md` (canonical) and mirror to `<cwd>/.omo/evaluations/<repo>.md`

## Project Structure

```
.
├── SKILL.md                  # OpenCode skill manifest: triggers, workflow, 6-dimension scoring
├── scripts/
│   ├── github-report.sh      # GitHub repo metadata scraper via gh CLI
│   └── security-scan.sh      # Security/intrusiveness scanner
├── templates/
│   └── report-template.md    # Evaluation report output template
├── docs/
│   ├── README.md                    # Documentation hub
│   ├── 01-evaluation-framework.md   # 6-dimension scoring methodology
│   ├── 02-usage-guide.md            # Usage guide and trigger words
│   └── 03-comparative-analysis.md   # vs existing tools comparison
├── .gitignore
├── .omo/
│   ├── evaluations/          # Canonical evaluation archive (cross-project, source of truth)
│   ├── notepads/             # Research notes
│   └── plans/                # Task plans
├── AGENTS.md                 # Project description for OpenCode agents
├── LICENSE                   # MIT
└── README.md                 # This file
```

## License

MIT
