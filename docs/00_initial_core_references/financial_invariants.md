# Financial Invariants

**Status:** DROP-IN SAFE  
**Scope:** BankCORE / BankEncore architecture reference  
**Purpose:** Define the non-negotiable financial and control invariants that must hold true in a teller-first, branch-centric core banking platform.

---

## 1. Overview

This document defines the core invariants that protect the BankCORE / BankEncore platform from financial corruption, control failure, and audit breakdown.

These invariants are not optional design preferences. They are foundational rules that must be enforced across:

- teller operations
- account servicing
- posting and subledger logic
- general ledger accounting
- settlement processing
- approvals and overrides
- reporting and end-of-day operations

If these invariants are not enforced consistently, the system becomes unsafe for production banking use.

---

## 2. Terminology

For this document:

- **Operational transaction** means the business event as initiated by staff or internal workflows.
- **Posting batch** means the canonical balanced financial representation of that event.
- **Posting leg** means an individual debit or credit component within a posting batch.
- **Account subledger** means customer-facing account activity.
- **GL** means the institution’s general ledger.
- **Business date** means the bank-controlled accounting date, which may differ from wall-clock calendar date.

---

## 3. Non-Negotiable Invariants

### 3.1 Every financial event must balance

**Rule**  
No financial event may be posted unless total debits equal total credits.

**Formal statement**

```text
SUM(debit_legs.amount) == SUM(credit_legs.amount)
```

**Why it matters**
- Prevents accidental creation or destruction of value
- Protects ledger integrity
- Ensures accounting correctness at the transaction level

**Applies to**
- teller deposits
- withdrawals
- transfers
- fee postings
- interest postings
- reversals
- settlement postings
- adjustments

**Implementation expectation**
- enforce at posting-batch validation time
- reject commit if the batch is unbalanced
- never rely solely on UI-side balancing

---

### 3.2 Posted financial history is immutable

**Rule**  
Once a financial transaction is posted, the posted representation may not be edited or deleted.

**Why it matters**
- Preserves forensic history
- Supports regulatory defensibility
- Eliminates hidden balance drift caused by destructive edits

**Allowed correction model**
- reverse the original posting batch
- create a new corrected posting batch if needed

**Not allowed**
- changing amounts on already-posted rows
- changing debit/credit destinations of already-posted rows
- deleting posted rows to “fix” history

**Implementation expectation**
- application-level restriction on updates/deletes to posted records
- database-level protection where practical
- explicit reversal linkage via `reversal_of_batch_id` or equivalent

---

### 3.3 Every operational transaction must resolve to one canonical posting batch

**Rule**  
Each completed financial event must have exactly one authoritative posted financial representation.

**Why it matters**
- Prevents duplicate or competing financial truth
- Makes reconciliation and tracing deterministic
- Supports clean drill-down from operations to accounting

**Implementation expectation**
- operational transaction → posting batch should be one-to-one for posted events
- complex transactions may have multiple lines/items, but still one canonical posted batch
- reversal is a new batch, not a mutation of the original batch

---

### 3.4 Every posted account movement must be explainable from posting

**Rule**  
Customer-facing account activity must derive from posted financial events.

**Why it matters**
- Ensures customer balances are anchored to accounting truth
- Prevents unsupported balance changes
- Preserves explainability from account history back to core posting

**Implementation expectation**
- `account_transactions` must point to `posting_batches` or equivalent financial source
- no orphan account movements
- no direct balance change without an underlying posted financial event

---

### 3.5 Cached balances are derivatives, not the source of truth

**Rule**  
Balances may be cached for performance, but the authoritative value must be derivable from subledger/posting history.

**Why it matters**
- Protects against silent cache corruption
- Supports rebuilds and reconciliation
- Makes audit and recovery possible

**Implementation expectation**
- `account_balances` is a performance table, not the sole authority
- true posted balance must be reproducible from financial history
- rebuild procedures must exist or be possible by design

---

### 3.6 Business date controls accounting, not wall-clock time alone

**Rule**  
All financial activity must be assigned a business date that determines accounting, GL inclusion, statements, and operational close.

**Why it matters**
- Banks close by controlled business date, not raw timestamp alone
- Supports end-of-day operations and after-hours workflows
- Allows consistent handling of backdated and future-dated items

