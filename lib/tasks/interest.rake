# frozen_string_literal: true

namespace :interest do
  desc "Run daily interest accrual for eligible deposit accounts"
  task accrue: :environment do
    results = InterestAccrualRunnerService.run!
    puts "Accrued: #{results[:accrued].size}, Skipped: #{results[:skipped].size}, Errors: #{results[:errors].size}"
  end
end
