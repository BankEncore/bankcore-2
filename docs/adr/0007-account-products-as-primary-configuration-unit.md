# ADR-0007: Use Account Products as the Primary Configuration Unit

**Status:** Accepted  
**Date:** 2026-03-08

## Context

Current behavior is distributed across:

- `account_type`
- `deposit_accounts`
- service-specific logic

That is sufficient for a narrow MVP, but it does not scale well as fee, interest, overdraft, and GL behavior become more product-aware.

## Decision

Use `account_products` as the primary configuration unit for product behavior.

Accounts should reference an account product, and product definitions should become the main home for shared behavior such as:

- GL control accounts
- statement cycle
- overdraft defaults
- fee eligibility
- interest configuration

## Consequences

- `accounts` gain `account_product_id`
- product definitions become more explicit and reusable
- `account_type` becomes transitional or derived rather than the main configuration axis
- multiple future rules engines can key off products consistently

## References

- `docs/00_initial_core_references/product_configuration_roadmap.md`
- `docs/progress/tables_status.md`
- `docs/00_initial_core_references/canonical_table_model.md`
