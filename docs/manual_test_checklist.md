# Manual Test Checklist

Use this checklist for regular manual verification of BankCORE back-office flows. Complement automated tests with human verification of critical paths.

**Reference:** [financial_change_checklist.md](financial_change_checklist.md), [release_checklist.md](release_checklist.md)

---

## 1. Authentication & Access

- [ ] **Login / logout** — Sign in with valid credentials; logout; redirect behavior correct
- [ ] **Unauthenticated access** — Protected pages redirect to login
- [ ] **Permission boundaries** — User without `post_transactions` cannot reach New Transaction or New Account; user without `reverse_transactions` cannot reverse; user without `approve_overrides` cannot approve/deny overrides

---

## 2. Customer Workspace

- [ ] **Customer Lookup** — Search by party number, display name, or account number; results grouped as Customers and Accounts; links work
- [ ] **Parties index** — List parties; New Party link works
- [ ] **Create party** — New party with required fields; validation errors shown; success redirects
- [ ] **Edit party** — Update display name, status; changes persist
- [ ] **Party show (Customer Workspace)** — Linked accounts, balances, recent activity; "Open New Account", "Open", "Post" links work
- [ ] **Return-to flow** — From account opening, create party with `return_to`; redirect back to account form with new party preselected

---

## 3. Account Management

- [ ] **Accounts index** — List accounts; New Account link works
- [ ] **New account form** — Party picker typeahead works; product defaults (account type, currency, deposit type) correct
- [ ] **Create account** — Account created with product defaults; redirect to account show
- [ ] **Account show** — Balances, holds, owners, recent activity displayed
- [ ] **Add account owner** — Add owner; association persists
- [ ] **Add account hold** — Create hold; release hold works
- [ ] **Check overdraft override** — Post check that overdrafts beyond threshold; override flow appears; approval allows posting

---

## 4. Transaction Posting (Critical Financial Paths)

| Transaction   | Test Scenario                                                                 |
|---------------|-------------------------------------------------------------------------------|
| **ADJ_CREDIT** | Credit account; verify balance increase; posting legs correct                |
| **ADJ_DEBIT**  | Debit account; verify balance decrease                                        |
| **XFER_INTERNAL** | Transfer between accounts; verify both balances; memo default correct      |
| **FEE_POST**   | Select fee type; post fee; verify balance and fee assessment                   |
| **ACH_CREDIT** | Post ACH credit; trace number, effective date, optional ACH metadata         |
| **ACH_DEBIT**  | Post ACH debit; verify balance and ACH metadata                               |
| **CHK_POST**   | Post check with number; verify check item and balance; overdraft override if applicable |

For each: verify preview (if available), posting success, transaction appears on account show and transactions index.

---

## 5. Reversals

- [ ] **Reversal preview** — On reversible transaction, Preview Reversal shows inverse legs
- [ ] **Reversal below threshold** — Reverse small transaction; no override required; reversal batch linked; original unchanged
- [ ] **Reversal above threshold** — Reverse transaction ≥ $100 (default); override required; request override → approve → reverse succeeds
- [ ] **DRAFT_ISSUE void** — Void Draft link (not generic Reverse) for DRAFT_ISSUE; void from bank draft show with reason; draft voided, reversal posted
- [ ] **Already reversed** — Attempt second reverse; appropriate error or no duplicate posting

---

## 6. Bank Draft Lifecycle

- [ ] **Issue draft** — Create cashier's check or money order from account; instrument number assigned; draft appears in list and show
- [ ] **Void draft** — Void issued draft with reason; reversal posted; draft status voided
- [ ] **Clear draft** — Mark issued draft cleared (optional reference); status cleared
- [ ] **Void/Clear visibility** — Void button only for issued drafts with posting batch; Clear only for issued drafts

---

## 7. Override Workflow

- [ ] **Create override request** — For reversal above threshold or check overdraft; request created
- [ ] **Override index** — Pending overrides visible to approvers
- [ ] **Approve override** — Approve; override consumed; subsequent reversal/check posting succeeds
- [ ] **Deny override** — Deny; request rejected; original flow fails until new override
- [ ] **Override context validation** — Override tied to correct transaction/context; wrong context rejected

---

## 8. Business Date

- [ ] **Business date display** — Current business date shown (topbar)
- [ ] **Close business date** — Close current date; status updates; next open date correct

---

## 9. Interest & Fees (Back Office)

- [ ] **Interest accruals** — Run accrual job; accruals appear in list
- [ ] **Interest postings** — Create interest posting; accrued interest paid to accounts
- [ ] **Fee assessments** — Fee assessments list shows expected entries

---

## 10. Financial Review

- [ ] **Trial balance** — Index and show; GL balances sensible
- [ ] **Audit events** — Index shows events; reversals and overrides logged
- [ ] **Transaction show** — Operational details, structured references, posting batch; legs balanced

---

## 11. Configuration & Reference Data

- [ ] **Account products** — CRUD; fee/interest rules
- [ ] **Fee types** — CRUD
- [ ] **GL accounts** — Index loads
- [ ] **Branches** — Index and show

---

## 12. Edge Cases & Validation

- [ ] **Balanced posting** — Posted transactions have balanced debits and credits
- [ ] **Immutability** — Posted records not editable; corrections via reversals only
- [ ] **Idempotency** — Duplicate request (same idempotency key) does not create duplicate postings
- [ ] **Invalid inputs** — Invalid account, negative amount, missing required fields produce clear errors
- [ ] **Safe return_to** — Cancel links with `return_to` only redirect to whitelisted paths (XSS protection)

---

## Suggested Cadence

| Frequency              | Scope                                                 |
|------------------------|-------------------------------------------------------|
| **Pre-release / PR**   | Smoke test (see [manual_test_smoke.md](manual_test_smoke.md)) |
| **Weekly**             | Full pass of sections 1–7, key items in 8–10          |
| **After financial changes** | All of 4, 5, 6, 7, 12                           |
| **After config changes**    | Section 11                                      |