**Implementation expectation**
- store both operational timestamps and business date
- GL batching and statements must key off business date
- branch-local timezone/cutoff logic must be respected

---

### 3.7 Financial posting must be atomic

**Rule**  
A financial event posts in full or not at all.

**Why it matters**
- Prevents partial ledger corruption
- Ensures account, cash, and GL effects remain synchronized
- Supports dependable retry behavior

**Implementation expectation**
- posting batch, posting legs, account subledger rows, and journal rows must commit in a single transaction where applicable
- any failure must rollback the entire financial mutation

---

### 3.8 Reversals must be explicit and traceable

**Rule**  
A reversal must reference the original posted event it is reversing.

**Why it matters**
- Preserves history without ambiguity
- Supports audit and operations review
- Allows netting and exception analysis

**Implementation expectation**
- reversal rows must link back to original posting batch and/or transaction
- reversal reason should be captured
- reversal timestamp, business date, actor, and approver should be auditable

---

### 3.9 External systems are settlement inputs, not authoritative ledgers

**Rule**  
No external network or third-party feed may directly define institution balances inside the core.

**Why it matters**
- Keeps the core system authoritative
- Prevents vendor/system mismatch from silently altering books
- Aligns with a controlled internal posting model

**Applies to**
- ACH files
- card settlements
- wire notices
- check clearing files
- ATM/network settlement data

**Implementation expectation**
- external activity is captured as clearing/settlement items
- institution staff or controlled batch logic turns that input into internal posting
- reconciliation compares internal posting to external settlement, not vice versa

---

### 3.10 Idempotency is mandatory for unsafe financial writes

**Rule**  
A repeated financial request must not create duplicate postings.

**Why it matters**
- Protects against retries, double-clicks, queue replays, and network ambiguity
- Prevents duplicate deposits, withdrawals, fees, or reversals

**Implementation expectation**
- unsafe writes require a unique request/reference/idempotency key
- duplicate retries with same payload return the original result
- conflicting retries with same key but different payload are rejected

---

### 3.11 Cash responsibility must reconcile to physical currency

**Rule**  
Teller and vault cash responsibility must reconcile mathematically from opening state through all movements to closing state.

**Formal concept**

```text
opening cash
+ inbound cash movements
- outbound cash movements
± approved adjustments
= expected closing cash
```

**Why it matters**
- Supports drawer balancing
- Protects against loss and theft
- Preserves operational accountability

**Implementation expectation**
- cash movements must be explicitly recorded
- teller sessions must have clear open/close state
- over/short differences must be captured as variances, not silently absorbed

---

### 3.12 Available funds and posted balance are not the same thing

**Rule**  
The system must distinguish between posted balance, available balance, and held/restricted funds.

**Why it matters**
- supports funds-availability policy
- supports holds, restraints, and pending restrictions
- prevents the misuse of customer ledger balance for real-time decisioning

**Implementation expectation**
- posted balance reflects posted activity only
- available balance reflects holds/release logic
- holds must have explicit lifecycle and, where needed, release schedule rows

---

### 3.13 Authorization and override controls must gate exceptional activity

**Rule**  
Certain risk-bearing actions must require elevated approval rather than normal execution.

**Examples**
- reversal of posted financial activity
- large withdrawals
- fee waiver above policy threshold
- override of account restrictions
- backdating outside permitted window
- vault transfers under dual control

**Why it matters**
- enforces segregation of duties
- reduces fraud and error risk
- supports branch and supervisory control expectations

**Implementation expectation**
- override lifecycle must be explicit
- approved overrides must be limited in scope and time
- use of an approved override must itself be audited

---

### 3.14 Auditability must exist for every material mutation and sensitive read

**Rule**  
The system must record who did what, to which record, when, and why for material mutations and sensitive events.

**Why it matters**
- required for regulated operations
- supports investigations and controls testing
- protects against untraceable privileged behavior

**Minimum auditable categories**
- financial postings and reversals
- account maintenance changes
- user/security actions
- override approvals and use
- settings/config changes
- PII unmask/read events where applicable
- export generation

**Implementation expectation**
- audit events should be append-only
- raw sensitive values should be masked/redacted in audit payloads where appropriate

---

### 3.15 Settlement differences must resolve through explicit exception handling

**Rule**  
Unmatched, incomplete, or failed external-origin items must never disappear silently.

