# frozen_string_literal: true

require "test_helper"

class FeePostingServiceTest < ActiveSupport::TestCase
  def setup
    @account = accounts(:one)
    @business_date = business_dates(:one).business_date
    ensure_fee_post_template!
    @fee_type = FeeType.find_or_create_by!(code: "TEST_FEE") do |ft|
      ft.name = "Test Fee"
      ft.default_amount_cents = 1000
      ft.gl_account_id = GlAccount.find_by!(gl_number: "4510")&.id
      ft.status = Bankcore::Enums::STATUS_ACTIVE
    end
  end

  test "assesses fee and creates fee_assessment" do
    batch = FeePostingService.assess!(
      account_id: @account.id,
      fee_type_id: @fee_type.id,
      amount_cents: 2500,
      business_date: @business_date
    )

    assert batch.persisted?
    assert_equal "posted", batch.status
    assessment = FeeAssessment.find_by(account_id: @account.id, fee_type_id: @fee_type.id)
    assert assessment
    assert_equal 2500, assessment.amount_cents
    assert_equal batch.id, assessment.posting_batch_id
  end

  test "uses fee_type default amount when amount_cents not provided" do
    batch = FeePostingService.assess!(
      account_id: @account.id,
      fee_type_id: @fee_type.id,
      business_date: @business_date
    )

    assessment = FeeAssessment.find_by(account_id: @account.id, fee_type_id: @fee_type.id)
    assert_equal 1000, assessment.amount_cents
  end

  test "raises when amount is zero or negative" do
    assert_raises(ArgumentError) do
      FeePostingService.assess!(
        account_id: @account.id,
        fee_type_id: @fee_type.id,
        amount_cents: 0,
        business_date: @business_date
      )
    end
  end

  test "duplicate idempotency key reuses batch without duplicate assessment" do
    key = "fee-idem-#{SecureRandom.hex(8)}"

    batch1 = FeePostingService.assess!(
      account_id: @account.id,
      fee_type_id: @fee_type.id,
      amount_cents: 2500,
      business_date: @business_date,
      idempotency_key: key
    )

    assert_no_difference "FeeAssessment.count" do
      batch2 = FeePostingService.assess!(
        account_id: @account.id,
        fee_type_id: @fee_type.id,
        amount_cents: 2500,
        business_date: @business_date,
        idempotency_key: key
      )

      assert_equal batch1.id, batch2.id
    end
  end

  test "idempotency rejects conflicting fee_type reuse" do
    other_fee_type = FeeType.create!(
      code: "OTHER_FEE",
      name: "Other Fee",
      default_amount_cents: 1000,
      gl_account_id: @fee_type.gl_account_id,
      status: Bankcore::Enums::STATUS_ACTIVE
    )
    key = "fee-idem-#{SecureRandom.hex(8)}"

    FeePostingService.assess!(
      account_id: @account.id,
      fee_type_id: @fee_type.id,
      amount_cents: 2500,
      business_date: @business_date,
      idempotency_key: key
    )

    assert_raises(PostingEngine::IdempotencyConflictError) do
      FeePostingService.assess!(
        account_id: @account.id,
        fee_type_id: other_fee_type.id,
        amount_cents: 2500,
        business_date: @business_date,
        idempotency_key: key
      )
    end
  end

  test "rolls back posting when fee assessment linkage fails" do
    assert_no_difference [ "BankingTransaction.count", "PostingBatch.count", "PostingLeg.count", "FeeAssessment.count" ] do
      error = assert_raises(RuntimeError) do
        with_stubbed_class_method(FeeAssessment, :find_or_create_by!, ->(*) { raise "fee linkage failed" }) do
          FeePostingService.assess!(
            account_id: @account.id,
            fee_type_id: @fee_type.id,
            amount_cents: 2500,
            business_date: @business_date
          )
        end
      end

      assert_equal "fee linkage failed", error.message
    end
  end

  test "stores fee rule linkage and uses rule gl override when provided" do
    rule = FeeRule.create!(
      fee_type: @fee_type,
      account_product: accounts(:two).account_product,
      gl_account: GlAccount.find_by!(gl_number: "4560"),
      priority: 100,
      method: FeeRule::METHOD_FIXED_AMOUNT,
      amount_cents: 700,
      effective_on: @business_date
    )

    batch = FeePostingService.assess!(
      account_id: accounts(:two).id,
      fee_type_id: @fee_type.id,
      fee_rule_id: rule.id,
      amount_cents: rule.amount_cents_for_assessment,
      gl_account_id: rule.gl_account_id_for_posting,
      business_date: @business_date
    )

    assessment = FeeAssessment.find_by!(posting_batch_id: batch.id)
    gl_numbers = batch.posting_legs.includes(:gl_account).order(:position).map { |leg| leg.gl_account&.gl_number }.compact

    assert_equal rule.id, assessment.fee_rule_id
    assert_equal 700, assessment.amount_cents
    assert_equal [ "4560" ], gl_numbers
  end

  private

  def with_stubbed_class_method(klass, method_name, replacement)
    original = klass.method(method_name)
    klass.define_singleton_method(method_name, &replacement)
    yield
  ensure
    klass.define_singleton_method(method_name, original)
  end

  def ensure_fee_post_template!
    return if PostingTemplate.joins(:transaction_code).exists?(transaction_codes: { code: "FEE_POST" })

    tc = TransactionCode.find_or_create_by!(code: "FEE_POST") do |t|
      t.description = "Fee assessment"
      t.reversal_code = "FEE_REVERSAL"
      t.active = true
    end
    gl = GlAccount.find_or_create_by!(gl_number: "4510") do |g|
      g.name = "Deposit Service Charges"
      g.category = "income"
      g.normal_balance = "credit"
      g.status = Bankcore::Enums::STATUS_ACTIVE
    end
    tpl = PostingTemplate.find_or_create_by!(transaction_code_id: tc.id) do |t|
      t.name = "Fee Assessment"
      t.description = "Debit account, Credit fee income"
      t.active = true
    end
    debit_leg = PostingTemplateLeg.find_or_initialize_by(posting_template_id: tpl.id, position: 0)
    debit_leg.assign_attributes(
      leg_type: Bankcore::Enums::LEG_TYPE_DEBIT,
      account_source: Bankcore::Enums::ACCOUNT_SOURCE_CUSTOMER,
      description: "Debit customer account"
    )
    debit_leg.save!

    credit_leg = PostingTemplateLeg.find_or_initialize_by(posting_template_id: tpl.id, position: 1)
    credit_leg.assign_attributes(
      leg_type: Bankcore::Enums::LEG_TYPE_CREDIT,
      account_source: Bankcore::Enums::ACCOUNT_SOURCE_FIXED_GL,
      gl_account_id: nil,
      description: "Credit fee income"
    )
    credit_leg.save!
  end
end
