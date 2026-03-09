# ADR-0012: Phase Product Configuration Evolution from GL Mapping to Fee and Interest Rules

**Status:** Proposed  
**Date:** 2026-03-08

## Context

Product configuration touches multiple domains:

- GL control accounts
- overdraft behavior
- statement defaults
- fee eligibility and overrides
- interest calculation and cadence

Implementing all of that at once would increase schema churn and risk.

## Decision

Evolve product configuration in phases:

1. product GL mapping
2. core product fields
3. product-aware interest
4. fee rules
5. interest rules

## Consequences

- the most urgent accounting gap is addressed first
- schema and behavior changes remain incremental
- product identity stabilizes before rule engines expand
- some logic remains temporarily hardcoded during transition

## References

- `docs/00_initial_core_references/product_configuration_roadmap.md`
