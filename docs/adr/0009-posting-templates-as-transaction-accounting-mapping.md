# ADR-0009: Use Posting Templates as the Primary Transaction-to-Accounting Mapping Model

**Status:** Accepted  
**Date:** 2026-03-08

## Context

The earlier enterprise draft included a dedicated `gl_mappings` concept, but the MVP implementation already centers transaction accounting behavior on:

- `transaction_codes`
- `posting_templates`
- `posting_template_legs`

This pattern is already reflected in documentation and code.

## Decision

Use posting templates as the primary mechanism for mapping transaction types to accounting behavior in the current MVP.

Do not introduce a separate `gl_mappings` registry as the main accounting model at this stage.

## Consequences

- accounting behavior stays template-driven and explicit
- transaction-to-posting logic remains generic in the posting engine
- the MVP avoids an additional abstraction layer
- future override or rule-driven mapping may still be introduced later if the product demands it

## References

- `docs/00_initial_core_references/posting_templates.md`
- `docs/progress/tables_status.md`
- `docs/00_initial_core_references/transaction_posting_spec.md`
