# Posting Lifecycle

**Status:** DROP-IN SAFE  
**Scope:** BankCORE / BankEncore architecture reference  
**Purpose:** Define the end-to-end lifecycle of a financial event from operational initiation through posting, subledger effects, GL effects, reversal handling, and end-of-day inclusion.

---

## 1. Overview

This document defines the canonical posting lifecycle for BankCORE / BankEncore.

It explains how a business event such as a deposit, withdrawal, transfer, fee, settlement item, or reversal moves through the platform and becomes:

- an operational record
- a balanced financial posting
- account-facing subledger activity
- general-ledger accounting activity
- an auditable event within the bank’s controlled business date model

This lifecycle is the financial spine of the platform.

It must remain:

- balanced
- atomic
- immutable after posting
- idempotent for unsafe writes
- traceable from source event to accounting output

---

## 2. Core Concepts

### 2.1 Operational transaction
The business event as users understand it.

Examples:
- teller deposit
- teller withdrawal
- account transfer
- check cashing
- fee assessment
- ACH settlement entry
- card settlement entry
- reversal request

This is the human/operational layer.

---

### 2.2 Posting batch
The canonical balanced financial representation of the event.

A posting batch:
- groups the accounting effects of one event
- must balance debits and credits
- is the financial source of truth for the event
- becomes immutable once posted

---

### 2.3 Posting leg
An individual debit or credit component in the posting batch.

A leg may point to:
- a customer account
- a GL account
- a cash location
- a settlement/suspense position

---

### 2.4 Account transaction
The customer-facing subledger effect produced from posting.

This is what appears as account activity and supports balances, statements, and history.

---

### 2.5 Journal entry
The accounting representation of the posted event in the institution’s GL layer.

---

### 2.6 Business date
The bank-controlled accounting date used for:
- posting inclusion
- GL batching
- statements
- close-of-business logic

This may differ from wall-clock time.

---

## 3. Lifecycle States

A practical lifecycle for a financial event is:

```text
draft
→ validated
→ approved (if needed)
→ posted
→ included in EOD / GL summary
→ exported / reported
```

A reversal is a separate lifecycle:

```text
posted original
→ reversal requested
→ approved (if needed)
→ reversal posted
→ both remain in history
```

---

## 4. End-to-End Lifecycle

## Step 1 — Event initiation

A user or controlled system workflow initiates an operational event.

Examples:
- teller enters a deposit
- back office keys an ACH debit
- fee engine assesses a monthly fee
- supervisor initiates a correcting reversal

### Inputs typically captured
- transaction type
- channel
- branch
- workstation
- teller session
- accounts involved
- amounts
- instruments/items
- reason/memo
- reference numbers
- initiating user
- requested business date
- idempotency or reference key

### Primary records
- `transactions` or current teller transaction equivalent
- `transaction_lines`
- `transaction_items`
- optional `transaction_references`

At this stage the event is operational, not yet financially authoritative.

---

## Step 2 — Operational validation

The system validates whether the event is allowed before building posting.

### Typical validations
- required fields present
- transaction type supported
- accounts exist and are active
- account restrictions do not block activity
- teller session is open
- workstation/branch context is valid
- amount is positive and within policy
- external references are not duplicates
- requested business date is allowed
- sufficient available funds where applicable
- required instruments/items are complete

### Possible outcomes
- pass validation
- fail with user-correctable errors
- fail and require supervisor override
- hold for review or exception state

### Possible related records
- `transaction_exceptions`
- `override_requests`

No financial posting exists yet.

---

## Step 3 — Approval / override resolution

Some transactions require elevated approval.

Examples:
- large cash withdrawal
- backdated posting outside normal window
- reversal of posted activity
- override of hold/restriction policy
- fee waiver or variance write-off

### Approval outcomes
- approved
- denied
- expired
- cancelled

### Design rule
Approval does not itself change balances.

Approval only authorizes the system to continue into posting.

### Related records
- `override_requests`
- `audit_events`

---

## Step 4 — Posting plan construction

Once the event is valid and approved if required, the system builds the posting plan.

This is where business meaning becomes accounting meaning.

### Example: teller cash deposit to DDA
Operational meaning:
- customer deposits cash
- teller receives physical currency
- deposit account liability increases

Canonical financial plan:
- debit cash on hand / teller cash
- credit deposit liability

### Example: withdrawal from DDA in cash
Canonical financial plan:
- debit deposit liability
- credit teller cash

### Example: internal transfer between two accounts
Canonical financial plan:
- debit source deposit liability
- credit destination deposit liability

### Example: fee assessment
Canonical financial plan:
- debit customer account or receivable
- credit fee income

