# First Transaction Types

**Status:** DROP-IN SAFE  
**Scope:** BankCORE / BankEncore MVP transaction catalog  
**Purpose:** Define the initial set of transaction types that the posting engine must support for the ledger-first / back-office-first MVP.

---

# 1. Overview

This document defines the **first operational transaction types** supported by the BankCORE financial kernel.

These transactions are intentionally **back-office oriented**, allowing the system to operate without a teller UI while still performing real banking functions.

The goal is to support:

- manual operational corrections
- internal transfers
- fee posting
- interest accrual
- interest posting
- ACH/manual settlement entries
- transaction reversals

These transaction types exercise the full **posting engine architecture**:

- PostingBatch
- PostingLeg
- AccountTransaction
- GL impact

---

# 2. Design Principles

## 2.1 Every transaction posts through the posting engine
All transaction types create a **PostingBatch** containing balanced **PostingLegs**.

## 2.2 Customer accounts are liability accounts
Customer deposit accounts represent a **bank liability**.

- Credit → customer balance increases
- Debit → customer balance decreases

## 2.3 Ledger integrity comes first
All transactions must:

- balance debits and credits
- produce immutable posting records
- support controlled reversal

## 2.4 Teller interaction is optional
All transaction types in this document can be executed via:

- operations UI
- batch processing
- system jobs

---

# 3. Transaction Catalog

The MVP includes the following transaction types.

| Code | Transaction | Purpose |
|-----|-------------|--------|
| ADJ_CREDIT | Manual account credit | Correct or manually credit a deposit account |
| ADJ_DEBIT | Manual account debit | Correct or manually debit a deposit account |
| XFER_INTERNAL | Internal account transfer | Move funds between accounts |
| FEE_POST | Fee assessment | Charge service fee to account |
| INT_ACCRUAL | Interest accrual | Accrue deposit interest expense |
| INT_POST | Interest posting | Pay accrued interest to account |
| ACH_CREDIT | ACH credit | Incoming ACH funds |
| ACH_DEBIT | ACH debit | Outgoing ACH funds |

---

# 4. Manual Adjustment — Account Credit

## Code
`ADJ_CREDIT`

## Description
Manual credit to a customer account.

Used for:

- corrections
- goodwill adjustments
- manual deposit postings

## Inputs

- account_id
- amount
- description
- optional reference

## Posting

Debit:

- 5190 Adjustment / Correction Expense
  OR
- 1180 Suspense / Adjustment Receivable

Credit:

- customer deposit liability

---

# 5. Manual Adjustment — Account Debit

## Code
`ADJ_DEBIT`

## Description
Manual debit to a customer account.

Used for:

- correction of over-credit
- fee reversal corrections
- operational adjustments

## Inputs

- account_id
- amount
- description

## Posting

Debit:

- customer deposit liability

Credit:

- 1180 Suspense / Adjustment Receivable
  OR
- 4560 Miscellaneous Income

---

# 6. Internal Transfer

## Code
`XFER_INTERNAL`

## Description
Moves funds between two deposit accounts within the bank.

## Inputs

- source_account
- destination_account
- amount

## Posting

Debit:

- source account liability

Credit:

- destination account liability

## GL Impact

No external GL accounts required.

---

# 7. Fee Posting

## Code
`FEE_POST`

## Description
Charges a fee against a customer account.

## Inputs

- account_id
- fee_type
- amount

## Posting

Debit:

- customer deposit liability

Credit:

- 4510 Deposit Service Charges
  OR
- 4540 NSF / Overdraft Fees
  OR
- 4560 Miscellaneous Income

---

# 8. Interest Accrual

## Code
`INT_ACCRUAL`

## Description
Accrues interest expense owed to deposit accounts.

Typically run as a **scheduled job**.

## Inputs

- account_id
- interest_amount

## Posting

Debit:

- 5120 Interest Expense – NOW
  OR
- 5130 Interest Expense – Savings

Credit:

- 2510 Accrued Interest Payable

---

# 9. Interest Posting

## Code
`INT_POST`

## Description
Moves accrued interest into the customer's account balance.

## Inputs

- account_id
- interest_amount

## Posting

Debit:

- 2510 Accrued Interest Payable

Credit:

- customer deposit liability

---

# 10. ACH Credit

## Code
`ACH_CREDIT`

## Description
Incoming ACH deposit.

## Inputs

- account_id
- amount
- ach_reference

## Posting

Debit:

- 1120 Due from Settlement Bank

Credit:

- customer deposit liability

---

# 11. ACH Debit

## Code
`ACH_DEBIT`

## Description
Outgoing ACH debit from a customer account.

## Inputs

- account_id
- amount

## Posting

Debit:

- customer deposit liability

Credit:

- 2170 ACH Settlement Clearing

---

# 12. Reversal Rules

All transaction types must support **reversal**.

Reversal behavior:

- create new PostingBatch
- mirror original PostingLegs
- link to original batch

Example:

Original:

Debit Expense
Credit Deposit

Reversal:

Debit Deposit
Credit Expense

---

# 13. Validation Rules

All transactions must validate:

- debit == credit
- account exists
- account is active
- amount > 0

Optional later controls:

- overdraft limits
- fee suppression
- regulatory holds

---

# 14. Minimum Engine Coverage

These transaction types exercise all critical parts of the system:

- GL posting
- deposit account updates
- suspense handling
- accrual accounting
- settlement clearing

If these work correctly, the **financial kernel is operational**.

---

# 15. One Sentence Summary

The first BankCORE transaction catalog provides a minimal but complete operational set of adjustment, transfer, fee, interest, and ACH transactions that fully exercise the posting engine and allow the bank ledger to function before teller-level workflows are introduced.

