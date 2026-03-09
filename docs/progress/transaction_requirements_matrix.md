# Transaction Requirements Matrix

## Scope

This matrix converts the current transaction reference docs into one implementation-facing contract for the existing BankCORE transaction families:

- adjustments
- internal transfers
- fees
- interest accrual/posting
- ACH entries
- reversals

It is intended to sit between:

- the operational reference docs in `docs/00_initial_core_references/`
- the current workstation implementation in `app/controllers/transactions_controller.rb` and related services

## Source Documents

- `docs/00_initial_core_references/transaction_catalog_spec.md`
- `docs/00_initial_core_references/transaction_posting_spec.md`
- `docs/00_initial_core_references/manual_transaction_entry_model.md`
- `docs/00_initial_core_references/first_transaction_types.md`

## Current Evidence

- Generic workstation entry and preview:
  - `app/controllers/transactions_controller.rb`
  - `app/views/transactions/new.html.erb`
  - `app/views/transactions/preview.html.erb`
  - `app/services/manual_transaction_entry_service.rb`
- Existing family services:
  - `app/services/fee_posting_service.rb`
  - `app/services/interest_accrual_service.rb`
  - `app/services/interest_posting_service.rb`
  - `app/services/reversal_service.rb`

## Compact Matrix

| Family / Codes | Current Operator Surface | Required Inputs | Required Metadata | Eligibility / Policy Rules | Required Service Path / Side Records | Reversal / Idempotency | Current Gap |
|---|---|---|---|---|---|---|---|
| `ADJ_CREDIT`, `ADJ_DEBIT` | Generic account-mode entry in `transactions/new` | `transaction_code`, `account_id`, `amount`, `business_date` | `reason_text`, `memo`, operator-visible `reference_number`, optional `external_reference` | account exists, account active/postable, amount positive, business date open; debit side should allow stricter policy thresholds than credit | direct posting path is acceptable; no extra family record required beyond `transactions` / `posting_batches` / projections | reverse through reversal code on `transaction_codes`; idempotency should key on account, amount, date, reference | current UI does not distinguish debit-vs-credit policy prompts, linked prior issue references, or high-value guidance |
| `XFER_INTERNAL` | Transfer-mode branch inside `transactions/new` | `source_account_id`, `destination_account_id`, `amount`, `business_date` | transfer memo, customer instruction/reference, contra-account context | both accounts exist, both active/postable, accounts must differ, currency compatible, amount positive, business date open | direct posting path is acceptable; `account_transactions` already derive contra-account context | compensating transfer or explicit reversal path; idempotency should key on source, destination, amount, reference | current UI only switches field shape; it does not enforce family-specific narrative or explainability requirements beyond the basic account pair |
| `FEE_POST`, `FEE_REVERSAL` | Generic account-mode entry today; fee history review in `app/views/fee_assessments/index.html.erb` | `account_id`, `fee_type_id`, optional amount override, business date; reversal also needs original fee linkage | fee code, fee rule or cycle reference, waiver/override reason, original fee reference for reversal | fee type active, account active/postable, product/rule eligible, amount positive, governed approval for waiver or late/manual reversal | must use `FeePostingService`; successful post must create `FeeAssessment`; fee reversal should preserve original fee linkage | idempotency should key on account + fee type + cycle/date or original fee reference | generic manual entry bypasses `FeePostingService` and therefore bypasses `FeeAssessment` creation and fee-specific metadata capture |
| `INT_ACCRUAL` | GL-only mode in `transactions/new`; accrual history review in `app/views/interest_accruals/index.html.erb` | `account_id`, `accrual_date`, amount or derived amount, interest rule context | accrual date, `interest_rule_id`, rate/basis details, cycle context | account/product interest-bearing, rule active, business date open, amount non-negative, product interest expense GL configured | must use `InterestAccrualService`; successful post must create `InterestAccrual` | reversal through accrual reversal code; idempotency should key on account + accrual date + rule context | current manual path treats accrual as generic GL-only posting and bypasses `InterestAccrual` record creation and rule metadata capture |
| `INT_POST` | Generic account-mode entry today; no dedicated posting workbench exists | `account_id`, posting cycle/date, amount or due-accrual set | posting cycle, rule reference, statement boundary, source accrual references | account/product interest-bearing, due cycle satisfied, accrued balance available, amount positive, business date open | must use `InterestPostingService` plus linkage creation to `InterestPostingApplication` rows | reversal through interest-post reversal code; idempotency should key on account + cycle/date | current manual path bypasses the accrual-linkage workflow and has no operator screen for due-account review before posting |
| `ACH_CREDIT`, `ACH_DEBIT` | Generic account-mode entry today | `account_id`, `amount`, effective date, settlement reference, business date | ACH trace, originator or authorization reference, file/batch reference, effective date, optional external counterparty reference | account exists, account active/postable, product eligible for ACH behavior, amount positive, business date open, policy checks for blocked/restricted accounts | target path should be a dedicated ACH entry service layered on `PostingEngine`; no specialized ACH side record exists yet in the current MVP | return/opposite-flow handling is future work; idempotency should key on trace, file/batch, account, amount | current UI has no ACH-specific fields, no dedicated service path, and no review flow for ACH-specific validation failures |
| Reversal workflow | Transaction review page and `OverrideRequestsController` flow | original transaction or posting batch, current business date, optional override request, optional idempotency key | original reference, reversal reason, override reason/context, approver linkage when required | original batch posted, not already reversed, business date open, threshold approval for governed reversals | must use `ReversalService`; may create `TransactionException` and consume `OverrideRequest` | explicit reversal flow only; idempotency tied to original batch + supplied key | reversal is functional but still coarse-grained: there is no dedicated preview/confirm workbench and high-value reversal guidance starts only after a failed attempt |

