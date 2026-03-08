# Posting Engine Rules

**Status:** DROP-IN SAFE  
**Purpose:** Define the rules, responsibilities, and invariants of the posting engine that converts operational transactions into balanced financial truth within BankCORE / BankEncore.

---

# 1. Overview

The posting engine is the financial core of the platform.

Its job is to take an operational banking event and turn it into:

- a balanced posting batch
- one or more posting legs
- customer-facing account subledger entries
- bank-facing journal entries
- immutable financial history

The posting engine is the only component allowed to create financial effects.

Users, workflows, jobs, teller screens, and back-office tools may initiate events, but they do not directly update balances or books.

---

# 2. Posting Engine Responsibilities

The posting engine must:

1. accept a valid operational transaction
2. construct a posting plan
3. generate debit and credit posting legs
4. verify balancing rules
5. create account transactions where applicable
6. create journal entries and lines
7. commit all financial effects atomically
8. reject invalid or unbalanced financial events
9. support reversal by inverse posting
10. preserve immutability of posted financial records

---

# 3. Core Rule: Operational Event vs Financial Truth

Operational transactions describe **what happened**.

The posting engine determines **how it affects money**.

This separation is essential.

Example:

```text
Operational event: manual fee post
Financial truth: debit customer account, credit fee income
```

Operational code must never directly decide balances by bypassing the posting engine.

---

# 4. Required Inputs

The posting engine receives an operational transaction or equivalent posting request with enough information to build balanced legs.

Minimum required input:

| Field | Purpose |
|---|---|
| transaction_id | source event |
| transaction_type | mapping behavior |
| business_date | accounting date |
| reference_number | traceability |
| affected account(s) | account-facing side |
| amount(s) | money values |
| descriptive metadata | memo / reason / source |

Optional inputs may include:

- external reference
- fee type
- interest accrual metadata
- reversal target
- product code
- branch or source channel

---

# 5. Core Outputs

A successful posting operation must generate some or all of the following.

## Required core outputs
- `posting_batches`
- `posting_legs`

## Usually required outputs
- `journal_entries`
- `journal_entry_lines`

## Required when customer accounts are affected
- `account_transactions`
- `account_balances` refresh or recalc trigger

## Required when reversing a prior event
- new reversal posting batch linked to original

---

# 6. Posting Batch Rules

A posting batch is the canonical financial representation of a single completed financial event.

## Rules
- exactly one primary posting batch per posted operational transaction
- batch has a unique posting reference
- batch has a business date
- batch has a posted timestamp when committed
- batch becomes immutable after posting
- reversal creates a new batch, not an edit to the original batch

## Minimum fields
- `transaction_id`
- `posting_reference`
- `status`
- `business_date`
- `posted_at`
- `reversal_of_batch_id` when applicable

---

# 7. Posting Leg Rules

Posting legs are the atomic debit/credit components of a posting batch.

## Required attributes
- belong to one posting batch
- represent either debit or credit
- represent either account-side or GL-side effect
- have positive amount
- carry currency code

## Allowed target patterns
A posting leg may target:
- customer account
- GL account
- later: cash location, clearing/suspense, or other scoped financial object

## MVP simplification
For the ledger-first MVP, the engine may initially support only:
- account legs
- GL legs

---

# 8. Non-Negotiable Balancing Rule

For every posted batch:

```text
SUM(debit legs) == SUM(credit legs)
```

This rule is mandatory.

If not true:
- posting must fail
- nothing may commit

This is the most important rule of the engine.

---

# 9. Account-Side Rules

When a posting affects customer accounts, the engine must create corresponding `account_transactions`.

## Rules
- each account-facing leg should map to one or more account transactions
- account transaction direction must match posting meaning
- account transaction amount must equal corresponding posting effect
- account transaction must reference the posting batch
- customer balance views must be reproducible from account transactions

## Important restriction
No direct update to `account_balances` without an underlying account transaction and posting source.

---

# 10. GL-Side Rules

When a posting affects bank accounting, the engine must create journal structure.

## Rules
- each posting batch should produce one journal entry for MVP
- each GL-facing effect becomes one or more journal entry lines
- journal lines must also balance

Required balancing rule:

```text
SUM(debit journal lines) == SUM(credit journal lines)
```

The journal is derived from posting, not independently authored.

---

# 11. Atomicity Rule

Posting is all-or-nothing.

A valid financial posting must commit these objects together where applicable:

- posting batch
- posting legs
- account transactions
- journal entry
- journal entry lines
- balance refresh side effects or recalculation markers
- reversal linkage metadata if applicable

If any required element fails, the entire posting must rollback.

There is no such thing as a partially posted transaction.

---

# 12. Immutability Rule

Once a posting batch is committed as posted:

- posting batch is immutable
- posting legs are immutable
- derived account transactions are immutable
- derived journal entries are immutable

Corrections are made only by:
- reversal
- replacement posting where needed

This preserves financial history.

---

# 13. Reversal Rules

A reversal is a new operational event and a new posting batch.

## Required behavior
- reference original posting batch
- create inverse posting legs
- create inverse account effects
- create inverse journal effects
- preserve original history unchanged

