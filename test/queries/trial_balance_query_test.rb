# frozen_string_literal: true

require "test_helper"

class TrialBalanceQueryTest < ActiveSupport::TestCase
  test "summary rows aggregate debit and credit totals by gl account" do
    PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: accounts(:one).id,
      amount_cents: 1_250,
      business_date: business_dates(:one).business_date,
      reference_number: "TB-001"
    )

    query = TrialBalanceQuery.new(business_date: business_dates(:one).business_date, include_zero: true)
    expense_row = query.summary_rows.find { |row| row.gl_account.gl_number == "5190" }
    liability_row = query.summary_rows.find { |row| row.gl_account.gl_number == "2110" }

    assert_equal 1_250, expense_row.debit_cents
    assert_equal 0, expense_row.credit_cents
    assert_equal "debit", expense_row.balance_side

    assert_equal 0, liability_row.debit_cents
    assert_equal 1_250, liability_row.credit_cents
    assert_equal "credit", liability_row.balance_side
    assert_equal query.totals[:debit_cents], query.totals[:credit_cents]
  end

  test "include_zero false hides inactive summary rows" do
    query = TrialBalanceQuery.new(business_date: business_dates(:one).business_date, include_zero: false)

    assert_empty query.summary_rows
  end

  test "detail rows expose posting and transaction context" do
    batch = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: accounts(:one).id,
      amount_cents: 2_000,
      business_date: business_dates(:one).business_date,
      reference_number: "TB-DETAIL-1"
    )

    gl_account = GlAccount.find_by!(gl_number: "5190")
    detail_row = TrialBalanceQuery
      .new(business_date: business_dates(:one).business_date, include_zero: true)
      .detail_rows(gl_account_id: gl_account.id)
      .first

    assert_equal batch.posting_reference, detail_row.posting_reference
    assert_equal "ADJ_CREDIT", detail_row.transaction_type
    assert_equal "TB-DETAIL-1", detail_row.transaction_reference_number
    assert_equal batch.operational_transaction_id, detail_row.operational_transaction_id
  end

  test "reversal activity appears as offsetting journal lines on the customer liability gl" do
    batch = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: accounts(:one).id,
      amount_cents: 1_000,
      business_date: business_dates(:one).business_date
    )
    ReversalService.reverse!(posting_batch: batch)

    gl_account = GlAccount.find_by!(gl_number: "2110")
    row = TrialBalanceQuery
      .new(business_date: business_dates(:one).business_date, include_zero: true)
      .summary_row_for(gl_account.id)

    assert_equal 1_000, row.debit_cents
    assert_equal 1_000, row.credit_cents
    assert_equal 0, row.net_cents
    assert_equal "flat", row.balance_side
  end
end
