---
name: Issue 60 Bank Draft Lifecycle
overview: "Implement bank draft lifecycle tracking for cashier's checks and money orders per GitHub issues #60 (parent), #73 (model), #74 (issuance), #75 (void), #76 (clearing). Posting-first, immutability, and ledger boundaries preserved."
todos:
  - id: 73-model
    content: "PR #1: Create bank_drafts model, schema, and bank_draft_sequences (#73)"
  - id: 74-issuance
    content: "PR #2: Add DRAFT_ISSUE workflow, GL 2160, DraftIssuanceService (#74)"
  - id: 75-void
    content: "PR #3: Add void workflow via VoidDraftService and ReversalService extension (#75)"
  - id: 76-clearing
    content: "PR #4: Add clearing workflow via DraftClearingService (#76)"
  - id: adr-docs
    content: "Create docs/adr/*.md to record documentable bank draft decisions"
isProject: true
---

# Plan: Bank Draft Lifecycle (Issues #60, #73, #74, #75, #76)

## Overview

Implement first-class operational tracking for cashier's checks and money orders: model, issuance, void, and clearing workflows. Aligns with BankCORE posting-first philosophy, immutability, and ledger boundaries.

**Parent issue:** [#60 Add bank draft lifecycle tracking](https://github.com/BankEncore/bankcore-2/issues/60)  
**Sub-issues:** [#73](https://github.com/BankEncore/bankcore-2/issues/73) | [#74](https://github.com/BankEncore/bankcore-2/issues/74) | [#75](https://github.com/BankEncore/bankcore-2/issues/75) | [#76](https://github.com/BankEncore/bankcore-2/issues/76)

### Execution Checklist

1. [ ] Post plan comment on GitHub #60
2. [ ] Post plan comment on GitHub #73, #74, #75, #76
3. [ ] PR #1: Branch `feature/73-bank-draft-model` → implement #73 → PR (Closes #73)
4. [ ] PR #2: Branch `feature/74-draft-issuance` → implement #74 → PR (Closes #74)
5. [ ] PR #3: Branch `feature/75-draft-void` → implement #75 → PR (Closes #75)
6. [ ] PR #4: Branch `feature/76-draft-clearing` → implement #76 → PR (Closes #76)
7. [ ] Close #60 when all PRs merged (or add "Closes #60" to final PR)
8. [ ] Create docs/adr/*.md to record documentable bank draft decisions

---

## Design Snapshot (Finalized)

### Model (#73)

| Field | Type | Nullable | Notes |
|-------|------|----------|-------|
| instrument_type | string | NOT NULL | `cashiers_check`, `money_order` |
| instrument_number | string | NOT NULL | Unique per `(instrument_type, instrument_number)` |
| amount_cents | integer | NOT NULL | |
| currency_code | string | NOT NULL | default "USD" |
| payee_name | string | NOT NULL | Free text |
| issue_date | date | NOT NULL | |
| status | string | NOT NULL | `issued`, `voided`, `cleared` |
| memo | text | optional | |
| expires_at | date | optional | |
| remitter_party_id | bigint | NOT NULL | |
| account_id | bigint | optional | Null when paid with cash/check (teller) |
| branch_id | bigint | NOT NULL | |
| issued_by_id | bigint | optional | |
| voided_by_id | bigint | optional | |
| voided_at | datetime | optional | |
| void_reason | string | optional | |
| cleared_at | datetime | optional | |
| cleared_by_id | bigint | optional | **Added per gap review** |
| clearing_reference | string | optional | |
| operational_transaction_id | bigint | optional | Set at issuance |
| posting_batch_id | bigint | optional | Set at issuance |

**Composite index:** `(instrument_type, instrument_number)` UNIQUE

### Workflows

- **#74 Issuance:** Account-funded only; DRAFT_ISSUE posting (Debit account, Credit 2160). Cash/check deferred to teller.
- **#75 Void:** VoidDraftService → ReversalService → mark draft voided. DRAFT_ISSUE_REVERSAL posting.
- **#76 Clearing:** State transition only; cleared_at, clearing_reference, cleared_by_id. GL movement via separate process.

---

## Decision Log / Rationale

Key decisions from the design session. Preserved for future implementers and reviewers.

### Model Design

| Decision | Rationale |
|----------|-----------|
| **payee_name** (free text) instead of payee_party_id | Payees are often third parties not in CIF; free text covers all cases. Can add payee_party_id later if CIF linkage is needed. |
| **remitter_party_id** required, **account_id** nullable | Remitter is always known (who bought the draft). Account is only set when paid from a deposit account; null when paid with cash/check (teller module). |
| **memo** and **expires_at** | Optional operational fields. memo for notes; expires_at for stale-draft handling (usage policy deferred). |
| **Composite unique** (instrument_type, instrument_number) | Separate number ranges per instrument type: cashier's checks and money orders can each have "1001". |
| **Separate model** from CheckItem | Bank drafts are institution-issued; CheckItem tracks customer-drawn checks. Different lifecycles (issued/voided/cleared vs posted/returned/reversed). |

### Workflow Design

| Decision | Rationale |
|----------|-----------|
| **#74 account-funded only** | Cash/check payment requires different posting (debit Cash GL, credit 2160). Teller module will add DRAFT_ISSUE_CASH or equivalent. |
| **DraftIssuanceService** mirrors CheckEntryService | PostingEngine creates transaction + batch; service then creates BankDraft and links. Same pattern as CheckItem. |
| **GL 2160 Official Checks Outstanding** | From [gl_account_seed_plan.md](docs/00_initial_core_references/gl_account_seed_plan.md) §4.2 (2160 listed as "Later"); promoted for this scope. |
| **Instrument number before post** | Allocate from sequence before calling PostingEngine. If post fails, sequence gap accepted. Alternative: allocate after post using client idempotency_key. |
| **Void single path** | For DRAFT_ISSUE, only "Void Draft" (not generic "Reverse") so we always capture void_reason and voided_by_id. |
| **#76 state-only clearing** | Clearing records lifecycle completion. GL debit of 2160 comes from check processing, correspondent, or manual entry. Draft clearing links to that when available. |

### Gap Resolutions Applied

| Gap | Resolution |
|-----|------------|
| cleared_by_id missing | Added to model for symmetry with voided_by_id. |
| Two void paths | Use Void Draft only for DRAFT_ISSUE; hide or redirect generic Reverse. |
| Account–remitter validation | DraftIssuanceService validates account belongs to or is valid for remitter. |
| expires_at usage | In model; optional at issuance. Policy for void eligibility deferred. |

### References

- **CheckEntryService** ([app/services/check_entry_service.rb](app/services/check_entry_service.rb)) — issuance orchestration pattern.
- **CheckItem** ([app/models/check_item.rb](app/models/check_item.rb)) — comparable instrument model; different domain.
- **ReversalService** ([app/services/reversal_service.rb](app/services/reversal_service.rb)) — mark_check_items_reversed! precedent for DRAFT_ISSUE.
- **gl_account_seed_plan.md** ([docs/00_initial_core_references/gl_account_seed_plan.md](docs/00_initial_core_references/gl_account_seed_plan.md)) — 2160 Official Checks Outstanding.

---

## PR Strategy

One PR per sub-issue for clean traceability. Each PR links and closes its issue. Parent #60 closed when all sub-issues merged.

| PR | Branch | Issue | Closes |
|----|--------|-------|--------|
| 1 | `feature/73-bank-draft-model` | #73 | #73 |
| 2 | `feature/74-draft-issuance` | #74 | #74 |
| 3 | `feature/75-draft-void` | #75 | #75 |
| 4 | `feature/76-draft-clearing` | #76 | #76 |

**PR title format:** `Add <topic> for bank drafts (Closes #XX)`  
**Commit format:** `feat(drafts): <scope> <summary>`

---

## PR #1: Bank Draft Model (#73)

**Branch:** `feature/73-bank-draft-model`  
**Issue:** [#73 Define bank draft data model and lifecycle states](https://github.com/BankEncore/bankcore-2/issues/73)

### Summary

- Add `bank_drafts` and `bank_draft_sequences` tables.
- Add `BankDraft` and `BankDraftSequence` models.
- Add draft-related enums to `Bankcore::Enums`.
- Inverse associations on `BankingTransaction`, `PostingBatch`, `Party`.

### Migrations

1. `CreateBankDrafts` — table per design snapshot (including `cleared_by_id`).
2. `CreateBankDraftSequences` — `(branch_id, instrument_type)` → `last_number`.

### Validation Commands

```bash
bin/rails db:migrate
bin/rails db:rollback
bin/rails db:migrate
bundle exec ruby -e "puts BankDraft.column_names"
```

### Test Plan

- [ ] Migration runs without error.
- [ ] `BankDraft` validations: instrument_type, instrument_number uniqueness (per type+number), status inclusion.
- [ ] `BankDraftSequence` model (if present) or sequence service unit test.
- [ ] Composite unique constraint on `(instrument_type, instrument_number)` enforced.

### Likely Files

- `db/migrate/*_create_bank_drafts.rb`
- `db/migrate/*_create_bank_draft_sequences.rb`
- `app/models/bank_draft.rb`
- `app/models/bank_draft_sequence.rb`
- `lib/bankcore/enums.rb`
- `app/models/banking_transaction.rb` (has_one :bank_draft)
- `app/models/posting_batch.rb` (has_one :bank_draft)
- `app/models/party.rb` (has_many :bank_drafts_as_remitter)

### PR Description Template

```markdown
## Summary
- Add bank_drafts table and BankDraft model per #73
- Add bank_draft_sequences for instrument number allocation per (branch, type)
- Add draft enums and inverse associations

Closes #73

## Test plan
- [ ] Migrations run cleanly
- [ ] BankDraft validations and uniqueness
- [ ] Model specs

## Migration impact
- New tables: bank_drafts, bank_draft_sequences
```

---

## PR #2: Draft Issuance (#74)

**Branch:** `feature/74-draft-issuance`  
**Base:** `feature/73-bank-draft-model` (or `main` after #73 merged)  
**Issue:** [#74 Add issuance workflow for cashier's checks and money orders](https://github.com/BankEncore/bankcore-2/issues/74)

### Summary

- Add GL account 2160 Official Checks Outstanding.
- Add transaction codes DRAFT_ISSUE, DRAFT_ISSUE_REVERSAL.
- Add posting templates for both.
- Add `BankDraftSequenceService` and `DraftIssuanceService`.
- Add `BankDraftsController` with new/create/show.
- Add `REFERENCE_TYPE_INSTRUMENT_NUMBER`.
- Validate account–remitter relationship at issuance.

### Prerequisites

- PR #1 merged.

### Migrations / Seeds

- Seeds: GL 2160, DRAFT_ISSUE, DRAFT_ISSUE_REVERSAL codes and templates.
- Or migration for GL 2160 + seeds for codes/templates.

### Validation Commands

```bash
bin/rails db:seed
bin/rails runner "puts TransactionCode.find_by(code: 'DRAFT_ISSUE')&.code"
bin/rails runner "DraftIssuanceService.post!(instrument_type: 'cashiers_check', remitter_party_id: 1, account_id: 1, amount_cents: 10000, payee_name: 'Test', branch_id: 1)"
```

### Test Plan

- [ ] GL 2160 seeded.
- [ ] DRAFT_ISSUE posting template: Debit customer_account, Credit 2160.
- [ ] DRAFT_ISSUE_REVERSAL template: Credit account, Debit 2160.
- [ ] DraftIssuanceService creates BankDraft, BankingTransaction, PostingBatch, TransactionReference.
- [ ] Instrument number allocated per (branch, instrument_type).
- [ ] Account–remitter validation.
- [ ] Controller create flow; show page displays draft and links to transaction.

### Likely Files

- `db/seeds.rb` (GL 2160, codes, templates)
- `app/services/bank_draft_sequence_service.rb`
- `app/services/draft_issuance_service.rb`
- `app/controllers/bank_drafts_controller.rb`
- `app/views/bank_drafts/new.html.erb`, `show.html.erb`, `index.html.erb`
- `app/models/transaction_reference.rb` (REFERENCE_TYPE_INSTRUMENT_NUMBER)
- `config/routes.rb`
- `test/services/draft_issuance_service_test.rb`
- `test/controllers/bank_drafts_controller_test.rb`

### PR Description Template

```markdown
## Summary
- Add DRAFT_ISSUE workflow for account-funded cashier's checks and money orders
- Add GL 2160 Official Checks Outstanding and posting templates
- Add DraftIssuanceService and BankDraftsController
- Instrument number allocation via bank_draft_sequences

Closes #74

## Test plan
- [ ] Full issuance flow
- [ ] Posting balance and linkage
- [ ] Controller tests

## Financial logic
- Balanced posting: Debit account, Credit 2160
- Idempotency on semantic payload
```

---

## PR #3: Draft Void (#75)

**Branch:** `feature/75-draft-void`  
**Base:** `main` (after #74 merged)  
**Issue:** [#75 Add void workflow for bank drafts](https://github.com/BankEncore/bankcore-2/issues/75)

### Summary

- Add `VoidDraftService`.
- Extend `ReversalService` with `mark_bank_drafts_voided!` for DRAFT_ISSUE.
- Add void action to `BankDraftsController`.
- For DRAFT_ISSUE transactions, show "Void Draft" instead of generic "Reverse"; route to void flow.
- Eligibility: only issued drafts; override for high-value per ReversalService.

### Prerequisites

- PR #2 merged (DRAFT_ISSUE_REVERSAL must exist).

### Validation Commands

```bash
# Create draft, then void
bin/rails runner "d = BankDraft.issued.first; VoidDraftService.void!(bank_draft: d, void_reason: 'Test', voided_by_id: 1)"
```

### Test Plan

- [ ] VoidDraftService validates eligibility (issued only).
- [ ] ReversalService marks BankDraft voided when reversing DRAFT_ISSUE.
- [ ] VoidDraftService sets void_reason and voided_by_id.
- [ ] Void action in UI; DRAFT_ISSUE transaction show links to Void Draft.

### Likely Files

- `app/services/void_draft_service.rb`
- `app/services/reversal_service.rb` (mark_bank_drafts_voided!)
- `app/controllers/bank_drafts_controller.rb` (void action)
- `app/views/bank_drafts/show.html.erb` (Void button)
- `app/views/transactions/show.html.erb` (Void Draft for DRAFT_ISSUE)
- `config/routes.rb` (post :void)
- `test/services/void_draft_service_test.rb`

### PR Description Template

```markdown
## Summary
- Add VoidDraftService for governed void workflow
- Extend ReversalService to mark BankDraft voided when reversing DRAFT_ISSUE
- Void action in BankDraftsController; DRAFT_ISSUE transactions use Void Draft flow

Closes #75

## Test plan
- [ ] Void flow and eligibility
- [ ] Reversal creates DRAFT_ISSUE_REVERSAL posting
- [ ] Immutability: original issuance intact
```

---

## PR #4: Draft Clearing (#76)

**Branch:** `feature/76-draft-clearing`  
**Base:** `main` (after #75 merged)  
**Issue:** [#76 Add clearing workflow and transaction linkage for bank drafts](https://github.com/BankEncore/bankcore-2/issues/76)

### Summary

- Add `DraftClearingService`.
- Add clear action to `BankDraftsController`.
- Update BankDraft: status → cleared, cleared_at, clearing_reference, cleared_by_id.
- Eligibility: only issued drafts; cannot clear voided.

### Prerequisites

- PR #1 merged (model has cleared_at, clearing_reference, cleared_by_id).

### Validation Commands

```bash
bin/rails runner "d = BankDraft.issued.first; DraftClearingService.clear!(bank_draft: d, clearing_reference: 'CHK-12345')"
```

### Test Plan

- [ ] DraftClearingService validates eligibility (issued only).
- [ ] State transition issued → cleared.
- [ ] Metadata persisted: cleared_at, clearing_reference, cleared_by_id.
- [ ] Clear action in UI.

### Likely Files

- `app/services/draft_clearing_service.rb`
- `app/controllers/bank_drafts_controller.rb` (clear action)
- `app/views/bank_drafts/show.html.erb` (Mark Cleared button)
- `config/routes.rb` (post :clear)
- `test/services/draft_clearing_service_test.rb`

### PR Description Template

```markdown
## Summary
- Add DraftClearingService for lifecycle completion
- State transition issued → cleared with cleared_at, clearing_reference, cleared_by_id
- Clear action in BankDraftsController

Closes #76

## Test plan
- [ ] Clear flow and eligibility
- [ ] Traceability to issuance preserved
## Note
Clearing is state-only; GL movement (debit 2160) handled by separate process (check processing, manual).
```

---

## GitHub Issue Updates

### Step 1: Comment on Parent Issue #60

Paste this comment on [GitHub #60](https://github.com/BankEncore/bankcore-2/issues/60):

```
## Implementation plan

Implementation is tracked in `.cursor/plans/issue-60-bank-draft-lifecycle.plan.md`.

**Delivery via sub-issues:**
- #73 — Bank draft model and sequences
- #74 — Issuance workflow
- #75 — Void workflow
- #76 — Clearing workflow

This issue will be closed when all four PRs are merged.
```

### Step 2: Comment on Each Sub-Issue (#73, #74, #75, #76)

Paste on the corresponding issue (replace XX with issue number):

```
Implementation plan: `.cursor/plans/issue-60-bank-draft-lifecycle.plan.md`
Branch: `feature/XX-<topic>` — PR will reference this issue with "Closes #XX"
```

### Step 3: PR Body — Link and Close

When opening each PR, include in the description:
- **Title:** `Add <topic> for bank drafts (Closes #XX)`
- **Body:** "Closes #XX" (GitHub will auto-close the issue on merge)

---

## Execution Order

1. **Create branches from `main`** (or from previous feature branch if stacking).
2. **PR #1** → merge → close #73.
3. **PR #2** → merge → close #74.
4. **PR #3** → merge → close #75.
5. **PR #4** → merge → close #76.
6. **Close #60** when all merged (or use GitHub auto-close when last PR merges with "Closes #60" if desired).

---

## Gap Resolutions (Applied)

- **cleared_by_id:** Added to model in PR #1.
- **Void single path:** PR #3 uses "Void Draft" only for DRAFT_ISSUE.
- **Account–remitter validation:** PR #2 DraftIssuanceService.
- **expires_at:** In model; usage deferred (optional at issuance, future policy).
- **Instrument number allocation:** Allocate before post; sequence gaps acceptable per design note.
- **#76 GL:** State-only; document in PR description.

---

## Scope Boundaries

**Included:**

- Bank draft model and lifecycle states
- Account-funded issuance
- Void via reversal
- Clearing as state transition

**Deferred:**

- Cash/check-funded issuance (teller module)
- DRAFT_ISSUE_CASH transaction code
- DRAFT_CLEAR posting (when check processing provides)
- expires_at policy for void eligibility

---

## ADR Documentation (To-Do)

Create `docs/adr/*.md` to record documentable decisions. Suggested scope:

- **Model:** Separate BankDraft from CheckItem; payee_name vs payee_party_id; remitter_party_id + nullable account_id; composite (instrument_type, instrument_number) uniqueness.
- **Workflows:** Account-funded issuance only; void single path for DRAFT_ISSUE; clearing state-only with GL via separate process.
- **GL:** Use of 2160 Official Checks Outstanding for bank draft liability.

Can be one ADR (e.g. `docs/adr/0016-bank-draft-lifecycle.md`) or split by topic. Reference the Decision Log above for content.
