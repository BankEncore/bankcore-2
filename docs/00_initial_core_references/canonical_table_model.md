# Canonical Table Model

**Status:** DROP-IN SAFE  
**Scope:** BankCORE / BankEncore architecture reference  
**Purpose:** Define a canonical target table model for a teller-first, branch-centric core banking platform, including table purpose, key relationships, and phased delivery.

---

## 1. Overview

This document defines a practical canonical data model for the BankCORE / BankEncore platform.

It is intended to:

- provide a stable architectural reference
- normalize naming across modules
- distinguish MVP tables from later-phase tables
- clarify how operational activity maps to posting, ledger, cash, and control layers

This model assumes the following architectural principles:

1. All financial activity must resolve through balanced debit/credit posting.
2. Posted financial history is immutable.
3. Teller, branch, and back-office actions are operational events that produce accounting effects.
4. External networks are settlement inputs, not the authoritative source of balances.
5. The platform is branch-centric, audit-heavy, and regulator-oriented.

---

## 2. Phasing Legend

- **P1** — BankCORE MVP / financial kernel
- **P2** — core banking operational maturity
- **P3** — institutional maturity / servicing / reporting depth
- **P4** — advanced integrations / automation

---

## 3. Canonical Table Families

1. Party / CIF
2. Accounts / products
3. Operational transactions
4. Posting / subledger
5. General ledger
6. Teller / cash / branch
7. External settlement / clearing
8. Fees / interest / controls
9. Security / RBAC
10. Audit / business date / settings / statements

---

# 4. Canonical Tables

## A. Party / CIF Domain

### 4.1 `parties`
**Phase:** P1  
**Purpose:** Master party record for any person or organization known to the institution.

**Typical columns**
- `id`
- `party_type` (`person`, `organization`)
- `party_number`
- `display_name`
- `status`
- `primary_branch_id`
- `opened_on`
- `closed_on`
- `created_at`
- `updated_at`

**Key relationships**
- has one `party_people` or `party_organizations`
- has many `party_contacts`
- has many `party_identifiers`
- has many `party_relationships`
- has many `account_owners`
- has many `advisories`

---

### 4.2 `party_people`
**Phase:** P2  
**Purpose:** Person-specific attributes for an individual party.

**Typical columns**
- `id`
- `party_id`
- `first_name`
- `middle_name`
- `last_name`
- `date_of_birth`
- `tax_reporting_name`
- `citizenship_country`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `parties`

---

### 4.3 `party_organizations`
**Phase:** P2  
**Purpose:** Organization-specific attributes for business/entity parties.

**Typical columns**
- `id`
- `party_id`
- `legal_name`
- `dba_name`
- `tax_id_last4`
- `formation_state`
- `entity_type`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `parties`

---

### 4.4 `party_contacts`
**Phase:** P2  
**Purpose:** Phones, emails, mailing channels, and related contact preferences.

**Typical columns**
- `id`
- `party_id`
- `contact_type` (`phone`, `email`, `address`)
- `label`
- `value`
- `is_primary`
- `is_verified`
- `effective_on`
- `ends_on`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `parties`

---

### 4.5 `party_identifiers`
**Phase:** P2  
**Purpose:** Masked references to tax IDs, government IDs, and verification status.

**Typical columns**
- `id`
- `party_id`
- `identifier_type`
- `masked_value`
- `last4`
- `issuer`
- `verified_at`
- `verification_status`
- `expires_on`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `parties`

---

### 4.6 `party_relationships`
**Phase:** P2  
**Purpose:** Relates parties to other parties, such as beneficial owner, spouse, guarantor, signer, trustee, or household member.

**Typical columns**
- `id`
- `party_id`
- `related_party_id`
- `relationship_type`
- `is_primary`
- `effective_on`
- `ends_on`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `parties`
- references related `parties`

---

### 4.7 `cards`
**Phase:** P1  
**Purpose:** Registry of debit/ATM cards issued or tracked by the institution.

