# ADR-0013: Use a Shared Operational Account Lookup Primitive for Searchable Account Selection

**Status:** Proposed  
**Date:** 2026-03-09

## Context

Issue `#62` introduces a searchable account picker for the transaction workstation.

The first implementation target is the shared transaction shell in `TransactionsController`, but the product roadmap and UI guidance already position back-office and teller screens as related workstation modes rather than isolated interfaces.

The current transaction workstation loads every active account into server-rendered `<select>` controls. That is workable for a small dataset, but it does not scale well and it creates a picker implementation that would need to be rebuilt for teller flows.

## Decision

Implement account search as a shared operational lookup primitive:

- expose a dedicated account lookup endpoint/controller
- keep the authorization boundary explicit and operationally governed
- return a compact, generic account payload suitable for multiple UIs
- build the picker as an account-focused Stimulus controller
- use the transaction workstation as the first consumer

The initial permission boundary will continue to use `post_transactions`, which is already available to both back-office and teller-capable roles in the current system.

## Consequences

- issue `#62` can ship in the transaction workstation without coupling search to transaction-controller internals
- future teller flows can reuse the same lookup endpoint and picker controller
- the picker stays focused on account search and selection, while each consuming workflow remains responsible for how selected IDs are submitted
- richer account context remains deferred to follow-on issue `#63`
- if future teller requirements need a narrower or broader lookup permission, the shared endpoint may need an authorization refinement later

## References

- `docs/architecture/transaction_rules_ui_roadmap.md`
- `docs/00_initial_core_references/ui_theme_and_workstation_primitives.md`
- `app/views/transactions/new.html.erb`
