# frozen_string_literal: true

require "test_helper"

class AccountHoldServiceTest < ActiveSupport::TestCase
  setup do
    @branch = Branch.first || Branch.create!(branch_code: "T", name: "Test", status: "active")
    @account = Account.first || Account.create!(
      account_number: "HOLD001",
      account_type: "dda",
      branch_id: @branch.id,
      status: "active"
    )
  end

  test "place! creates active hold" do
    hold = AccountHoldService.place!(
      account_id: @account.id,
      amount_cents: 10_000,
      hold_type: "manual",
      reason_code: "court_order"
    )

    assert hold.persisted?
    assert_equal "active", hold.status
    assert_equal 10_000, hold.amount_cents
    assert_equal "manual", hold.hold_type
    assert_equal @account.id, hold.account_id
  end

  test "release! updates hold status" do
    hold = AccountHoldService.place!(
      account_id: @account.id,
      amount_cents: 5_000
    )

    AccountHoldService.release!(account_hold: hold)

    hold.reload
    assert_equal "released", hold.status
    assert hold.released_at.present?
  end

  test "place! raises for invalid account" do
    assert_raises(AccountHoldService::HoldError) do
      AccountHoldService.place!(
        account_id: 999_999,
        amount_cents: 1_000
      )
    end
  end

  test "place! raises for zero amount" do
    assert_raises(AccountHoldService::HoldError) do
      AccountHoldService.place!(
        account_id: @account.id,
        amount_cents: 0
      )
    end
  end

  test "release! raises when hold not active" do
    hold = AccountHoldService.place!(
      account_id: @account.id,
      amount_cents: 1_000
    )
    AccountHoldService.release!(account_hold: hold)

    assert_raises(AccountHoldService::HoldError) do
      AccountHoldService.release!(account_hold: hold)
    end
  end

  test "release! updates available balance" do
    PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: @account.id,
      amount_cents: 10_000,
      business_date: BusinessDateService.current
    )
    hold = AccountHoldService.place!(
      account_id: @account.id,
      amount_cents: 3_000
    )

    balance_before = @account.account_balances.first
    assert_equal 10_000, balance_before.posted_balance_cents
    assert_equal 7_000, balance_before.available_balance_cents

    AccountHoldService.release!(account_hold: hold)

    @account.reload
    balance_after = @account.account_balances.first
    assert_equal 10_000, balance_after.posted_balance_cents
    assert_equal 10_000, balance_after.available_balance_cents, "Available balance should increase when hold is released"
  end
end
