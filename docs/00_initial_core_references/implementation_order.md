Bas# Implementation Order

**Status:** DROP-IN SAFE  
**Scope:** BankCORE / BankEncore architecture and build planning reference  
**Purpose:** Translate the ledger-first / back-office-first architecture into a practical implementation sequence, including migration order, model/service order, initial transaction types, seed data priorities, and deferred scope.

---

# 1. Overview

This document defines the recommended build order for the revised BankCORE MVP.

The goal is to build the platform in a sequence that:

- proves financial correctness early
- reduces rework
- keeps schema dependencies manageable
- enables usable back-office posting before teller complexity is introduced
- preserves clean boundaries between operational entry, posting, subledger, and GL

This order assumes the current MVP priority is:

1. ledger integrity
2. manual operational posting
3. interest accrual and fee posting
4. business date control
5. teller and branch cash workflows later

---

# 2. Guiding Build Principles

## 2.1 Build financial truth before UI richness
The system must know how to post safely before it knows how to offer many operator interaction patterns.

## 2.2 Build stable references before transactional layers
Master tables and accounting references should exist before posting logic depends on them.

## 2.3 Build the posting engine before specialized workflows
Fees, interest, ACH entries, and later teller flows should all reuse the same posting model.

## 2.4 Delay projections until the source of truth is stable
Derived tables like `account_balances` should come after posting and subledger mechanics are defined.

## 2.5 Delay cash and teller orchestration until the ledger-first MVP is operational
Teller sessions, cash drawers, and vault workflows add substantial state complexity and should not distort the financial kernel early.

---

# 3. Recommended High-Level Phases

```text
Phase 0  Foundation and reference setup
Phase 1  Core master records and business date
Phase 2  Transaction and posting kernel
Phase 3  GL projection and account projection
Phase 4  First usable back-office transaction types
Phase 5  Interest and fees foundation
Phase 6  Audit, overrides, and holds
Phase 7  Teller and branch cash controls
```

---

# 4. Phase 0 — Foundation and Reference Setup

## Objective
Create the minimum non-transactional framework needed for safe implementation.

## Deliverables
- architecture docs committed
- naming conventions stabilized
- model boundaries agreed
- migration naming/order convention agreed
- seed-data strategy agreed
- status enums and code constants standardized

## Recommended outputs
- architecture docs under `docs/architecture/`
- a light glossary for transaction/accounting terms
- stable enum/constants list for statuses and transaction types

## Why this phase matters
It reduces later renaming, migration churn, and semantic drift.

---

# 5. Phase 1 — Core Master Records and Business Date

## Objective
Create stable master data tables required by the financial kernel.

## Migrations to build first
1. `parties`
2. `accounts`
3. `account_owners`
4. `gl_accounts`
5. `business_dates`

## Why this order
- `parties` and `accounts` are required for customer/account context
- `account_owners` depends on both
- `gl_accounts` is required before posting rules can target real accounting destinations
- `business_dates` is required before posted financial activity becomes banking-aware

## Models/services to implement next
- Party model
- Account model
- AccountOwner model
- GlAccount model
- BusinessDate model/service

## Minimum features to support in this phase
- create party
- create account
- link owner to account
- seed chart of accounts
- open one business date
- validate current open business date

## Seed data priorities
At minimum seed GL accounts for:
- deposit liability
- adjustment/suspense
- interest expense
- interest payable
- fee income
- ACH clearing

---

# 6. Phase 2 — Transaction and Posting Kernel

## Objective
Build the smallest safe transactional accounting engine.

## Migrations
6. `transactions`
7. `posting_batches`
8. `posting_legs`

## Why this order
- `transactions` is the operational anchor
- `posting_batches` depends on `transactions`
- `posting_legs` depends on `posting_batches` and references accounts/GL accounts

## Models/services
- Transaction model
- PostingBatch model
- PostingLeg model
- PostingBuilder or PostingEngine service
- PostingValidator service
- Reversal planner/service skeleton

## Minimum service responsibilities
- accept operational transaction
- choose mapping rule by transaction type
- build debit/credit legs
- verify balancing
- verify account and GL targets exist
- verify business date is allowed
- commit or fail closed

## Must-have rules in this phase
- one posting batch per transaction
- positive amounts only in legs
- debit total equals credit total
- no direct balance mutation outside posting path

## First supported transaction types in this phase
1. `manual_adjustment`
2. `internal_transfer`
3. `reversal` (skeleton if full reversal not yet wired)

---

# 7. Phase 3 — GL Projection and Account Projection

## Objective
Project posted financial truth into account-facing and GL-facing ledgers.

## Migrations
9. `journal_entries`
10. `journal_entry_lines`
11. `account_transactions`
12. `account_balances`