### Example: ACH settlement debit against customer account
Canonical financial plan:
- debit customer deposit liability
- credit ACH settlement clearing / suspense / payable target

### Posting plan outputs
- one `posting_batch`
- many `posting_legs`
- optional intended `account_transactions`
- optional intended `cash_movements`
- one `journal_entry` with `journal_entry_lines`

At this point the system has a proposed financial representation, but it is not yet committed.

---

## Step 5 — Posting validation

Before commit, the proposed posting batch must satisfy financial invariants.

### Required checks
- debits equal credits
- all required ledger targets resolve
- accounts referenced are valid for posting
- no duplicate posted event for the same idempotency/reference key
- business date is allowed
- reversal references a valid original posting if applicable
- any cash leg is compatible with teller session/cash location context
- resulting account effects are allowed by policy or approved override

### Failure behavior
If any posting validation fails:
- do not partially post
- return transaction to exception/error state
- record audit as appropriate

---

## Step 6 — Atomic posting commit

If posting validation succeeds, the system commits the financial event atomically.

### Must commit together where applicable
- `posting_batches`
- `posting_legs`
- `account_transactions`
- `journal_entries`
- `journal_entry_lines`
- `cash_movements`
- fee/interest/accrual linkage rows if involved
- audit event for posting

### Resulting state
- the event is now `posted`
- posting history is immutable
- balances may be recalculated or caches updated
- account activity becomes visible
- cash responsibility changes become visible
- GL effects now exist

### Design rule
There is no such thing as “half-posted.”

Either the financial mutation succeeds in full or the transaction rolls back.

---

## Step 7 — Subledger effects

After atomic commit, the system exposes the posted event through subledgers.

### 7.1 Account subledger
`account_transactions` are created for affected accounts.

These rows support:
- posted account history
- running balance calculations
- statements
- customer inquiry
- account reconciliation

### 7.2 Cash subledger / responsibility layer
`cash_movements` record physical cash effects.

These rows support:
- teller drawer balancing
- vault transfers
- branch cash reporting
- variance detection

### 7.3 Fee / interest operational linkage
For fee or interest events, supporting rows may be linked:
- `fee_assessments`
- `interest_accruals`
- `posting_links`

---

## Step 8 — Balance update / cache refresh

After posting, account balances may be refreshed.

### Important rule
Balances are derivative, not authoritative.

The true posted balance must always be explainable from durable posted history.

### Common balance effects
- posted balance updates immediately on posted account activity
- available balance adjusts based on holds and policy logic
- average balance snapshots may update on schedule

### Related records
- `account_balances`
- `account_holds`
- `funds_availability_holds`

---

## Step 9 — Audit event creation

Material posting actions must emit audit records.

### Minimum auditable events
- transaction initiated
- approval requested
- approval granted/denied
- posting committed
- reversal requested
- reversal committed
- failed posting attempt for material reason
- business-date exception or override use

### Audit goals
- who acted
- what action occurred
- which records were affected
- when it happened
- why it happened

---

## Step 10 — End-of-day inclusion

Once posted, the financial event belongs to a business date.

At end of day, posted events for that business date may be:
- included in GL summarization
- included in statement periods
- included in teller balancing and branch reports
- exported through daily control artifacts

### Related records
- `business_dates`
- `gl_batches`
- `gl_batch_lines`
- `statement_runs`
- `statements`
- `export_jobs`

A posted event does not become real only at EOD. It is already real when posted.

EOD changes how it is summarized, closed, and reported.

---

## 5. Reversal Lifecycle

A reversal is not an edit. It is a new posted financial event.

## Step R1 — reversal request
A user identifies a posted event that must be reversed.

### Inputs
- original posting batch / transaction reference
- reversal reason
- requested business date
- approver if needed

---

## Step R2 — reversal eligibility check
The system validates:
- original event exists and is posted
- original event is eligible for reversal under policy
- event has not already been fully reversed if prohibited
- reversal window/business-date rules are satisfied
- required approval is obtained

---

## Step R3 — reversal posting construction
The system builds a new posting batch whose legs mirror the original in inverse form.

### Example
Original:
- debit cash 100.00
- credit deposits 100.00

Reversal:
- debit deposits 100.00
- credit cash 100.00

### Required linkage
- reversal batch references original batch
- audit trail links both actions

---

## Step R4 — reversal posting commit
The reversal commits atomically like any other posting.

Effects:
- new `posting_batch`
- inverse `posting_legs`
- inverse `account_transactions`
- inverse `journal_entry_lines`
- balancing cash effects if relevant

Both original and reversal remain in history.

---

