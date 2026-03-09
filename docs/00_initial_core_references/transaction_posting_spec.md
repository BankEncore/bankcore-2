# Transaction Posting Specification

**Status:** DROP-IN SAFE  
**Scope:** BankCORE / BankEncore posting and accounting behavior for the operational transaction catalog  
**Purpose:** Define how each supported transaction type is translated into posting batches, posting legs, account subledger effects, and general ledger effects.

---

# 1. Overview

This document defines the **posting-side specification** for the BankCORE transaction catalog.

It answers questions such as:

- what debit and credit shape does each transaction type produce?
- which legs affect customer accounts vs GL accounts?
- where do GL targets come from?
- how should product-linked GL resolution behave?
- how should reversals mirror the original posting?

This document is intentionally distinct from the operational transaction specification.

- `transaction_catalog_spec.md` describes **what happened operationally**
- this document describes **how it posts financially**

Related documents:

- [transaction_catalog_spec.md](transaction_catalog_spec.md)
- [posting_templates.md](posting_templates.md)
- [gl_account_seed_plan.md](gl_account_seed_plan.md)
- [ledger_boundaries.md](ledger_boundaries.md)
- [layer_responsibility_map.md](layer_responsibility_map.md)

---

# 2. Posting Model

The posting flow should be understood as:

```text
transaction_code
    -> posting_template
        -> posting_template_legs
            -> posting_batch
                -> posting_legs
                    -> account_transactions
                    -> journal_entry_lines
```

The posting engine is responsible for:

- balanced debit/credit translation
- atomic commit
- idempotency for unsafe write paths
- production of both subledger and general ledger effects

---

# 3. Leg Source Model

The current template model supports these account sources:

| Source | Meaning |
|---|---|
| `customer_account` | Primary account on the transaction |
| `source_account` | Source account in a transfer |
| `destination_account` | Destination account in a transfer |
| `fixed_gl` | Static GL account referenced directly in the template |
| `product_gl` | GL account resolved from the account product |

## 3.1 Current vs target behavior

Current implementation is strongest on `fixed_gl`, `customer_account`, `source_account`, and `destination_account`.

Target behavior should expand `product_gl` so that:

- customer-account legs also resolve to the correct product control account in the general ledger
- product-aware fee and interest paths can select the correct income, liability, asset, or expense GL

---

# 4. GL Resolution Strategies

Every posting leg that affects accounting should resolve through one of the following strategies.

| Strategy | Use Case |
|---|---|
| Fixed GL | Suspense, settlement, accrued interest payable, correction expense |
| Product GL | Deposit liability, loan asset, product-specific fee or interest GL |
| Fee-Type GL | Fee income selected from fee definition or fee rule |
| Rule-Driven GL | Future product/rule-based accounting variations |

## 4.1 Immediate target state

For the near term, BankCORE should support:

- fixed GL on explicit GL legs
- product GL for customer-account effects

That allows:

- internal transfers to affect the correct liability buckets
- account adjustments to hit product-specific deposit liability GLs
- interest posting to credit the correct product liability

---

# 5. Posting Matrix

## 5.1 Compact Matrix

| Code | Debit Legs | Credit Legs | Account vs GL Scope | GL Resolution Strategy | Current State | Target State |
|---|---|---|---|---|---|---|
| `ADJ_CREDIT` | correction/suspense GL | customer account | one GL leg, one account leg | fixed GL + product GL | fixed GL + account leg | account leg also projects to product liability GL |
| `ADJ_DEBIT` | customer account | suspense or misc income GL | one account leg, one GL leg | product GL + fixed GL | account leg + fixed GL | account leg also projects to product liability GL |
| `XFER_INTERNAL` | source account | destination account | two account legs | product GL on both sides | subledger only | debit source product GL, credit destination product GL |
| `FEE_POST` | customer account | fee income GL | one account leg, one GL leg | product GL + fee-type or product fee GL | fixed fee income GL | account leg projects to product liability GL; fee side may remain fee-type GL |
| `FEE_REVERSAL` | fee income GL | customer account | one GL leg, one account leg | fee-type GL + product GL | fixed fee income GL | customer side projects to product liability GL |
| `INT_ACCRUAL` | interest expense GL | accrued interest payable GL | two GL legs | fixed or product/rule-driven expense GL | fixed GLs | product-aware interest expense GL where applicable |
| `INT_ACCRUAL_REVERSAL` | accrued interest payable GL | interest expense GL | two GL legs | same as original | fixed GLs | same as original |
| `INT_POST` | accrued interest payable GL | customer account | one GL leg, one account leg | fixed payable GL + product GL | fixed payable GL + account leg | account leg projects to correct product liability GL |
| `INT_POST_REVERSAL` | customer account | accrued interest payable GL | one account leg, one GL leg | product GL + fixed payable GL | account leg + fixed GL | customer side projects to correct product liability GL |
| `ACH_CREDIT` | settlement/due-from-bank GL | customer account | one GL leg, one account leg | fixed settlement GL + product GL | fixed GL + account leg | customer side projects to product liability GL |
| `ACH_DEBIT` | customer account | ACH clearing GL | one account leg, one GL leg | product GL + fixed clearing GL | account leg + fixed GL | customer side projects to product liability GL |

