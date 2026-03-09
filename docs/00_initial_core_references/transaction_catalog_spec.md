# Transaction Catalog Specification

**Status:** DROP-IN SAFE  
**Scope:** BankCORE / BankEncore operational transaction catalog  
**Purpose:** Define the operational meaning, required inputs, eligibility rules, metadata requirements, approval expectations, and reversal behavior for the initial BankCORE transaction catalog.

---

# 1. Overview

This document defines the **operational transaction catalog** for BankCORE.

It answers questions such as:

- what business event does a transaction type represent?
- what inputs are required to create one?
- which products or accounts are eligible?
- what metadata must be captured for audit and operator traceability?
- what approvals, exceptions, and reversals apply?

This is intentionally distinct from the accounting specification.

- This document describes **what happened operationally**
- `transaction_posting_spec.md` describes **how it posts financially**

Related documents:

- [first_transaction_types.md](first_transaction_types.md)
- [transaction_posting_spec.md](transaction_posting_spec.md)
- [posting_templates.md](posting_templates.md)
- [ledger_boundaries.md](ledger_boundaries.md)
- [layer_responsibility_map.md](layer_responsibility_map.md)

---

# 2. Transaction Definition Model

Each transaction type should be defined using the following rule dimensions.

| Dimension | Meaning |
|---|---|
| `code` | Stable system-defined transaction identifier |
| `purpose` | Business event represented by the transaction |
| `required_inputs` | Minimum data needed to create the transaction |
| `eligible_targets` | Which accounts, products, or channels may use it |
| `required_metadata` | Memo, references, contra account, rule IDs, external trace data |
| `approval_policy` | Whether approval, override, or supervisory review is required |
| `reversal_behavior` | Whether and how the transaction may be reversed |
| `idempotency_strategy` | How duplicate replay should be detected and handled |
| `initiation_mode` | Operator, batch job, or system-generated |

---

# 3. Design Principles

## 3.1 Transaction types are system-defined
Operators create **transaction instances**, but they do not invent new transaction types ad hoc.

## 3.2 Operational records describe business meaning
Transaction definitions should capture:

- user intent
- business context
- operational references
- approval and exception semantics

They do not directly mutate balances.

## 3.3 Financial effects are delegated to the posting layer
Every operational transaction type must have a corresponding posting definition in `transaction_posting_spec.md`.

## 3.4 Metadata matters
If a transaction cannot be understood by operations staff from its recorded metadata, the operational design is incomplete even if the posting is financially correct.

---

# 4. Current MVP Transaction Catalog

## 4.1 Compact Matrix