**Why it matters**
- protects reconciliation integrity
- prevents hidden losses or off-book items
- makes suspense and exception management explicit

**Implementation expectation**
- unmatched settlement items become reconciliation exceptions or suspense-posting cases
- exception state must remain visible until resolved
- resolution action must be tracked and auditable

---

### 3.16 Closed business periods must remain protected

**Rule**  
Backdated activity affecting a closed business date or closed statement/GL period must be controlled and explicitly flagged.

**Why it matters**
- protects accounting close integrity
- supports deterministic reporting and statementing
- prevents casual corruption of prior closed periods

**Implementation expectation**
- backdating beyond policy requires override
- affected GL batches/statements must be flagged for recomputation or adjustment handling
- historical re-open behavior must be governed, not implicit

---

### 3.17 Product and policy rules may shape posting, but may not violate invariants

**Rule**  
Configurable product logic can influence behavior, but no configuration may override balancing, immutability, atomicity, or auditability.

**Why it matters**
- prevents “flexible configuration” from weakening core controls
- protects system safety across products and branches

**Implementation expectation**
- fee rules, interest rules, funds-availability policies, and account settings remain subordinate to core ledger invariants
- settings validation must prevent invalid combinations where possible

---

## 4. Derived Control Expectations

The invariants above imply the following platform expectations.

### 4.1 Required platform traits
- balanced posting engine
- immutable posting history
- explicit reversal support
- business-date model
- auditable override workflow
- account holds and available-balance logic
- explicit cash movement tracking
- settlement exception handling
- durable audit event model
- ability to rebuild or verify balances from history

### 4.2 Expected data-model support
At minimum, the platform should support the following table families:

- operational transactions
- posting batches / posting legs
- account transactions / balances / holds
- journal entries / journal lines / GL batches
- teller sessions / cash movements / cash variances
- clearing items / settlement exceptions
- override requests
- audit events
- business dates

---

## 5. Invariants Mapped to Canonical Table Areas

| Invariant | Primary tables/modules involved |
|---|---|
| balanced posting | `posting_batches`, `posting_legs`, `journal_entries`, `journal_entry_lines` |
| immutability | `posting_batches`, `posting_legs`, `account_transactions`, `journal_entries` |
| atomic posting | posting service + database transaction boundaries |
| business date | `transactions`, `posting_batches`, `business_dates`, `gl_batches`, `statements` |
| cash reconciliation | `teller_sessions`, `cash_movements`, `cash_counts`, `cash_variances` |
| holds vs available funds | `account_balances`, `account_holds`, `funds_availability_holds` |
| authorization / override | `override_requests`, `transaction_exceptions`, `audit_events` |
| settlement exception handling | `clearing_items`, `settlement_batches`, `reconciliation_exceptions` |
| auditability | `audit_events` across all modules |
| config cannot violate core rules | `settings_catalog`, `settings_values`, platform validators |

---

## 6. Practical Enforcement Guidance

### 6.1 Enforce in more than one layer
Important invariants should be protected in multiple places:
- UI/workflow validation
- application service layer validation
- database constraints or transaction design where practical
- audit logging for attempted violation or override

### 6.2 Prefer structural prevention over procedural warning
Where possible:
- make invalid state impossible
- do not rely on training or screen messaging alone

### 6.3 Treat reporting as a verification layer, not a substitute for controls
Reports help detect issues, but invariant enforcement must occur at transaction time.

---

## 7. What this means for BankCORE / BankEncore

BankCORE already aligns strongly with the highest-value invariants because its architecture centers on:

- operational transaction capture
- posting-batch / posting-leg accounting
- account transaction derivation
- teller session and cash movement tracking
- GL-ready financial structure

BankEncore extends those same invariants into the broader operational platform through:

- CIF and compliance
- statements
- funds availability and holds
- settings and policy control
- audit and business-date orchestration
- reconciliation and servicing workflows

That means the current architectural direction is correct. The work ahead is primarily about deepening control coverage, operational maturity, and product completeness without weakening the financial kernel.

---

## 8. Final Statement

The most important rule of the platform is this:

> Every financial event must be explainable, balanced, auditable, and reconstructable from durable history.

If that remains true, the platform can mature safely. If that becomes false, the system stops being a trustworthy banking core.

