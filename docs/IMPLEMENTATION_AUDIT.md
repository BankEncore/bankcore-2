# BankCORE Implementation Audit

**Date:** 2026-03-08  
**Reference:** [implementation_order.md](00_initial_core_references/implementation_order.md) and related docs in `docs/00_initial_core_references/`

---

## Executive Summary

The BankCORE implementation is **substantially compliant** with the implementation order and financial invariants. Phases 0–6 are implemented; Phase 7 (teller/cash) is correctly deferred. A few gaps and minor deviations are noted below.

---

## 1. Financial Invariants Compliance

### 1.1 Balanced Posting ✓

**Requirement:** SUM(debit_legs.amount) == SUM(credit_legs.amount)

**Implementation:** [PostingValidator](app/services/posting_validator.rb) `validate_balance!` enforces this before commit. PostingEngine calls it in `build_and_validate_legs!` before `create_posted_records!`.

### 1.2 Immutability ✓

**Requirement:** Posted records may not be edited or deleted; corrections use reversals.

**Implementation:** No UPDATE/DELETE on posted records. [ReversalService](app/services/reversal_service.rb) creates a new inverse PostingBatch via PostingEngine with `reversal_of_batch_id` linking to the original. Original batch is never mutated.

### 1.3 Atomicity ✓

**Requirement:** All-or-nothing posting; rollback on failure.

**Implementation:** PostingEngine wraps `create_posted_records!` in `ActiveRecord::Base.transaction`. ReversalService wraps `create_reversal_batch!` in a transaction.

### 1.4 No Direct Balance Updates ✓

**Requirement:** `account_balances` is a projection; update only via posting engine path.

**Implementation:** Balance changes flow through:
- PostingEngine → AccountProjector → AccountTransaction creation → BalanceRefreshService.refresh!
- No direct `AccountBalance.update` or similar outside BalanceRefreshService.
- BalanceRefreshService computes from AccountTransaction history.

### 1.5 Idempotency ✓

**Requirement:** Duplicate requests must not create duplicate postings.

**Implementation:** PostingEngine checks `idempotency_key`; returns existing batch if duplicate. ManualTransactionEntryService, FeePostingService, InterestAccrualService, InterestAccrualRunnerService, FeeAssessmentRunnerService all support idempotency keys.

---

## 2. Ledger Boundaries ✓

**Requirement:** Operational layer → Posting engine → Subledger → GL layer; no crossing.

**Implementation:**
- Operational: BankingTransaction (transactions table)
- Posting: PostingBatch, PostingLeg
- Subledger: AccountTransaction (created by AccountProjector)
- GL: JournalEntry, JournalEntryLine (created by JournalProjector)

Flow is correct: PostingEngine creates legs → JournalProjector and AccountProjector derive downstream records.

---

## 3. Phase Compliance (implementation_order.md)

### Phase 0 — Foundation ✓

- Docs in `docs/00_initial_core_references/`
- Enums in `lib/bankcore/enums.rb`
- Constants in `lib/bankcore/constants.rb`
- Transaction codes and posting templates seeded

### Phase 1 — Core Master Records ✓

| Item | Status |
|------|--------|
| parties | ✓ |
| accounts | ✓ |
| account_owners | ✓ |
| gl_accounts | ✓ |
| business_dates | ✓ |
| Party model | ✓ |
| Account model | ✓ |
| AccountOwner model | ✓ |
| GlAccount model | ✓ |
| BusinessDate model | ✓ |
| BusinessDateService | ✓ |
| create party (UI) | ✓ |
| create account | ✓ (via seeds; no dedicated UI) |
| link owner to account | ✓ |
| seed chart of accounts | ✓ |
| open one business date | ✓ |
| validate current open business date | ✓ |

**Note:** Account creation has no dedicated UI; accounts are created via seeds. The doc says "create account" as a minimum feature—consider adding a simple account creation form if needed.

### Phase 2 — Transaction and Posting Kernel ✓

| Item | Status |
|------|--------|
| transactions | ✓ (BankingTransaction) |
| posting_batches | ✓ |
| posting_legs | ✓ |
| PostingEngine | ✓ |
| PostingValidator | ✓ |
| ReversalService | ✓ |
| manual_adjustment | ✓ (ADJ_CREDIT/ADJ_DEBIT) |
| internal_transfer | ✓ (XFER_INTERNAL) |
| reversal | ✓ |

### Phase 3 — GL and Account Projection ✓

| Item | Status |
|------|--------|
| journal_entries | ✓ |
| journal_entry_lines | ✓ |
| account_transactions | ✓ |
| account_balances | ✓ |
| JournalProjector | ✓ |
| AccountProjector | ✓ |
| BalanceRefreshService | ✓ |

### Phase 4 — Back-Office Transaction Types ✓

| Item | Status |
|------|--------|
| manual_adjustment | ✓ |
| internal_transfer | ✓ |
| ach_entry | ✓ (ACH_CREDIT, ACH_DEBIT) |
| manual transaction form | ✓ |
| transaction type mapping | ✓ (PostingTemplate) |
| posting preview | ✓ |
| posting result screen | ✓ |

