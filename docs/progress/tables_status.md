# Tables Status

## Purpose

This document compares the current implementation against the original draft schema in:

- `docs/00_initial_core_references/BankCORE 260306 Schema - Tables_Fields.csv`
- `docs/00_initial_core_references/BankCORE 260306 Schema - Tables_Purpose.csv`

It is organized as a practical gap list rather than a raw table dump. The current system follows the later `implementation_order.md` closely for the ledger-first MVP, but not the full breadth of the earlier enterprise schema draft.

---

## Current Baseline

### Strongly implemented

These tables form the current ledger-first MVP backbone and are already in use:

- `parties`
- `accounts`
- `account_owners`
- `deposit_accounts`
- `gl_accounts`
- `business_dates`
- `transactions`
- `posting_batches`
- `posting_legs`
- `journal_entries`
- `journal_entry_lines`
- `account_transactions`
- `account_balances`
- `fee_types`
- `fee_assessments`
- `interest_accruals`
- `audit_events`
- `override_requests`
- `account_holds`
- `branches`
- `users`
- `roles`
- `role_permissions`
- `user_roles`

### Practical substitutions already in place

The current codebase uses a few structures that were not central in the original draft, but are good fits for the implemented architecture:

- `transaction_codes`
- `posting_templates`
- `posting_template_legs`

These effectively replace a dedicated draft-style `gl_mappings` or transaction mapping registry for the current MVP.

---

## Priority 1: Missing Tables Worth Adding Soon

These are the missing draft tables that are most likely to become useful in the near term without dragging the app into teller/cash complexity too early.

### 1. `transaction_references`

**Why it matters**

The current system spreads operational references across:

- `transactions.reference_number`
- `transactions.external_reference`
- `posting_batches.idempotency_key`

A dedicated `transaction_references` table would make alternate lookup keys, external references, network references, and idempotency-style references more extensible and auditable.

**Current substitute**

- Partial substitute exists
- Not urgent for current MVP, but high-value if ACH / external settlement workflows expand

### 2. `transaction_exceptions`

**Why it matters**

Today, exception handling is represented through:

- `override_requests`
- audit events
- controller/service logic

A dedicated `transaction_exceptions` table would make review-needed, override-required, policy-blocked, and resolved exception states first-class.

**Current substitute**

- Partial substitute exists
- Good next-step if operator exception workflows become more explicit

### 3. `account_products`

**Why it matters**

The draft assumes products become the home for defaults such as:

- fee behavior
- statement cycle
- interest method
- overdraft policy

Right now, account behavior is mostly encoded through account type, deposit attributes, and service logic. That works, but products will help once account behavior needs to scale beyond a few hard-coded types.

**Current substitute**

- Not implemented
- Useful next when fee and interest rules become more configurable

### 4. `fee_rules`

**Why it matters**

Current fee processing works via:

- `fee_types`
- `fee_assessments`
- posting / runner services

But the draft anticipates event-driven or scheduled rule definitions. If fee assessment needs to become configurable instead of service-coded, `fee_rules` becomes important.

**Current substitute**

- Service logic and runners
- Medium-term priority, not immediate MVP blocker

### 5. `interest_rules`

**Why it matters**

Current interest support relies on:

- `interest_accruals`
- interest services
- deposit-level rate attributes such as `interest_rate_basis_points`

That is enough for the MVP, but not for richer product-level interest policies. `interest_rules` would normalize how accrual and posting logic is configured.

**Current substitute**

- Deposit account fields and services
- Medium-term priority

---

## Priority 2: Field Backfills on Existing Tables

These are not missing tables, but important draft fields that may be worth backfilling as the platform matures.

### `parties`

Current table is good for MVP, but the draft expected:

- `tax_id_last4`

Potential next additions:

- masked identifier summary fields
- stronger lifecycle semantics if customer status becomes more nuanced

### `accounts`

Draft fields not currently present:

- `account_reference`
- `account_product_id`

These become more valuable once product configuration or alternate operational identifiers matter.

### `account_balances`

Draft included:

- `average_balance_cents`

This is not necessary for current posting integrity, but may matter later for product logic, fees, or reporting.

### `account_transactions`

Draft expected:

- `transaction_id`
- `account_reference`

