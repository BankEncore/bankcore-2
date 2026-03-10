# ADR Backlog

**Status:** WORKING BACKLOG  
**Scope:** BankCORE / BankEncore architectural decision record candidates  
**Purpose:** Capture the architectural decisions that have effectively already been made in reference docs, plans, and implementation work, but have not yet been formalized as ADRs.

---

# 1. How To Use This Backlog

This document is not itself an ADR.

It is a curated list of decisions that are good candidates for formal ADRs because they:

- constrain multiple future features
- shape schema and service boundaries
- are expensive to reverse later
- define shared terminology and modeling rules

Each candidate below includes:

- suggested ADR title
- recommended priority
- current status recommendation
- short decision statement
- main consequences
- source documents to mine when writing the ADR

Recommended ADR statuses for initial drafting:

- `Accepted` for decisions already reflected in implementation and core docs
- `Proposed` for decisions documented as roadmap direction but not yet fully implemented

---

# 1.1 Formalized ADRs

The following ADRs have now been created under `docs/adr/`:

- `0001-posting-first-financial-architecture.md`
- `0002-financial-layer-separation.md`
- `0003-authoritative-posting-records.md`
- `0004-reversal-over-mutation.md`
- `0005-controlled-transaction-catalog.md`
- `0006-separate-transaction-and-posting-definitions.md`
- `0007-account-products-as-primary-configuration-unit.md`
- `0008-product-based-gl-resolution-for-customer-balance-effects.md`
- `0009-posting-templates-as-transaction-accounting-mapping.md`
- `0010-derived-account-balances.md`
- `0011-defer-full-operational-transaction-detail-model.md`
- `0012-phase-product-configuration-evolution.md`
- `0013-shared-operational-account-lookup-primitive.md`
- `0014-check-clearing-operational-family.md`
- `0015-check-overdraft-override-context.md`

These files should now be treated as the primary home for the corresponding decisions.

---

# 2. Priority 1 ADR Candidates

## ADR-001 — Adopt posting-first financial architecture

**Recommended status:** `Accepted`

**Decision**

All material financial effects must resolve through the posting engine rather than directly mutating balances or books.

**Why this matters**

This is the core architectural choice that distinguishes BankCORE from a generic business system with balance columns.

**Main consequences**

- financial effects must pass through balanced posting
- balances become derived rather than authoritative write targets
- every future transaction family must integrate with posting rather than bypass it

**Source documents**

- `docs/00_initial_core_references/bankencore_platform_architecture.md`
- `docs/00_initial_core_references/ledger_boundaries.md`
- `docs/progress/posting_compliance_matrix.md`

---

## ADR-002 — Separate operational, posting, subledger, and general-ledger layers

**Recommended status:** `Accepted`

**Decision**

BankCORE uses four distinct financial layers:

- operational layer
- posting engine layer
- account subledger layer
- general ledger layer

**Why this matters**

This defines the shared system vocabulary and prevents business context from being collapsed into accounting rows.

**Main consequences**

- table placement and responsibilities become clearer
- features can evolve without blurring accounting boundaries
- operator workflows stay distinct from financial truth

**Source documents**

- `docs/00_initial_core_references/ledger_boundaries.md`
- `docs/00_initial_core_references/layer_responsibility_map.md`
- `docs/00_initial_core_references/bankencore_platform_architecture.md`

---

## ADR-003 — Use posting batches and posting legs as authoritative financial records

**Recommended status:** `Accepted`

**Decision**

`posting_batches` and `posting_legs` form the canonical financial event model. Subledger and GL records are downstream projections.

**Why this matters**

This is the core data-model decision behind recoverability, reconciliation, and auditability.

**Main consequences**

- `account_transactions` are derived from posting
- `journal_entries` are derived from posting
- reconstruction and validation logic should center on posting history

**Source documents**

- `docs/00_initial_core_references/ledger_boundaries.md`
- `docs/progress/posting_compliance_matrix.md`
- `docs/00_initial_core_references/transaction_posting_spec.md`

---

## ADR-004 — Correct posted financial events through reversals instead of mutation

**Recommended status:** `Accepted`

**Decision**

Posted financial history must be corrected through explicit inverse postings linked to the original event, not by updating or deleting posted rows.

**Why this matters**

This is a core banking control posture and directly affects safety, auditability, and user workflows.

**Main consequences**

- reversal flows become first-class
- update/delete of posted records should be blocked
- policies and approvals should govern reversal behavior

**Source documents**

- `docs/00_initial_core_references/ledger_boundaries.md`
- `docs/progress/posting_compliance_matrix.md`
- `docs/00_initial_core_references/transaction_posting_spec.md`

---

## ADR-005 — Use a controlled system-defined transaction catalog

**Recommended status:** `Accepted`

**Decision**

Transaction types are system-defined catalog entries. Operators create transaction instances but do not invent ad hoc transaction types.

**Why this matters**

This stabilizes business semantics, approvals, reversals, and posting behavior.

**Main consequences**

- transaction definitions are curated and versioned
- transaction instances reference known transaction codes
- permissions and approvals can be tied to stable transaction types

**Source documents**

- `docs/00_initial_core_references/transaction_catalog_spec.md`
- `docs/00_initial_core_references/first_transaction_types.md`
- `docs/00_initial_core_references/posting_templates.md`

---

## ADR-006 — Separate operational transaction definitions from posting definitions

**Recommended status:** `Accepted`

**Decision**

Operational transaction rules and accounting/posting rules should be documented and modeled separately.

**Why this matters**

This prevents business meaning from being mixed with debit/credit mechanics and keeps both specs easier to evolve.

