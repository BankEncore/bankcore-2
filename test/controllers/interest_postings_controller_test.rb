# frozen_string_literal: true

require "test_helper"

class InterestPostingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_url, params: { username: "testuser", password: "secret" }
    travel_to Time.zone.local(2026, 3, 31, 12, 0, 0)

    BusinessDate.update_all(status: Bankcore::Enums::BUSINESS_DATE_CLOSED)
    ensure_business_date_open!(Date.new(2026, 3, 31))
    ensure_int_post_template!

    deposit_account = DepositAccount.find_or_initialize_by(account_id: accounts(:two).id)
    deposit_account.deposit_type ||= accounts(:two).account_product.default_deposit_type
    deposit_account.interest_bearing = true
    deposit_account.save!

    InterestAccrual.create!(
      account: accounts(:two),
      interest_rule: interest_rules(:savings_default),
      accrual_date: Date.new(2026, 3, 30),
      amount_cents: 250,
      status: Bankcore::Enums::STATUS_POSTED
    )
  end

  teardown do
    travel_back
  end

  test "index renders due accounts" do
    get interest_postings_url

    assert_response :success
    assert_select "h2", text: /Due Accounts/
    assert_select "td", text: accounts(:two).account_number
  end

  test "create posts due interest and links accruals" do
    assert_difference "InterestPostingApplication.count", 1 do
      post interest_postings_url
    end

    assert_response :success
    assert_select "div", text: /Latest Run Summary/
  end

  private

  def ensure_business_date_open!(date)
    BusinessDate.find_or_create_by!(business_date: date) do |business_date|
      business_date.status = Bankcore::Enums::BUSINESS_DATE_OPEN
      business_date.opened_at = Time.current
    end
  end

  def ensure_int_post_template!
    return if PostingTemplate.joins(:transaction_code).exists?(transaction_codes: { code: "INT_POST" })

    transaction_code = TransactionCode.find_or_create_by!(code: "INT_POST") do |record|
      record.description = "Interest posting"
      record.reversal_code = "INT_POST_REVERSAL"
      record.active = true
    end
    posting_template = PostingTemplate.create!(
      transaction_code: transaction_code,
      name: "Interest Posting",
      description: "Debit payable, credit account",
      active: true
    )
    PostingTemplateLeg.create!(
      posting_template: posting_template,
      leg_type: Bankcore::Enums::LEG_TYPE_DEBIT,
      account_source: Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL,
      gl_account: gl_accounts(:five),
      description: "Debit accrued interest payable",
      position: 0
    )
    PostingTemplateLeg.create!(
      posting_template: posting_template,
      leg_type: Bankcore::Enums::LEG_TYPE_CREDIT,
      account_source: Bankcore::Enums::ACCOUNT_SOURCE_CUSTOMER,
      description: "Credit customer account",
      position: 1
    )
  end
end
