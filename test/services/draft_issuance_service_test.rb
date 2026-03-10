# frozen_string_literal: true

require "test_helper"

class DraftIssuanceServiceTest < ActiveSupport::TestCase
  setup do
    ensure_draft_issue_template!
    BankDraft.destroy_all
    BankDraftSequence.where(branch_id: branches(:one).id).update_all(last_number: 0)
    @branch = branches(:one)
    @party = parties(:one)
    @account = accounts(:one)
    AccountOwner.find_or_create_by!(account_id: @account.id, party_id: @party.id) do |ao|
      ao.role_type = "primary"
      ao.is_primary = true
      ao.effective_on = Date.current
    end
  end

  def ensure_draft_issue_template!
    return if PostingTemplate.joins(:transaction_code).exists?(transaction_codes: { code: "DRAFT_ISSUE" })

    gl_2160 = GlAccount.find_or_create_by!(gl_number: "2160") do |g|
      g.name = "Official Checks Outstanding"
      g.category = "liability"
      g.normal_balance = "credit"
      g.status = Bankcore::Enums::STATUS_ACTIVE
      g.allow_direct_posting = true
    end

    draft_code = TransactionCode.find_or_create_by!(code: "DRAFT_ISSUE") do |r|
      r.description = "Bank draft issuance"
      r.reversal_code = "DRAFT_ISSUE_REVERSAL"
      r.active = true
    end
    tpl = PostingTemplate.create!(
      transaction_code: draft_code,
      name: "Bank Draft Issuance",
      description: "Debit account, credit official checks",
      active: true
    )
    PostingTemplateLeg.create!(posting_template: tpl, leg_type: "debit", account_source: "customer_account", description: "Debit", position: 0)
    PostingTemplateLeg.create!(posting_template: tpl, leg_type: "credit", account_source: "fixed_gl", gl_account: gl_2160, description: "Credit", position: 1)

    rev_code = TransactionCode.find_or_create_by!(code: "DRAFT_ISSUE_REVERSAL") do |r|
      r.description = "Bank draft reversal"
      r.reversal_code = nil
      r.active = true
    end
    rev_tpl = PostingTemplate.create!(transaction_code: rev_code, name: "Draft Reversal", description: "Credit account, debit 2160", active: true)
    PostingTemplateLeg.create!(posting_template: rev_tpl, leg_type: "credit", account_source: "customer_account", description: "Credit", position: 0)
    PostingTemplateLeg.create!(posting_template: rev_tpl, leg_type: "debit", account_source: "fixed_gl", gl_account: gl_2160, description: "Debit", position: 1)
  end

  test "post! creates bank draft and posting" do
    assert_difference [ "BankDraft.count", "BankingTransaction.count" ], 1 do
      batch = DraftIssuanceService.post!(
        instrument_type: "cashiers_check",
        remitter_party_id: @party.id,
        account_id: @account.id,
        amount_cents: 5000,
        payee_name: "Acme Corp",
        branch_id: @branch.id
      )
      assert batch.persisted?
      draft = BankDraft.find_by(posting_batch_id: batch.id)
      assert draft.present?
      assert_equal "issued", draft.status
      assert_equal "5000", draft.amount_cents.to_s
      assert_equal "Acme Corp", draft.payee_name
      assert draft.instrument_number.present?
    end
  end

  test "post! rejects account not owned by remitter" do
    other_party = Party.create!(party_type: "person", party_number: "P999", display_name: "Other", status: "active")
    other_account = Account.create!(
      account_number: "9999",
      account_reference: "DDA-9999",
      account_type: "dda",
      account_product_id: AccountProduct.first.id,
      branch_id: @branch.id,
      currency_code: "USD",
      status: "active",
      opened_on: Date.current
    )
    AccountOwner.create!(account_id: other_account.id, party_id: other_party.id, role_type: "primary", is_primary: true, effective_on: Date.current)
    assert_no_difference "BankDraft.count" do
      assert_raises(DraftIssuanceService::DraftIssuanceError) do
        DraftIssuanceService.post!(
          instrument_type: "cashiers_check",
          remitter_party_id: @party.id,
          account_id: other_account.id,
          amount_cents: 5000,
          payee_name: "Acme",
          branch_id: @branch.id
        )
      end
    end
  end

  test "instrument number increments per branch and type" do
    b1 = DraftIssuanceService.post!(
      instrument_type: "cashiers_check",
      remitter_party_id: @party.id,
      account_id: @account.id,
      amount_cents: 1000,
      payee_name: "A",
      branch_id: @branch.id
    )
    d1 = BankDraft.find_by(posting_batch_id: b1.id)
    b2 = DraftIssuanceService.post!(
      instrument_type: "cashiers_check",
      remitter_party_id: @party.id,
      account_id: @account.id,
      amount_cents: 2000,
      payee_name: "B",
      branch_id: @branch.id
    )
    d2 = BankDraft.find_by(posting_batch_id: b2.id)
    assert_not_equal d1.instrument_number, d2.instrument_number
  end
end
