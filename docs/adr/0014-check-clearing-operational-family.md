# ADR-0014: Check clearing as operational family with side-record check items

**Status:** Accepted  
**Date:** 2026-03-10  
**Context:** Issue #59

## Context

The canonical model has check_items belonging to clearing_items. The current app uses transaction-code–driven posting (like ACH) without a clearing-item registry.

## Decision

Implement check clearing as a first-class operational family (`CHK_POST`) with `check_items` linked directly to `operational_transaction` and `posting_batch`. No `clearing_items` table. Eligibility at product level (`check_writing_eligible`).

## Consequences

- Check posting follows the same pattern as ACH
- `check_items` is a side record for traceability and lifecycle (posted, returned, reversed, exception)
- Future clearing-item registry can be layered without changing posting flow
- Product-level and optional account-level override for check-writing eligibility

## References

- docs/progress/tables_status.md
- docs/00_initial_core_references/ledger_boundaries.md
- GitHub issue #59