Current design relies on `posting_batch_id`, which fits the posting-first model well. A direct transaction link may still be useful for operator traceability.

### `posting_legs`

Draft included:

- `cash_location_id`

Not needed while teller / physical cash is deferred, but relevant later.

### `transactions`

Draft expected but current schema does not include:

- `workstation_id`
- `teller_session_id`

These are correctly absent for now because teller mode is deferred.

---

## Safely Deferred: Teller / Branch Cash Domain

These draft tables should stay deferred until Phase 7-level teller workflows are intentionally started.

- `cash_locations`
- `teller_sessions`
- `cash_movements`
- `workstations`
- `vault_transfers`
- `cash_counts`
- `cash_variances`

**Reason for deferral**

The current architecture intentionally delays cash orchestration until after the ledger-first MVP is operational. This matches `implementation_order.md` and is not a gap that needs immediate action.

---

## Safely Deferred: External Clearing Detail Tables

These were in the draft, but are not required for the current manual back-office settlement approach.

- `clearing_items`
- `check_items`
- `ach_items`
- `card_settlements`
- `wire_items`
- `settlement_batches`
- `reconciliation_exceptions`

**Reason for deferral**

The current app supports ACH-like operational posting through transaction codes (`ACH_CREDIT`, `ACH_DEBIT`) instead of a full clearing-item registry. That is acceptable for the current phase.

---

## Safely Deferred: Rich CIF / Customer Detail Decomposition

These draft tables would deepen party and relationship modeling, but are not required for the current MVP.

- `party_people`
- `party_organizations`
- `party_contacts`
- `party_identifiers`
- `party_relationships`
- `advisories`

**Reason for deferral**

The current `parties` table is sufficient for basic ownership and account linking. These tables become relevant when onboarding, KYC, relationship management, or alerts expand.

---

## Safely Deferred: Enterprise Ops / Reporting Infrastructure

These are valid longer-term tables, but not needed for the current operational core.

- `gl_batches`
- `gl_batch_lines`
- `posting_links`
- `permissions`
- `user_branch_access`
- `sessions`
- `mfa_events`
- `holidays`
- `statement_runs`
- `statements`
- `settings_catalog`
- `settings_values`
- `export_jobs`

**Reason for deferral**

These support scale, configuration, enterprise integration, reporting, or hardened security. They are outside the core ledger-first MVP.

---

## Notable Design Deviations That Are Acceptable

These are places where the current implementation differs from the original draft, but the deviation is reasonable.

### 1. No `transaction_lines`

The draft included a line-level operational detail table. The current system instead relies on:

- `transactions`
- `posting_legs`
- `account_transactions`
- `journal_entry_lines`

This is acceptable for the current posting-first MVP, though it means operational detail is not modeled separately from financial projection layers.

### 2. No dedicated `gl_mappings`

The current architecture uses:

- `transaction_codes`
- `posting_templates`
- `posting_template_legs`

This is a strong replacement for a dedicated GL mapping table at the current scale.

### 3. Broader `p1` in the draft than in reality

The original CSV draft placed many teller/cash and clearing tables in `p1`. The actual implementation follows the more disciplined sequencing in `implementation_order.md`, which is the better guide for the current system.

---

## Recommended Next Moves

If the goal is to improve schema fidelity without overbuilding, the next best additions are:

1. Add `transaction_references`
2. Add `transaction_exceptions`
3. Add `account_products`
4. Add `fee_rules`
5. Add `interest_rules`
6. Backfill selected fields on existing tables:
   - `accounts.account_reference`
   - `accounts.account_product_id`
   - `account_balances.average_balance_cents`
   - optional direct `transaction_id` traceability on `account_transactions`

If the goal instead is to stay aligned with the current roadmap, all teller/cash/clearing/reporting/settings tables should remain deferred.

---

## Bottom Line

The current implementation is strong where it needs to be strong:

- posting kernel
- subledger / GL projection
- back-office transaction entry
- fee / interest foundation
- audit / overrides / holds

The biggest remaining schema gaps are not in financial integrity. They are in:

- configurable product/rule modeling
- explicit reference/exception tracking
- deferred teller / clearing / enterprise infrastructure

That means the app is in good shape for the ledger-first MVP, while still being materially smaller than the original enterprise draft.
