# Financial Change Checklist

Use this checklist for any change affecting transaction, posting engine, subledger, GL, account balances, reversal flows, or idempotency.

## 1) Classification

- [ ] Change touches financial flow (transaction/posting/subledger/GL)
- [ ] Related issue(s) linked in PR
- [ ] Affected components identified (services/models/jobs/controllers)

## 2) Invariants (Mandatory)

- [ ] **Balanced Posting:** every posting batch remains balanced (`SUM(debits) == SUM(credits)`)
- [ ] **Immutability:** posted rows are not updated/deleted in-place
- [ ] **Reversals:** corrections use explicit inverse posting batches linked to original postings
- [ ] **Atomicity:** posting operations remain all-or-nothing
- [ ] **Derivable Balances:** no direct mutation that bypasses posting history authority
- [ ] **Idempotency:** duplicate requests do not create duplicate financial effects

## 3) Ledger Boundary Integrity

- [ ] Operational layer changes do not leak posting/GL concerns into wrong layer
- [ ] Posting engine remains source of monetary truth
- [ ] Subledger and GL projections stay consistent with posting output

## 4) Data and Migration Risk

- [ ] Schema/data changes reviewed for financial integrity risk
- [ ] Backfill/reconciliation strategy documented when needed
- [ ] Rollback/remediation path documented

## 5) Verification Evidence

- [ ] Automated tests added/updated for changed financial behavior
- [ ] Negative-path tests cover failure/rollback conditions
- [ ] Idempotency tests cover duplicate request scenarios
- [ ] Reversal tests verify inverse-link behavior and no mutation of original posted rows

## 6) PR Disclosure

- [ ] PR includes explicit "Financial logic risk" section
- [ ] PR includes exact commands/checks run
- [ ] PR confirms invariants preserved (or clearly states intentional migration plan)

## 7) Sign-off

- [ ] Reviewer with financial-domain context has approved
- [ ] Release checklist (`docs/release_checklist.md`) completed for release-impacting changes