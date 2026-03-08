# frozen_string_literal: true

require "test_helper"

class BalanceRefreshServiceTest < ActiveSupport::TestCase
  def setup
    @account = accounts(:one)
    @business_date = business_dates(:one).business_date
  end

  test "refresh! creates or updates account balance" do
    PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: @account.id,
      amount_cents: 3000,
      business_date: @business_date
    )

    BalanceRefreshService.refresh!(account_ids: [ @account.id ])

    @account.reload
    balance = @account.account_balances.first
    assert balance
    assert_equal 3000, balance.posted_balance_cents
  end

  test "rebuild! reconstructs balance from transactions" do
    PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: @account.id,
      amount_cents: 2000,
      business_date: @business_date
    )
    PostingEngine.post!(
      transaction_code: "ADJ_DEBIT",
      account_id: @account.id,
      amount_cents: 500,
      business_date: @business_date
    )

    BalanceRefreshService.rebuild!(account_id: @account.id)

    @account.reload
    balance = @account.account_balances.first
    assert_equal 1500, balance.posted_balance_cents
  end

  test "available_balance subtracts active holds" do
    PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: @account.id,
      amount_cents: 10_000,
      business_date: @business_date
    )
    AccountHold.create!(
      account_id: @account.id,
      hold_type: "manual",
      amount_cents: 3_000,
      status: Bankcore::Enums::HOLD_STATUS_ACTIVE,
      effective_on: @business_date
    )

    BalanceRefreshService.refresh!(account_ids: [ @account.id ])

    balance = @account.account_balances.first
    assert_equal 10_000, balance.posted_balance_cents
    assert_equal 7_000, balance.available_balance_cents
  end
end