**Typical columns**
- `id`
- `card_number_last4`
- `card_type`
- `status`
- `issued_on`
- `expires_on`
- `party_id`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `parties`
- has many `card_links`

---

### 4.8 `card_links`
**Phase:** P1  
**Purpose:** Links cards to parties and/or accounts.

**Typical columns**
- `id`
- `card_id`
- `account_id`
- `party_id`
- `link_role`
- `effective_on`
- `ends_on`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `cards`
- belongs to `accounts`
- belongs to `parties`

---

### 4.9 `advisories`
**Phase:** P2  
**Purpose:** Manual notes, alerts, flags, or record-level advisories associated to parties and/or accounts.

**Typical columns**
- `id`
- `party_id`
- `account_id`
- `category`
- `priority`
- `subject`
- `body`
- `workspace_scope`
- `pinned`
- `effective_on`
- `expires_on`
- `acknowledged_at`
- `created_by_id`
- `created_at`
- `updated_at`

**Key relationships**
- optionally belongs to `parties`
- optionally belongs to `accounts`
- belongs to `users` through `created_by_id`

---

## B. Accounts / Product Domain

### 4.10 `account_products`
**Phase:** P2  
**Purpose:** Product catalog defining default rules for deposit and loan products.

**Typical columns**
- `id`
- `product_code`
- `name`
- `product_family`
- `currency_code`
- `interest_method`
- `statement_cycle`
- `allow_overdraft`
- `status`
- `created_at`
- `updated_at`

**Key relationships**
- has many `accounts`
- has many `fee_rules`
- has many `interest_rules`

---

### 4.11 `accounts`
**Phase:** P1  
**Purpose:** Master financial account record.

**Typical columns**
- `id`
- `account_number`
- `account_reference`
- `account_product_id`
- `account_type`
- `branch_id`
- `currency_code`
- `status`
- `opened_on`
- `closed_on`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `account_products`
- belongs to `branches`
- has many `account_owners`
- has one `deposit_accounts` or `loan_accounts`
- has many `account_transactions`
- has many `account_holds`
- has many `account_balances`

---

### 4.12 `account_owners`
**Phase:** P1  
**Purpose:** Links parties to accounts with defined ownership or authority roles.

**Typical columns**
- `id`
- `account_id`
- `party_id`
- `role_type`
- `is_primary`
- `effective_on`
- `ends_on`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `accounts`
- belongs to `parties`

---

### 4.13 `deposit_accounts`
**Phase:** P1  
**Purpose:** Deposit-specific account attributes.

**Typical columns**
- `id`
- `account_id`
- `deposit_type`
- `interest_bearing`
- `overdraft_policy`
- `minimum_balance_cents`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `accounts`

---

### 4.14 `loan_accounts`
**Phase:** P1  
**Purpose:** Loan-specific account attributes.

**Typical columns**
- `id`
- `account_id`
- `loan_type`
- `original_principal_cents`
- `current_principal_cents`
- `rate_type`
- `interest_rate`
- `origination_date`
- `maturity_date`
- `status`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `accounts`

---

### 4.15 `account_balances`
**Phase:** P1  
**Purpose:** Point-in-time cached balances used for operational reads.

**Typical columns**
- `id`
- `account_id`
- `posted_balance_cents`
- `available_balance_cents`
- `average_balance_cents`
- `as_of_at`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `accounts`

---

### 4.16 `account_holds`
**Phase:** P1  
**Purpose:** Restrictive or funds-availability holds against an account.

**Typical columns**
- `id`
- `account_id`
- `hold_type`
- `amount_cents`
- `status`
- `reason_code`
- `effective_on`
- `release_on`
- `released_at`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `accounts`
- may reference `transactions`

---

### 4.17 `account_limits`
**Phase:** P2  
**Purpose:** Account-specific overrides for overdraft, cash limits, or daily transaction caps.