## Why this order
- journal structures derive from posting
- account transactions derive from posting
- balances derive from account transactions

## Models/services
- JournalEntry model
- JournalEntryLine model
- AccountTransaction model
- AccountBalance model
- Journal projector/service
- Account projector/service
- Balance refresh/rebuild service

## Minimum behaviors
- one journal entry per posted batch for MVP
- one or more journal lines derived from GL-facing posting legs
- one or more account transactions derived from account-facing posting legs
- balance refresh after successful posting

## Critical implementation rule
Do not build account balance mutation as a standalone feature. It must be driven from posted account transactions.

---

# 8. Phase 4 — First Usable Back-Office Transaction Types

## Objective
Turn the kernel into a usable back-office posting system.

## Implement these transaction types first
### 4.1 `manual_adjustment`
Use case:
- correct account balance with explicit offset GL

Why first:
- simplest real-world back-office transaction
- exercises account + GL posting together

### 4.2 `internal_transfer`
Use case:
- move value between two accounts

Why second:
- proves account-to-account posting without complex GL configuration

### 4.3 `ach_entry`
Use case:
- record manual ACH debit/credit settlement item

Why third:
- proves external-origin entry into internal posting model

## Services/UI needed
- manual transaction form/service
- transaction type mapping registry
- posting preview or validation summary (recommended)
- posting result screen/log view

## Deliverable milestone
At the end of this phase, operations staff should be able to create and post a small set of real transactions through the ledger-first model.

---

# 9. Phase 5 — Interest and Fees Foundation

## Objective
Add the financial behaviors that motivated the revised MVP.

## Migrations to add next
13. `fee_types`
14. `fee_assessments`
15. `interest_accruals`

## Why this order
- `fee_types` defines the fee catalog
- `fee_assessments` tracks applied fees
- `interest_accruals` tracks earned interest before posting or crediting

## Models/services
- FeeType model
- FeeAssessment model
- InterestAccrual model
- Fee posting service
- Interest accrual calculation service
- Interest posting service

## Implement in this order
### 5.1 Manual fee posting
Why first:
- simplest fee behavior
- exercises transaction → posting → account → GL flow

### 5.2 Scheduled/simple fee posting
Why second:
- proves job-driven transaction creation using same posting engine

### 5.3 Interest accrual
Why third:
- exercises pure GL posting without immediate account effect

### 5.4 Interest posting to account
Why fourth:
- bridges accrued GL liability into customer account credit

## First seed/setup data required
- fee types (maintenance, service charge, manual correction fee)
- account/product rate attributes or simple account-level rate field
- GL accounts for fee income, interest expense, interest payable

---

# 10. Phase 6 — Audit, Overrides, and Holds

## Objective
Add the minimum governance and control structures needed for serious operations.

## Migrations
16. `audit_events`
17. `override_requests`
18. `account_holds`

## Why this phase comes here
Once posting and fee/accrual activity are working, the next priority is operational control and explainability.

## Models/services
- AuditEvent model/service
- OverrideRequest model/service
- AccountHold model/service

## Implementation order
### 6.1 Audit events
Must begin capturing:
- transaction created
- posting succeeded/failed
- reversal created
- fee/interest actions

### 6.2 Override requests
Initially needed for:
- reversal approval
- high-value adjustments
- backdated activity outside policy

### 6.3 Account holds
Can begin as simple manual holds before full funds-availability maturity

## Deliverable milestone
At the end of this phase, the back-office MVP becomes much more defensible operationally.

---

# 11. Phase 7 — Teller and Branch Cash Controls

## Objective
Add the teller-specific orchestration later, without changing the kernel.

## Migrations to add at this stage
19. `teller_sessions`
20. `cash_locations`
21. `cash_movements`
22. `cash_counts`
23. `cash_variances`
24. `workstations`
25. `branches` (if not already introduced earlier)

## Why this phase is deferred
These features add substantial workflow and state-management complexity:
- session lifecycle
- branch/cash responsibility
- physical balancing
- denomination counts
- vault movements

By postponing them, the ledger and fee/accrual system stays clean.

## Key architectural rule
Teller workflows must consume the same transaction and posting engine already built.

Teller UI is a new source of operational transactions, not a replacement for the back-office posting model.

---

# 12. Recommended Migration Order (Condensed)

```text
001 parties
002 accounts
003 account_owners
004 gl_accounts
005 business_dates
006 transactions
007 posting_batches
008 posting_legs
009 journal_entries
010 journal_entry_lines
011 account_transactions
012 account_balances
013 fee_types
014 fee_assessments
015 interest_accruals
016 audit_events
017 override_requests
018 account_holds
019 branches
020 workstations
021 cash_locations
022 teller_sessions
023 cash_movements
024 cash_counts
025 cash_variances
```

If branches are already foundational in your app, move them earlier.

