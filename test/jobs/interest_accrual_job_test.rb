# frozen_string_literal: true

require "test_helper"

class InterestAccrualJobTest < ActiveJob::TestCase
  test "performs accrual and returns results" do
    # With no interest-bearing accounts, runner returns empty results
    result = InterestAccrualJob.perform_now

    assert result.is_a?(Hash)
    assert result.key?(:accrued)
    assert result.key?(:skipped)
    assert result.key?(:errors)
  end
end
