# ADR-0001: Adopt Posting-First Financial Architecture

**Status:** Accepted  
**Date:** 2026-03-08

## Context

BankCORE is intended to be a core banking platform, not a CRUD application with mutable balance fields.

The platform must ensure that:

- every material financial event resolves through balanced debit/credit posting
- customer balances remain explainable from durable history
- financial effects are auditable and reconstructable

This decision is already reflected across the core architecture and posting reference docs.

## Decision

Adopt a posting-first architecture for all material financial activity.

Operational actions may initiate financial events, but financial truth is created only when the posting engine constructs and commits balanced posting records.

Direct balance mutation is not an acceptable implementation pattern for financial features.

## Consequences

- all financial workflows must integrate with the posting engine
- financial effects are expressed as posting batches and posting legs
- balances, customer history, and GL books become downstream projections of posting history
- future modules such as teller, ACH, fees, and interest must route through the same kernel
- implementation speed may be lower in the short term, but auditability and correctness improve materially

## References

- `docs/00_initial_core_references/bankencore_platform_architecture.md`
- `docs/00_initial_core_references/ledger_boundaries.md`
- `docs/progress/posting_compliance_matrix.md`
