# frozen_string_literal: true

require "test_helper"

class TransactionEntry::RequestTest < ActiveSupport::TestCase
  test "normalizes ids, amount, and dates from form params" do
    request = TransactionEntry::Request.from_form(
      raw_params: {
        transaction_code: "ACH_DEBIT",
        account_id: accounts(:one).id.to_s,
        amount: "42.50",
        ach_effective_date: "2026-03-08"
      },
      created_by_id: users(:one).id,
      business_date: business_dates(:one).business_date
    )

    assert_equal "ACH_DEBIT", request.transaction_code
    assert_equal accounts(:one).id, request.account_id
    assert_equal 4250, request.amount_cents
    assert_equal Date.new(2026, 3, 8), request.ach_effective_date
    assert_equal :ach, request.family
  end
end