## Shared Request Contract

Every family should be normalized into one transaction-entry request object before policy validation or dispatch.

Minimum shared fields:

- `transaction_code`
- `business_date`
- `amount_cents`
- `reference_number`
- `memo`
- `reason_text`
- `external_reference`
- `idempotency_key`
- `account_id` or family-specific account routing fields
- `created_by_id`

Family-specific fields that the current generic form does not model consistently:

- `fee_type_id`
- `fee_rule_id`
- `authorization_reference`
- `authorization_source`
- `original_fee_assessment_id`
- `interest_rule_id`
- `accrual_date`
- `posting_cycle`
- `ach_trace_number`
- `ach_effective_date`
- `ach_batch_reference`
- `override_request_id`
- `reversal_target_transaction_id`

## Shared Resources And References

Some fields should be treated as shared resources rather than incidental free-text metadata because they connect transaction families to other governed workflows or external control evidence.

Cross-cutting shared resources to model explicitly:

- `authorization_reference`
  - used when a transaction depends on customer authorization, ACH authorization, or another governed approval artifact
- `override_request_id`
  - used when a transaction depends on a supervisor approval or governed exception path
- `reversal_target_transaction_id`
  - used when a new transaction is explicitly correcting or reversing an existing one
- `fee_rule_id`
  - used when fee posting is driven by a product/rule decision that should remain traceable
- `interest_rule_id`
  - used when accrual or posting is justified by a specific product rule
- external network references such as `ach_trace_number`, `ach_batch_reference`, and `external_reference`
  - used for settlement traceability and duplicate detection

These resources should be captured in the normalized request object and validated by family policy objects, even when they are only required for a subset of transaction families.

## Implementation Notes

- The current workstation is strongest for adjustments and internal transfers because those families can tolerate direct posting with shared metadata.
- The current workstation is weakest for fee, interest, and ACH families because their business meaning depends on family-specific inputs or side records that are not captured by `ManualTransactionEntryService`.
- Reversal is already explicit and governed, but it needs a first-class preview/confirm UX rather than a single action button plus exception redirect.

## Practical Conclusion

This matrix should be treated as the contract for the next implementation phase:

- policy validation should enforce these requirements before posting
- dispatch should choose the correct family service path
- workstation UI should collect the required inputs and metadata for the chosen family
- tests should prove that side records, posting batches, and projections stay aligned