**Main consequences**

- the operational layer can become richer without changing posting semantics
- posting templates can evolve without rewriting transaction catalog language
- docs and tests can be organized around separate concerns

**Source documents**

- `docs/00_initial_core_references/transaction_catalog_spec.md`
- `docs/00_initial_core_references/transaction_posting_spec.md`
- `docs/00_initial_core_references/layer_responsibility_map.md`

---

## ADR-007 — Use account products as the primary configuration unit

**Recommended status:** `Proposed`

**Decision**

Product behavior should be centered on `account_products` rather than dispersed across `account_type`, `deposit_accounts`, and service-specific hardcoding.

**Why this matters**

This is the main schema and configuration direction for product-aware banking behavior.

**Main consequences**

- `accounts` gain `account_product_id`
- product definitions become the home for fee, interest, overdraft, and statement defaults
- `account_type` may become transitional rather than primary

**Source documents**

- `docs/00_initial_core_references/product_configuration_roadmap.md`
- `docs/progress/tables_status.md`
- `docs/00_initial_core_references/canonical_table_model.md`

---

## ADR-008 — Resolve customer balance GL effects through account products

**Recommended status:** `Proposed`

**Decision**

Customer account effects should hit the general ledger through product control accounts rather than remaining subledger-only or relying solely on fixed GL template legs.

**Why this matters**

This is the key accounting-model decision behind product-aware liability and asset reporting.

**Main consequences**

- deposit products map to liability GLs
- loan products map to asset GLs
- internal transfers, adjustments, and interest posting become fully represented in bank accounting

**Source documents**

- `docs/00_initial_core_references/product_configuration_roadmap.md`
- `docs/00_initial_core_references/transaction_posting_spec.md`
- `docs/00_initial_core_references/gl_account_seed_plan.md`

---

# 3. Priority 2 ADR Candidates

## ADR-009 — Use posting templates as the primary transaction-to-accounting mapping model

**Recommended status:** `Accepted`

**Decision**

For the current MVP, transaction accounting behavior is driven by:

- `transaction_codes`
- `posting_templates`
- `posting_template_legs`

rather than a dedicated `gl_mappings` registry.

**Main consequences**

- accounting behavior remains generic and template-driven
- the system avoids an extra mapping table in the MVP
- future expansion may still introduce richer mapping or override structures

**Source documents**

- `docs/00_initial_core_references/posting_templates.md`
- `docs/progress/tables_status.md`
- `docs/00_initial_core_references/transaction_posting_spec.md`

---

## ADR-010 — Treat account balances as derived projections rather than source of truth

**Recommended status:** `Accepted`

**Decision**

`account_balances` is a projection/cache. Authoritative balances derive from posting and account transaction history.

**Main consequences**

- balance rebuilds remain possible
- balance corruption risk is reduced
- reporting and operational logic should avoid treating balance rows as independent truth

**Source documents**

- `docs/00_initial_core_references/ledger_boundaries.md`
- `docs/progress/posting_compliance_matrix.md`

---

## ADR-011 — Defer full operational transaction detail model until after posting-kernel maturity

**Recommended status:** `Accepted` or `Proposed` depending on desired tone

**Decision**

The MVP intentionally starts with a thinner operational layer and defers richer structures such as:

- `transaction_lines`
- `transaction_references`
- `transaction_exceptions`

until after the posting kernel is stable.

**Main consequences**

- MVP delivery is faster
- operator traceability is thinner in the short term
- later phases must add richer operational context for transfers, external references, and exception workflows

**Source documents**

- `docs/progress/tables_status.md`
- `docs/00_initial_core_references/transaction_catalog_spec.md`
- `docs/00_initial_core_references/layer_responsibility_map.md`

---

## ADR-012 — Phase product configuration from GL mapping to fee and interest rules

**Recommended status:** `Proposed`

**Decision**

Product evolution should happen in phases:

1. product GL mapping
2. core product fields
3. product-aware interest
4. fee rules
5. interest rules

**Main consequences**

- schema and behavior changes remain incremental
- the most important accounting gap is closed first
- rule engines are deferred until product identity and GL behavior are stable

**Source documents**

- `docs/00_initial_core_references/product_configuration_roadmap.md`

---

# 4. Suggested Writing Order

If starting the ADR library now, the most useful first batch is:

1. `Adopt posting-first financial architecture`
2. `Separate operational, posting, subledger, and general-ledger layers`
3. `Use posting batches and posting legs as authoritative financial records`
4. `Correct posted financial events through reversals instead of mutation`
5. `Use a controlled system-defined transaction catalog`
6. `Use account products as the primary configuration unit`
7. `Resolve customer balance GL effects through account products`
8. `Use posting templates as the primary transaction-to-accounting mapping model`

---

# 5. Suggested ADR Library Structure

If you create a formal ADR library, a simple structure would work well:

```text
docs/architecture/adr/
  0001-posting-first-architecture.md
  0002-financial-layer-separation.md
  0003-authoritative-posting-records.md
  0004-reversal-over-mutation.md
  ...
```

Possible supporting files:

- `docs/architecture/adr/README.md` for status meanings and naming rules
- `docs/architecture/adr/template.md` for a standard ADR template

---

# 6. Practical Conclusion

BankCORE already has several major architectural decisions encoded in reference docs and implementation direction.

The highest-value ADRs are the ones that lock in:

- financial truth model
- layer boundaries
- reversal posture
- transaction catalog control
- product-centered configuration
- product-driven GL behavior

Those decisions are broad enough, sticky enough, and consequential enough to deserve formal ADRs rather than living only in reference docs and conversational context.