## 6. Idempotency Lifecycle

Unsafe financial writes must be idempotent.

## Step I1 — request fingerprinting
A unique idempotency or reference key is captured at transaction initiation.

## Step I2 — duplicate detection
Before posting, the system checks for an existing committed financial event with that same key.

## Step I3 — duplicate handling
- same key + same payload → return prior result
- same key + different payload → reject as conflict

This protects against:
- double-submit
- network retry ambiguity
- queue replay
- browser refresh after submit

---

## 7. Example Posting Flows

## 7.1 Cash deposit to deposit account

### Operational event
Teller receives $500 cash for account 1234.

### Likely records
- operational transaction header
- one or more transaction lines
- teller session context

### Posting batch
- debit teller cash / cash on hand: 500.00
- credit deposit liability for account 1234: 500.00

### Derived effects
- account transaction credit 500.00
- cash movement into teller responsibility
- journal entry lines to cash asset and deposit liability

---

## 7.2 Cash withdrawal from deposit account

### Posting batch
- debit deposit liability: 200.00
- credit teller cash: 200.00

### Derived effects
- account transaction debit 200.00
- cash movement out of teller responsibility

---

## 7.3 Transfer between two customer accounts

### Posting batch
- debit source account deposit liability: 75.00
- credit destination account deposit liability: 75.00

### Derived effects
- source account transaction debit 75.00
- destination account transaction credit 75.00
- usually no cash movement

---

## 7.4 Monthly maintenance fee

### Posting batch
- debit customer deposit account: 10.00
- credit fee income: 10.00

### Derived effects
- fee assessment row linked to posting
- account transaction debit 10.00
- GL income effect

---

## 7.5 ACH debit settlement entry

### Posting batch
- debit customer account: amount
- credit ACH clearing / payable / settlement target: amount

### Derived effects
- clearing item linked to posting
- account subledger updated
- settlement visible for reconciliation

---

## 8. State Model Recommendations

### 8.1 Transaction state suggestions
A practical state model for `transactions`:
- `draft`
- `validated`
- `pending_approval`
- `approved`
- `posting_failed`
- `posted`
- `voided` (only before posting)
- `reversed` (status by relationship, not mutation, if desired)

### 8.2 Posting batch state suggestions
A practical state model for `posting_batches`:
- `pending`
- `posted`
- `rejected`
- `reversed` (advisory classification; original row remains posted)

### 8.3 Override request state suggestions
- `requested`
- `approved`
- `denied`
- `expired`
- `used`
- `void`

---

## 9. Required Invariants During Lifecycle

The posting lifecycle must always preserve the following:

1. every posted batch balances  
2. posting is atomic  
3. posted history is immutable  
4. account effects derive from posting  
5. business date is explicit  
6. reversals are linked, not destructive  
7. cash movements reconcile to responsibility context  
8. idempotency prevents duplicates  
9. audit events capture material lifecycle transitions

---

## 10. Table Mapping

| Lifecycle stage | Primary tables/modules |
|---|---|
| initiation | `transactions`, `transaction_lines`, `transaction_items`, `transaction_references` |
| validation | transaction services, `transaction_exceptions` |
| approval | `override_requests`, `audit_events` |
| posting plan | posting service / builder |
| posting commit | `posting_batches`, `posting_legs`, `journal_entries`, `journal_entry_lines`, `account_transactions`, `cash_movements` |
| balance refresh | `account_balances`, `account_holds` |
| EOD inclusion | `business_dates`, `gl_batches`, `gl_batch_lines`, `statement_runs`, `statements` |
| reversal | new `posting_batches`, inverse `posting_legs`, linked `account_transactions`, `audit_events` |

---

## 11. BankCORE vs BankEncore Interpretation

### BankCORE focus
BankCORE primarily owns the hardest part of this lifecycle:
- operational event capture
- posting construction
- balanced posting commit
- account subledger effects
- cash movement effects
- GL-ready journal structure

### BankEncore extension
BankEncore extends that same lifecycle into broader operational maturity:
- CIF context and compliance gates
- funds availability controls
- fee and interest automation
- business-date close orchestration
- statements and reporting
- settlement reconciliation
- configuration and policy frameworks

In other words:

- **BankCORE** implements the financial kernel of posting
- **BankEncore** completes the surrounding banking operating model

---

## 12. Final Statement

The correct mental model for the platform is:

```text
Operational event
→ validation / approval
→ balanced posting batch
→ account + cash + GL effects
→ audit trail
→ business-date close and reporting
```

If this lifecycle remains explicit, balanced, and immutable, the platform can scale into a serious core banking system without losing financial integrity.

