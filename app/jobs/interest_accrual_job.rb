# frozen_string_literal: true

class InterestAccrualJob < ApplicationJob
  queue_as :default

  # Runs daily interest accrual for all eligible deposit accounts.
  # Scheduled via Solid Queue recurring tasks (e.g. at 1am every day).
  def perform(accrual_date: nil)
    results = InterestAccrualRunnerService.run!(accrual_date: accrual_date)

    Rails.logger.info(
      "[InterestAccrualJob] accrual_date=#{accrual_date || BusinessDateService.current} " \
      "accrued=#{results[:accrued].size} skipped=#{results[:skipped].size} errors=#{results[:errors].size}"
    )

    results
  end
end
