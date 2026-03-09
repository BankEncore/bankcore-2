# ADR-0003: Use Posting Batches and Posting Legs as Authoritative Financial Records

**Status:** Accepted  
**Date:** 2026-03-08

## Context

BankCORE needs a canonical financial event model that supports:

- balancing
- reversals
- auditability
- recovery and reconstruction

The current architecture already centers these responsibilities on `posting_batches` and `posting_legs`, with account and journal records projected from them.

## Decision

Treat `posting_batches` and `posting_legs` as the authoritative financial records for committed events.

Other financial views, including account activity and journal entries, are derived from posting rather than independently authored.

## Consequences

- `account_transactions` are projections of account-facing posting legs
- `journal_entries` and `journal_entry_lines` are projections of GL-facing posting legs
- posting history becomes the primary source for reconstruction and audit review
- implementation must preserve strong linkage from posting to all downstream projections
- failures in downstream projection become serious because they threaten completeness of derived layers

## References

- `docs/00_initial_core_references/ledger_boundaries.md`
- `docs/progress/posting_compliance_matrix.md`
- `docs/00_initial_core_references/transaction_posting_spec.md`
