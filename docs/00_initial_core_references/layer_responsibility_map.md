# Layer Responsibility Map

**Status:** DROP-IN SAFE  
**Scope:** BankCORE / BankEncore table-to-layer reference  
**Purpose:** Provide a compact mapping of core tables to architectural layers so that operational, posting, subledger, and general-ledger terminology stay consistent during design and implementation.

---

# 1. Overview

BankCORE separates banking activity into distinct layers:

1. Operational layer
2. Posting engine layer
3. Account subledger layer
4. General ledger layer

This document is a practical companion to `ledger_boundaries.md`.

It answers:

- which tables belong to which layer?
- what is each table responsible for?
- what should not be stored in that layer?
- how does data flow from one layer to the next?

Related documents:

- [ledger_boundaries.md](ledger_boundaries.md)
- [transaction_catalog_spec.md](transaction_catalog_spec.md)
- [transaction_posting_spec.md](transaction_posting_spec.md)
- [product_configuration_roadmap.md](product_configuration_roadmap.md)

---

# 2. Compact Layer Map

| Layer | Primary Question | Core Tables | What It Stores |
|---|---|---|---|
| Operational | What happened? | `transactions`, `transaction_lines`, `transaction_items`, `transaction_references`, `transaction_exceptions` | Business event, input context, references, operator workflow state |
| Posting engine | How does it affect money? | `posting_batches`, `posting_legs` | Balanced debit/credit translation of the operational event |
| Account subledger | What does the customer see? | `account_transactions`, `account_balances`, `account_holds` | Customer-facing account history and derived balances |
| General ledger | What are the bank's books? | `gl_accounts`, `journal_entries`, `journal_entry_lines` | Official bank accounting records |

---

# 3. Table-by-Table Reference

## 3.1 Operational Layer

### `transactions`
- Role: operational header for the business event
- Examples: internal transfer, fee assessment, ACH credit
- Should contain: type, channel, branch, lifecycle state, reference numbers, initiator
- Should not contain: final debit/credit accounting logic

### `transaction_lines`
- Role: operational detail rows for accounts or instruments involved
- Examples: source account line, destination account line, fee line, memo line
- Should contain: account targets, amounts, direction, memo, position
- Should not contain: authoritative GL accounting results

### `transaction_items`
- Role: instrument-level or network-level detail
- Examples: ACH item detail, check data, denomination detail, card settlement item
- Should contain: item-specific reference payload
- Should not contain: balance authority

### `transaction_references`
- Role: alternate lookup keys and external traceability
- Examples: ACH trace, batch reference, idempotency key, case ID
- Should contain: reference type and value
- Should not contain: posting decisions

### `transaction_exceptions`
- Role: explicit review-needed or policy-blocked transaction state
- Examples: requires override, blocked by policy, pending review
- Should contain: exception status and disposition workflow
- Should not contain: financial effects by itself

---

## 3.2 Posting Engine Layer

### `posting_batches`
- Role: canonical balanced financial event
- Should contain: transaction code, business date, posting reference, linkage to operational transaction, reversal linkage
- Should not contain: operator narrative beyond lightweight trace fields

### `posting_legs`
- Role: individual debit/credit lines making up the posting batch
- Should contain: leg type, target scope, amount, account or GL target
- Should not contain: customer-facing narrative as the primary source of truth

Important rule:
- this layer is the financial source of truth
- debits must equal credits
- posted rows must be immutable

---

## 3.3 Account Subledger Layer

### `account_transactions`
- Role: derived customer-facing account activity
- Should contain: account impact, debit/credit direction, posting linkage, business date, display narrative
- Should not contain: independent accounting decisions outside posting

### `account_balances`
- Role: cached balance projection
- Should contain: posted and available balance summaries
- Should not contain: authoritative balance truth independent of account transaction history

### `account_holds`
- Role: operational restrictions affecting available funds
- Should contain: hold amount, reason, effective state
- Should not contain: direct balance mutation

---

## 3.4 General Ledger Layer

### `gl_accounts`
- Role: chart of accounts
- Should contain: account number, category, normal balance, posting eligibility

### `journal_entries`
- Role: GL header derived from posting
- Should contain: posting linkage, business date, reference number
- Should not contain: independent business-event semantics

### `journal_entry_lines`
- Role: official debit/credit accounting lines for the bank
- Should contain: GL target, debit/credit amount, branch if relevant
- Should not contain: operational workflow semantics

---

# 4. Data Flow Between Layers

## 4.1 Normal flow

```text
transactions
    -> transaction_lines / transaction_references
        -> posting_batch
            -> posting_legs
                -> account_transactions
                -> journal_entry_lines
```

## 4.2 Meaning of each step

- Operational layer records the business event
- Posting layer translates that event into balanced accounting
- Subledger layer shows the customer-facing account impact
- General ledger layer records the bank-accounting impact

---

# 5. Real Example: Internal Transfer

## Operational layer
- `transactions`: internal transfer header
- `transaction_lines`: source account, destination account, amount, memo

## Posting layer
- `posting_batch`: one balanced transfer event
- `posting_legs`: debit source account, credit destination account

## Subledger layer
- `account_transactions`: one debit on source account, one credit on destination account

## General ledger layer
- `journal_entry_lines`: debit source product liability GL, credit destination product liability GL

This is why a transfer can be operationally rich, financially balanced, and customer-visible at the same time without collapsing all meanings into one table.

---

# 6. Common Design Mistakes to Avoid

## 6.1 Putting business meaning in posting legs only
If transfer narrative, contra-account context, or external references exist only indirectly in posting rows, operator traceability will be weak.

## 6.2 Letting operational rows mutate balances directly
Operational rows describe intent and workflow. They must not become the balance authority.

## 6.3 Treating account balances as source of truth
`account_balances` is a projection, not the authoritative history.

## 6.4 Using the general ledger as a customer-history substitute
The GL answers bank-accounting questions, not customer service questions.

---

# 7. Practical Conclusion

Use this rule of thumb:

- Operational layer: **what happened**
- Posting engine layer: **how it affects money**
- Account subledger layer: **what the customer sees**
- General ledger layer: **what the bank books show**

If a proposed field or table does not clearly belong to one of those responsibilities, the design likely needs refinement before implementation.
