# frozen_string_literal: true

class FeeAssessmentRunnerService
  # Runs fee assessment for a fee type across eligible accounts.
  # MVP rule: all active DDA accounts.
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
    Account
      .where(account_type: "dda", status: Bankcore::Enums::STATUS_ACTIVE)
  end

  def assess_account(account)
    account_id = account.id

    if already_assessed?(account_id)
      return { status: :skipped, account_id: account_id, reason: "already_assessed" }
    end

    FeePostingService.assess!(
      account_id: account_id,
      fee_type_id: @fee_type_id,
      business_date: @assessment_date,
      idempotency_key: idempotency_key(account_id)
    )

    { status: :assessed, account_id: account_id }
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
end
