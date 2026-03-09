# frozen_string_literal: true

require "test_helper"

class TransactionEntry::RequestTest < ActiveSupport::TestCase
  test "generates default reference for blank manual entry when code present" do
    request = TransactionEntry::Request.from_form(
      raw_params: {
        transaction_code: "ADJ_CREDIT",
        account_id: accounts(:one).id.to_s,
        amount: "10.00",
        reason_text: "Test",
        reference_number: ""
      },
      created_by_id: users(:one).id,
      business_date: business_dates(:one).business_date
    )

    assert request.reference_number.present?
    assert_match /\AMAN-ADJ_CREDIT-\d{12}\z/, request.reference_number
  end

  test "preserves operator-supplied reference number" do
    request = TransactionEntry::Request.from_form(
      raw_params: {
        transaction_code: "ADJ_CREDIT",
        account_id: accounts(:one).id.to_s,
        amount: "10.00",
        reason_text: "Test",
        reference_number: "OPERATOR-REF-001"
      },
      created_by_id: users(:one).id,
      business_date: business_dates(:one).business_date
    )

    assert_equal "OPERATOR-REF-001", request.reference_number
  end

  test "does not generate default for non-manual codes" do
    request = TransactionEntry::Request.from_form(
      raw_params: {
        transaction_code: "INT_ACCRUAL",
        account_id: accounts(:one).id.to_s,
        reference_number: ""
      },
      created_by_id: users(:one).id,
      business_date: business_dates(:one).business_date
    )

    assert_nil request.reference_number
  end

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
