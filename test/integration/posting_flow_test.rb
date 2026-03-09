# frozen_string_literal: true

require "test_helper"

class PostingFlowTest < ActiveSupport::TestCase
  # Integration test: full flow from posting through reversal
  def setup
    @account = accounts(:one)
    @business_date = business_dates(:one).business_date
  end

  test "full posting and reversal flow" do
    # 1. Post ADJ_CREDIT
    batch = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: @account.id,
      amount_cents: 4_000,
      business_date: @business_date
    )

    assert batch.persisted?
    assert_equal "posted", batch.status
    assert_equal 2, batch.posting_legs.count

    # 2. Verify journal and account projection
    assert batch.journal_entries.any?, "Journal entry should be created"
    assert @account.account_transactions.any?, "Account transaction should be created"

    # 3. Verify balance
    @account.reload
    balance = @account.account_balances.first
    assert balance, "Account balance should exist"
    assert_equal 4_000, balance.posted_balance_cents
    assert_equal 4_000, balance.average_balance_cents

    # 4. Reverse
    reversal_batch = ReversalService.reverse!(posting_batch: batch)

    assert reversal_batch.persisted?
    assert_equal batch.id, reversal_batch.reversal_of_batch_id

    # 5. Verify balance zeroed
    @account.reload
    balance = @account.account_balances.first
    assert_equal 0, balance.posted_balance_cents
    assert_equal 2_000, balance.average_balance_cents
  end

  test "ADJ_DEBIT posts and affects balance correctly" do
    batch = PostingEngine.post!(
      transaction_code: "ADJ_DEBIT",
      account_id: @account.id,
      amount_cents: 5000,
      business_date: @business_date
    )

    assert batch.persisted?
    @account.reload
    balance = @account.account_balances.first
    assert_equal(-5000, balance.posted_balance_cents)
    assert_equal(-5000, balance.average_balance_cents)
  end
end