**Typical columns**
- `id`
- `account_id`
- `limit_type`
- `amount_cents`
- `effective_on`
- `ends_on`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `accounts`

---

### 4.18 `account_status_events`
**Phase:** P2  
**Purpose:** Historical lifecycle transitions for accounts.

**Typical columns**
- `id`
- `account_id`
- `status_from`
- `status_to`
- `reason_code`
- `effective_at`
- `created_by_id`
- `created_at`

**Key relationships**
- belongs to `accounts`
- belongs to `users`

---

### 4.19 `account_transactions`
**Phase:** P1  
**Purpose:** Customer-facing account activity subledger.

**Typical columns**
- `id`
- `account_id`
- `posting_batch_id`
- `transaction_id`
- `account_reference`
- `amount_cents`
- `direction`
- `description`
- `running_balance_cents`
- `business_date`
- `posted_at`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `accounts`
- belongs to `posting_batches`
- optionally belongs to `transactions`

---

## C. Operational Transaction Domain

### 4.20 `transactions`
**Phase:** P2  
**Purpose:** General operational transaction header across teller, back-office, clearing, and fee/interest flows.

**Typical columns**
- `id`
- `transaction_type`
- `channel`
- `branch_id`
- `workstation_id`
- `teller_session_id`
- `status`
- `reference_number`
- `external_reference`
- `business_date`
- `initiated_at`
- `posted_at`
- `created_by_id`
- `approved_by_id`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `branches`
- belongs to `workstations`
- belongs to `teller_sessions`
- belongs to `users`
- has many `transaction_lines`
- has many `transaction_items`
- has one `posting_batches`

---

### 4.21 `transaction_lines`
**Phase:** P1/P2 transition  
**Purpose:** Line-level operational detail within a transaction.

**Typical columns**
- `id`
- `transaction_id`
- `line_type`
- `account_id`
- `amount_cents`
- `direction`
- `memo`
- `position`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `transactions`
- optionally belongs to `accounts`

---

### 4.22 `transaction_items`
**Phase:** P2  
**Purpose:** Instrument-level detail such as checks, denominations, fee items, or non-cash instruments.

**Typical columns**
- `id`
- `transaction_id`
- `item_type`
- `amount_cents`
- `reference_data_json`
- `status`
- `position`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `transactions`

---

### 4.23 `transaction_references`
**Phase:** P2  
**Purpose:** Stores idempotency keys, external references, network references, and alternate lookup keys.

**Typical columns**
- `id`
- `transaction_id`
- `reference_type`
- `reference_value`
- `created_at`

**Key relationships**
- belongs to `transactions`

---

### 4.24 `transaction_exceptions`
**Phase:** P2  
**Purpose:** Captures policy exceptions, override-required conditions, and transaction-level control events.

**Typical columns**
- `id`
- `transaction_id`
- `exception_type`
- `status`
- `requires_override`
- `reason_code`
- `resolved_at`
- `resolved_by_id`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `transactions`
- belongs to `users`

---

## D. Posting / Subledger Domain

### 4.25 `posting_batches`
**Phase:** P1  
**Purpose:** Canonical financial event container for balanced posting.

**Typical columns**
- `id`
- `transaction_id`
- `posting_reference`
- `status`
- `business_date`
- `posted_at`
- `reversal_of_batch_id`
- `created_at`
- `updated_at`

**Key relationships**
- optionally belongs to `transactions`
- has many `posting_legs`
- has many `account_transactions`
- may reference another `posting_batches` as reversal source

---

### 4.26 `posting_legs`
**Phase:** P1  
**Purpose:** Balanced debit/credit lines belonging to a posting batch.

**Typical columns**
- `id`
- `posting_batch_id`
- `leg_type`
- `ledger_scope`
- `gl_account_id`
- `account_id`
- `cash_location_id`
- `amount_cents`
- `currency_code`
- `position`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `posting_batches`
- optionally belongs to `gl_accounts`
- optionally belongs to `accounts`
- optionally belongs to `cash_locations`

