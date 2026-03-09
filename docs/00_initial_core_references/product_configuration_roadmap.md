# Product Configuration Roadmap

**Status:** DROP-IN SAFE  
**Scope:** BankCORE account product configuration  
**Purpose:** Phased roadmap for product catalog evolution and product-driven behavior, from GL mapping through interest and fee rules.

---

# 1. Overview

Account products define the configuration home for deposit and loan behaviors. Today, the system relies on `account_type` and `deposit_accounts` attributes for much of this logic. This roadmap describes the phased migration from type-based to product-based configuration.

Each phase builds on the previous. The eventual goal is for `account_product` to be the primary source of truth for:

- GL mapping (liability/asset control accounts)
- interest and fee eligibility and GL destinations
- overdraft and statement defaults
- deposit subledger defaults

During migration, `account_type` may remain for backward compatibility and can be derived from `product.product_code` where appropriate.

Related documents:

- [canonical_table_model.md](canonical_table_model.md) — §4.10 account_products, §4.50 fee_rules, §4.52 interest_rules
- [gl_account_seed_plan.md](gl_account_seed_plan.md) — §7 GL usage by transaction type
- [tables_status.md](../progress/tables_status.md) — account_products, fee_rules, interest_rules
- [interest_and_fees_foundation.md](interest_and_fees_foundation.md)
- [transaction_catalog_spec.md](transaction_catalog_spec.md)
- [transaction_posting_spec.md](transaction_posting_spec.md)
- [../architecture/adr_backlog.md](../architecture/adr_backlog.md)

---

# 2. Product Configuration Dimensions

Summary of where each configuration aspect lives: product, account/deposit, or rule tables.

| Dimension       | Product                          | Account/Deposit           | Rules           |
|-----------------|----------------------------------|---------------------------|-----------------|
| GL mapping      | liability_gl, asset_gl           | —                         | —               |
| Interest        | method, expense_gl               | rate override             | interest_rules  |
| Fees            | eligibility scope                | —                         | fee_rules       |
| Overdraft       | allow_overdraft                  | policy override           | —               |
| Statement       | statement_cycle                  | —                         | —               |
| Deposit defaults| product_code → deposit_type      | —                         | —               |

---

# 3. Phased Roadmap

## Phase 1 — Product-GL Mapping

**Objective:** Ensure every account leg that affects customer balance flows to the general ledger via the product’s liability (or asset) control account.

**Deliverables:**

- Create `account_products` table with `liability_gl_account_id`, `asset_gl_account_id`
- Add `accounts.account_product_id`
- Seed products: dda→2110, now→2120, savings→2130, cd→2130
- Extend JournalProjector so account legs project to product GL
- Add ProductGlResolver (or equivalent) for account → product → GL resolution
- Backfill existing accounts from `account_type`
- Account creation form: product selector (required for new accounts)

**Outcome:** Deposit liability GLs (2110, 2120, 2130) receive postings; internal transfers and adjustments are fully reflected in the bank’s books.

---

## Phase 2 — Core Product Fields

**Objective:** Add structural and operational product attributes from the canonical model.

**Deliverables:**

- Add to `account_products`: `product_family`, `statement_cycle`, `allow_overdraft`
- Enforce or default `currency_code` at product level where appropriate
- Use product to derive `deposit_type` and default `interest_bearing` when creating `DepositAccount`
- Optionally deprecate or derive `account_type` from `product_code`

**Outcome:** Products define deposit and overdraft behavior; account creation is product-driven.

---

## Phase 3 — Product-Aware Interest

**Objective:** Route interest accrual to the correct interest expense GL by product (5120 for NOW, 5130 for Savings).

**Deliverables:**

- Add `interest_expense_gl_account_id` to `account_products`
- Update INT_ACCRUAL template or posting flow to use product GL when available
- Optionally add `interest_method` to product for future interest_rules

**Outcome:** Interest expense is reported by product line; accrual accounting aligns with product type.

---

## Phase 4 — Fee Rules and Product Eligibility

**Objective:** Replace hardcoded fee eligibility with product-based rules and support product-level fee GL overrides.

**Deliverables:**

- Add `fee_rules` table with `account_product_id`, `fee_type_id`, `amount_cents`, `conditions_json`
- Replace hardcoded `account_type: "dda"` in FeeAssessmentRunnerService with product-based eligibility
- Support product-level fee GL overrides (4510 vs 4540 vs 4560) via fee_rules or product

**Outcome:** Fees are configurable per product; different products can post fees to different income GLs.

---

## Phase 5 — Interest Rules

**Objective:** Move interest rate and cadence configuration to product-level rules.

**Deliverables:**

- Add `interest_rules` table with `account_product_id`, `rate`, `day_count_method`, `posting_cadence`
- Move default rate from `deposit_accounts.interest_rate_basis_points` to product-level rules
- InterestAccrualRunnerService uses interest_rules for eligible accounts

**Outcome:** Interest behavior is configurable per product; rates and posting frequency are no longer hardcoded.

---

# 4. Schema Evolution Summary

| Addition                                   | Phase |
|-------------------------------------------|-------|
| `account_products` table                  | 1     |
| `accounts.account_product_id`            | 1     |
| `account_products.product_family`         | 2     |
| `account_products.statement_cycle`       | 2     |
| `account_products.allow_overdraft`        | 2     |
| `account_products.interest_expense_gl_account_id` | 3 |
| `fee_rules` table                        | 4     |
| `interest_rules` table                   | 5     |

---

# 5. Dependencies and Risks

- **Phase 1 prerequisite:** Must complete before account legs can hit liability GLs; all later phases depend on `account_product_id` being populated.
- **Phase 4 and 5:** Require `account_product_id` on all accounts used in fee or interest processing.
- **Backward compatibility:** During migration, ProductGlResolver should fall back to `account_type` → gl_number mapping when `account_product_id` is nil.
