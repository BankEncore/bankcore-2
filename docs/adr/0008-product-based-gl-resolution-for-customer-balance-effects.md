# ADR-0008: Resolve Customer Balance GL Effects Through Account Products

**Status:** Proposed  
**Date:** 2026-03-08

## Context

BankCORE currently handles many customer-side effects as account legs that influence subledger history, while explicit GL legs cover only fixed accounting destinations.

This leaves an accounting gap: customer balance changes may not fully reach product-specific liability or asset buckets in the general ledger.

## Decision

Resolve customer balance GL effects through account products.

Deposit products should map to liability control accounts. Loan products should map to asset control accounts. Customer-side transaction effects should project to the general ledger using those product mappings.

## Consequences

- internal transfers can debit and credit the correct liability buckets
- adjustments and interest posting become fully visible in bank accounting
- product identity becomes a dependency for complete GL fidelity
- future loan behavior can use the same pattern with asset control accounts

## References

- `docs/00_initial_core_references/product_configuration_roadmap.md`
- `docs/00_initial_core_references/transaction_posting_spec.md`
- `docs/00_initial_core_references/gl_account_seed_plan.md`