### Phase 5 — Interest and Fees ✓

| Item | Status |
|------|--------|
| fee_types | ✓ |
| fee_assessments | ✓ |
| interest_accruals | ✓ |
| FeePostingService | ✓ |
| InterestAccrualService | ✓ |
| InterestPostingService | ✓ |
| InterestAccrualRunnerService | ✓ |
| FeeAssessmentRunnerService | ✓ |
| Manual fee posting | ✓ |
| Scheduled fee posting | ✓ (rake + job) |
| Interest accrual | ✓ |
| Interest posting | ✓ |

### Phase 6 — Audit, Overrides, Holds ✓

| Item | Status |
|------|--------|
| audit_events | ✓ |
| override_requests | ✓ |
| account_holds | ✓ |
| AuditEmissionService | ✓ |
| OverrideRequestService | ✓ |
| AccountHoldService | ✓ |
| Override for reversal | ✓ |
| Manual holds | ✓ |

### Phase 7 — Teller and Branch Cash ✓ Deferred

Correctly deferred per doc. Branches exist (moved earlier); teller_sessions, cash_locations, etc. not implemented.

---

## 4. Practical Notes Compliance (§18)

### 4.1 Posting logic in services ✓

Controllers invoke ManualTransactionEntryService, PostingEngine, ReversalService, etc. No posting logic in controllers.

### 4.2 Transaction-type mapping explicit ✓

PostingTemplate + PostingTemplateLeg define mapping by transaction_code. No scattered rules.

### 4.3 Balance refresh isolated ✓

BalanceRefreshService is the single place for balance computation/upsert. Called from AccountProjector after posting.

### 4.4 Append-only event patterns ✓

Posting, reversals, audit events are append-only. No destructive updates.

### 4.5 UI state vs financial state ✓

Transactions are real only when posting commits. Preview does not persist.

---

## 5. Milestones (§17)

| Milestone | Status |
|-----------|--------|
| A — Static banking references ready | ✓ |
| B — Posting kernel works | ✓ |
| C — Back-office MVP usable | ✓ |
| D — Accrual foundation works | ✓ |
| E — Operational controls present | ✓ |

---

## 6. Gaps and Recommendations

### 6.1 Positive amounts in legs ✓ Resolved

**Doc:** implementation_order §6: "positive amounts only in legs"

**Implementation:** PostingValidator now includes `validate_positive_amounts!` (runs first in `validate!`). Raises `InvalidAmountError` when any leg has `amount_cents` blank, zero, or negative. TransactionsController rescues `PostingValidator::ValidationError` and surfaces the message to the user.

### 6.2 Account creation UI ✓ Resolved

**Doc:** Phase 1 minimum features include "create account"

**Implementation:** AccountsController#new and #create added. Form includes account_number, account_type, branch, currency, and optional primary owner (party). DepositAccount is auto-created for dda/now/savings/cd. "New Account" link on accounts index and navbar.

### 6.3 Migration order (Minor deviation)

**Doc:** Recommended order: parties, accounts, account_owners, gl_accounts, business_dates, transactions, posting_batches, posting_legs, journal_entries, journal_entry_lines, account_transactions, account_balances, fee_types, fee_assessments, interest_accruals, audit_events, override_requests, account_holds, branches...

**Current:** Branches created before business_dates (20260307234418 vs 20260307234431). Doc says "If branches are already foundational in your app, move them earlier"—so this is acceptable.

### 6.4 Override "evaluation" service naming

**Doc:** §13 lists "Override evaluation service"

**Current:** OverrideRequestService handles request, approve, deny, use. The "evaluation" (e.g., whether an override is needed for a reversal) lives in TransactionsController#reverse and ReversalService. No separate OverrideEvaluationService. Functionally complete; naming difference only.

---

## 7. Transaction Types (§15)

| Doc Order | Type | Code | Status |
|-----------|------|------|--------|
| 1 | Manual adjustment | ADJ_CREDIT/ADJ_DEBIT | ✓ |
| 2 | Internal transfer | XFER_INTERNAL | ✓ |
| 3 | Manual fee post | FEE_POST | ✓ |
| 4 | Interest accrual | INT_ACCRUAL | ✓ |
| 5 | Interest post | INT_POST | ✓ |
| 6 | ACH entry | ACH_CREDIT/ACH_DEBIT | ✓ |
| 7 | Reversal | Various reversal codes | ✓ |

---

## 8. GL Accounts Seeded (§14)

Required: Deposit Liability, Interest Payable, Fee Income, Interest Expense, Adjustment/Correction Expense, ACH Clearing, Suspense/Adjustment Clearing.

**Current:** Seeds include 2110 (DDA), 2510 (Interest Payable), 4510 (Deposit Service Charges), 5130 (Interest Expense), 5190 (Adjustment/Correction), 1120 (Settlement Bank), 2190 (Suspense). Covers required categories.

---

## 9. Conclusion

The implementation aligns well with implementation_order.md and the financial invariants. Positive-amount validation has been added to PostingValidator. Remaining items (account creation UI, migration-order nuances) are optional improvements.
