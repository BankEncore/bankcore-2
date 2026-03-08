# frozen_string_literal: true

require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  test "index renders" do
    get transactions_url
    assert_response :success
  end

  test "new renders form" do
    get new_transaction_url
    assert_response :success
    assert_select "select#transaction_code"
    assert_select "input[name=amount]"
  end

  test "create posts ADJ_CREDIT and redirects" do
    account = accounts(:one)
    assert_difference "BankingTransaction.count", 1 do
      post transactions_url, params: {
        transaction_code: "ADJ_CREDIT",
        account_id: account.id,
        amount: "100.50"
      }
    end
    assert_redirected_to transaction_path(BankingTransaction.last)
    follow_redirect!
    assert_match /posted successfully/i, flash[:notice]
  end

  test "show renders transaction" do
    txn = BankingTransaction.create!(
      transaction_type: "ADJ_CREDIT",
      branch: branches(:one),
      status: "posted",
      business_date: business_dates(:one).business_date
    )
    get transaction_url(txn)
    assert_response :success
  end

  test "reverse redirects to override request when threshold exceeded without approval" do
    batch = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: accounts(:one).id,
      amount_cents: 10_000,
      business_date: business_dates(:one).business_date
    )
    txn = batch.operational_transaction

    post reverse_transaction_url(txn)

    assert_redirected_to new_override_request_path(transaction_id: txn.id, request_type: "reversal")
    assert_match /require supervisor approval/i, flash[:alert]
  end
end
