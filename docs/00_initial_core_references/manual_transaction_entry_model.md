# Manual Transaction Entry Model

**Status:** DROP-IN SAFE  
**Purpose:** Define how operational users create banking transactions that flow into the posting engine within the BankCORE back-office MVP.

---

# 1. Overview

The manual transaction entry model provides a structured method for operations staff to record financial events that affect customer accounts or internal ledger balances.

These transactions are not posted directly to balances. Instead, they become **operational transactions** that the posting engine converts into balanced financial entries.

Core flow:

```text
User Entry
   ↓
Operational Transaction
   ↓
Validation
   ↓
Posting Batch + Posting Legs
   ↓
Account Transactions
   ↓
Journal Entries
```

This architecture ensures that manual activity is auditable, reversible, and compliant with double-entry accounting rules.

---

# 2. Transaction Lifecycle

Each transaction moves through the following lifecycle states.

```text
Draft → Validated → Posted → Reversed
```

### Draft
Transaction is created but not yet eligible for posting.

### Validated
System confirms required fields and business rules.

### Posted
Posting engine creates a posting batch and associated ledger effects.

### Reversed
A new reversal transaction creates inverse postings.

Original records remain immutable.

---

# 3. Transaction Header

All manual transactions share a common header structure.

| Field | Purpose |
|------|--------|
| transaction_type | classification of operation |
| business_date | accounting date |
| reference_number | operator-visible identifier |
| description | narrative description |
| created_by | user initiating transaction |
| initiated_at | timestamp |
| status | lifecycle state |

This header allows the system to treat many operational events consistently.

---

# 4. Transaction Types (MVP)

The MVP supports a limited set of operational transaction types.

| Type | Description |
|-----|-------------|
| manual_adjustment | correction to account balance |
| internal_transfer | transfer between two accounts |
| fee_post | apply fee to account |
| interest_post | credit accrued interest |
| interest_accrual | record accrued interest |
| ach_entry | manual settlement entry |
| reversal | reversal of prior posting |

Additional transaction types can be introduced later without altering the posting architecture.

---

# 5. Transaction Lines

Some transactions require line-level detail.

Examples:

- transfer between two accounts
- ACH settlement
- multi-account adjustments

A transaction may include one or more lines containing:

| Field | Purpose |
|------|--------|
| account_id | affected account |
| amount_cents | amount |
| direction | debit or credit |
| memo | line explanation |

The posting engine converts these lines into posting legs.

---

# 6. Validation Rules

Before a transaction can post, several validations occur.

### Required fields

- transaction_type
- business_date
- reference_number
- affected account(s)
- amount

### Structural checks

- accounts exist and are active
- amount is non-zero
- valid business date

### Balance checks (where applicable)

- sufficient funds if debit
- account status allows posting

Validation failures keep the transaction in draft state.

---

# 7. Posting Engine Interaction

When validation succeeds, the transaction is submitted to the posting engine.

The posting engine:

1. Constructs a posting batch
2. Generates posting legs
3. Validates that debits equal credits
4. Commits posting atomically

Outputs generated:

- posting batch
- posting legs
- account transactions
- journal entries

---

# 8. Idempotency and Reference Control

Manual transactions must support safe re-submission.

Each transaction may include an **idempotency key** or unique reference number.

This prevents duplicate posting if a transaction is accidentally submitted more than once.

Example rule:

```text
(reference_number, business_date) must be unique
```

---

# 9. Reversal Workflow

Users cannot edit posted financial records.

Instead, corrections occur through reversal.

Steps:

1. user selects original transaction
2. system generates reversal transaction
3. posting engine produces inverse posting batch
4. new account and journal entries recorded

Original and reversal remain permanently linked.

---

# 10. Operational Controls

The model supports expansion to include operational safeguards.

Future controls may include:

- supervisor approval for high-value transactions
- dual control requirements
- override logging
- reason codes

These can be layered without altering the posting structure.

---

# 11. Example Transaction Flows

## Manual Account Credit

```text
User enters adjustment
  → credit account
  → offset suspense GL
```

---

## Internal Transfer

```text
User enters transfer
  → debit account A
  → credit account B
```

---

## Manual Fee Posting

```text
User selects fee type
  → debit account
  → credit fee income
```

---

## ACH Settlement Entry

```text
Operations records ACH debit
  → debit account
  → credit clearing GL
```

---

# 12. Relationship to Teller Workflows

The manual transaction model forms the foundation for future teller interactions.

Later teller UI will simply assemble transactions using the same transaction types and posting engine.

Example:

```text
Teller Deposit UI
        ↓
Creates Operational Transaction
        ↓
Posting Engine Processes It
```

No accounting redesign is required.

---

# 13. Key Design Rule

The central rule governing manual transaction entry is:

> operators record business events, but the posting engine determines financial truth.

Users describe the event.

The system determines the balanced accounting representation.

This separation ensures:

- accounting correctness
- operational flexibility
- safe automation expansion

---

# 14. Summary

The manual transaction entry model provides a controlled operational gateway into the financial kernel.

It ensures that all human-entered activity becomes:

- validated
- balanced
- auditable
- reversible

while preserving the integrity of the ledger-first architecture.