## Example
Original fee posting:
- debit customer account 10.00
- credit fee income 10.00

Reversal:
- debit fee income 10.00
- credit customer account 10.00

## Rule
A reversal may never mutate the original posting rows.

---

# 14. Idempotency Rules

Unsafe posting operations must be idempotent.

## Required behavior
- transaction reference and/or idempotency key must uniquely identify submission intent
- duplicate retry with same semantic payload must not create a second posted batch
- conflicting retry with same idempotency key but different payload must be rejected

This protects against:
- network retry
- UI double-submit
- job replay
- operator resubmission confusion

---

# 15. Business Date Rules

Every posted batch must carry a business date.

## Required behavior
- business date must be valid under platform rules
- posting against a closed or disallowed date must fail or require governed override
- business date drives inclusion in EOD, statements, and GL summarization

This makes the engine banking-aware rather than generic accounting logic.

---

# 16. Transaction-Type Mapping Rules

The posting engine should map operational transaction types into posting behavior through explicit rules, not scattered conditionals across the application.

## Recommended approach
Introduce a transaction-type mapping layer that defines:
- required inputs
- account-side behavior
- GL-side behavior
- reversal eligibility
- descriptive defaults

## MVP transaction types likely include
- `manual_adjustment`
- `internal_transfer`
- `fee_post`
- `interest_accrual`
- `interest_post`
- `ach_entry`
- `reversal`

---

# 17. Example Mapping Patterns

## 17.1 Manual account credit adjustment
Operational meaning:
- increase customer account by manual correction

Typical posting:
- debit adjustment expense or suspense GL
- credit customer account

---

## 17.2 Internal transfer between two accounts
Typical posting:
- debit source account
- credit destination account

No net GL change beyond liability reclassification if both are deposit accounts.

---

## 17.3 Fee posting
Typical posting:
- debit customer account
- credit fee income

---

## 17.4 Interest accrual
Typical posting:
- debit interest expense
- credit interest payable

---

## 17.5 Interest posting to account
Typical posting:
- debit interest payable
- credit customer account

---

## 17.6 ACH entry
Typical posting:
- debit or credit customer account depending on direction
- opposite leg to ACH clearing / settlement GL

---

# 18. Validation Rules Before Commit

Before posting commit, the engine must validate at least the following.

## Structural validation
- source transaction exists
- source transaction eligible for posting
- business date valid
- required accounts/GL targets present
- no duplicate posting already exists for that transaction

## Financial validation
- all leg amounts are positive
- debit total equals credit total
- derived journal totals also balance

## Referential validation
- all referenced accounts exist and are eligible
- all referenced GL accounts exist and are active

## Reversal validation
- original posting exists
- original is eligible for reversal
- reversal has not already been performed where policy forbids duplicates

---

# 19. Failure Rules

If posting validation fails:
- no financial records may commit
- transaction remains unposted
- failure reason should be recorded for operator/system visibility
- audit event should exist for material failure if appropriate

The engine must fail closed.

---

# 20. Balance Refresh Rules

`account_balances` is a projection layer.

## Rules
- it may be updated immediately after successful posting
- or recalculated asynchronously if design chooses
- but it must always be derivable from durable account transactions

The engine must never rely on cached balances as authoritative truth.

---

# 21. Audit Expectations

The posting engine should emit or trigger audit events for material lifecycle transitions.

Minimum expected audit points:
- posting requested
- posting committed
- posting failed for material reason
- reversal requested
- reversal committed

Audit payloads should identify:
- who or what initiated the event
- which transaction and posting batch were involved
- when it occurred
- why or under what type it occurred

---

# 22. MVP Scope Boundaries

For the ledger-first MVP, the posting engine does **not** yet need to understand:
- teller drawer state
- cash denominations
- vault balancing
- advanced holds/funds availability
- complex product rules

Those can be layered later as additional posting mappings or validators.

The MVP posting engine only needs to safely handle:
- account-side effects
- GL-side effects
- fee and interest patterns
- manual operational entry
- reversals
- business-date discipline

---

# 23. Required Service Contract

A practical posting engine service contract should answer these questions clearly:

1. What operational transaction is being posted?
2. What posting rule or mapping applies?
3. What debit and credit legs will be created?
4. What account transactions will be created?
5. What journal lines will be created?
6. Does the event balance?
7. Is the business date allowed?
8. Is this a duplicate or replay?
9. Is this a reversal?
10. Can everything commit atomically?

If the answer to any required rule is no, posting must not occur.

---

# 24. Relationship to Other Architecture Documents

This document refines and operationalizes the rules defined in:

- `FINANCIAL_INVARIANTS.md`
- `POSTING_LIFECYCLE.md`
- `LEDGER_BOUNDARIES.md`
- `BACK_OFFICE_MVP.md`
- `MANUAL_TRANSACTION_ENTRY_MODEL.md`
- `INTEREST_AND_FEES_FOUNDATION.md`

It acts as the implementation-facing contract for the financial kernel.

---

# 25. Final Design Rule

The single most important principle of the posting engine is:

> operational workflows may describe a banking event, but only the posting engine may create financial truth.

That boundary is what keeps the platform safe as more UI layers, batch jobs, automation, and product types are added.

