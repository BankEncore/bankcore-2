# frozen_string_literal: true

require "test_helper"

class DraftClearingServiceTest < ActiveSupport::TestCase
  setup do
    ensure_draft_issue_template!
    BankDraft.destroy_all
    BankDraftSequence.where(branch_id: branches(:one).id).update_all(last_number: 0)
    @branch = branches(:one)
    @party = parties(:one)
    @account = accounts(:one)
    @user = users(:one)
    AccountOwner.find_or_create_by!(account_id: @account.id, party_id: @party.id) do |ao|
      ao.role_type = "primary"
      ao.is_primary = true
      ao.effective_on = Date.current
    end
    @batch = DraftIssuanceService.post!(
      instrument_type: "cashiers_check",
      remitter_party_id: @party.id,
      account_id: @account.id,
      amount_cents: 5000,
      payee_name: "Acme Corp",
      branch_id: @branch.id
    )
    @draft = BankDraft.find_by!(posting_batch_id: @batch.id)
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

  test "clear! transitions issued to cleared" do
    assert_equal BankDraft::STATUS_ISSUED, @draft.status

    result = DraftClearingService.clear!(
      bank_draft: @draft,
      clearing_reference: "CHK-12345",
      cleared_by_id: @user.id
    )

    assert_equal @draft, result
    @draft.reload
    assert_equal BankDraft::STATUS_CLEARED, @draft.status
    assert @draft.cleared_at.present?
    assert_equal "CHK-12345", @draft.clearing_reference
    assert_equal @user.id, @draft.cleared_by_id
  end

  test "clear! allows optional clearing_reference" do
    DraftClearingService.clear!(
      bank_draft: @draft,
      cleared_by_id: @user.id
    )
    @draft.reload
    assert_equal BankDraft::STATUS_CLEARED, @draft.status
    assert_nil @draft.clearing_reference
  end

  test "clear! rejects draft not in issued status" do
    @draft.update!(status: BankDraft::STATUS_VOIDED)
    assert_raises(DraftClearingService::DraftClearingError, match: /not issued/) do
      DraftClearingService.clear!(bank_draft: @draft, cleared_by_id: @user.id)
    end
  end

  test "clear! rejects already cleared draft" do
    @draft.update!(status: BankDraft::STATUS_CLEARED)
    assert_raises(DraftClearingService::DraftClearingError, match: /not issued/) do
      DraftClearingService.clear!(bank_draft: @draft, cleared_by_id: @user.id)
    end
  end
end