---

# 13. Recommended Model / Service Order (Condensed)

## Models first
1. Party
2. Account
3. AccountOwner
4. GlAccount
5. BusinessDate
6. Transaction
7. PostingBatch
8. PostingLeg
9. JournalEntry
10. JournalEntryLine
11. AccountTransaction
12. AccountBalance
13. FeeType
14. FeeAssessment
15. InterestAccrual
16. AuditEvent
17. OverrideRequest
18. AccountHold

## Services next
1. Business date service
2. Posting validator
3. Posting engine / builder
4. Journal projector
5. Account projector
6. Balance refresh service
7. Manual transaction entry service
8. Reversal service
9. Fee posting service
10. Interest accrual service
11. Interest posting service
12. Audit emission service
13. Override evaluation service

---

# 14. First GL Accounts to Seed

The exact chart can expand later, but the MVP should seed at least:

## Liability / customer-side
- Deposit Liability
- Interest Payable

## Income
- Fee Income

## Expense
- Interest Expense
- Adjustment Expense or Correction Expense

## Clearing / suspense
- ACH Clearing
- Suspense / Adjustment Clearing

## Optional early additions
- Loan Receivable (if loans are active in MVP)
- NSF Fee Income
- Miscellaneous Income

These accounts are enough to support the first transaction types without over-designing the chart.

---

# 15. First Transaction Types to Implement

Implement these in this order.

## 1. Manual adjustment
Why first:
- simplest meaningful posting path
- proves account + GL interaction

## 2. Internal transfer
Why second:
- proves multi-account event
- low external dependency

## 3. Manual fee post
Why third:
- introduces fee behavior through existing kernel

## 4. Interest accrual
Why fourth:
- introduces scheduled/system-generated GL posting

## 5. Interest post
Why fifth:
- connects accrued liability to customer accounts

## 6. ACH entry
Why sixth:
- introduces external-origin settlement entry

## 7. Reversal
Why seventh if not earlier:
- critical control path once enough activity exists to reverse

---

# 16. What to Postpone Deliberately

The build will stay healthier if you postpone these until after the kernel is stable.

## Postpone initially
- teller session management
- drawer balancing
- denomination UI
- vault transfer flows
- broad CIF/KYC maturity
- statement generation
- full funds availability engine
- automated ACH/file imports
- complex fee rule engine
- tiered or compounding interest models
- advanced reconciliation dashboards

## Why postpone
These add state, policy, and UI complexity without increasing confidence in the financial kernel early.

---

# 17. First Practical Milestones

## Milestone A — Static banking references ready
Done when:
- parties/accounts exist
- account owners work
- GL accounts seeded
- business date can open/close manually

## Milestone B — Posting kernel works
Done when:
- manual adjustment posts successfully
- posting batch balances
- journal and account projections created
- balances refresh correctly

## Milestone C — Back-office MVP usable
Done when:
- internal transfers work
- manual fees work
- reversals work
- audit capture exists for postings

## Milestone D — Accrual foundation works
Done when:
- accrual rows can be created
- interest accrual posts to GL
- interest posting credits customer account

## Milestone E — Operational controls present
Done when:
- override path exists for reversal/high-value activity
- manual holds exist
- audit trail is queryable

---

# 18. Practical Notes for Rails Implementation

## Keep posting logic in services, not controllers
Controllers should collect input and invoke a posting or transaction-entry service.

## Keep transaction-type mapping explicit
Do not scatter posting rules throughout multiple controllers/models.

## Keep balance refresh isolated
Balance recomputation should be a dedicated service or callback boundary, not ad hoc math in many places.

## Prefer append-only event patterns where possible
Especially for posting, reversals, and audit structures.

## Avoid using UI state as financial state
A transaction is not financially real because a screen says so. It is real only once posting commits.

---

# 19. Relationship to Existing Architecture Docs

This document turns the architecture into build sequence and depends on:

- `BACK_OFFICE_MVP.md`
- `MANUAL_TRANSACTION_ENTRY_MODEL.md`
- `INTEREST_AND_FEES_FOUNDATION.md`
- `POSTING_ENGINE_RULES.md`
- `FINANCIAL_INVARIANTS.md`
- `POSTING_LIFECYCLE.md`
- `LEDGER_BOUNDARIES.md`
- `BUSINESS_DATE_AND_EOD.md`

It is the practical sequencing companion to those documents.

---

# 20. Final Recommendation

The cleanest implementation path is:

```text
master records
→ posting kernel
→ account + journal projections
→ manual back-office transaction entry
→ fees
→ interest accrual/posting
→ audit/overrides/holds
→ teller and cash controls later
```

That sequence proves the accounting core first, keeps complexity manageable, and preserves the architecture needed for BankEncore to grow into a full banking platform.

