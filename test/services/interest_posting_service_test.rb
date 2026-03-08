# frozen_string_literal: true

require "test_helper"

class InterestPostingServiceTest < ActiveSupport::TestCase
  def setup
    @account = accounts(:one)
    @business_date = business_dates(:one).business_date
    ensure_int_post_template!
  end

  test "posts interest to account" do
    batch = InterestPostingService.post!(
      account_id: @account.id,
      amount_cents: 500,
      business_date: @business_date
    )

    assert batch.persisted?
    assert_equal "posted", batch.status
    @account.reload
    balance = @account.account_balances.first
    assert balance
    assert_equal 500, balance.posted_balance_cents
  end

  test "raises when amount is zero or negative" do
    assert_raises(ArgumentError) do
      InterestPostingService.post!(
        account_id: @account.id,
        amount_cents: 0,
        business_date: @business_date
      )
    end
  end

  private

  def ensure_int_post_template!
    return if PostingTemplate.joins(:transaction_code).exists?(transaction_codes: { code: "INT_POST" })

    tc = TransactionCode.find_or_create_by!(code: "INT_POST") do |t|
      t.description = "Interest posting"
      t.reversal_code = "INT_POST_REVERSAL"
      t.active = true
    end
    gl_payable = GlAccount.find_or_create_by!(gl_number: "2510") do |g|
      g.name = "Accrued Interest Payable"
      g.category = "liability"
      g.normal_balance = "credit"
      g.status = Bankcore::Enums::STATUS_ACTIVE
    end
    tpl = PostingTemplate.find_or_create_by!(transaction_code_id: tc.id) do |t|
      t.name = "Interest Posting"
      t.description = "Debit payable, Credit account"
      t.active = true
    end
    PostingTemplateLeg.find_or_create_by!(posting_template_id: tpl.id, position: 0) do |l|
      l.leg_type = Bankcore::Enums::LEG_TYPE_DEBIT
      l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL
      l.gl_account_id = gl_payable.id
      l.description = "Debit interest payable"
    end
    PostingTemplateLeg.find_or_create_by!(posting_template_id: tpl.id, position: 1) do |l|
      l.leg_type = Bankcore::Enums::LEG_TYPE_CREDIT
      l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_CUSTOMER
      l.description = "Credit customer account"
    end
  end
end
