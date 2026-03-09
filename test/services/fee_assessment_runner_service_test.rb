# frozen_string_literal: true

require "test_helper"

class FeeAssessmentRunnerServiceTest < ActiveSupport::TestCase
  def setup
    @business_date = business_dates(:one).business_date
    ensure_fee_post_template!
  end

  test "assesses only accounts whose products have active rules for the fee type" do
    results = FeeAssessmentRunnerService.run!(
      fee_type_id: fee_types(:maintenance).id,
      assessment_date: @business_date
    )

    assert_equal [ accounts(:one).id ], results[:assessed].map { |result| result[:account_id] }
    assert_empty results[:errors]
    refute_includes results[:assessed].map { |result| result[:account_id] }, accounts(:two).id
  end

  test "uses fee rule amount and gl override for matching product" do
    results = FeeAssessmentRunnerService.run!(
      fee_type_id: fee_types(:service_charge).id,
      assessment_date: @business_date
    )

    assert_equal [ accounts(:two).id ], results[:assessed].map { |result| result[:account_id] }

    assessment = FeeAssessment.find_by!(
      account_id: accounts(:two).id,
      fee_type_id: fee_types(:service_charge).id,
      assessed_on: @business_date
    )
    gl_numbers = assessment.posting_batch.posting_legs.includes(:gl_account).map { |leg| leg.gl_account&.gl_number }.compact

    assert_equal fee_rules(:service_charge_savings).id, assessment.fee_rule_id
    assert_equal 700, assessment.amount_cents
    assert_equal [ "4560" ], gl_numbers
  end

  test "returns no assessments when no active rules exist for the fee type" do
    results = FeeAssessmentRunnerService.run!(
      fee_type_id: FeeType.create!(
        code: "UNRULED_FEE",
        name: "Unruled Fee",
        default_amount_cents: 100,
        gl_account: gl_accounts(:three),
        status: Bankcore::Enums::STATUS_ACTIVE
      ).id,
      assessment_date: @business_date
    )

    assert_empty results[:assessed]
    assert_empty results[:errors]
  end

  private

  def ensure_fee_post_template!
    return if PostingTemplate.joins(:transaction_code).exists?(transaction_codes: { code: "FEE_POST" })

    tc = TransactionCode.find_or_create_by!(code: "FEE_POST") do |t|
      t.description = "Fee assessment"
      t.reversal_code = "FEE_REVERSAL"
      t.active = true
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
