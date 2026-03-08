# BankEncore & BankCORE: Platform Architecture and Canonical Table Model

## Executive Summary

BankEncore is a branch-centric, internally authoritative core banking platform built upon the BankCORE financial kernel. The platform's architecture is founded on a "posting-first" philosophy, ensuring that every financial event originates as an operational action and resolves through a balanced, immutable, and atomic posting engine. This design prioritizes financial integrity, regulatory compliance, and operational realism for teller and branch environments.

## Critical Takeaways:

* Internal Authority: The platform serves as the authoritative system of record for balances and financial history; external networks are merely settlement inputs.
* The Financial Kernel (BankCORE): Manages the hardest architectural layers—posting engine, balanced subledgers, and financial invariants—to ensure the "books are safe."
* The Operating Platform (BankEncore): Extends the kernel to include customer information (CIF), business-date orchestration, statements, and institutional workflows to make the "institution operable."
* Ledger Boundaries: A strict separation exists between the Operational Layer (what happened), the Posting Engine (how it affects money), and the Subledger/GL Layers (how it affects the customer and the bank).
* Phased Maturity: Development follows a logical progression from the P1 Financial Kernel (MVP) toward P3/P4 institutional maturity and advanced automation.


--------------------------------------------------------------------------------


## 1. Core Platform Philosophy and Invariants

The platform is governed by non-negotiable financial and control invariants designed to prevent financial corruption and audit breakdown.

### 1.1 Fundamental Financial Invariants

Invariant	Description
Balanced Posting	No event is posted unless total debits equal total credits.
Immutability	Once a transaction is posted, it cannot be edited or deleted. Corrections require explicit reversals.
Atomicity	Posting is all-or-nothing; if any part of a financial mutation fails, the entire transaction rolls back.
Derivable Balances	Authoritative balances must always be reconstructable from durable posting history.
Idempotency	Duplicate financial requests (retries/double-clicks) must not create duplicate postings.

### 1.2 Operational Reality

* Internal Authority: The platform does not allow external systems to directly control balances.
* Business Date Dominance: Financial activity is governed by a bank-controlled "Business Date," which may differ from the wall-clock time to facilitate end-of-day (EOD) procedures and multi-branch coordination.
* Regulator-Ready Controls: Architecture assumes durable auditability, segregation of duties, and controlled exceptions via supervisor overrides.


--------------------------------------------------------------------------------


## 2. The Seven-Layer Architecture

The BankEncore platform is organized into seven stacked layers, moving from user interaction to deep governance.

1. User Workspaces: Interfaces for tellers, CSRs, back-office staff, and supervisors to initiate workflows.
2. Customer / Account Domain: Defines the "who" (CIF/Parties) and the "what" (Products/Accounts) of the banking relationship.
3. Operational Banking Services: Captures business activity (deposits, withdrawals, ACH entry) as operational transactions.
4. Financial Kernel (BankCORE): The engine that validates posting eligibility and commits balanced financial effects.
5. Bank Accounting Layer: Manages the Chart of Accounts, GL mapping rules, and end-of-day GL summarization.
6. Institutional Operations Layer: Manages business dates, funds availability, statement generation, and settlement reconciliation.
7. Governance, Security, and Control: Enforces RBAC, supervisor overrides, audit logging, and policy management.


--------------------------------------------------------------------------------


## 3. The Posting Lifecycle: From Event to Ledger

The financial "heartbeat" of the system follows a specific flow to ensure accounting truth.

### 3.1 Step-by-Step Flow

1. Operational Event: A user or system initiates an action (e.g., a teller cash deposit).
2. Validation: The system checks business rules, account status, and limits.
3. Posting Plan Construction: The engine translates business meaning into accounting meaning (e.g., Debit Cash, Credit Deposit Liability).
4. Atomic Commit: The system simultaneously records the Posting Batch, Posting Legs, Account Transaction (subledger), and Journal Entry (GL).
5. Projection: Cached balances and cash responsibility totals are updated based on the committed transactions.

