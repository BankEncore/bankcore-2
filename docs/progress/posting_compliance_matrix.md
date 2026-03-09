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
| GL-side projection from posting | Complete | `JournalProjector` derives `journal_entries` and `journal_entry_lines` from explicit GL legs and product-resolved customer-account effects | Low | Maintain one-journal-per-batch MVP rule and keep product GL resolution explicit |
| No direct balance authority outside posting history | Complete | `BalanceRefreshService` rebuilds from `account_transactions`; `account_balances` behaves as projection/cache | Low | Keep using `account_transactions` as source of truth |
| Reversal uses new linked batch | Complete | `ReversalService` creates a new posting via `PostingEngine.post!` and links with `reversal_of_batch_id` | Low | Add more policy checks as reversal scope expands |
| Atomic posting of batch, legs, journal, account projection | Partial | `PostingEngine.post!` wraps posting, projections, and audit emission in one transaction | Good core behavior, but not all related side effects are included | Keep transaction boundary around all required posting effects |
| Atomic fee/interest linkage rows | Partial | `FeePostingService` and `InterestAccrualService` post first, then create linkage rows afterward | If linkage row creation fails, financial posting is already committed | Wrap posting + linkage row creation in one outer transaction or move linkage creation into posting workflow |
| Idempotent duplicate replay | Complete | Existing posted batch is returned when `idempotency_key` already exists and the semantic payload fingerprint matches | Low | Keep semantic fingerprint comparison as the baseline idempotency rule |
| Idempotency conflict rejection | Complete | `PostingEngine` raises `IdempotencyConflictError` when the same key is reused with a different semantic payload | Low | Keep coverage around payload canonicalization and conflict paths |
| Business date validation | Complete | `PostingValidator` requires open business date | Low | Keep current rule and expand later for governed override/backdating windows |
| Posting reference uniqueness | Complete | `PostingBatch` assigns a unique `posting_reference` before validation on create and tests cover uniqueness | Low | Keep the unique index and regression coverage |
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
| Immutability of posted history | Complete | Posted financial models include `PostedRecordImmutable`, and tests confirm update/delete are rejected for posted rows | Low | Keep immutability guards and extend them to any future posted financial models |
| Audit on posting committed | Complete | `PostingEngine` emits `posting_committed` after successful posting | Low | Keep as baseline lifecycle audit |
| Audit on reversal committed | Complete | `ReversalService` emits `reversal_committed` after reversal posting succeeds | Low | Keep lifecycle naming aligned with the current audit event vocabulary |
| Audit on posting requested | Complete | `PostingEngine` emits `posting_requested` before committing the financial event | Low | Keep requested vs committed distinction |
| Audit on posting failure | Complete | `PostingEngine` emits `posting_failed` for material failures | Low | Keep failure audit emission in the core posting path |
| Audit on approval granted / denied / override use | Complete | `OverrideRequestService` emits approval, denial, and use audit events | Low | Keep override lifecycle audit coverage |
| Audit on reversal requested | Complete | `ReversalService` emits `reversal_requested` before constructing the inverse posting | Low | Keep requested vs committed reversal distinction |
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
- semantic idempotency and conflict rejection
- posting reference generation
- lifecycle audit coverage for posting, reversal, and override flows
- immutability guards on posted financial rows

### Biggest compliance gaps

- atomic inclusion of fee/interest linkage rows
- proactive eligibility validation for accounts, GL targets, and reversal policy
- centralized policy/approval gating outside the reversal path
- richer operational reference capture and transaction metadata
- explicit journal-level post-build balance assertion

### Overall assessment

Current implementation is **strong on posting integrity** and **partial on lifecycle completeness**.

That means the system already follows the most important financial invariants well:

- balanced
- atomic at the core posting layer
- reversal-based correction
- projection-derived balances

But it does **not yet fully implement** the broader operational control model described in the reference documents:

- explicit lifecycle state tracking
- richer policy / approval gating
- fuller operational reference capture
- richer exception and workflow visibility

---

## Suggested Remediation Order

1. Wrap fee / interest linkage rows into the same atomic commit boundary
2. Add proactive target eligibility validation for accounts, GL accounts, and reversal policy
3. Centralize policy / approval checks for posting paths beyond reversal
4. Add richer operational reference capture and transaction metadata
5. Add explicit journal-level balance assertion and regression coverage
6. Introduce richer lifecycle states only if/when operator workflow visibility requires them

---

## Practical Conclusion

If measured against the financial safety rules, the implementation is in good shape.

If measured against the full end-to-end lifecycle model, it is not complete yet.

That is an acceptable position for the current ledger-first MVP, as long as the remaining governance and immutability gaps are treated as next-phase hardening work rather than permanently deferred behavior.
