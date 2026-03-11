# Manual Smoke Test

Quick manual verification for pre-release, PR merge, or after critical changes. Completes in ~10–15 minutes.

**Full checklist:** [manual_test_checklist.md](manual_test_checklist.md)

---

## Prerequisites

- App running (`bin/dev`)
- Test user with `post_transactions` and `reverse_transactions`
- At least one active account and party (or create during test)

---

## 1. Authentication (1 min)

- [ ] Login with valid credentials
- [ ] Logout
- [ ] Re-login (required for subsequent steps)

---

## 2. Core Navigation (1 min)

- [ ] Transactions index loads
- [ ] New Transaction link works
- [ ] Bank Drafts index loads
- [ ] Accounts index loads
- [ ] New Account link works (or skip if no products configured)
- [ ] Customer Lookup loads; run one search

---

## 3. Transaction Post (3–5 min)

- [ ] New Transaction → choose **ADJ_CREDIT** (or ADJ_DEBIT)
- [ ] Select account, amount (e.g. $1.00), memo
- [ ] Post (or Preview then Post)
- [ ] Verify success message; transaction appears in list
- [ ] Open transaction → verify posting batch and legs

---

## 4. Reversal (2–3 min)

- [ ] Open the transaction from step 3
- [ ] Click Preview Reversal (or Void Draft if DRAFT_ISSUE)
- [ ] Confirm reversal
- [ ] Verify reversal posted; original transaction shows reversed
- [ ] If amount ≥ $100: verify override flow or that override was required

---

## 5. Bank Draft (3–5 min)

- [ ] New Bank Draft
- [ ] Select cashier's check, remitter, account, amount, payee
- [ ] Issue draft
- [ ] Verify draft in list; open draft show
- [ ] Void draft with reason (or Mark Cleared if testing clear path)
- [ ] Verify draft status updated; reversal present if voided

---

## 6. Sanity Checks (1–2 min)

- [ ] Trial Balance loads
- [ ] Audit Events shows recent activity
- [ ] Business date displayed in topbar

---

## Pass Criteria

All checked items pass with no unexpected errors. If any step fails, document the failure and run the full [manual_test_checklist.md](manual_test_checklist.md) before release.
