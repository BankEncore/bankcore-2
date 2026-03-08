# frozen_string_literal: true

require "test_helper"

class InterestAccrualServiceTest < ActiveSupport::TestCase
  def setup
    @account = accounts(:one)
    @other_account = Account.create!(
      account_number: "2002",
      account_type: @account.account_type,
      branch: @account.branch,
      currency_code: @account.currency_code,
      status: Bankcore::Enums::STATUS_ACTIVE,
      opened_on: @account.opened_on
    )
    @accrual_date = business_dates(:one).business_date
    ensure_int_accrual_template!
  end

  test "accrues interest and creates interest_accrual record" do
    batch = InterestAccrualService.accrue!(
      account_id: @account.id,
      amount_cents: 150,
      accrual_date: @accrual_date
    )

    assert batch.persisted?
    assert_equal "posted", batch.status
    accrual = InterestAccrual.find_by(account_id: @account.id, accrual_date: @accrual_date)
    assert accrual
    assert_equal 150, accrual.amount_cents
    assert_equal batch.id, accrual.posting_batch_id
  end

  test "raises when amount is negative" do
    assert_raises(ArgumentError) do
      InterestAccrualService.accrue!(
        account_id: @account.id,
        amount_cents: -100,
        accrual_date: @accrual_date
      )
    end
  end

  test "duplicate idempotency key reuses batch without duplicate accrual" do
    key = "accrual-idem-#{SecureRandom.hex(8)}"

    batch1 = InterestAccrualService.accrue!(
      account_id: @account.id,
      amount_cents: 150,
      accrual_date: @accrual_date,
      idempotency_key: key
    )

    assert_no_difference "InterestAccrual.count" do
      batch2 = InterestAccrualService.accrue!(
        account_id: @account.id,
        amount_cents: 150,
        accrual_date: @accrual_date,
        idempotency_key: key
      )

      assert_equal batch1.id, batch2.id
    end
  end

  test "idempotency rejects conflicting accrual account reuse" do
    key = "accrual-idem-#{SecureRandom.hex(8)}"

    InterestAccrualService.accrue!(
      account_id: @account.id,
      amount_cents: 150,
      accrual_date: @accrual_date,
      idempotency_key: key
    )

    assert_raises(PostingEngine::IdempotencyConflictError) do
      InterestAccrualService.accrue!(
        account_id: @other_account.id,
        amount_cents: 150,
        accrual_date: @accrual_date,
        idempotency_key: key
      )
    end
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
end
