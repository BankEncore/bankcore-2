# ADR-0004: Correct Posted Financial Events Through Reversals Instead of Mutation

**Status:** Accepted  
**Date:** 2026-03-08

## Context

Financial history must remain explainable after errors, corrections, and operator mistakes.

Updating or deleting posted financial rows destroys the audit trail and weakens the integrity of historical balances.

BankCORE has already adopted reversal flows conceptually and in service design.

## Decision

Posted financial events must be corrected through explicit reversal postings linked to the original event.

The original posted rows remain intact. Corrections are represented as new inverse postings rather than mutations of prior records.

## Consequences

- reversal workflows become first-class operational behavior
- posted financial models should be protected against update and delete operations
- approvals and override policies naturally attach to reversal activity
- historical balances remain explainable because both original and corrective events are retained
- some operational workflows become more complex than simple edits, but financial defensibility improves

## References

- `docs/00_initial_core_references/ledger_boundaries.md`
- `docs/progress/posting_compliance_matrix.md`
- `docs/00_initial_core_references/transaction_posting_spec.md`
