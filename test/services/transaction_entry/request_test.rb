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

  test "generates default transfer memo for XFER_INTERNAL when blank and account numbers provided" do
    request = TransactionEntry::Request.from_form(
      raw_params: {
        transaction_code: "XFER_INTERNAL",
        source_account_id: accounts(:one).id.to_s,
        destination_account_id: accounts(:two).id.to_s,
        amount: "100.00",
        memo: "",
        reference_number: "MAN-XFER-001"
      },
      created_by_id: users(:one).id,
      business_date: business_dates(:one).business_date,
      account_numbers: { source: "1001", destination: "3001" }
    )

    assert_equal "Internal transfer: 1001 → 3001", request.memo
  end

  test "preserves operator-supplied memo for transfer" do
    request = TransactionEntry::Request.from_form(
      raw_params: {
        transaction_code: "XFER_INTERNAL",
        source_account_id: accounts(:one).id.to_s,
        destination_account_id: accounts(:two).id.to_s,
        amount: "100.00",
        memo: "Operator memo text",
        reference_number: "MAN-XFER-001"
      },
      created_by_id: users(:one).id,
      business_date: business_dates(:one).business_date,
      account_numbers: { source: "1001", destination: "3001" }
    )

    assert_equal "Operator memo text", request.memo
  end

  test "does not generate transfer memo for non-transfer codes" do
    request = TransactionEntry::Request.from_form(
      raw_params: {
        transaction_code: "ADJ_CREDIT",
        account_id: accounts(:one).id.to_s,
        amount: "10.00",
        memo: "",
        reason_text: "Test",
        reference_number: "MAN-ADJ-001"
      },
      created_by_id: users(:one).id,
      business_date: business_dates(:one).business_date,
      account_numbers: { source: "1001", destination: "3001" }
    )

    assert_nil request.memo
  end

  test "generates ACH-specific reference when trace and effective date present" do
    request = TransactionEntry::Request.from_form(
      raw_params: {
        transaction_code: "ACH_DEBIT",
        account_id: accounts(:one).id.to_s,
        amount: "10.00",
        ach_trace_number: "123456789012345",
        ach_effective_date: "2026-03-09",
        ach_batch_reference: "FILE-1",
        authorization_reference: "AUTH-1",
        reference_number: ""
      },
      created_by_id: users(:one).id,
      business_date: business_dates(:one).business_date
    )

    assert_match /\AACH-123456789012345-260309-\d{6}\z/, request.reference_number
  end

  test "generates generic MAN reference for ACH when trace or effective date missing" do
    request = TransactionEntry::Request.from_form(
      raw_params: {
        transaction_code: "ACH_CREDIT",
        account_id: accounts(:one).id.to_s,
        amount: "10.00",
        ach_trace_number: "",
        ach_effective_date: "2026-03-09",
        ach_batch_reference: "FILE-1",
        reference_number: ""
      },
      created_by_id: users(:one).id,
      business_date: business_dates(:one).business_date
    )

    assert request.reference_number.present?
    assert_match /\AMAN-ACH_CREDIT-\d{12}\z/, request.reference_number
  end

  test "preserves operator-supplied reference for ACH" do
    request = TransactionEntry::Request.from_form(
      raw_params: {
        transaction_code: "ACH_DEBIT",
        account_id: accounts(:one).id.to_s,
        amount: "10.00",
        ach_trace_number: "123456789012345",
        ach_effective_date: "2026-03-09",
        ach_batch_reference: "FILE-1",
        authorization_reference: "AUTH-1",
        reference_number: "OPERATOR-ACH-REF"
      },
      created_by_id: users(:one).id,
      business_date: business_dates(:one).business_date
    )

    assert_equal "OPERATOR-ACH-REF", request.reference_number
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