---

# 6. Transaction-by-Transaction Notes

## 6.1 `ADJ_CREDIT`

**Operational meaning**

Manual increase to customer account balance.

**Posting shape**

- Debit correction offset GL such as `5190` or `1180`
- Credit customer account liability

**Important note**

Once product GL mapping is active, the customer-account effect must also appear in the correct product liability GL rather than only in subledger history.

---

## 6.2 `ADJ_DEBIT`

**Operational meaning**

Manual decrease to customer account balance.

**Posting shape**

- Debit customer account liability
- Credit suspense or income offset GL

**Important note**

This should remain policy-gated where appropriate because it reduces customer balance.

---

## 6.3 `XFER_INTERNAL`

**Operational meaning**

Move value between two internal accounts.

**Posting shape**

- Debit source account liability
- Credit destination account liability

**Important note**

In subledger terms this is sufficient, but in bank accounting terms the transaction is incomplete until both sides resolve to product liability GLs.

This is the clearest example of why product GL mapping matters.

---

## 6.4 `FEE_POST`

**Operational meaning**

Assess a fee against a customer account.

**Posting shape**

- Debit customer account liability
- Credit fee income GL

**Important note**

The income side may remain selected by fee definition, but the account side should resolve to the product liability GL.

---

## 6.5 `INT_ACCRUAL`

**Operational meaning**

Recognize interest expense earned but not yet posted to the customer balance.

**Posting shape**

- Debit interest expense GL
- Credit accrued interest payable GL

**Important note**

This is GL-only and should remain balanced entirely in the general ledger.

Future product awareness mainly affects which interest expense GL is selected.

---

## 6.6 `INT_POST`

**Operational meaning**

Release accrued interest into the customer account.

**Posting shape**

- Debit accrued interest payable GL
- Credit customer account liability

**Important note**

The payable side is fixed or rule-driven; the customer side should resolve to product liability GL.

---

## 6.7 `ACH_CREDIT` and `ACH_DEBIT`

**Operational meaning**

Represent external settlement movement between customer balances and clearing/settlement positions.

**Posting shape**

- `ACH_CREDIT`: debit settlement asset, credit customer account liability
- `ACH_DEBIT`: debit customer account liability, credit clearing liability

**Important note**

External settlement GLs are fixed, but the customer-side liability should still resolve by product.

---

# 7. Reversal Pattern

Reversals should follow these rules:

- do not mutate original posted rows
- create a new inverse posting batch linked to the original
- mirror original leg targets and amounts
- preserve original GL resolution logic

For product-aware posting, reversal should resolve the same product-linked GL path as the original transaction.

---

# 8. Product Dependency Notes

The transaction catalog can be defined before product configuration is complete, but the following posting behaviors depend on product design:

- customer liability GL resolution
- loan asset GL resolution
- product-specific interest expense GLs
- product-specific fee income overrides

This makes `product_configuration_roadmap.md` a dependency for complete general-ledger fidelity.

---

# 9. Practical Conclusion

The transaction catalog and the posting catalog should remain separate on purpose.

- the **transaction catalog** explains what business event occurred
- the **posting specification** explains how it affects money

That separation keeps:

- operational semantics clean
- accounting rules testable
- product-linked GL behavior extensible
- reversal behavior explicit and auditable
