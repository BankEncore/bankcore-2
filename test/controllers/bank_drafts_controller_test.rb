# frozen_string_literal: true

require "test_helper"

class BankDraftsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_url, params: { username: "testuser", password: "secret" }
    ensure_draft_issue_template!
    @branch = branches(:one)
    @party = parties(:one)
    @account = accounts(:one)
    AccountOwner.find_or_create_by!(account_id: @account.id, party_id: @party.id) do |ao|
      ao.role_type = "primary"
      ao.is_primary = true
      ao.effective_on = Date.current
    end
  end

  test "index" do
    get bank_drafts_path
    assert_response :success
    assert_select "h1", text: /Bank Drafts/
  end

  test "new" do
    get new_bank_draft_path
    assert_response :success
    assert_select "h1", text: /Issue Bank Draft/
    assert_select "select#instrument_type"
    assert_select "select#remitter_party_id"
    assert_select "select#account_id"
    assert_select "input#payee_name"
  end

  test "create issues draft" do
    BankDraft.destroy_all
    BankDraftSequence.where(branch_id: @branch.id).update_all(last_number: 0)

    assert_difference "BankDraft.count", 1 do
      post bank_drafts_path, params: {
        instrument_type: "cashiers_check",
        remitter_party_id: @party.id,
        account_id: @account.id,
        amount: "50.00",
        payee_name: "Test Payee Co",
        branch_id: @branch.id
      }
    end
    assert_redirected_to bank_draft_path(BankDraft.last)
    draft = BankDraft.last
    assert_equal "issued", draft.status
    assert_equal 5000, draft.amount_cents
    assert_equal "Test Payee Co", draft.payee_name
  end

  test "show" do
    draft = BankDraft.create!(
      instrument_type: "cashiers_check",
      instrument_number: "9999",
      amount_cents: 1000,
      currency_code: "USD",
      payee_name: "Show Test",
      issue_date: Date.current,
      status: "issued",
      remitter_party: @party,
      branch: @branch,
      account: @account
    )
    get bank_draft_path(draft)
    assert_response :success
    assert_select "h1", text: /9999/
    assert_match "Show Test", response.body
  end

  test "clear marks issued draft as cleared" do
    BankDraft.destroy_all
    BankDraftSequence.where(branch_id: @branch.id).update_all(last_number: 0)
    post bank_drafts_path, params: {
      instrument_type: "cashiers_check",
      remitter_party_id: @party.id,
      account_id: @account.id,
      amount: "50.00",
      payee_name: "Clear Test Payee",
      branch_id: @branch.id
    }
    draft = BankDraft.last
    assert_equal "issued", draft.status

    post clear_bank_draft_path(draft), params: { clearing_reference: "BATCH-999" }
    assert_redirected_to bank_draft_path(draft)
    draft.reload
    assert_equal "cleared", draft.status
    assert_equal "BATCH-999", draft.clearing_reference
    assert draft.cleared_at.present?
  end

  test "void voids issued draft" do
    BankDraft.destroy_all
    BankDraftSequence.where(branch_id: @branch.id).update_all(last_number: 0)
    post bank_drafts_path, params: {
      instrument_type: "cashiers_check",
      remitter_party_id: @party.id,
      account_id: @account.id,
      amount: "50.00",
      payee_name: "Void Test Payee",
      branch_id: @branch.id
    }
    draft = BankDraft.last
    assert_equal "issued", draft.status

    assert_no_difference "BankDraft.count" do
      post void_bank_draft_path(draft), params: { void_reason: "Customer cancelled" }
    end
    assert_redirected_to bank_draft_path(draft)
    draft.reload
    assert_equal "voided", draft.status
    assert_equal "Customer cancelled", draft.void_reason
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
      r.description = "Bank draft"
      r.reversal_code = "DRAFT_ISSUE_REVERSAL"
      r.active = true
    end
    tpl = PostingTemplate.create!(transaction_code: draft_code, name: "Draft Issue", description: "Debit, credit 2160", active: true)
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
end
