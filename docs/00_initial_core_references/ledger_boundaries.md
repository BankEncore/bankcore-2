# Ledger Boundaries

**Status:** DROP-IN SAFE  
**Scope:** BankCORE / BankEncore architecture reference  
**Purpose:** Define the boundaries and responsibilities between operational records, the account subledger, the internal posting engine, and the institution general ledger.

---

# 1. Why Ledger Boundaries Matter

Banking systems frequently fail or become unmaintainable when the boundaries between:

- operational transactions
- customer account history
- internal posting logic
- the general ledger

become blurred.

The architecture used in **BankCORE / BankEncore** deliberately separates these layers so that:

- operational workflows remain flexible
- financial accounting remains correct
- customer balances remain explainable
- reconciliation remains possible
- regulatory audit remains defensible

These boundaries are foundational to a safe core banking platform.

---

# 2. The Four Financial Layers

The system intentionally separates financial activity into four layers.

```
Operational Layer
        ↓
Posting Engine Layer
        ↓
Subledger Layer (Customer Accounts)
        ↓
General Ledger Layer (Bank Accounting)
```

Each layer has a distinct responsibility.

---

# 3. Layer 1 — Operational Layer

## Purpose

Capture **what happened operationally**.

This is the user-facing layer of the system.

Examples:

- teller deposit
- teller withdrawal
- internal transfer
- fee assessment
- ACH item posting
- card settlement item
- check clearing item

Operational records contain **business meaning**, not accounting meaning.

---

## Typical tables

| Table | Purpose |
|------|--------|
| `transactions` | Operational transaction header |
| `transaction_lines` | Accounts or instruments involved |
| `transaction_items` | Checks, ACH items, card items |
| `transaction_references` | External IDs or idempotency keys |

---

## Important rule

Operational records **do not directly change balances**.

They must go through the posting engine.

---

# 4. Layer 2 — Posting Engine Layer

## Purpose

Translate operational meaning into **balanced financial accounting entries**.

This layer enforces:

- double entry
- atomic commit
- financial invariants
- immutability after posting

---

## Typical tables

| Table | Purpose |
|------|--------|
| `posting_batches` | Balanced financial event |
| `posting_legs` | Individual debit/credit lines |

---

## Example

Customer deposits $500 cash.

Posting batch:

| Debit | Credit |
|------|-------|
| Cash on Hand | Deposits Liability |

The posting engine is **the financial source of truth**.

---

## Key rules

Posting engine must guarantee:

- debits equal credits
- posting is atomic
- posting history is immutable

---

# 5. Layer 3 — Account Subledger

## Purpose

Provide the **customer-facing financial history**.

This is the ledger used for:

- account balances
- statements
- transaction history
- customer service inquiries

---

## Typical tables

| Table | Purpose |
|------|--------|
| `account_transactions` | Account activity rows |
| `account_balances` | Cached balances |
| `account_holds` | Restrictions and holds |

---

## Relationship to posting

Account transactions are **derived from posting**, not created independently.

```
posting_batch
   → posting_leg
       → account_transaction
```

This ensures account balances remain consistent with financial accounting.

---

# 6. Layer 4 — General Ledger

## Purpose

Represent the bank's **official accounting books**.

This layer supports:

- financial statements
- regulatory reporting
- GL trial balance
- accounting reconciliation

---

## Typical tables

| Table | Purpose |
|------|--------|
| `gl_accounts` | Chart of accounts |
| `journal_entries` | Financial journal header |
| `journal_entry_lines` | Debit/credit lines |

---

## Relationship to posting

Posting batches generate journal entries.

```
posting_batch
   → journal_entry
       → journal_entry_lines
```

GL summarization may occur at end-of-day.

---

# 7. Cash Responsibility Layer

Cash is a special case.

Physical currency must reconcile with financial posting.

---

## Typical tables

| Table | Purpose |
|------|--------|
| `teller_sessions` | Teller drawer lifecycle |
| `cash_movements` | Cash entering/leaving responsibility |
| `cash_counts` | Physical cash verification |
| `cash_variances` | Over/short tracking |

---

## Relationship to posting

Cash legs in posting batches produce `cash_movements`.

```
posting_leg (cash)
      ↓
 cash_movement
```

This keeps teller balancing tied to financial posting.

---

# 8. Settlement & Clearing Layer

External systems introduce transactions that must eventually resolve into posting.

Examples:

- ACH
- card networks
- check clearing
- wire settlements

---

## Typical tables

| Table | Purpose |
|------|--------|
| `clearing_items` | External settlement items |
| `settlement_batches` | Settlement groupings |
| `reconciliation_exceptions` | Unmatched items |

---

## Important rule

External networks **never directly change balances**.

They produce items which must be converted into posting batches.

---

# 9. Boundary Rules

## Rule 1

Operational records never directly change balances.

---

## Rule 2

Posting engine is the only component allowed to create financial effects.

---

## Rule 3

Subledger rows must derive from posting.

---

## Rule 4

General ledger rows must derive from posting.

---

## Rule 5

External settlement systems cannot directly modify balances.

---

## Rule 6

Reversals must occur via new posting batches.

---

# 10. Data Flow Overview

The full financial data flow is:

```
Operational Event
        ↓
Posting Engine
        ↓
Posting Batch / Legs
        ↓
Account Subledger
        ↓
General Ledger
        ↓
Reporting & Statements
```

Cash and settlement layers intersect with posting but never bypass it.

---

# 11. Why This Model Scales

Separating these layers allows the system to grow without corrupting financial integrity.

Operational workflows can evolve without touching accounting.

Accounting can change structure without rewriting teller workflows.

Settlement integrations can be added without bypassing financial controls.

---

# 12. BankCORE vs BankEncore Roles

## BankCORE

Implements the financial kernel:

- posting engine
- account subledger
- teller session cash controls
- core transaction workflows

---

## BankEncore

Extends the platform around the financial core:

- CIF
- compliance
- statements
- reporting
- settlement reconciliation
- policy and configuration management

---

# 13. Final Mental Model

A safe banking system always answers three questions clearly:

**What happened?**  
Operational layer.

**How did it affect the books?**  
Posting engine.

**How did it affect the customer?**  
Account subledger.

**How did it affect the bank's accounting?**  
General ledger.

Maintaining these boundaries keeps the platform stable as it grows from a teller system into a full banking core.

