# ADR-0005: Use a Controlled System-Defined Transaction Catalog

**Status:** Accepted  
**Date:** 2026-03-08

## Context

BankCORE needs stable business semantics for:

- approvals
- reversals
- posting templates
- permissions
- audit review

If operators can invent transaction types ad hoc, those semantics become inconsistent and difficult to govern.

## Decision

Transaction types are system-defined catalog entries.

Users, jobs, and integrations create transaction instances using approved transaction types, but they do not define new types dynamically at runtime.

## Consequences

- the transaction catalog becomes a controlled part of system design
- transaction types can be tied predictably to posting behavior and reversal logic
- permissions and policy rules can be attached to stable transaction codes
- future extensibility should occur through controlled configuration, not free-form operator definition

## References

- `docs/00_initial_core_references/transaction_catalog_spec.md`
- `docs/00_initial_core_references/first_transaction_types.md`
- `docs/00_initial_core_references/posting_templates.md`
