# frozen_string_literal: true

require "test_helper"

class InterestAccrualsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_url, params: { username: "testuser", password: "secret" }
    ensure_int_accrual_template!
    deposit_account = DepositAccount.find_or_initialize_by(account_id: accounts(:two).id)
    deposit_account.deposit_type ||= accounts(:two).account_product.default_deposit_type
    deposit_account.interest_bearing = true
    deposit_account.save!

    balance = AccountBalance.find_or_initialize_by(account_id: accounts(:two).id)
    balance.posted_balance_cents = 10_000
    balance.available_balance_cents = 10_000
    balance.average_balance_cents = 10_000
    balance.as_of_at = Time.current
    balance.save!
  end

  test "index renders workbench" do
    get interest_accruals_url

    assert_response :success
    assert_select "h2", text: /Accrual Workbench/
  end

  test "run posts accruals through runner" do
    assert_difference "InterestAccrual.count", 1 do
      post run_interest_accruals_url
    end

    assert_response :success
    assert_select "div", text: /Latest Run Summary/
  end

  private

  def ensure_int_accrual_template!
    return if PostingTemplate.joins(:transaction_code).exists?(transaction_codes: { code: "INT_ACCRUAL" })

    transaction_code = TransactionCode.find_or_create_by!(code: "INT_ACCRUAL") do |record|
      record.description = "Interest accrual"
      record.reversal_code = "INT_ACCRUAL_REVERSAL"
      record.active = true
    end
    posting_template = PostingTemplate.create!(
      transaction_code: transaction_code,
      name: "Interest Accrual",
      description: "GL-only accrual",
      active: true
    )
    PostingTemplateLeg.create!(
      posting_template: posting_template,
      leg_type: Bankcore::Enums::LEG_TYPE_DEBIT,
      account_source: Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL,
      gl_account: gl_accounts(:four),
      description: "Debit interest expense",
      position: 0
    )
    PostingTemplateLeg.create!(
      posting_template: posting_template,
      leg_type: Bankcore::Enums::LEG_TYPE_CREDIT,
      account_source: Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL,
      gl_account: gl_accounts(:five),
      description: "Credit accrued interest payable",
      position: 1
    )
  end
end
