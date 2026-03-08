# BankCORE / BankEncore — AI Agent Context

## Project Identity

Core banking platform built on the BankCORE financial kernel and BankEncore operating platform. The architecture follows a **posting-first philosophy**: every financial event originates as an operational action and resolves through a balanced, immutable, atomic posting engine.

## Non-Negotiable Financial Invariants

- **Balanced Posting**: No event posts unless SUM(debits) == SUM(credits)
- **Immutability**: Posted records are permanent; corrections require explicit reversals
- **Atomicity**: All-or-nothing posting; rollback on any failure
- **Derivable Balances**: `account_balances` is a cache; authoritative balances derive from posting history
- **Idempotency**: Duplicate requests must not create duplicate postings

## Tech Stack

- Rails 8.1, MySQL, Hotwire (Turbo + Stimulus)
- TailwindCSS + DaisyUI (theme: `bankcore`)
- Propshaft for assets

## Key Reference Docs

- Architecture: `docs/00_initial_core_references/00_executive_summary_lm.md`
- Roadmap: `docs/00_initial_core_references/00_implementation_roadmap_lm.md`
- Transaction types: `docs/00_initial_core_references/first_transaction_types.md`
- Posting templates: `docs/00_initial_core_references/posting_templates.md`
- GL seed plan: `docs/00_initial_core_references/gl_account_seed_plan.md`
- UI/Theme: `docs/00_initial_core_references/tailwind_daisyui_theme_spec.md`

## Ledger Boundaries (Do Not Cross)

- **Operational Layer** → "what happened" (transactions)
- **Posting Engine** → "how it affects money" (posting_batches, posting_legs)
- **Subledger** → "how it affects customer" (account_transactions)
- **GL Layer** → "how it affects bank accounting" (journal_entries)

## When Implementing Financial Logic

1. Never update balances directly; always go through the posting engine
2. Consult `posting_templates.md` for posting leg patterns
3. Follow phased build order (P1 kernel before P2+ operational features)
4. Reversals create a new inverse PostingBatch linked to the original; never mutate posted records
