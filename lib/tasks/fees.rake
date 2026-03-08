# frozen_string_literal: true

namespace :fees do
  desc "Run fee assessment for a fee type (usage: rake fees:assess FEE_TYPE_ID=1)"
  task assess: :environment do
    id = ENV["FEE_TYPE_ID"]
    raise "Set FEE_TYPE_ID (e.g. rake fees:assess FEE_TYPE_ID=1)" unless id.present?

    results = FeeAssessmentRunnerService.run!(fee_type_id: id)
    puts "Assessed: #{results[:assessed].size}, Skipped: #{results[:skipped].size}, Errors: #{results[:errors].size}"
  end
end
