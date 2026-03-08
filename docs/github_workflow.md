# GitHub Workflow

## Repository

- GitHub repository: [BankEncore/bankcore-2](https://github.com/BankEncore/bankcore-2)
- Default branch: `main`
- Visibility: public
- Preferred merge strategy: squash merge

## Default Workflow

Use short-lived branches by default for non-trivial work.

Recommended branch names:

- `feature/<topic>`
- `fix/<topic>`
- `docs/<topic>`
- `chore/<topic>`
- `refactor/<topic>`
- `test/<topic>`

## When Direct Commits To `main` Are Allowed

Direct commits to `main` are reserved for very small, low-risk changes such as:

- repository bootstrap or metadata cleanup
- documentation-only changes
- Cursor rule or skill maintenance
- small `.github` configuration updates

Anything involving application code, database schema, business logic, or UI should use a branch and pull request.

## Commit Policy

Use concise, scoped commit messages:

- `feat(scope): ...`
- `fix(scope): ...`
- `docs(scope): ...`
- `chore(scope): ...`
- `refactor(scope): ...`
- `test(scope): ...`

## Push Policy

- Do not push unless explicitly requested.
- Push feature branches early once work is coherent.
- Never force-push `main`.
- Avoid force-pushing shared branches unless the user explicitly requests it.

## Pull Request Policy

Use pull requests for all meaningful code changes.

Every PR should include:

- a clear summary
- an explicit test plan
- notes on migrations, schema impact, or financial logic risk when relevant
- screenshots for UI changes when helpful

## Cursor Guidance

Project-specific git and GitHub guidance lives in:

- `.cursor/rules/git-github-workflow.mdc`
- `.cursor/rules/git-meta-files.mdc`
- `.cursor/skills/github-workflow/SKILL.md`
- `.cursor/skills/pr-prep/SKILL.md`

These should be kept aligned with the actual repository workflow.
