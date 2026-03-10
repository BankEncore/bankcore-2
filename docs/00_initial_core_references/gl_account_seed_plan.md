# GL Account Seed Plan

**Status:** DROP-IN SAFE  
**Scope:** BankCORE / BankEncore architecture and implementation reference  
**Purpose:** Define the initial chart-of-accounts seed plan for the ledger-first / back-office-first MVP, using the provided model bank COA as a reference but narrowing and adapting it to the current project scope.

---

# 1. Overview

This document defines the recommended starting GL account structure for BankCORE.

It uses the uploaded model bank chart of accounts as a reference point, but intentionally modifies and narrows it for the current project direction:

- ledger-first MVP
- back-office transaction entry before teller drawer controls
- early priority on fees and interest
- manual settlement entry
- strong support for reversals and suspense handling
- deposit-side accounting first, loan depth later

The goal is **not** to seed a full community-bank production COA on day one.

The goal is to seed the smallest serious GL set that allows the posting engine to safely support:

- manual adjustments
- internal transfers
- fee posting
- interest accrual
- interest posting
- ACH/manual clearing entry
- reversals
- business-date close support

---

# 2. Design Principles

## 2.1 Seed only what the MVP can actually post to
Do not seed large volumes of unused accounts simply because they appear in a model bank COA.

## 2.2 Prefer stable parent/child structure early
The chart should already reflect eventual banking categories, even if many detailed child accounts remain inactive or unseeded initially.

## 2.3 Keep suspense and clearing explicit
During an MVP, correction and suspense paths matter more than perfect product depth.

## 2.4 Separate accrual liability from customer balance liability
Interest accrual and interest posting are distinct accounting events and should use distinct GL accounts.

## 2.5 Prepare for later teller expansion without forcing teller cash accounts now
Cash/vault/drawer accounts can exist structurally later, but teller-drawer-specific control accounts do not need to drive the first MVP.

---

# 3. Recommended MVP GL Categories

The MVP should seed accounts in these categories:

## Assets
- bank cash / due-from-bank
- suspense / adjustment receivable if needed

## Liabilities
- customer deposit liabilities
- accrued interest payable
- ACH or settlement clearing
- suspense / unidentified deposits
- internal transfer clearing if needed

## Income
- fee income
- optional miscellaneous income

## Expense
- interest expense
- optional adjustment expense

## Equity
- retained earnings / current-year profit and loss placeholders

This is enough to make the back-office accounting core financially real.

---

# 4. Recommended MVP Seed Set

## 4.1 Assets

### 1100 — Cash and Due from Banks
**Type:** Asset  
**Seed in MVP:** Yes  
**Why:** Base asset-side cash position for balancing manual entries and later liquidity expansion.

### 1120 — Due from Federal Reserve / Primary Settlement Bank
**Type:** Asset  
**Seed in MVP:** Yes  
**Why:** Practical asset account for settlement-side balancing when external-origin entries are introduced.

### 1180 — Suspense / Unposted Cash or Adjustment Receivable
**Type:** Asset  
**Seed in MVP:** Yes  
**Why:** Needed for corrections, unresolved adjustments, and controlled temporary balancing.

### 1140 — Cash Items in Process of Collection
**Type:** Asset  
**Seed in MVP:** Optional / later  
**Why:** Useful once check-clearing depth increases, but not required for the first ledger-first MVP.

### 1400+ Loan principal and interest receivable accounts
**Type:** Asset  
**Seed in MVP:** Defer unless loans are active in MVP  
**Why:** Keep loan domain structurally separate until loan servicing is actually in play.

---

## 4.2 Liabilities

### 2100 — Deposits (Parent)
**Type:** Liability  
**Seed in MVP:** Yes  
**Why:** Logical parent grouping for deposit products.

### 2110 — Noninterest-Bearing Demand Deposits (DDA)
**Type:** Liability  
**Seed in MVP:** Yes  
**Why:** Core customer deposit liability for noninterest checking accounts.

### 2120 — Interest-Bearing Demand Deposits (NOW)
**Type:** Liability  
**Seed in MVP:** Yes  
**Why:** Needed if MVP supports posting interest to demand products.

### 2130 — Savings / Money Market Accounts
**Type:** Liability  
**Seed in MVP:** Yes  
**Why:** Strong fit for interest-accrual MVP use cases.

