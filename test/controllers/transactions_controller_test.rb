# frozen_string_literal: true

require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post login_url, params: { username: "testuser", password: "secret" }
  end

  test "index renders" do
    get transactions_url
    assert_response :success
  end

  test "new renders form" do
    get new_transaction_url
    assert_response :success
    assert_select "select#transaction_code"
    assert_select "input[name='transaction[amount]']"
  end

  test "create posts ADJ_CREDIT and redirects" do
    account = accounts(:one)
    assert_difference "BankingTransaction.count", 1 do
      assert_difference "TransactionReference.count", 2 do
        post transactions_url, params: {
          transaction: {
            transaction_code: "ADJ_CREDIT",
            account_id: account.id,
            amount: "100.50",
            memo: "Courtesy credit",
            reason_text: "Service recovery",
            reference_number: "MAN-20260309-001",
            external_reference: "CASE-42"
          }
        }
      end
    end
    assert_redirected_to transaction_path(BankingTransaction.last)
    transaction = BankingTransaction.last
    assert_equal "Courtesy credit", transaction.memo
    assert_equal "Service recovery", transaction.reason_text
    assert_equal "MAN-20260309-001", transaction.reference_number
    assert_equal "CASE-42", transaction.external_reference
    assert_equal [ "external_reference", "reference_number" ], transaction.transaction_references.order(:reference_type).pluck(:reference_type)
    follow_redirect!
    assert_match /posted successfully/i, flash[:notice]
  end

  test "preview preserves operational metadata for confirm step" do
    post transactions_url, params: {
      preview: "1",
      transaction: {
        transaction_code: "ADJ_CREDIT",
        account_id: accounts(:one).id,
        amount: "25.00",
        memo: "Preview memo",
        reason_text: "Preview reason",
        reference_number: "MAN-20260309-002",
        external_reference: "CASE-99"
      }
    }

    assert_response :success
    assert_select "input[type=hidden][name='transaction[memo]'][value='Preview memo']"
    assert_select "input[type=hidden][name='transaction[reason_text]'][value='Preview reason']"
    assert_select "input[type=hidden][name='transaction[reference_number]'][value='MAN-20260309-002']"
    assert_select "input[type=hidden][name='transaction[external_reference]'][value='CASE-99']"
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

  test "show renders structured references" do
    get transaction_url(BankingTransaction.find_by!(reference_number: "TXN-002"))

    assert_response :success
    assert_select "h2", text: /Structured References/
    assert_select "td", text: "reference_number"
    assert_select "td", text: "TXN-002"
  end

  test "reverse requires reverse_transactions permission" do
    batch = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: accounts(:one).id,
      amount_cents: 4000,
      business_date: business_dates(:one).business_date
    )
    txn = batch.operational_transaction

    delete logout_url
    post login_url, params: { username: "limiteduser", password: "secret" }
    post reverse_transaction_url(txn)

    assert_response :forbidden
    assert_match /do not have permission/i, flash[:alert]
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
