# ADR-0015: Overdraft override with pre-transaction context

**Status:** Accepted  
**Date:** 2026-03-10  
**Context:** Issue #70

## Context

Check OD override is required **before** a transaction exists. Override must carry context for validation on resubmit.

## Decision

Add `context_json` to `override_requests`; support `OVERRIDE_TYPE_CHECK_OVERDRAFT` with `account_id`, `amount_cents`, `check_number` in context. Under-threshold OD: allow with confirm; above-threshold: override flow. On resubmit, `OverrideRequestService.use!` validates context matches current request before consuming.

## Consequences

- `OverrideRequest` can support pre-transaction overrides
- `context_json` enables validation on resubmit and preserves audit trail
- Check overdraft flow: redirect to override request → approve → "Post this check" link with params → post with override_request_id

## References

- app/services/override_request_service.rb
- GitHub issue #70
