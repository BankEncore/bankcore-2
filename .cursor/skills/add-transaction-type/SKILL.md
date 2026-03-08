---
name: add-transaction-type
description: Adds a new transaction type to BankCORE with operational model and posting template. Use when implementing a new transaction type, extending the transaction catalog, or when the user mentions ADJ_CREDIT, XFER_INTERNAL, FEE_POST, INT_ACCRUAL, INT_POST, ACH_CREDIT, ACH_DEBIT, or similar transaction codes.
---

# Add Transaction Type

## Workflow

1. **Define operational meaning** — What business event does this represent?
2. **Identify posting legs** — Debit/credit pairs; consult `docs/00_initial_core_references/posting_templates.md`
3. **Implement** — Transaction model + posting service + template
4. **Verify invariants** — Balanced, atomic, reversible

## Checklist

- [ ] Transaction code follows existing pattern (e.g. ADJ_CREDIT, XFER_INTERNAL)
- [ ] Posting legs balance (debits == credits)
- [ ] Reversal path defined (inverse posting linked to original)
- [ ] No direct balance updates; all changes flow through posting engine

## Reference

- Transaction catalog: `docs/00_initial_core_references/first_transaction_types.md`
- Posting templates: `docs/00_initial_core_references/posting_templates.md`
