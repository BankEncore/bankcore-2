# Business Date and End-of-Day (EOD)

**Status:** DROP-IN SAFE  
**Scope:** BankCORE / BankEncore architecture reference  
**Purpose:** Define how the platform manages the banking business date, daily operational closure, financial summarization, and control procedures required to operate a regulated banking environment.

---

# 1. Overview

Banks do not operate purely on wall-clock time.

Financial systems operate using a **controlled business date** that determines:

- which day transactions belong to
- which GL period receives postings
- which statement cycle includes activity
- which teller sessions may remain open
- when reconciliation must occur

The **Business Date** is the authoritative accounting date for the institution.

---

# 2. Wall Time vs Business Date

Two time concepts must exist simultaneously.

| Concept | Meaning |
|---|---|
| Wall Clock Time | Actual system timestamp |
| Business Date | Accounting day controlled by the bank |

Example:

```
Wall Clock: 2026‑03‑06 18:30
Business Date: 2026‑03‑06
```

If the branch operates past midnight:

```
Wall Clock: 2026‑03‑07 00:30
Business Date: 2026‑03‑06
```

Transactions continue posting to the **prior business day** until the institution performs day‑close.

---

# 3. Why Business Date Exists

Business date control allows banks to:

- finish teller balancing after closing time
- complete nightly settlement processing
- produce deterministic financial reports
- prevent accidental back‑posting into closed periods
- coordinate multi‑branch operations

Without a controlled business date, financial reporting becomes unreliable.

---

# 4. Business Date Table

## Suggested table

`business_dates`

| Column | Purpose |
|---|---|
| id | Primary key |
| business_date | Accounting date |
| status | open / closing / closed |
| opened_at | Timestamp when day began |
| closed_at | Timestamp when day closed |
| opened_by | User/system |
| closed_by | User/system |

---

## Rules

Only **one business date** may be open at a time for the institution.

States:

```
open → closing → closed
```

---

# 5. Teller Operational Lifecycle

The teller lifecycle occurs inside the business date.

## Teller session lifecycle

```
session_open
→ transactions posted
→ balancing
→ session_close
```

## Teller session table

`teller_sessions`

| Field | Purpose |
|---|---|
| teller_id | user |
| branch_id | branch |
| business_date | accounting day |
| opened_at | timestamp |
| closed_at | timestamp |
| opening_cash | starting drawer |
| closing_expected | calculated |
| closing_actual | counted |
| variance | over/short |

---

# 6. Cash Balancing

Cash responsibility must reconcile.

```
opening cash
+ inbound cash movements
- outbound cash movements
± adjustments
= expected closing cash
```

If counted cash differs:

```
variance = counted - expected
```

Variances must be recorded and explained.

---

# 7. Branch Close Requirements

Before a business date can close, several conditions must be satisfied.

Typical requirements:

- all teller sessions closed
- vault balanced
- no unresolved transaction exceptions
- settlement imports processed
- reconciliation exceptions acknowledged

The system should enforce these checks before allowing EOD.

---

# 8. End-of-Day (EOD) Process

The EOD process transitions the institution from one business date to the next.

## EOD Phases

```
1. Teller closure
2. Operational validation
3. Financial summarization
4. Statement inclusion
5. GL batch generation
6. Settlement reconciliation
7. Business date rollover
```

---

# 9. Phase 1 — Teller Closure

Requirements:

- all teller sessions closed
- cash counted
- variances recorded

Outputs:

- teller balancing reports
- branch cash totals

---

# 10. Phase 2 — Operational Validation

System verifies:

- no open teller sessions
- no transactions stuck in "pending"
- no incomplete postings
- required settlements imported

Failures should block EOD.

---

# 11. Phase 3 — Financial Summarization

Posting batches from the day may be grouped into GL batches.

Tables involved:

- `posting_batches`
- `journal_entries`
- `journal_entry_lines`
- `gl_batches`

Example summarization:

```
All deposit liability credits
All cash debits
All fee income
```

These become the bank's accounting entries for the day.

---

# 12. Phase 4 — Statement Inclusion

Transactions belonging to the business date become eligible for statement runs.

Tables:

- `statement_runs`
- `statements`

Statement engines may run nightly or on cycle.

---

# 13. Phase 5 — GL Batch Creation

The system generates accounting batches for the general ledger.

Tables:

| Table | Purpose |
|---|---|
| `gl_batches` | Accounting batch |
| `gl_batch_lines` | summarized entries |

GL export may occur automatically or through integration.

---

# 14. Phase 6 — Settlement Reconciliation

External networks must reconcile against internal posting.

Examples:

- ACH totals
- card settlement totals
- check clearing totals

Tables:

- `clearing_items`
- `settlement_batches`
- `reconciliation_exceptions`

Exceptions must remain visible until resolved.

---

# 15. Phase 7 — Business Date Rollover

After successful completion of all checks:

```
current_date.status → closed
next_date.status → open
```

New transactions now post to the new business date.

---

# 16. Backdating Rules

Backdating may be allowed within policy.

Examples:

- correcting same-day entry
- late settlement item

However:

- backdating into **closed business dates** should require override
- GL impact must be flagged

---

# 17. Multi-Branch Considerations

Branches may operate in different time zones.

However the system must enforce:

- a single institutional business date
- branch cutoff times
- branch-specific close readiness

---

# 18. Failure Handling

If EOD fails:

- business date remains open
- system records failure state
- operators must resolve issues

The system should never partially close a business day.

---

# 19. Audit Requirements

EOD activity must generate audit records.

Required audit items:

- business date opened
- business date closed
- teller variance
- settlement mismatch
- manual overrides

---

# 20. Relationship to Other Architecture Docs

This document connects with:

| Document | Relationship |
|---|---|
| FINANCIAL_INVARIANTS.md | Business date protects accounting integrity |
| POSTING_LIFECYCLE.md | Posting assigns business date |
| LEDGER_BOUNDARIES.md | GL summarization occurs at EOD |
| CANONICAL_TABLE_MODEL.md | Defines supporting tables |

---

# 21. BankCORE vs BankEncore Roles

## BankCORE

Implements:

- teller session lifecycle
- cash balancing
- transaction posting with business date

## BankEncore

Extends with:

- institution-level day close
- GL summarization
- statement generation
- settlement reconciliation
- reporting and controls

---

# 22. Final Mental Model

A banking day behaves like this:

```
Business Date Opens
      ↓
Tellers Process Transactions
      ↓
Posting Engine Records Financial Events
      ↓
Tellers Balance Drawers
      ↓
Branch Operations Validate State
      ↓
End-of-Day Processing Runs
      ↓
Business Date Closes
      ↓
Next Business Date Opens
```

This cycle repeats every banking day and forms the operational heartbeat of the institution.

