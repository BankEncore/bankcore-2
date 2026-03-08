# frozen_string_literal: true

class FeeAssessmentJob < ApplicationJob
  queue_as :default

  # Runs fee assessment for a fee type across eligible accounts.
  # Triggered manually via rake or enqueued with fee_type_id.
  def perform(fee_type_id:, assessment_date: nil)
    results = FeeAssessmentRunnerService.run!(
      fee_type_id: fee_type_id,
      assessment_date: assessment_date
    )

    Rails.logger.info(
      "[FeeAssessmentJob] fee_type_id=#{fee_type_id} " \
      "assessed=#{results[:assessed].size} skipped=#{results[:skipped].size} errors=#{results[:errors].size}"
    )

    results
  end
end
