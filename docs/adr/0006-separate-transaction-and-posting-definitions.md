# ADR-0006: Separate Operational Transaction Definitions from Posting Definitions

**Status:** Accepted  
**Date:** 2026-03-08

## Context

Operational transaction design and accounting posting design answer different questions:

- operational transaction definitions explain what happened
- posting definitions explain how it affects money

Combining both into a single document or model makes business rules harder to reason about and accounting rules harder to validate.

## Decision

Maintain separate specifications and conceptual models for:

- operational transaction definitions
- posting and accounting definitions

Operational rules may reference posting behavior, but they remain distinct concerns.

## Consequences

- operational documentation can focus on inputs, metadata, eligibility, and approvals
- posting documentation can focus on debit/credit shape and GL resolution
- reviews become clearer because business semantics and accounting mechanics are not conflated
- future operational richness can grow without forcing a rewrite of accounting logic

## References

- `docs/00_initial_core_references/transaction_catalog_spec.md`
- `docs/00_initial_core_references/transaction_posting_spec.md`
- `docs/00_initial_core_references/layer_responsibility_map.md`
