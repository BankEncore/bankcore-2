# ADR-0016: Bank draft lifecycle tracking

**Status:** Accepted  
**Date:** 2026-03-10  
**Context:** Issues #60, #73, #74, #75, #76

## Context

Bank drafts (cashier's checks and money orders) require first-class operational tracking separate from customer-drawn checks. The system needed a model, issuance workflow, void workflow, and clearing workflow aligned with posting-first philosophy and ledger boundaries.

## Decision

### Model

- **Separate BankDraft model** from CheckItem. Bank drafts are institution-issued; CheckItem tracks customer-drawn checks. Different lifecycles (issued/voided/cleared vs posted/returned/reversed).
- **payee_name** (free text) instead of payee_party_id. Payees are often third parties not in CIF; free text covers all cases.
- **remitter_party_id** required, **account_id** nullable. Remitter is always known. Account set only when paid from deposit account; null when paid with cash/check (teller).
- **Composite unique** (instrument_type, instrument_number). Separate number ranges per instrument type (cashier's checks and money orders can each have "1001").

### Workflows

- **Issuance (#74):** Account-funded only. DRAFT_ISSUE posting (Debit customer account, Credit GL 2160 Official Checks Outstanding). Cash/check payment deferred to teller module.
- **Void (#75):** Single path via VoidDraftService → ReversalService for DRAFT_ISSUE. Always capture void_reason and voided_by_id. Do not expose generic "Reverse" for DRAFT_ISSUE; route to "Void Draft" flow.
- **Clearing (#76):** State transition only. Set status → cleared, cleared_at, clearing_reference, cleared_by_id. GL debit of 2160 comes from check processing, correspondent, or manual entry; draft clearing is lifecycle completion, not posting.

### GL

- Use **GL 2160 Official Checks Outstanding** (liability) for bank draft liability at issuance and reversal.

## Consequences

- Bank drafts have traceable lifecycle: issued → voided or cleared
- Void uses ReversalService for balanced DRAFT_ISSUE_REVERSAL posting; VoidDraftService records void metadata
- Clearing does not post; GL movement handled by separate process
- Instrument number allocation via bank_draft_sequences per (branch_id, instrument_type)

## References

- .cursor/plans/issue-60-bank-draft-lifecycle.plan.md
- app/models/bank_draft.rb
- app/services/draft_issuance_service.rb
- app/services/void_draft_service.rb
- app/services/draft_clearing_service.rb
- docs/00_initial_core_references/gl_account_seed_plan.md
- GitHub issues #60, #73, #74, #75, #76
