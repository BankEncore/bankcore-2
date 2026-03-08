# frozen_string_literal: true

require "test_helper"

class InterestAccrualRunnerServiceTest < ActiveSupport::TestCase
  def setup
    @account = accounts(:one)
    @accrual_date = business_dates(:one).business_date
    ensure_int_accrual_template!
    ensure_interest_bearing_deposit!
    ensure_balance!
  end

  test "accrues interest for eligible account with positive balance" do
    results = InterestAccrualRunnerService.run!(accrual_date: @accrual_date)

    assert_equal 1, results[:accrued].size
    assert results[:accrued].first[:amount_cents].positive?
    assert_equal @account.id, results[:accrued].first[:account_id]

    accrual = InterestAccrual.find_by(account_id: @account.id, accrual_date: @accrual_date)
    assert accrual
    assert accrual.amount_cents.positive?
  end

  test "skips account with zero balance" do
    AccountBalance.find_by(account_id: @account.id).update!(posted_balance_cents: 0, available_balance_cents: 0)

    results = InterestAccrualRunnerService.run!(accrual_date: @accrual_date)

    assert_equal 0, results[:accrued].size
    assert results[:skipped].any? { |s| s[:account_id] == @account.id && s[:reason] == "zero_balance" }
  end

  test "skips account already accrued for date" do
    InterestAccrualRunnerService.run!(accrual_date: @accrual_date)
    results = InterestAccrualRunnerService.run!(accrual_date: @accrual_date)

    assert_equal 0, results[:accrued].size
    assert results[:skipped].any? { |s| s[:account_id] == @account.id && s[:reason] == "already_accrued" }
  end

  test "skips non-interest-bearing accounts" do
    deposit_accounts(:one).update!(interest_bearing: false, interest_rate_basis_points: 0)

    results = InterestAccrualRunnerService.run!(accrual_date: @accrual_date)

    assert_equal 0, results[:accrued].size
  end

  private

  def ensure_int_accrual_template!
    return if PostingTemplate.joins(:transaction_code).exists?(transaction_codes: { code: "INT_ACCRUAL" })

    tc = TransactionCode.find_or_create_by!(code: "INT_ACCRUAL") do |t|
      t.description = "Interest accrual"
      t.reversal_code = "INT_ACCRUAL_REVERSAL"
      t.active = true
    end
    gl_expense = GlAccount.find_or_create_by!(gl_number: "5130") do |g|
      g.name = "Interest Expense"
      g.category = "expense"
      g.normal_balance = "debit"
      g.status = Bankcore::Enums::STATUS_ACTIVE
    end
    gl_payable = GlAccount.find_or_create_by!(gl_number: "2510") do |g|
      g.name = "Accrued Interest Payable"
      g.category = "liability"
      g.normal_balance = "credit"
      g.status = Bankcore::Enums::STATUS_ACTIVE
    end
    tpl = PostingTemplate.find_or_create_by!(transaction_code_id: tc.id) do |t|
      t.name = "Interest Accrual"
      t.description = "GL-only accrual"
      t.active = true
    end
    PostingTemplateLeg.find_or_create_by!(posting_template_id: tpl.id, position: 0) do |l|
      l.leg_type = Bankcore::Enums::LEG_TYPE_DEBIT
      l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL
      l.gl_account_id = gl_expense.id
      l.description = "Debit interest expense"
    end
    PostingTemplateLeg.find_or_create_by!(posting_template_id: tpl.id, position: 1) do |l|
      l.leg_type = Bankcore::Enums::LEG_TYPE_CREDIT
      l.account_source = Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL
      l.gl_account_id = gl_payable.id
      l.description = "Credit interest payable"
    end
  end

  def ensure_interest_bearing_deposit!
    deposit_accounts(:one).update!(
      interest_bearing: true,
      interest_rate_basis_points: 365 # ~3.65% annual = ~0.01% daily, 100000 cents = $1000 -> ~1 cent/day
    )
  end

  def ensure_balance!
    AccountBalance.find_or_create_by!(account_id: @account.id) do |b|
      b.posted_balance_cents = 100_000 # $1000
      b.available_balance_cents = 100_000
      b.as_of_at = Time.current
    end
  end
end
