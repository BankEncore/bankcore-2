---
name: posting-plan-review
description: Reviews posting logic for balance, immutability, and reversal support. Use when reviewing posting engine code, PostingBatch/PostingLeg implementations, or when the user asks for a financial logic review.
---

# Posting Plan Review

## Review Checklist

1. **Balance** — SUM(debit_legs.amount) == SUM(credit_legs.amount) before commit
2. **Immutability** — Posted records are never updated or deleted
3. **Atomicity** — All legs commit together or roll back entirely
4. **Reversal** — Corrections create inverse PostingBatch linked to original
5. **No direct balance updates** — `account_balances` updated only via posting engine projection

## Red Flags

- Direct `UPDATE account_balances` or similar
- Partial commits (some legs posted, others not)
- Mutating posted records instead of creating reversals
- Missing idempotency key for retry-safe operations

## Reference

- Invariants: `.cursor/rules/bankcore-invariants.mdc`
- Posting templates: `docs/00_initial_core_references/posting_templates.md`