---

### 4.27 `posting_links`
**Phase:** P2  
**Purpose:** Cross-reference table connecting posting batches to operational artifacts, holds, fees, and settlement objects.

**Typical columns**
- `id`
- `posting_batch_id`
- `link_type`
- `linked_record_type`
- `linked_record_id`
- `created_at`

**Key relationships**
- belongs to `posting_batches`

---

## E. General Ledger Domain

### 4.28 `gl_accounts`
**Phase:** P1  
**Purpose:** Chart of accounts for bank-wide accounting.

**Typical columns**
- `id`
- `gl_number`
- `name`
- `category`
- `normal_balance`
- `branch_scoped`
- `status`
- `created_at`
- `updated_at`

**Key relationships**
- has many `journal_entry_lines`
- has many `posting_legs`

---

### 4.29 `journal_entries`
**Phase:** P1  
**Purpose:** Accounting journal entry header.

**Typical columns**
- `id`
- `posting_batch_id`
- `reference_number`
- `status`
- `business_date`
- `posted_at`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `posting_batches`
- has many `journal_entry_lines`

---

### 4.30 `journal_entry_lines`
**Phase:** P1  
**Purpose:** Debit/credit accounting lines for the GL journal entry.

**Typical columns**
- `id`
- `journal_entry_id`
- `gl_account_id`
- `branch_id`
- `debit_cents`
- `credit_cents`
- `currency_code`
- `memo`
- `position`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `journal_entries`
- belongs to `gl_accounts`
- belongs to `branches`

---

### 4.31 `gl_mappings`
**Phase:** P2  
**Purpose:** Maps source transaction types or product families to GL accounts.

**Typical columns**
- `id`
- `source_type`
- `product_type`
- `branch_id`
- `debit_gl_account_id`
- `credit_gl_account_id`
- `priority`
- `effective_on`
- `ends_on`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `branches`
- belongs to `gl_accounts`

---

### 4.32 `gl_batches`
**Phase:** P2  
**Purpose:** End-of-day summary batch for export to enterprise GL or control reporting.

**Typical columns**
- `id`
- `business_date`
- `branch_id`
- `status`
- `closed_at`
- `exported_at`
- `export_reference`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `branches`
- has many `gl_batch_lines`

---

### 4.33 `gl_batch_lines`
**Phase:** P2  
**Purpose:** Aggregated GL totals within an end-of-day batch.

**Typical columns**
- `id`
- `gl_batch_id`
- `gl_account_id`
- `branch_id`
- `debit_cents`
- `credit_cents`
- `line_count`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `gl_batches`
- belongs to `gl_accounts`
- belongs to `branches`

---

## F. Teller / Branch / Cash Domain

### 4.34 `branches`
**Phase:** P1  
**Purpose:** Branch master table.

**Typical columns**
- `id`
- `branch_code`
- `name`
- `timezone_name`
- `status`
- `opened_on`
- `closed_on`
- `created_at`
- `updated_at`

**Key relationships**
- has many `accounts`
- has many `transactions`
- has many `cash_locations`
- has many `teller_sessions`
- has many `workstations`

---

### 4.35 `cash_locations`
**Phase:** P1  
**Purpose:** Branch vaults, teller drawers, tills, transit cash, or suspense cash locations.

**Typical columns**
- `id`
- `branch_id`
- `location_type`
- `code`
- `name`
- `status`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `branches`
- has many `cash_movements`
- has many `cash_counts`

---

### 4.36 `teller_sessions`
**Phase:** P1  
**Purpose:** Teller open/close cash responsibility session.

**Typical columns**
- `id`
- `user_id`
- `branch_id`
- `cash_location_id`
- `status`
- `opened_at`
- `closed_at`
- `opening_amount_cents`
- `closing_amount_cents`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `users`
- belongs to `branches`
- belongs to `cash_locations`
- has many `transactions`
- has many `cash_movements`

