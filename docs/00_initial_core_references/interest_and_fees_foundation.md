# Interest and Fees Foundation

**Status:** DROP-IN SAFE  
**Purpose:** Define the minimum architecture for interest accruals, interest posting, and fee assessment within the BankCORE ledger-first MVP.

---

# 1. Overview

Interest and fee processing are fundamental banking behaviors. Even in a back-office-first MVP, the system must be capable of:

- accruing interest
- posting earned interest to accounts
- assessing service fees
- reversing fees when appropriate
- producing correct GL accounting

These processes operate through the same posting engine used for all other financial activity.

---

# 2. Architectural Principle

All financial activity must flow through the posting engine.

```text
Interest or Fee Event
        ↓
Operational Transaction
        ↓
Posting Batch
        ↓
Posting Legs
        ↓
Account Transactions
        ↓
Journal Entries
```

This ensures that interest and fees remain fully auditable and reversible.

---

# 3. Interest Model

Interest handling is split into two phases.

### Phase 1 — Accrual

Accrual represents interest expense earned but not yet credited to the customer account.

Example posting:

```text
Debit   Interest Expense
Credit  Interest Payable
```

Accruals typically occur daily.

---

### Phase 2 — Posting

Posting moves the accumulated payable interest to the customer account.

Example posting:

```text
Debit   Interest Payable
Credit  Customer Deposit Account
```

This normally occurs monthly or at statement cycle boundaries.

---

# 4. Fee Model

Fees represent service charges applied to accounts.

Example posting:

```text
Debit   Customer Account
Credit  Fee Income
```

Fees may be:

- manually assessed
- rule-driven
- triggered by events

For MVP purposes, manual and simple rule-based fees are sufficient.

---

# 5. Core Tables Supporting This Layer

Recommended tables for this functionality:

## fee_types

Defines fee definitions.

| Field | Purpose |
|------|--------|
| code | short identifier |
| name | display label |
| amount_cents | default amount |
| gl_income_account_id | target income GL |
| active | enable/disable |

---

## fee_assessments

Tracks individual fee events.

| Field | Purpose |
|------|--------|
| account_id | affected account |
| fee_type_id | fee definition |
| amount_cents | applied amount |
| transaction_id | posting transaction |
| assessed_on | business date |

---

## interest_accruals

Tracks accumulated interest amounts before posting.

| Field | Purpose |
|------|--------|
| account_id | account earning interest |
| accrual_date | date accrued |
| amount_cents | accrued interest |
| transaction_id | accrual posting |

---

# 6. Example Operational Workflows

## Daily Interest Accrual

```text
System Job
  → calculate daily interest
  → create interest_accrual transaction
  → posting batch generated
```

---

## Monthly Interest Credit

```text
System Job
  → sum accruals
  → create interest_post transaction
  → posting batch generated
```

---

## Monthly Maintenance Fee

```text
Scheduled Job
  → create fee_post transaction
  → debit customer account
  → credit fee income
```

---

## Manual Fee Adjustment

```text
Operations User
  → selects account
  → selects fee type
  → submits manual fee
  → posting generated
```

---

# 7. Reversals

All fees and interest postings must support reversals.

Reversal behavior:

```text
Original Posting
      ↓
Reversal Transaction
      ↓
Inverse Posting Batch
```

Original records remain unchanged.

---

# 8. MVP Simplifications

The first version may intentionally simplify several areas:

- single interest rate per account
- no compounding options
- no tiered interest
- no complex fee waiver rules
- no promotional rates

These can be layered later without altering the posting architecture.

---

# 9. What This Enables

With interest and fee processing operational, the system can support:

- routine bank revenue
- liability accounting
- earnings tracking
- statement-ready activity

This represents a critical milestone in moving from a transaction prototype to a real banking system.

---

# 10. Relationship to Teller Phase

Interest and fee functionality operates independently of teller workflows.

When teller functionality is later introduced, teller transactions will simply become another source of operational transactions feeding the same posting engine.

The accounting model does not change.

---

# 11. Key Design Rule

The most important rule governing this layer is:

> interest and fees are never "directly applied" to balances.

They must always be expressed as balanced postings through the ledger.

This preserves auditability, reversibility, and accounting correctness.

