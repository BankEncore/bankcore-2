# ADR-0011: Defer Full Operational Transaction Detail Model Until After Posting-Kernel Maturity

**Status:** Accepted  
**Date:** 2026-03-08

## Context

The full enterprise draft anticipates a richer operational transaction model with:

- `transaction_lines`
- `transaction_references`
- `transaction_exceptions`

The current MVP intentionally emphasizes financial kernel maturity first.

## Decision

Defer implementation of the full operational transaction detail model until after the posting kernel is stable and trusted.

The MVP may use a thinner operational layer initially, with richer transaction detail added in later phases.

## Consequences

- delivery of the financial kernel is faster
- early operational traceability is thinner than the target end state
- future work must fill in operational metadata gaps such as contra-account context and richer external references
- documentation should keep the fuller operational target visible so the thin MVP is understood as intentional, not final

## References

- `docs/progress/tables_status.md`
- `docs/00_initial_core_references/transaction_catalog_spec.md`
- `docs/00_initial_core_references/layer_responsibility_map.md`