### 2140 — Time Deposits (CDs)
**Type:** Liability  
**Seed in MVP:** Optional / later  
**Why:** Seed only if CDs are actually in MVP product scope.

### 2150 — Check Clearing
**Type:** Liability  
**Seed in MVP:** Yes  
**Why:** Essential for check posting (CHK_POST); aligns with 2170 ACH pattern for clearing liability treatment.

### 2170 — ACH Settlement Clearing
**Type:** Liability  
**Seed in MVP:** Yes  
**Why:** Essential once manual ACH entry is supported.

### 2190 — Suspense / Unidentified Deposits
**Type:** Liability  
**Seed in MVP:** Yes  
**Why:** Needed for unresolved inbound funds and exception-friendly accounting.

### 2510 — Accrued Interest Payable – Deposits
**Type:** Liability  
**Seed in MVP:** Yes  
**Why:** Critical for separating accrual from customer account credit.

### 2590 — Clearing – Internal Transfers
**Type:** Liability  
**Seed in MVP:** Optional  
**Why:** Useful if internal transfer workflow or multi-step reclass flows need a clearing intermediary; otherwise direct account-to-account liability movement may be enough for MVP.

### 2160 — Official Checks Outstanding
**Type:** Liability  
**Seed in MVP:** Later  
**Why:** Not needed unless official check issuance enters scope.

### 2180 — RTP / Card Clearing
**Type:** Liability  
**Seed in MVP:** Later  
**Why:** Defer until card/network settlement activity is truly active.

---

## 4.3 Income

### 4500 — Non-Interest Income (Parent)
**Type:** Income  
**Seed in MVP:** Yes  
**Why:** Parent grouping for fee-related lines.

### 4510 — Deposit Service Charges
**Type:** Income  
**Seed in MVP:** Yes  
**Why:** Primary fee-income account for maintenance and service fees.

### 4540 — NSF / Overdraft Fees
**Type:** Income  
**Seed in MVP:** Optional but recommended  
**Why:** Useful if returned-item or NSF fee logic is expected early.

### 4560 — Miscellaneous Income
**Type:** Income  
**Seed in MVP:** Yes  
**Why:** Catch-all for manual fee or other service-income activity not yet split more finely.

### 4520 / 4530 / 4550
**Type:** Income  
**Seed in MVP:** Later  
**Why:** ATM interchange, wire fees, safe deposit fees should wait until those services actually exist.

---

## 4.4 Expense

### 5100 — Interest Expense – Deposits (Parent)
**Type:** Expense  
**Seed in MVP:** Yes  
**Why:** Parent grouping for deposit interest cost.

### 5120 — Interest Expense – NOW Accounts
**Type:** Expense  
**Seed in MVP:** Yes if NOW accounts are in scope  
**Why:** Supports product-aware accrual accounting.

### 5130 — Interest Expense – Savings / MMDA
**Type:** Expense  
**Seed in MVP:** Yes  
**Why:** Most likely primary deposit-interest expense line in the ledger-first MVP.

### 5140 — Interest Expense – Time Deposits
**Type:** Expense  
**Seed in MVP:** Later unless CDs are active  
**Why:** Only needed if CDs are in actual MVP product scope.

### 5190 — Adjustment / Correction Expense
**Type:** Expense  
**Seed in MVP:** Yes (project-specific addition)  
**Why:** The reference COA implies suspense/correction handling, but a dedicated correction expense line is useful for manual back-office adjustments in this project.

### 5200 and broader operating expense lines
**Type:** Expense  
**Seed in MVP:** Later  
**Why:** Borrowing expense, salaries, occupancy, technology, and FDIC assessment lines are important institutionally but not needed to validate the first financial kernel.

---

## 4.5 Equity

### 3200 — Retained Earnings
**Type:** Equity  
**Seed in MVP:** Yes  
**Why:** Standard close structure anchor.

### 3300 — Current-Year Profit / Loss
**Type:** Equity  
**Seed in MVP:** Yes  
**Why:** Useful for simple period-close and P&L rollover structure even in MVP.

### 3100 / 3120 Capital accounts
**Type:** Equity  
**Seed in MVP:** Optional / later  
**Why:** Valid institutionally but not necessary to prove ledger-first MVP accounting flows.

---