| Code | Purpose | Required Inputs | Eligible Targets | Required Metadata | Approval / Exceptions | Reversal / Idempotency | Initiation |
|---|---|---|---|---|---|---|---|
| `ADJ_CREDIT` | Manual credit to customer account | `account_id`, `amount`, `reason` | Active postable deposit accounts | reason, operator memo, optional reference | High-value or sensitive adjustments may require override | Reverse via paired code or controlled reversal; idempotency on account, amount, date, reference | Operator |
| `ADJ_DEBIT` | Manual debit to customer account | `account_id`, `amount`, `reason` | Active postable deposit accounts | reason, operator memo, linked prior issue reference | High-value or sensitive adjustments may require override | Reverse via paired code or controlled reversal; idempotency on account, amount, date, reference | Operator |
| `XFER_INTERNAL` | Move funds between internal accounts | `source_account_id`, `destination_account_id`, `amount` | Active internal accounts, same institution, compatible currency | contra account, transfer memo, customer instruction/reference | Threshold checks or policy exceptions if needed | Reversal by compensating transfer or controlled inverse posting; idempotency on source, destination, amount, reference | Operator |
| `FEE_POST` | Charge service fee | `account_id`, `fee_type_id`, optional amount override | Accounts/products eligible for fee | fee code, cycle or rule reference, waiver override reason | Waiver or manual override may require approval | `FEE_REVERSAL`; idempotency on account, fee type, cycle/date | Operator or system |
| `FEE_REVERSAL` | Reverse posted fee | original fee reference, `account_id`, amount | Existing reversible fee assessment | original posting reference, reason | May require approval outside normal window | Terminal reversal; idempotency on original fee reference | Operator |
| `INT_ACCRUAL` | Accrue earned interest expense | `account_id`, `accrual_date`, amount or derived amount | Interest-bearing eligible deposit products | accrual date, rule ID, rate, basis details | Normally system-controlled | `INT_ACCRUAL_REVERSAL`; idempotency on account and accrual date | System |
| `INT_ACCRUAL_REVERSAL` | Reverse prior accrual | original accrual reference, amount/date | Existing reversible accrual | original accrual reference, reason | Controlled/manual if needed | Terminal reversal; idempotency on original accrual reference | Operator or system |
| `INT_POST` | Move accrued interest into customer balance | `account_id`, posting cycle/date, amount | Accounts with accrued interest payable | cycle, statement boundary, rule reference | Normally system-controlled | `INT_POST_REVERSAL`; idempotency on account and cycle/date | System |
| `INT_POST_REVERSAL` | Reverse interest posting | original interest posting reference, amount | Existing reversible interest posting | original posting reference, reason | Controlled/manual if needed | Terminal reversal; idempotency on original posting reference | Operator or system |
| `ACH_CREDIT` | Incoming external credit | `account_id`, `amount`, external reference | Accounts/products eligible for ACH credit | ACH trace, originator, file/batch reference, effective date | Exception path for blocked or invalid account | Opposite debit/return flow later; idempotency on trace, file, account, amount | System or back office |
| `ACH_DEBIT` | Outgoing external debit | `account_id`, `amount`, external reference | Accounts/products eligible for ACH debit | ACH trace, authorization reference, file/batch reference, effective date | Stronger policy and authorization checks | Opposite credit/return flow later; idempotency on trace, file, account, amount | System or back office |

---

# 5. Transaction Type Specifications

## 5.1 `ADJ_CREDIT`

**Purpose**

Manual credit to a customer account for corrections, goodwill, or operational adjustments.

**Required inputs**

- `account_id`
- `amount`
- `reason`

**Eligibility**

- account must exist
- account must be active and postable
- product must permit the account-side posting behavior

**Required metadata**

- operator reason text
- optional external or case reference
- optional linked prior transaction reference

**Approval and exception notes**

- policy checks may require supervisor override above threshold

**Reversal notes**

- should be reversible through paired or controlled inverse transaction

---

## 5.2 `ADJ_DEBIT`

**Purpose**

Manual debit to a customer account for correction of prior over-credit or other operational adjustments.

**Required inputs**

- `account_id`
- `amount`
- `reason`

**Eligibility**

- account must exist
- account must be active and postable
- policy rules may block debit if account state is restricted

**Required metadata**

- operator reason text
- optional linked prior issue reference

**Approval and exception notes**

- higher scrutiny than credit adjustments is typical

**Reversal notes**

- should reverse through paired or controlled inverse transaction

---

## 5.3 `XFER_INTERNAL`

**Purpose**

Move funds between two internal accounts held within the institution.

**Required inputs**

- `source_account_id`
- `destination_account_id`
- `amount`

**Eligibility**

- both accounts must exist
- both accounts must be active and postable
- accounts must not be identical
- currencies must be compatible

**Required metadata**

- contra account context
- transfer memo
- customer instruction or operator reference

**Approval and exception notes**

- may be policy-gated for large-value or restricted-account transfers

**Reversal notes**

- usually reversed through a compensating transfer or explicit reversal workflow

---

## 5.4 `FEE_POST`

**Purpose**

Assess a service fee against a customer account.

**Required inputs**

- `account_id`
- `fee_type_id`
- optional amount override

**Eligibility**