---

### 4.37 `cash_movements`
**Phase:** P1  
**Purpose:** Records physical cash in/out between drawer, vault, customer, or transit.

**Typical columns**
- `id`
- `teller_session_id`
- `transaction_id`
- `from_cash_location_id`
- `to_cash_location_id`
- `movement_type`
- `amount_cents`
- `business_date`
- `moved_at`
- `created_by_id`
- `approved_by_id`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `teller_sessions`
- belongs to `transactions`
- belongs to `cash_locations`
- belongs to `users`

---

### 4.38 `vault_transfers`
**Phase:** P2  
**Purpose:** Specialized dual-control vault transfer records.

**Typical columns**
- `id`
- `branch_id`
- `from_cash_location_id`
- `to_cash_location_id`
- `amount_cents`
- `requested_by_id`
- `approved_by_id`
- `status`
- `transferred_at`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `branches`
- belongs to `cash_locations`
- belongs to `users`

---

### 4.39 `cash_counts`
**Phase:** P2  
**Purpose:** Denomination-level counts for drawers and vaults.

**Typical columns**
- `id`
- `cash_location_id`
- `teller_session_id`
- `count_type`
- `denominations_json`
- `total_cents`
- `counted_at`
- `counted_by_id`
- `created_at`

**Key relationships**
- belongs to `cash_locations`
- belongs to `teller_sessions`
- belongs to `users`

---

### 4.40 `cash_variances`
**Phase:** P2  
**Purpose:** Over/short exceptions and resolution records.

**Typical columns**
- `id`
- `teller_session_id`
- `cash_location_id`
- `variance_cents`
- `status`
- `reason_code`
- `resolved_by_id`
- `resolved_at`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `teller_sessions`
- belongs to `cash_locations`
- belongs to `users`

---

### 4.41 `workstations`
**Phase:** P1  
**Purpose:** Tracks physical or logical teller/branch workstations.

**Typical columns**
- `id`
- `branch_id`
- `code`
- `name`
- `status`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `branches`
- has many `transactions`

---

## G. External Settlement / Clearing Domain

### 4.42 `clearing_items`
**Phase:** P1  
**Purpose:** Base registry for externally-originated or clearing-related items.

**Typical columns**
- `id`
- `clearing_type`
- `status`
- `amount_cents`
- `business_date`
- `settlement_date`
- `reference_number`
- `account_id`
- `transaction_id`
- `created_at`
- `updated_at`

**Key relationships**
- optionally belongs to `accounts`
- optionally belongs to `transactions`

---

### 4.43 `check_items`
**Phase:** P1  
**Purpose:** Check-level item detail for deposits, cashing, or clearing.

**Typical columns**
- `id`
- `clearing_item_id`
- `check_number`
- `routing_number`
- `account_number_last4`
- `amount_cents`
- `on_us`
- `status`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `clearing_items`

---

### 4.44 `ach_items`
**Phase:** P1  
**Purpose:** ACH debit/credit items entered manually or imported for settlement.

**Typical columns**
- `id`
- `clearing_item_id`
- `standard_entry_class`
- `trace_number`
- `company_name`
- `entry_type`
- `amount_cents`
- `effective_entry_date`
- `status`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `clearing_items`

---

### 4.45 `card_settlements`
**Phase:** P1  
**Purpose:** Card network settlement items recorded internally.

**Typical columns**
- `id`
- `clearing_item_id`
- `card_id`
- `network_name`
- `merchant_reference`
- `amount_cents`
- `entry_type`
- `status`
- `settled_at`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `clearing_items`
- belongs to `cards`

---

### 4.46 `wire_items`
**Phase:** P2  
**Purpose:** Wire-in and wire-out items handled internally.

**Typical columns**
- `id`
- `clearing_item_id`
- `wire_direction`
- `origin_reference`
- `beneficiary_name`
- `amount_cents`
- `status`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `clearing_items`

