# Contributing to BankCORE / BankEncore

Thanks for contributing.

This repository is a core-banking codebase and follows strict financial invariants and governance rules. Please read this guide before opening a pull request.

## First Principles

All contributions must preserve:

- **Balanced posting** (`SUM(debits) == SUM(credits)`)
- **Immutability** of posted records (corrections via reversal, never mutation)
- **Atomic posting** (all-or-nothing)
- **Derivable balances** (posting history is authoritative)
- **Idempotency** (duplicate requests must not duplicate postings)

See also:

- `AGENTS.md`
- `docs/github_workflow.md`
- `docs/00_initial_core_references/financial_invariants.md`
- `docs/00_initial_core_references/posting_templates.md`

## Contribution Workflow

For non-trivial work, follow **Issue → Branch → PR**:

1. Open or confirm a GitHub issue.
2. Create a short-lived branch from `main`.
3. Implement and validate changes.
4. Open a PR linked to the issue.

Branch name suggestions:

- `feature/<issue>-<topic>`
- `fix/<issue>-<topic>`
- `chore/<issue>-<topic>`
- `docs/<issue>-<topic>`
- `refactor/<issue>-<topic>`
- `test/<issue>-<topic>`

Use commit format: `type(scope): summary`.

## What Counts as Non-Trivial

A change is non-trivial if it touches any of the following:

- app/runtime logic
- dependencies
- CI/build/deploy scripts
- migrations
- transaction/posting/subledger/GL behavior
- more than 3 files (excluding docs/metadata-only edits)

## Pull Request Requirements

Every PR should include:

- concise summary
- linked issue
- exact validation commands executed
- migration/data impact notes (or `None`)
- financial logic risk notes (or `None`)
- rollback/remediation notes
- screenshots for UI changes when applicable

Use `.github/pull_request_template.md`.

## Financial Change Expectations

If your PR touches transaction/posting/subledger/GL flow, complete:

- `docs/financial_change_checklist.md`

And confirm in the PR that:

- balanced posting is preserved
- immutability/reversal semantics are preserved
- idempotency behavior is preserved

## Release Readiness

Before merge/deploy, coordinate against:

- `docs/release_checklist.md`

## Code Style and Scope

- Keep changes focused and minimal.
- Avoid unrelated refactors in feature/fix PRs.
- Preserve ledger boundaries:
  - Operational Layer: what happened
  - Posting Engine: money effect
  - Subledger: customer effect
  - GL Layer: bank accounting effect