# 5. Recommended MVP Seed List (Condensed)

This is the practical seed set I would start with.

## Assets
- 1100 Cash and Due from Banks
- 1120 Due from Federal Reserve / Settlement Bank
- 1180 Suspense / Adjustment Receivable

## Liabilities
- 2100 Deposits (parent)
- 2110 Noninterest-Bearing DDA
- 2120 Interest-Bearing Demand Deposits (NOW)
- 2130 Savings / MMDA
- 2170 ACH Settlement Clearing
- 2190 Suspense / Unidentified Deposits
- 2510 Accrued Interest Payable – Deposits

## Income
- 4500 Non-Interest Income (parent)
- 4510 Deposit Service Charges
- 4540 NSF / Overdraft Fees
- 4560 Miscellaneous Income

## Expense
- 5100 Interest Expense – Deposits (parent)
- 5120 Interest Expense – NOW Accounts
- 5130 Interest Expense – Savings / MMDA
- 5190 Adjustment / Correction Expense

## Equity
- 3200 Retained Earnings
- 3300 Current-Year Profit / Loss

That gives the MVP a serious but compact accounting spine.

---

# 6. Project-Specific Modifications to the Reference COA

The reference COA is broader than the current project needs. For BankCORE’s revised MVP, I recommend these modifications.

## 6.1 Promote correction/suspense explicitly
The reference COA includes suspense and clearing accounts, but the MVP should emphasize them more because manual back-office posting and reversal safety are early priorities.

Recommended emphasis:
- 1180 Suspense / Adjustment Receivable
- 2190 Suspense / Unidentified Deposits
- 5190 Adjustment / Correction Expense

## 6.2 Keep deposit liability product buckets simple
Rather than seed a large product catalog, begin with:
- 2110 DDA
- 2120 NOW
- 2130 Savings/MMDA
- optional 2140 CDs later

## 6.3 Defer lending detail unless the MVP truly posts loans
The reference COA includes a healthy lending structure. That is appropriate long-term, but if the active MVP is deposit/fees/interest/manual ops, most loan principal and receivable lines should remain unseeded until needed.

## 6.4 Defer branch/drawer cash detail until teller phase
The reference COA includes cash-in-vault / drawer ideas. For this project, detailed branch/drawer subledgers should wait for teller phase. Early MVP can remain more centralized on bank cash / due-from-bank.

---

# 7. Suggested GL Usage by First Transaction Types

## 7.1 Manual adjustment — account credit
Typical posting:
- Debit 5190 Adjustment / Correction Expense **or** 1180 Suspense / Adjustment Receivable
- Credit customer deposit liability account (2110/2120/2130)

## 7.2 Manual adjustment — account debit
Typical posting:
- Debit customer deposit liability account (2110/2120/2130)
- Credit 1180 Suspense / Adjustment Receivable **or** 4560 Miscellaneous Income depending on business intent

## 7.3 Internal transfer
Typical posting:
- Debit source deposit liability account
- Credit destination deposit liability account

In most simple same-bank deposit transfers, no separate income/expense line is needed.

## 7.4 Fee posting
Typical posting:
- Debit customer deposit liability account
- Credit 4510 Deposit Service Charges or 4540 NSF / Overdraft Fees or 4560 Miscellaneous Income

## 7.5 Interest accrual
Typical posting:
- Debit 5120 or 5130 Interest Expense – Deposits
- Credit 2510 Accrued Interest Payable – Deposits

## 7.6 Interest posting to account
Typical posting:
- Debit 2510 Accrued Interest Payable – Deposits
- Credit customer deposit liability account (typically 2120 or 2130)

## 7.7 Manual ACH credit to customer
Typical posting:
- Debit 1120 Due from Settlement Bank **or** offset settlement position as appropriate
- Credit customer deposit liability account

## 7.8 Manual ACH debit from customer
Typical posting:
- Debit customer deposit liability account
- Credit 2170 ACH Settlement Clearing

---

# 8. Parent vs Posting Accounts

The model COA includes parent/grouping lines. For BankCORE MVP, treat them carefully.

## Recommended approach
Some accounts should be **grouping/organizational only** and not direct posting destinations unless deliberately allowed.

Likely grouping-only or mostly-grouping accounts:
- 2100 Deposits
- 4500 Non-Interest Income
- 5100 Interest Expense – Deposits