---

### 4.47 `settlement_batches`
**Phase:** P2  
**Purpose:** Groups manually entered or imported settlement items by date/source.

**Typical columns**
- `id`
- `settlement_type`
- `source_name`
- `business_date`
- `status`
- `item_count`
- `total_amount_cents`
- `created_at`
- `updated_at`

**Key relationships**
- has many `clearing_items`

---

### 4.48 `reconciliation_exceptions`
**Phase:** P3  
**Purpose:** Tracks unmatched or suspense settlement items.

**Typical columns**
- `id`
- `clearing_item_id`
- `exception_type`
- `status`
- `reason_code`
- `resolved_at`
- `resolved_by_id`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `clearing_items`
- belongs to `users`

---

## H. Fees / Interest / Controls Domain

### 4.49 `fee_types`
**Phase:** P1  
**Purpose:** Catalog of known fee types.

**Typical columns**
- `id`
- `code`
- `name`
- `category`
- `default_amount_cents`
- `status`
- `created_at`
- `updated_at`

**Key relationships**
- has many `fee_rules`
- has many `fee_assessments`

---

### 4.50 `fee_rules`
**Phase:** P2  
**Purpose:** Event-driven or scheduled rules for fee assessment.

**Typical columns**
- `id`
- `fee_type_id`
- `account_product_id`
- `transaction_type`
- `priority`
- `method`
- `amount_cents`
- `basis_points`
- `conditions_json`
- `effective_on`
- `ends_on`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `fee_types`
- belongs to `account_products`

---

### 4.51 `fee_assessments`
**Phase:** P1  
**Purpose:** Actual fee charges assessed against transactions or accounts.

**Typical columns**
- `id`
- `fee_type_id`
- `fee_rule_id`
- `account_id`
- `transaction_id`
- `posting_batch_id`
- `amount_cents`
- `status`
- `assessed_on`
- `reversal_of_id`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `fee_types`
- belongs to `fee_rules`
- belongs to `accounts`
- belongs to `transactions`
- belongs to `posting_batches`

---

### 4.52 `interest_rules`
**Phase:** P2  
**Purpose:** Product or account-level rules for interest accrual and posting.

**Typical columns**
- `id`
- `account_product_id`
- `account_id`
- `interest_method`
- `rate`
- `day_count_method`
- `posting_cadence`
- `effective_on`
- `ends_on`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `account_products`
- optionally belongs to `accounts`

---

### 4.53 `interest_accruals`
**Phase:** P2  
**Purpose:** Daily or periodic accrual rows for deposit or loan interest.

**Typical columns**
- `id`
- `account_id`
- `accrual_date`
- `amount_cents`
- `status`
- `interest_rule_id`
- `posting_batch_id`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `accounts`
- belongs to `interest_rules`
- belongs to `posting_batches`

---

### 4.54 `funds_availability_holds`
**Phase:** P2  
**Purpose:** Specialized hold schedule rows for deposit availability plans.

**Typical columns**
- `id`
- `account_hold_id`
- `release_date`
- `release_amount_cents`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `account_holds`

---

### 4.55 `override_requests`
**Phase:** P2  
**Purpose:** Lifecycle of supervisor override requests.

**Typical columns**
- `id`
- `request_type`
- `status`
- `requested_by_id`
- `approved_by_id`
- `branch_id`
- `transaction_id`
- `expires_at`
- `used_at`
- `reason_text`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `users`
- belongs to `branches`
- optionally belongs to `transactions`

---

## I. Security / RBAC Domain

### 4.56 `users`
**Phase:** P1  
**Purpose:** Employee/system user records.

**Typical columns**
- `id`
- `username`
- `display_name`
- `email`
- `status`
- `primary_branch_id`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `branches`
- has many `user_roles`
- has many `teller_sessions`

---

### 4.57 `roles`
**Phase:** P1  
**Purpose:** RBAC role definitions.

