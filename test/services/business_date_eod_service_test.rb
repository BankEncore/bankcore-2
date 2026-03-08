# frozen_string_literal: true

require "test_helper"

class BusinessDateEodServiceTest < ActiveSupport::TestCase
  test "run! closes current date, opens next date, and emits audit events" do
    current_date = business_dates(:one).business_date
    BankingTransaction.where(business_date: current_date, status: "draft").update_all(status: "posted", posted_at: Time.current)

    assert_difference "AuditEvent.count", 2 do
      assert BusinessDateEodService.run!
    end

    assert_equal "closed", BusinessDate.find_by!(business_date: current_date).status
    assert_equal "open", BusinessDate.find_by!(business_date: current_date + 1).status
    assert_equal [ "business_date_closed", "business_date_opened" ], AuditEvent.order(:id).last(2).map(&:event_type)
  end
end