Likely direct posting accounts:
- 2110
n- 2120
- 2130
- 2170
- 2190
- 2510
- 4510
- 4540
- 4560
- 5120
- 5130
- 5190
- 1180
- 1120

## Project rule recommendation
Add a field such as `allow_direct_posting` on `gl_accounts` so the system distinguishes grouping accounts from true posting targets.

---

# 9. Suggested `gl_accounts` Seed Attributes

For each seeded account, I recommend at least:

- `gl_number`
- `name`
- `category` (`asset`, `liability`, `income`, `expense`, `equity`)
- `normal_balance` (`debit`, `credit`)
- `status` (`active`, `inactive`)
- `allow_direct_posting` (boolean)
- `parent_gl_account_id` (nullable)
- `description`

This will make later chart expansion much easier.

---

# 10. Recommended Normal Balances

## Debit-normal
- assets
- expenses

## Credit-normal
- liabilities
- income
- equity

Applied to current MVP seeds:

### Debit-normal
- 1100
- 1120
- 1180
- 5120
- 5130
- 5190

### Credit-normal
- 2110
- 2120
- 2130
- 2170
- 2190
- 2510
- 4510
- 4540
- 4560
- 3200
- 3300

---

# 11. Recommended Seeding Order

Seed in this order so dependencies are clear.

## Step 1 — Parents / grouping accounts
- 2100 Deposits
- 4500 Non-Interest Income
- 5100 Interest Expense – Deposits

## Step 2 — Direct posting liability accounts
- 2110 DDA
- 2120 NOW
- 2130 Savings/MMDA
- 2170 ACH Settlement Clearing
- 2190 Suspense / Unidentified Deposits
- 2510 Accrued Interest Payable – Deposits

## Step 3 — Direct posting asset accounts
- 1100 Cash and Due from Banks
- 1120 Due from Settlement Bank
- 1180 Suspense / Adjustment Receivable

## Step 4 — Direct posting income and expense accounts
- 4510 Deposit Service Charges
- 4540 NSF / Overdraft Fees
- 4560 Miscellaneous Income
- 5120 Interest Expense – NOW
- 5130 Interest Expense – Savings/MMDA
- 5190 Adjustment / Correction Expense

## Step 5 — Equity anchors
- 3200 Retained Earnings
- 3300 Current-Year Profit / Loss

---

# 12. What to Seed Later

These are valid accounts from the reference COA, but they should wait until the project truly needs them.

## Later lending accounts
- 1410+ loan principal
- 14x5 interest receivable
- 1490 deferred fees/costs
- 1499 ACL

## Later branch/teller cash accounts
- 1110 Cash in Vaults / Drawers
- 1140 CIPC if check-clearing depth expands
- detailed vault/drawer/location subledgers

## Later liability detail
- 2140 CDs
- 2160 Official Checks Outstanding
- 2180 RTP/Card Clearing
- 2550 Deferred Income
- 2700+ borrowings

## Later income/expense detail
- interchange, wire fees, safe deposit fees
- borrowings expense
- general operating expense lines
- provision for credit losses

This keeps the first seed set aligned with real usage rather than theoretical completeness.

---

# 13. Practical Recommendation for This Project

For BankCORE’s current direction, the seed plan should be treated as:

## Tier 1 — Must seed now
The compact set required to support the revised MVP.

## Tier 2 — Ready but inactive
Accounts present structurally for near-term expansion, but not necessarily used by first posting rules.

## Tier 3 — Deferred
Longer-term bank-operating accounts that should not complicate the first posting engine rollout.

This tiered approach is better than pretending the MVP needs a fully mature community-bank COA immediately.

---

# 14. Final Recommendation

The right first chart for this project is **not** the broadest chart.

It is the chart that cleanly supports:
- deposit liabilities
- fee income
- interest expense and payable
- suspense and adjustments
- ACH clearing
- basic period-close structure

That is enough to make the back-office MVP financially real while keeping the chart small, explainable, and easy to seed.

---

# 15. One-Sentence Summary

> The BankCORE MVP chart of accounts should be a compact, posting-ready deposit-and-operations chart built from the reference COA but narrowed to liabilities, accruals, fees, suspense, ACH clearing, and period-close anchors, with broader lending, teller cash, and operating-expense detail deferred until later phases.

