# Posting Compliance Matrix

## Scope

This matrix reviews current implementation alignment against:

- `docs/00_initial_core_references/posting_lifecycle.md`
- `docs/00_initial_core_references/posting_engine_rules.md`

It focuses on practical compliance of the current posting engine, reversal flow, account/GL projection, and related control services.

## Rating Key

- `Complete` — implemented and broadly aligned with the reference intent
- `Partial` — implemented in part, but missing important enforcement or lifecycle detail
- `Gap` — not materially implemented yet

---

## Compact Matrix

| Area / Rule | Status | Current Evidence | Gap / Risk | Recommended Fix |
|---|---|---|---|---|
| Balanced posting batches | Complete | `PostingValidator` checks debit total equals credit total before commit; posting runs inside a DB transaction | Low | Keep as core invariant and add regression coverage around template drift |
| Positive leg amounts | Complete | `PostingValidator` and `PostingLeg` both enforce positive amounts | Low | Keep dual validation at service + model layer |
| Supported MVP target scopes | Complete | `PostingEngine` builds only `account` and `gl` legs, matching MVP boundary | Low | Extend only when teller/cash scope is intentionally added |
| Account-side projection from posting | Complete | `AccountProjector` derives `account_transactions` from account-facing `posting_legs` | Low | Maintain projection-only design |
| GL-side projection from posting | Complete | `JournalProjector` derives `journal_entries` and `journal_entry_lines` from GL-facing `posting_legs` | Low | Maintain one-journal-per-batch MVP rule |
| No direct balance authority outside posting history | Complete | `BalanceRefreshService` rebuilds from `account_transactions`; `account_balances` behaves as projection/cache | Low | Keep using `account_transactions` as source of truth |
| Reversal uses new linked batch | Complete | `ReversalService` creates a new posting via `PostingEngine.post!` and links with `reversal_of_batch_id` | Low | Add more policy checks as reversal scope expands |
| Atomic posting of batch, legs, journal, account projection | Partial | `PostingEngine.post!` wraps posting, projections, and audit emission in one transaction | Good core behavior, but not all related side effects are included | Keep transaction boundary around all required posting effects |
| Atomic fee/interest linkage rows | Partial | `FeePostingService` and `InterestAccrualService` post first, then create linkage rows afterward | If linkage row creation fails, financial posting is already committed | Wrap posting + linkage row creation in one outer transaction or move linkage creation into posting workflow |
| Idempotent duplicate replay | Partial | Existing posted batch is returned when `idempotency_key` already exists | Safe for exact retry, but no payload comparison | Store/compare semantic fingerprint or operational request payload |
| Idempotency conflict rejection | Gap | Same key with different payload is not rejected | Silent cross-request collision can return wrong prior batch | Add semantic payload comparison and raise conflict on mismatch |
| Business date validation | Complete | `PostingValidator` requires open business date | Low | Keep current rule and expand later for governed override/backdating windows |
| Posting reference uniqueness | Gap | `posting_reference` exists on `posting_batches`, but `PostingEngine` does not populate it | Traceability does not meet reference rule fully | Generate unique posting reference for every committed batch |
| Exactly one primary posting batch per operational event | Partial | `PostingEngine` creates one batch per created `BankingTransaction` | Works for current engine path, but not strongly enforced by DB constraint or richer workflow state machine | Add uniqueness/consistency rule if multiple posting paths are introduced |
| Traceability from source event to financial output | Partial | `PostingBatch.operational_transaction_id`, `AccountTransaction.posting_batch_id`, and `JournalEntry.posting_batch_id` provide good linkage | No richer reference registry, no dedicated transaction references, limited operational metadata | Add `transaction_references` or stronger reference model when external flows mature |
| Operational lifecycle states (`draft -> validated -> approved -> posted`) | Gap | Current flow generally goes straight to posting on success | Lifecycle doc expects explicit intermediate states and exception paths | Introduce stored transaction lifecycle states only when needed for operational workflow visibility |
| Approval does not directly mutate balances | Complete | Override flow gates reversal posting; approval itself only changes `override_requests` | Low | Keep approval as authorization-only control |
| Override / policy-gated posting checks | Partial | Reversal threshold logic exists in controller and uses `override_requests` | Governance logic is not centralized in posting validation; most posting paths do not enforce policy checks before commit | Move approval/policy checks into service layer before posting commit |
| Validation of referenced account existence / eligibility | Partial | Presence of target IDs is checked; later model creation would fail if target is invalid | Inactive or ineligible accounts are not proactively rejected during validation | Validate target account exists and is postable before commit |
| Validation of referenced GL existence / eligibility | Partial | Presence of `gl_account_id` is checked; journal creation relies on FK/model validity later | Inactive GL targets are not proactively rejected | Validate GL target exists and is active/allowed before commit |
| Reversal eligibility checks | Partial | `ReversalService` checks original batch is posted and not already reversed | Does not yet enforce reversal window, business-date restrictions, or broader policy eligibility | Add reversal policy validator before constructing inverse posting |
| Journal balancing guarantee | Partial | GL journal lines are derived from already balanced GL legs, which is structurally good | No explicit post-build journal balance assertion | Add journal-level balance assertion and regression test |
| Fail closed / no partial posting | Partial | Core posting transaction should rollback if batch/legs/projection/journal creation fails | Material failure audits and linkage-row atomicity are incomplete | Add tests that intentionally fail projector/linkage creation and assert zero committed financial rows |
| Immutability of posted history | Gap | Design uses reversals rather than edits, but models do not block update/delete on posted rows | Posted financial records can still be mutated or destroyed by application code | Enforce readonly behavior or guards on posted `PostingBatch`, `PostingLeg`, `JournalEntry`, `JournalEntryLine`, `AccountTransaction` |
| Audit on posting committed | Complete | `PostingEngine` emits `posting_succeeded` | Low | Keep as baseline lifecycle audit |
| Audit on reversal committed | Complete | `ReversalService` emits `reversal_created` after reversal posting succeeds | Naming is acceptable, though “reversal_committed” may better match doc language | Consider aligning event names with lifecycle document |
| Audit on posting requested | Gap | No explicit event on request initiation | Reduced observability for operator intent vs posted result | Emit request/initiation audit in transaction entry flow |
| Audit on posting failure | Gap | Posting failures raise errors, but no material failure audit is emitted | Harder to review failed attempts and control exceptions | Emit `posting_failed` for material validation/commit failures |
| Audit on approval granted / denied / override use | Partial | Override state changes are persisted; reversal controller uses approved overrides | No audit emission around approve/deny/use transitions | Emit audit events from `OverrideRequestService` |
| Audit on reversal requested | Gap | Only committed reversal is audited | Missing requested vs completed distinction from lifecycle doc | Emit reversal-requested audit before actual reversal posting |
| EOD inclusion and business date close control | Partial | `BusinessDateEodService` blocks close when transactions are not posted/reversed and emits close audit | No GL summary/export inclusion layer yet | Good for current phase; extend when GL batch/export work begins |
| External/reference key capture at initiation | Partial | `idempotency_key` is accepted through UI/service path | No dedicated reference table and not all trace fields are persisted on operational transaction | Add structured reference capture when external channels expand |

