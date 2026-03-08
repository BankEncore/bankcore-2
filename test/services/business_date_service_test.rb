# frozen_string_literal: true

require "test_helper"

class BusinessDateServiceTest < ActiveSupport::TestCase
  test "current returns open business date" do
    bd = business_dates(:one)
    assert_equal bd.business_date, BusinessDateService.current
  end

  test "open? returns true for open date" do
    bd = business_dates(:one)
    assert BusinessDateService.open?(bd.business_date)
  end

  test "open? returns false for closed date" do
    closed_date = Date.current + 60
    refute BusinessDateService.open?(closed_date)
  end

  test "raises NoOpenBusinessDateError when no open date" do
    BusinessDate.where(status: "open").update_all(status: "closed")

    assert_raises(BusinessDateService::NoOpenBusinessDateError) do
      BusinessDateService.current
    end
  ensure
    BusinessDate.where(business_date: Date.current).update_all(status: "open")
  end
end