**Typical columns**
- `id`
- `code`
- `name`
- `description`
- `created_at`
- `updated_at`

**Key relationships**
- has many `role_permissions`
- has many `user_roles`

---

### 4.58 `permissions`
**Phase:** P2  
**Purpose:** Explicit permission registry if normalized separately.

**Typical columns**
- `id`
- `code`
- `name`
- `description`
- `created_at`
- `updated_at`

**Key relationships**
- has many `role_permissions`

---

### 4.59 `role_permissions`
**Phase:** P1  
**Purpose:** Assigns permissions to roles.

**Typical columns**
- `id`
- `role_id`
- `permission_code` or `permission_id`
- `created_at`

**Key relationships**
- belongs to `roles`
- optionally belongs to `permissions`

---

### 4.60 `user_roles`
**Phase:** P1  
**Purpose:** Assigns roles to users.

**Typical columns**
- `id`
- `user_id`
- `role_id`
- `effective_on`
- `ends_on`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `users`
- belongs to `roles`

---

### 4.61 `user_branch_access`
**Phase:** P2  
**Purpose:** Explicit multi-branch access entitlement table.

**Typical columns**
- `id`
- `user_id`
- `branch_id`
- `is_primary`
- `effective_on`
- `ends_on`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `users`
- belongs to `branches`

---

### 4.62 `sessions`
**Phase:** P2  
**Purpose:** Authentication/refresh token session registry.

**Typical columns**
- `id`
- `user_id`
- `workstation_id`
- `session_type`
- `started_at`
- `ended_at`
- `status`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `users`
- belongs to `workstations`

---

### 4.63 `mfa_events`
**Phase:** P2  
**Purpose:** PIN/MFA challenge and verification records.

**Typical columns**
- `id`
- `user_id`
- `event_type`
- `status`
- `occurred_at`
- `context_json`
- `created_at`

**Key relationships**
- belongs to `users`

---

## J. Audit / Business Date / Settings / Statements Domain

### 4.64 `audit_events`
**Phase:** P2  
**Purpose:** Immutable who/what/when/why event log.

**Typical columns**
- `id`
- `event_type`
- `actor_type`
- `actor_id`
- `target_type`
- `target_id`
- `action`
- `status`
- `business_date`
- `occurred_at`
- `metadata_json`
- `created_at`

**Key relationships**
- polymorphic to many domains

---

### 4.65 `business_dates`
**Phase:** P2  
**Purpose:** Tracks branch-level business date state and close status.

**Typical columns**
- `id`
- `branch_id`
- `business_date`
- `status`
- `opened_at`
- `closed_at`
- `recompute_required`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `branches`

---

### 4.66 `holidays`
**Phase:** P2  
**Purpose:** Holiday calendar used in business-date and funds-availability logic.

**Typical columns**
- `id`
- `holiday_date`
- `name`
- `branch_id`
- `created_at`
- `updated_at`

**Key relationships**
- optionally belongs to `branches`

---

### 4.67 `settings_catalog`
**Phase:** P3  
**Purpose:** Registry of supported runtime settings and metadata.

**Typical columns**
- `id`
- `key`
- `value_type`
- `description`
- `default_json`
- `scope_allowed_json`
- `is_secret`
- `created_at`
- `updated_at`

**Key relationships**
- has many `settings_values`

---

### 4.68 `settings_values`
**Phase:** P3  
**Purpose:** Scoped runtime configuration values.

**Typical columns**
- `id`
- `settings_catalog_id`
- `scope_type`
- `scope_id`
- `value_json`
- `value_cipher`
- `effective_on`
- `ends_on`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `settings_catalog`

---

### 4.69 `export_jobs`
**Phase:** P3  
**Purpose:** Tracks GL exports, audit exports, statement exports, and related generated artifacts.

**Typical columns**
- `id`
- `export_type`
- `status`
- `reference_number`
- `started_at`
- `completed_at`
- `artifact_path`
- `created_by_id`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `users`