---

## Summary

### Strongest areas

- financial balance enforcement
- positive-amount validation
- posting-derived subledger and GL projection
- reversal-as-new-batch pattern
- derivative balance cache design

### Biggest compliance gaps

- immutable-history enforcement at the model/data layer
- idempotency conflict detection for reused keys with different payloads
- atomic inclusion of fee/interest linkage rows
- fuller audit coverage for requested/failed/approved lifecycle states
- proactive eligibility validation for accounts, GL targets, and reversal policy
- required `posting_reference` generation

### Overall assessment

Current implementation is **strong on posting integrity** and **partial on lifecycle completeness**.

That means the system already follows the most important financial invariants well:

- balanced
- atomic at the core posting layer
- reversal-based correction
- projection-derived balances

But it does **not yet fully implement** the broader operational control model described in the reference documents:

- explicit lifecycle state tracking
- full audit trail coverage
- strict immutability enforcement
- richer policy / approval gating
- complete idempotency semantics

---

## Suggested Remediation Order

1. Enforce immutability for posted financial rows
2. Add idempotency conflict detection for same key + different payload
3. Populate unique `posting_reference` on every committed batch
4. Wrap fee / interest linkage rows into the same atomic commit boundary
5. Add proactive target eligibility validation for accounts, GL accounts, and reversal policy
6. Expand audit coverage for request, failure, approval, override use, and reversal request events
7. Introduce richer lifecycle states only if/when operator workflow visibility requires them

---

## Practical Conclusion

If measured against the financial safety rules, the implementation is in good shape.

If measured against the full end-to-end lifecycle model, it is not complete yet.

That is an acceptable position for the current ledger-first MVP, as long as the remaining governance and immutability gaps are treated as next-phase hardening work rather than permanently deferred behavior.
