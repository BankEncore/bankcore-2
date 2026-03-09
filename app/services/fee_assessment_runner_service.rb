# frozen_string_literal: true

class FeeAssessmentRunnerService
  # Runs fee assessment for a fee type across eligible accounts.
  # Phase 4 rule: active fee_rules tied to account products.
  def self.run!(fee_type_id:, assessment_date: nil)
    new(fee_type_id: fee_type_id, assessment_date: assessment_date).run!
  end

  def initialize(fee_type_id:, assessment_date: nil)
    @fee_type_id = fee_type_id
    @assessment_date = assessment_date || BusinessDateService.current
  end

  def run!
    results = { assessed: [], skipped: [], errors: [] }

    eligible_accounts.find_each do |account|
      result = assess_account(account)
      results[result[:status]] << result
    end

    results
  end

  private

  def eligible_accounts
    return Account.none if active_rules_by_product.empty?

    Account
      .includes(:account_product)
      .where(status: Bankcore::Enums::STATUS_ACTIVE, account_product_id: active_rules_by_product.keys)
  end

  def assess_account(account)
    account_id = account.id
    fee_rule = active_rules_by_product[account.account_product_id]
    return { status: :skipped, account_id: account_id, reason: "no_rule" } unless fee_rule

    if already_assessed?(account_id)
      return { status: :skipped, account_id: account_id, reason: "already_assessed" }
    end

    FeePostingService.assess!(
      account_id: account_id,
      fee_type_id: @fee_type_id,
      fee_rule_id: fee_rule.id,
      amount_cents: fee_rule.amount_cents_for_assessment,
      gl_account_id: fee_rule.gl_account_id_for_posting,
      business_date: @assessment_date,
      idempotency_key: idempotency_key(account_id)
    )

    { status: :assessed, account_id: account_id, fee_rule_id: fee_rule.id }
  rescue StandardError => e
    { status: :errors, account_id: account_id, error: e.message }
  end

  def already_assessed?(account_id)
    FeeAssessment.exists?(
      account_id: account_id,
      fee_type_id: @fee_type_id,
      assessed_on: @assessment_date
    )
  end

  def idempotency_key(account_id)
    "fee-#{@fee_type_id}-#{account_id}-#{@assessment_date}"
  end

  def active_rules_by_product
    @active_rules_by_product ||= FeeRule
      .includes(:fee_type)
      .where(fee_type_id: @fee_type_id)
      .active_on(@assessment_date)
      .ordered
      .each_with_object({}) do |fee_rule, result|
        result[fee_rule.account_product_id] ||= fee_rule
      end
  end
end
