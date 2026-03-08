---
name: github-workflow
description: Guides branch creation, commits, pushes, and pull requests for this repository. Use when the user asks to create a branch, commit changes, push to GitHub, open a pull request, or set up repository workflow files.
---

# GitHub Workflow

## Defaults

- Repository: `BankEncore/bankcore-2`
- Default branch: `main`
- Workflow: hybrid
- Preferred merge strategy: squash merge

## Branch Strategy

Use short-lived branches by default for meaningful work.

Recommended names:

- `feature/<topic>`
- `fix/<topic>`
- `docs/<topic>`
- `chore/<topic>`
- `refactor/<topic>`
- `test/<topic>`

Direct work on `main` is acceptable only for very small docs, setup, Cursor, or repo-metadata changes.

## Safety Rules

- Never commit unless the user explicitly asks.
- Never push unless the user explicitly asks.
- Never force-push `main`.
- Before a PR, review branch changes, summarize the why, and include a test plan.

## Commit Format

Prefer:

- `feat(scope): summary`
- `fix(scope): summary`
- `docs(scope): summary`
- `chore(scope): summary`
- `refactor(scope): summary`
- `test(scope): summary`

## PR Checklist

- Summary is clear and concise.
- Test plan is explicit.
- Schema or migration impact is called out.
- Financial logic risk is called out when relevant.
- UI changes mention screenshots when helpful.

## Reference

- `docs/github_workflow.md`
- `.cursor/rules/git-github-workflow.mdc`