---

### 4.70 `statement_runs`
**Phase:** P2  
**Purpose:** Statement generation job runs by cycle/date/account group.

**Typical columns**
- `id`
- `business_date`
- `statement_cycle`
- `status`
- `started_at`
- `completed_at`
- `created_at`
- `updated_at`

**Key relationships**
- has many `statements`

---

### 4.71 `statements`
**Phase:** P2  
**Purpose:** Durable storage of customer statements.

**Typical columns**
- `id`
- `statement_run_id`
- `account_id`
- `period_start`
- `period_end`
- `statement_date`
- `status`
- `delivery_channel`
- `artifact_path`
- `created_at`
- `updated_at`

**Key relationships**
- belongs to `statement_runs`
- belongs to `accounts`

---

# 5. MVP vs Later-Phase Summary

## P1 — BankCORE MVP
- parties
- cards
- card_links
- accounts
- account_owners
- deposit_accounts
- loan_accounts
- account_balances
- account_holds
- account_transactions
- transaction_lines or teller_transaction_lines
- posting_batches
- posting_legs
- gl_accounts
- journal_entries
- journal_entry_lines
- branches
- cash_locations
- teller_sessions
- cash_movements
- workstations
- clearing_items
- check_items
- ach_items
- card_settlements
- fee_types
- fee_assessments
- users
- roles
- role_permissions
- user_roles

## P2 — Core Banking Operations
- party_people
- party_organizations
- party_contacts
- party_identifiers
- party_relationships
- advisories
- account_products
- account_limits
- account_status_events
- transactions
- transaction_items
- transaction_references
- transaction_exceptions
- posting_links
- gl_mappings
- gl_batches
- gl_batch_lines
- vault_transfers
- cash_counts
- cash_variances
- wire_items
- settlement_batches
- fee_rules
- interest_rules
- interest_accruals
- funds_availability_holds
- override_requests
- permissions
- user_branch_access
- sessions
- mfa_events
- audit_events
- business_dates
- holidays
- statement_runs
- statements

## P3 — Institutional Maturity
- reconciliation_exceptions
- settings_catalog
- settings_values
- export_jobs

---

# 6. Naming Guidance Relative to Current BankCORE Tables

## Good candidates to keep
- `accounts`
- `account_owners`
- `account_balances`
- `account_holds`
- `account_transactions`
- `deposit_accounts`
- `loan_accounts`
- `gl_accounts`
- `journal_entries`
- `journal_entry_lines`
- `branches`
- `cash_locations`
- `teller_sessions`
- `cash_movements`
- `users`
- `roles`
- `role_permissions`
- `user_roles`
- `workstations`

## Good candidates to generalize
- `owners` → `parties`
- `beneficial_owners` → `party_relationships`
- `card_accounts` → `card_links`
- `card_transactions` → `card_settlements`
- `holds` → use purpose-specific naming if distinct from `account_holds`
- `teller_transactions` → retain operationally, but consider eventual shared `transactions`
- `teller_transaction_lines` → consider eventual shared `transaction_lines`

---

# 7. Final Architectural Shape

The canonical model ultimately resolves into this structure:

```text
Parties / CIF
  ↓
Accounts / Product Rules
  ↓
Operational Transactions
  ↓
Posting Batches / Posting Legs
  ↓
Account Subledger + Cash Subledger + GL Journal
  ↓
Business Date / Statements / Reporting / Audit / Settings
```

This is the target shape for a serious, teller-first, branch-centric internal banking platform.

---

# 8. Practical Conclusion

BankCORE is already well aligned with the hardest architectural layers:

- operational transactions
- posting engine
- account subledger
- cash movement control
- GL foundation

The remaining work is primarily in:

- CIF maturity
- business-date orchestration
- fees and interest rules
- statements
- audit framework
- settings/configuration
- settlement reconciliation depth

That means the current design is not off track. It is already following the standard core-banking convergence path.

