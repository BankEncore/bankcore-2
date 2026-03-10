---
name: Issue 66 ACH Default Reference
overview: "Generate an ACH-specific default reference_number in format ACH-{trace}-{YYMMDD} when blank for ACH_CREDIT/ACH_DEBIT and trace+effective_date are present, with server-side application and optional client fallback to generic MAN format when trace not yet entered."
todos:
  - id: 66-ach-ref-server
    content: Add ACH-specific reference default in Request when trace+effective_date present
  - id: 66-ach-ref-client
    content: Wire workstation to use ACH format when ACH fields filled, else MAN fallback
  - id: 66-ach-ref-tests
    content: Add request and controller tests for ACH reference defaults
isProject: false
---

# Plan Issue #66 — ACH-Specific Default References

## Goal

Generate a default `reference_number` for ACH transactions in format `ACH-{trace}-{YYMMDD}` when the field is blank and both `ach_trace_number` and `ach_effective_date` are present, improving traceability to the ACH network identifiers. Fall back to generic `MAN-{code}-{timestamp}` when trace/date are not yet filled (e.g. on type selection before operator enters ACH fields).

## Current State

- Issue #64 defaults `reference_number` to `MAN-{code}-{YYMMDDHHMMSS}` for all MANUAL_ENTRY_CODES including ACH_CREDIT and ACH_DEBIT.
- ACH policy requires: `ach_trace_number`, `ach_effective_date`, `ach_batch_reference`; `authorization_reference` for ACH_DEBIT.
- Transaction catalog: idempotency keys on trace, file/batch, account, amount. Trace is the primary network identifier.
- ACH fields: [app/views/transactions/_ach_fields.html.erb](app/views/transactions/_ach_fields.html.erb) — trace, effective date, batch reference, authorization.

## Recommended Design

**Preferred format when ACH fields present:** `ACH-{trace}-{effective_date_YYMMDD}`

**When to apply ACH-specific:**
- Transaction code is `ACH_CREDIT` or `ACH_DEBIT`
- `reference_number` is blank (or was our generic MAN default and we're replacing)
- `ach_trace_number` and `ach_effective_date` are both present

**Fallback:** When ACH code but trace/date not yet entered, use existing `MAN-{code}-{timestamp}` from #64 so operator always has a non-blank reference before submit.

**Behavior:**
- Server-side: In `default_reference_if_blank`, for ACH codes, when trace+effective_date present, generate `ACH-{trace}-{YYMMDD}`. Else use generic `MAN-{code}-{timestamp}`.
- Client-side: When ACH type selected, if trace and effective_date inputs have values, autofill reference with ACH format. Else use MAN format (existing behavior).
- Preserve operator-entered reference in all cases.
- Preserve through preview → confirm → post.

## GitHub Alignment

- Create or confirm GitHub issue #66: "Generate ACH-specific default reference for ACH_CREDIT/ACH_DEBIT when trace and effective date present"
- Branch: `feature/66-ach-default-reference`
- Workflow: Issue → Branch → Validate → Commit → Push → PR

## Key Constraint

Do not put this in [app/services/posting_engine.rb](app/services/posting_engine.rb). Keep logic in transaction-entry layer.

## Implementation Steps

### 1. Server-side

- Extend `default_reference_if_blank` / `generate_default_reference` in [app/services/transaction_entry/request.rb](app/services/transaction_entry/request.rb) to accept optional ACH context: `ach_trace_number`, `ach_effective_date`.
- For ACH_CREDIT/ACH_DEBIT when reference blank: if both trace and effective_date present, return `ACH-{trace}-{YYMMDD}`; else return `MAN-{code}-{timestamp}`.
- Pass normalized `ach_trace_number` and `ach_effective_date` from raw_params into the helper (values already available in from_form).

### 2. Client-side

- In [app/javascript/controllers/index.js](app/javascript/controllers/index.js), extend `updateReferenceAutofill` for ACH codes: when `achTrace` and `achEffectiveDate` targets have values, generate `ACH-{trace}-{YYMMDD}`. Else use existing MAN format.
- Ensure `account-picker:changed` is not the trigger for ACH (no account context needed). Trigger on `achTrace` and `achEffectiveDate` input/change when in ACH mode.
- Preserve `markReferenceUserEdited` and overwrite logic: only autofill when blank or when value matches our patterns (MAN-ACH_*-* or ACH-*-*).

### 3. Tests

- Request: ACH_DEBIT with blank reference, trace and effective_date -> `ACH-123456789012345-250309`
- Request: ACH_CREDIT with operator reference -> preserved
- Request: ACH_DEBIT with trace but no effective_date -> generic MAN format
- Controller: ACH with blank reference, trace, effective_date -> posts with ACH format
- Controller: ACH preview preserves ACH-format reference through confirm

## Likely Files

- [app/services/transaction_entry/request.rb](app/services/transaction_entry/request.rb)
- [app/javascript/controllers/index.js](app/javascript/controllers/index.js)
- [app/views/transactions/_ach_fields.html.erb](app/views/transactions/_ach_fields.html.erb) — add change listeners if needed for reference update when trace/date filled
- [test/services/transaction_entry/request_test.rb](test/services/transaction_entry/request_test.rb)
- [test/controllers/transactions_controller_test.rb](test/controllers/transactions_controller_test.rb)

## Scope Boundaries

**Included:**
- ACH-specific reference format when trace+effective_date present
- Fallback to MAN format when ACH fields not yet filled
- Server and client coverage

**Deferred:**
- Batch reference in default format (trace+date sufficient for MVP)
- ACH return/exception reference handling