### 3.2 Ledger Boundaries

To maintain maintainability, the system strictly separates layers:

* Operational Layer: Records "what happened" (e.g., transactions, transaction_items).
* Posting Engine Layer: Records "how it affects the books" (e.g., posting_batches, posting_legs).
* Subledger Layer: Records "how it affects the customer" (e.g., account_transactions).
* General Ledger Layer: Records "how it affects the bank's accounting" (e.g., journal_entries).


--------------------------------------------------------------------------------


## 4. Business Date and End-of-Day (EOD) Operations

Banks operate on a controlled accounting day to ensure deterministic reporting and reconciliation.

### 4.1 Wall Time vs. Business Date

The Business Date remains the authoritative accounting date until the institution performs a "Day-Close," even if the wall-clock time passes midnight.

### 4.2 The EOD Process Phases

1. Teller Closure: All teller sessions must be closed and cash drawers balanced (reconciling opening cash + inbound - outbound movements).
2. Operational Validation: Verifies no transactions are stuck in "pending" and required settlements are imported.
3. Financial Summarization: Posting batches are grouped into GL batches for the day.
4. Statement Inclusion: Transactions are flagged for inclusion in the relevant statement cycles.
5. Business Date Rollover: The current date status moves to closed, and the next_date moves to open.


--------------------------------------------------------------------------------


## 5. Interest and Fees Foundation

Interest and fees are never directly applied to balances; they are processed as balanced postings to preserve auditability.

* Interest Accrual: A daily phase where the bank records interest expense earned by the customer but not yet credited (Debit Interest Expense, Credit Interest Payable).
* Interest Posting: A periodic phase (usually monthly) moving accumulated payable interest to the customer's account (Debit Interest Payable, Credit Deposit Account).
* Fee Model: Fees (manual or rule-driven) are assessed by debiting the customer account and crediting Fee Income.


--------------------------------------------------------------------------------


## 6. Canonical Table Families and Phasing

The implementation is categorized into four phases (P1–P4) to prioritize core ledger integrity before operational complexity.

### 6.1 Phase 1 (MVP / Financial Kernel)

* Parties & Accounts: parties, accounts, account_owners, deposit_accounts, loan_accounts.
* Financials: posting_batches, posting_legs, account_transactions, account_balances, gl_accounts, journal_entries.
* Branch/Cash: branches, cash_locations, teller_sessions, workstations.

### 6.2 Phase 2 (Core Operational Maturity)

* CIF Depth: party_people, party_organizations, party_relationships, advisories.
* Operational Control: transactions, transaction_exceptions, override_requests, audit_events.
* Advanced Accounting: gl_mappings, gl_batches, interest_accruals, fee_rules.

### 6.3 Phase 3 & 4 (Institutional & Advanced)

* Maturity: reconciliation_exceptions, settings_catalog, export_jobs.


--------------------------------------------------------------------------------


## 7. Implementation Strategy

The recommended build order emphasizes "financial truth before UI richness."

1. Phase 0-1 (Foundation): Establish master records (Parties, Accounts, GL Accounts) and Business Date controls.
2. Phase 2-3 (The Kernel): Build the posting engine and the projection services that translate postings into Account and GL ledgers.
3. Phase 4-5 (Back-Office Operations): Enable manual adjustments, internal transfers, and the interest/fee foundation.
4. Phase 6-7 (Governance and Teller): Layer on audit trails, supervisor overrides, and finally, the high-state complexity of teller cash drawers and physical movements.


--------------------------------------------------------------------------------


## 8. Key Architectural Quotes

> "BankCORE makes the books safe. BankEncore makes the institution operable."

> "Every financial event must be explainable, balanced, auditable, and reconstructable from durable history. If that remains true, the platform can mature safely."

> "Operational records contain business meaning, not accounting meaning. They do not directly change balances; they must go through the posting engine."

> "The platform is the authoritative system of record... External systems may provide input or enrichment, but they do not directly control balances or books."
