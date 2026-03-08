require "test_helper"

class BankingTransactionTest < ActiveSupport::TestCase
  test "belongs to branch" do
    txn = BankingTransaction.create!(
      transaction_type: "ADJ_CREDIT",
      branch: branches(:one),
      status: "draft",
      business_date: business_dates(:one).business_date
    )
    assert txn.branch.present?
  end

  test "has posting batch" do
    txn = BankingTransaction.create!(
      transaction_type: "ADJ_CREDIT",
      branch: branches(:one),
      status: "draft",
      business_date: business_dates(:one).business_date
    )
    assert_respond_to txn, :posting_batch
  end
end
