# frozen_string_literal: true

class InterestPostingJob < ApplicationJob
  queue_as :default

  # Runs due interest posting for eligible accounts based on product cadence.
  def perform(business_date: nil)
    results = InterestPostingRunnerService.run!(business_date: business_date)

    Rails.logger.info(
      "[InterestPostingJob] business_date=#{business_date || BusinessDateService.current} " \
      "posted=#{results[:posted].size} skipped=#{results[:skipped].size} errors=#{results[:errors].size}"
    )

    results
  end
end
