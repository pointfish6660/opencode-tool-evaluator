# AGENTS.md

OpenCode skill (`tool-evaluator`) for evaluating AI dev tools (Skill/MCP Server/CLI) across 6 weighted dimensions. Pure Bash + Markdown, no build step.

## Structure

```
.
├── SKILL.md                  # OpenCode skill manifest: triggers, actions, config
├── scripts/
│   ├── github-report.sh      # GitHub repo metadata scraper
│   └── security-scan.sh      # Security/intrusiveness scanner
├── docs/
│   ├── README.md
│   ├── 01-evaluation-framework.md
│   ├── 02-usage-guide.md
│   └── 03-comparative-analysis.md
├── templates/
│   └── report-template.md    # Evaluation output markdown template
├── .omo/
│   ├── evaluations/          # Canonical evaluation archive (cross-project, source of truth)
│   ├── notepads/             # Research notes and learnings
│   └── plans/                # Task plans and progress
└── README.md                 # User-facing documentation
```

## Key Files

| File | Role |
|------|------|
| `SKILL.md` | OpenCode skill descriptor; defines trigger patterns, action chain, config schema |
| `scripts/github-report.sh` | Fetches stars, issues, contributors, commits via GitHub API |
| `scripts/security-scan.sh` | Scans for hooks/launchd/settings.json modifications and network calls |
| `templates/report-template.md` | Markdown template for structured evaluation output |
| `docs/01-evaluation-framework.md` | 6-dimension scoring rubrics and weight configuration |
| `docs/03-comparative-analysis.md` | Comparison against 13 existing tools |

## Conventions

- **Markdown only** for docs and templates — no HTML, no LaTeX
- **Bash scripts** for all automation — no Python, Node, or other runtime dependencies
- **No build step** — SKILL.md is consumed directly by OpenCode; scripts run as-is
- **Dual-write caching** — every evaluation writes two copies: canonical at `$SKILL_ROOT/.omo/evaluations/<repo>.md` (cross-project archive, single source of truth) + mirror at `<cwd>/.omo/evaluations/<repo>.md` (current-project copy). Cache checks read only the canonical copy.
- **Evidence** — each score must be backed by a reference or inline data in the report

## Common Tasks

- **Add a scoring dimension** — edit `docs/01-evaluation-framework.md` and `SKILL.md`
- **Tweak verdict thresholds** — edit `SKILL.md` (Verdict 规则 section)
- **Fix GitHub scraping** — edit `scripts/github-report.sh`
- **Change output format** — edit `templates/report-template.md`
- **Update skill triggers** — edit `SKILL.md` (触发条件 section)