- fee type must be active
- account/product must be eligible for the fee

**Required metadata**

- fee code
- cycle, event, or rule reference
- waiver or override reason if manually adjusted

**Approval and exception notes**

- fee waivers or overrides may require approval

**Reversal notes**

- reversed with `FEE_REVERSAL`

---

## 5.5 `INT_ACCRUAL` and `INT_POST`

**Purpose**

- `INT_ACCRUAL`: recognize interest expense earned but not yet posted to the account
- `INT_POST`: release accrued interest into the customer balance

**Required inputs**

- `account_id`
- relevant cycle/date
- amount or rule-derived amount

**Eligibility**

- account/product must be interest-bearing
- rule/cycle conditions must be satisfied

**Required metadata**

- interest rule reference
- rate or basis details
- accrual or statement cycle date

**Approval and exception notes**

- typically system-generated rather than operator-created

**Reversal notes**

- use dedicated reversal codes for accrual and posting flows

---

## 5.6 `ACH_CREDIT` and `ACH_DEBIT`

**Purpose**

Represent external settlement activity entering or leaving customer deposit accounts.

**Required inputs**

- `account_id`
- `amount`
- ACH or settlement reference

**Eligibility**

- account/product must be eligible for ACH behavior
- account must pass policy and status checks

**Required metadata**

- trace number
- batch/file reference
- originator or authorization reference
- effective date

**Approval and exception notes**

- exceptions may require explicit review if authorization or routing data is suspect

**Reversal notes**

- eventual design may distinguish normal reversal from return-item or dispute workflows

---

# 6. Metadata Standards

The following metadata categories should be considered first-class as operational richness increases.

| Category | Examples |
|---|---|
| Operator narrative | reason text, memo, notes |
| Counterparty / contra context | source account, destination account, external party |
| External references | ACH trace, batch reference, case ID, network reference |
| Rule references | fee rule ID, interest rule ID, product reference |
| Approval context | override request ID, approver, exception reason |

---

# 7. Next Operational Metadata Increment

Now that product identity and product-linked GL behavior are in place, the next operational increment should stay intentionally small and focus on traceability rather than trying to implement the entire deferred transaction-detail model at once.

## 7.1 Near-term scope

The next increment should add or standardize:

- persisted memo and reason text on manual transaction entry paths
- durable transaction references for alternate lookup and external traceability
- direct transaction traceability from `account_transactions` back to the operational transaction
- contra-account context for bilateral transactions such as `XFER_INTERNAL`

## 7.2 Concrete targets

| Need | Suggested implementation target |
|---|---|
| Manual memo / reason capture | carry memo or reason through `transactions` and account-history description logic |
| External and alternate references | add `transaction_references` |
| Direct traceability from account history | add `account_transactions.transaction_id` |
| Better transfer explainability | add contra-account context, either through `transaction_lines` or a focused account-history field |

## 7.3 Explicit deferral

This increment does **not** require full teller-era operational richness yet.

The following can remain deferred until broader operational workflows justify them:

- full `transaction_lines` coverage for every transaction family
- instrument-heavy `transaction_items`
- complete `transaction_exceptions` workflow modeling

The immediate goal is to make posted transactions easier for operators to understand and trace, especially for internal transfers and externally referenced activity.

---

# 8. Relationship to Future Operational Tables

As the operational layer matures, this specification is expected to map naturally to:

- `transactions` as the operational header
- `transaction_lines` as account/instrument detail
- `transaction_items` as external instrument detail
- `transaction_references` as traceability and lookup references
- `transaction_exceptions` as review and policy-blocked workflow state

---

# 9. Practical Conclusion

The transaction catalog should remain **controlled and system-defined**, while transaction instances are created by users, services, and jobs.

This keeps:

- business semantics stable
- approvals predictable
- reversals explicit
- accounting outcomes auditable

The operational layer should tell staff **what happened**, while the posting specification tells the system **how it affects money**.
