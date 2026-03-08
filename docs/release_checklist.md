# Release Checklist

Use this checklist before merging release-critical changes or promoting to production.

## 1) Scope and Governance

- [ ] PR is linked to issue(s)
- [ ] PR summary, risk notes, and rollback notes are complete
- [ ] Any migration/data impact is documented
- [ ] Required approvals are present

## 2) CI and Build Health

- [ ] Required CI checks are green
- [ ] `bin/rails test` (or equivalent CI suite) passes
- [ ] Asset build path is validated (`bin/rails assets:precompile` for release-impacting UI/CSS changes)
- [ ] Any Docker/Kamal build path changes are validated when applicable

## 3) Database and Migration Safety

- [ ] Migration plan reviewed (forward + rollback strategy)
- [ ] No destructive data change without explicit approval and backup/mitigation plan
- [ ] Migration runtime risk and locking behavior considered

## 4) Financial Control Gate (If Applicable)

If release includes transaction/posting/subledger/GL changes:

- [ ] `docs/financial_change_checklist.md` completed
- [ ] Balanced posting invariants verified
- [ ] Immutability and reversal semantics verified
- [ ] Idempotency behavior verified
- [ ] No direct balance mutation introduced

## 5) Operational Readiness

- [ ] Monitoring/alert implications reviewed
- [ ] Runbook/support notes updated if behavior changed
- [ ] Backout/rollback steps documented and tested as feasible

## 6) UI/UX and Communication

- [ ] User-facing changes documented (and screenshots attached where relevant)
- [ ] Stakeholders notified of notable behavior changes

## 7) Final Merge Gate

- [ ] Branch is up-to-date with `main`
- [ ] Merge strategy follows `docs/github_workflow.md` (squash by default)
- [ ] Post-merge verification owner assigned