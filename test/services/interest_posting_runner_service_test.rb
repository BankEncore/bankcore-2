# frozen_string_literal: true

require "test_helper"

class InterestPostingRunnerServiceTest < ActiveSupport::TestCase
  def setup
    @account = accounts(:two)
    @interest_rule = interest_rules(:savings_default)
    @business_date = Date.new(2026, 3, 31)
    ensure_business_date_open!(@business_date)
    ensure_interest_bearing_deposit!
    ensure_int_post_template!
    ensure_zero_balance!
  end

  test "posts summed unposted accruals when monthly cadence is due" do
    create_accrual!(Date.new(2026, 3, 29), 10)
    create_accrual!(Date.new(2026, 3, 30), 15)

    results = InterestPostingRunnerService.run!(business_date: @business_date)

    assert_equal 1, results[:posted].size
    assert_equal 25, results[:posted].first[:amount_cents]
    assert_equal 2, results[:posted].first[:accrual_count]

    batch = PostingBatch.find(results[:posted].first[:posting_batch_id])
    assert_equal "INT_POST", batch.transaction_code
    assert_equal 2, InterestPostingApplication.where(posting_batch: batch).count
  end

  test "skips when cadence is not due" do
    april_date = Date.new(2026, 4, 30)
    ensure_business_date_open!(april_date)
    @interest_rule.update!(posting_cadence: InterestRule::POSTING_CADENCE_QUARTERLY)
    create_accrual!(Date.new(2026, 4, 29), 10)

    results = InterestPostingRunnerService.run!(business_date: april_date)

    assert_equal 0, results[:posted].size
    assert results[:skipped].any? { |entry| entry[:account_id] == @account.id && entry[:reason] == "cadence_not_due" }
    assert_equal 0, InterestPostingApplication.count
  end

  test "skips when no unposted accruals exist" do
    results = InterestPostingRunnerService.run!(business_date: @business_date)

    assert_equal 0, results[:posted].size
    assert results[:skipped].any? { |entry| entry[:account_id] == @account.id && entry[:reason] == "no_unposted_accruals" }
  end

  test "does not repost accruals already linked to an interest posting" do
    create_accrual!(Date.new(2026, 3, 29), 10)
    create_accrual!(Date.new(2026, 3, 30), 15)

    first_results = InterestPostingRunnerService.run!(business_date: @business_date)
    second_results = InterestPostingRunnerService.run!(business_date: @business_date)

    assert_equal 1, first_results[:posted].size
    assert_equal 0, second_results[:posted].size
    assert results_include_reason?(second_results[:skipped], "no_unposted_accruals")
    assert_equal 2, InterestPostingApplication.count
    assert_equal 1, PostingBatch.where(transaction_code: "INT_POST", business_date: @business_date).count
  end

  private

  def create_accrual!(accrual_date, amount_cents)
    InterestAccrual.create!(
      account: @account,
      interest_rule: @interest_rule,
      accrual_date: accrual_date,
      amount_cents: amount_cents,
      status: Bankcore::Enums::STATUS_POSTED
    )
  end

  def ensure_interest_bearing_deposit!
    deposit_account = DepositAccount.find_or_initialize_by(account_id: @account.id)
    deposit_account.deposit_type ||= @account.account_product.default_deposit_type
    deposit_account.interest_bearing = true
    deposit_account.save!
  end

  def ensure_zero_balance!
    balance = AccountBalance.find_or_initialize_by(account_id: @account.id)
    balance.posted_balance_cents ||= 0
    balance.available_balance_cents ||= 0
    balance.average_balance_cents ||= 0
    balance.as_of_at ||= Time.current
    balance.save!
  end

  def ensure_business_date_open!(date)
    BusinessDate.find_or_create_by!(business_date: date) do |business_date|
      business_date.status = Bankcore::Enums::BUSINESS_DATE_OPEN
      business_date.opened_at = Time.current
    end
  end

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

  def results_include_reason?(entries, reason)
    entries.any? { |entry| entry[:account_id] == @account.id && entry[:reason] == reason }
  end
end
