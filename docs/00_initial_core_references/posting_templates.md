# Posting Templates

**Status:** DROP-IN SAFE  
**Scope:** BankCORE / BankEncore Posting Engine  
**Purpose:** Define the posting template structure that maps transaction codes to balanced posting legs.

**Related documents:**
- [transaction_catalog_spec.md](transaction_catalog_spec.md)
- [transaction_posting_spec.md](transaction_posting_spec.md)
- [first_transaction_types.md](first_transaction_types.md)
- [product_configuration_roadmap.md](product_configuration_roadmap.md)

---

# 1. Overview

Posting templates define how a **transaction type translates into ledger activity**.

They act as the bridge between:

transaction_codes → posting_templates → posting_legs → ledger effects

A template describes:

- which accounts are debited
- which accounts are credited
- which legs affect customer accounts
- which legs affect GL accounts

The template system allows the posting engine to remain **generic and rule-driven**.

---

# 2. Core Concept

A transaction does **not directly create ledger entries**.

Instead:

1. The system identifies a `transaction_code`
2. The code references a `posting_template`
3. The template generates the `posting_legs`

This allows:

- configurable accounting
- audit transparency
- safe future expansion

---

# 3. Table Model

## transaction_codes

Defines the operational transaction type.

Fields:

- id
- code
- description
- reversal_code
- active

Example:

| code | description |
|-----|-------------|
| ADJ_CREDIT | Manual account credit |
| ADJ_DEBIT | Manual account debit |
| XFER_INTERNAL | Internal transfer |
| FEE_POST | Fee assessment |
| INT_ACCRUAL | Interest accrual |
| INT_POST | Interest posting |
| ACH_CREDIT | Incoming ACH |
| ACH_DEBIT | Outgoing ACH |

---

## posting_templates

Defines a reusable template tied to a transaction code.

Fields:

- id
- transaction_code_id
- name
- description
- active

---

## posting_template_legs

Defines the debit/credit behavior.

Fields:

- id
- posting_template_id
- leg_type (debit/credit)
- account_source
- gl_account_id
- description

---

# 4. Account Sources

The system must allow legs to reference different account sources.

Possible sources:

| Source | Description |
|------|-------------|
| customer_account | the transaction's primary account |
| source_account | transfer source |
| destination_account | transfer destination |
| fixed_gl | static GL account |
| product_gl | product-linked GL |

This makes templates reusable.

---

# 5. Template Examples

## Manual Credit

Transaction Code

ADJ_CREDIT

Template

Debit

- GL: 5190 Adjustment Expense

Credit

- customer_account

---

## Manual Debit

Transaction Code

ADJ_DEBIT

Template

Debit

- customer_account

Credit

- GL: 1180 Suspense Receivable

---

## Internal Transfer

Transaction Code

XFER_INTERNAL

Template

Debit

- source_account

Credit

- destination_account

---

## Fee Posting

Transaction Code

FEE_POST

Template

Debit

- customer_account

Credit

- product_gl (fee income account)

---

## Interest Accrual

Transaction Code

INT_ACCRUAL

Template

Debit

- GL: Interest Expense

Credit

- GL: Accrued Interest Payable

---

## Interest Posting

Transaction Code

INT_POST

Template

Debit

- GL: Accrued Interest Payable

Credit

- customer_account

---

## ACH Credit

Transaction Code

ACH_CREDIT

Template

Debit

- GL: Due From Settlement Bank

Credit

- customer_account

---

## ACH Debit

Transaction Code

ACH_DEBIT

Template

Debit

- customer_account

Credit

- GL: ACH Settlement Clearing

---

## Check Post

Transaction Code

CHK_POST

Template

Debit

- customer_account

Credit

- GL: 2150 Check Clearing

---

# 6. Posting Engine Execution

When executing a transaction:

1. User submits transaction
2. System loads `transaction_code`
3. System loads associated `posting_template`
4. Template legs expand into `posting_legs`
5. PostingBatch created
6. Ledger entries committed

---

# 7. Validation Rules

Before committing a batch:

- debits must equal credits
- accounts must be active
- amount must be positive

---

# 8. Reversal Handling

Each transaction_code can define a `reversal_code`.

Reversal logic:

- copy original posting legs
- swap debit/credit
- link batches

---

# 9. Why Templates Matter

Posting templates provide:

- configurable accounting
- strong audit traceability
- reduced application complexity

They mirror the **posting matrices used in commercial core banking systems**.

---

# 10. Summary

Posting templates transform high-level transactions into balanced ledger entries, allowing BankCORE to maintain strict accounting integrity while keeping transaction workflows flexible and extensible.

