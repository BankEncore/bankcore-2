# ADR-0010: Treat Account Balances as Derived Projections Rather Than Source of Truth

**Status:** Accepted  
**Date:** 2026-03-08

## Context

In financial systems, balance tables are tempting operational shortcuts, but they are dangerous if treated as the primary authority for money movement.

BankCORE documentation and services already assume that balances are reconstructed from transactional history.

## Decision

Treat `account_balances` as a derived projection/cache rather than the source of truth.

Authoritative account balance history must remain reconstructable from posting-derived account activity.

## Consequences

- balance rebuilds remain possible
- corruption in cached balance rows does not destroy financial truth
- features must avoid direct balance updates as a business rule mechanism
- reporting and statement logic should rely on derived history, not independent balance mutation

## References

- `docs/00_initial_core_references/ledger_boundaries.md`
- `docs/progress/posting_compliance_matrix.md`
