# frozen_string_literal: true

require "test_helper"

class InterestAccrualServiceTest < ActiveSupport::TestCase
  def setup
    @account = create_interest_account(
      account_number: "2002",
      product: account_products(:now),
      rate_basis_points: 365
    )
    @other_account = create_interest_account(
      account_number: "2003",
      product: account_products(:savings),
      rate_basis_points: 365
    )
    @accrual_date = business_dates(:one).business_date
    ensure_int_accrual_template!
  end

  test "accrues interest and creates interest_accrual record" do
    batch = InterestAccrualService.accrue!(
      account_id: @account.id,
      amount_cents: 150,
      accrual_date: @accrual_date,
      interest_rule_id: interest_rules(:now_default).id
    )

    assert batch.persisted?
    assert_equal "posted", batch.status
    accrual = InterestAccrual.find_by(account_id: @account.id, accrual_date: @accrual_date)
    assert accrual
    assert_equal 150, accrual.amount_cents
    assert_equal batch.id, accrual.posting_batch_id
    assert_equal interest_rules(:now_default).id, accrual.interest_rule_id
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

  test "rolls back posting when interest accrual linkage fails" do
    assert_no_difference [ "BankingTransaction.count", "PostingBatch.count", "PostingLeg.count", "InterestAccrual.count" ] do
      error = assert_raises(RuntimeError) do
        with_stubbed_class_method(InterestAccrual, :find_or_create_by!, ->(*) { raise "accrual linkage failed" }) do
          InterestAccrualService.accrue!(
            account_id: @account.id,
            amount_cents: 150,
            accrual_date: @accrual_date
          )
        end
      end

      assert_equal "accrual linkage failed", error.message
    end
  end

  test "uses product-aware interest expense gl for now products" do
    batch = InterestAccrualService.accrue!(
      account_id: @account.id,
      amount_cents: 150,
      accrual_date: @accrual_date
    )

    gl_numbers = batch.posting_legs.includes(:gl_account).order(:position).map { |leg| leg.gl_account.gl_number }
    assert_equal %w[5120 2510], gl_numbers
  end

  test "uses product-aware interest expense gl for savings products" do
    batch = InterestAccrualService.accrue!(
      account_id: @other_account.id,
      amount_cents: 150,
      accrual_date: @accrual_date
    )

    gl_numbers = batch.posting_legs.includes(:gl_account).order(:position).map { |leg| leg.gl_account.gl_number }
    assert_equal %w[5130 2510], gl_numbers
  end

  private

  def with_stubbed_class_method(klass, method_name, replacement)
    original = klass.method(method_name)
    klass.define_singleton_method(method_name, &replacement)
    yield
  ensure
    klass.define_singleton_method(method_name, original)
  end

  def ensure_int_accrual_template!
    return if PostingTemplate.joins(:transaction_code).exists?(transaction_codes: { code: "INT_ACCRUAL" })

    tc = TransactionCode.find_or_create_by!(code: "INT_ACCRUAL") do |t|
      t.description = "Interest accrual"
      t.reversal_code = "INT_ACCRUAL_REVERSAL"
      t.active = true
    end
    GlAccount.find_or_create_by!(gl_number: "5130") do |g|
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
    debit_leg = PostingTemplateLeg.find_or_initialize_by(posting_template_id: tpl.id, position: 0)
    debit_leg.assign_attributes(
      leg_type: Bankcore::Enums::LEG_TYPE_DEBIT,
      account_source: Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL,
      gl_account_id: nil,
      description: "Debit product interest expense"
    )
    debit_leg.save!

    credit_leg = PostingTemplateLeg.find_or_initialize_by(posting_template_id: tpl.id, position: 1)
    credit_leg.assign_attributes(
      leg_type: Bankcore::Enums::LEG_TYPE_CREDIT,
      account_source: Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL,
      gl_account_id: gl_payable.id,
      description: "Credit interest payable"
    )
    credit_leg.save!
  end

  def create_interest_account(account_number:, product:, rate_basis_points:)
    account = Account.create!(
      account_number: account_number,
      account_type: product.product_code,
      account_product: product,
      branch: branches(:one),
      currency_code: product.currency_code,
      status: Bankcore::Enums::STATUS_ACTIVE,
      opened_on: Date.current
    )

    DepositAccount.create!(
      account: account,
      deposit_type: product.default_deposit_type,
      interest_bearing: true,
      interest_rate_basis_points: rate_basis_points
    )

    account
  end
end
