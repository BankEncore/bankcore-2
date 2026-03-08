---
name: pr-prep
description: Prepares pull request titles, summaries, and test plans for this repository. Use when the user asks to open a PR, summarize a branch, or format a PR description for GitHub.
---

# PR Preparation

## Output Format

Use this structure:

```markdown
## Summary
- <one to three bullets>

## Test plan
- [ ] <test or verification step>
```

## Requirements

- Focus on why the branch exists, not a file-by-file changelog.
- Mention migrations, schema impact, or financial logic risk when relevant.
- Mention UI screenshots when the branch changes the interface.
- Keep the title concise and aligned with the branch purpose.

## Title Style

Prefer a short imperative title, usually matching commit/branch intent.

Examples:

- `Add GitHub workflow guidance`
- `Harden posting idempotency checks`
- `Update account review workstation`

## Reference

- `docs/github_workflow.md`
- `.github/pull_request_template.md`
