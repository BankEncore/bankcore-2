# ADR-0002: Separate Operational, Posting, Subledger, and General-Ledger Layers

**Status:** Accepted  
**Date:** 2026-03-08

## Context

Banking systems become fragile when operational meaning, financial posting, customer history, and bank accounting are stored or reasoned about as if they were the same thing.

BankCORE documentation consistently distinguishes:

- operational layer
- posting engine layer
- account subledger layer
- general ledger layer

## Decision

Use four explicit financial layers in the system design:

1. Operational layer: what happened
2. Posting engine layer: how it affects money
3. Account subledger layer: what the customer sees
4. General ledger layer: what the bank books show

Tables, services, and fields should be assigned to one of these layers deliberately.

## Consequences

- operational records remain flexible without becoming accounting truth
- posting records remain focused on balanced financial events
- customer-facing transaction history can evolve independently from GL reporting
- design reviews can ask whether a new field or table belongs in the correct layer
- some concepts will exist in more than one layer, but with different meanings and responsibilities

## References

- `docs/00_initial_core_references/ledger_boundaries.md`
- `docs/00_initial_core_references/layer_responsibility_map.md`
- `docs/00_initial_core_references/bankencore_platform_architecture.md`
