# frozen_string_literal: true

require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "validates account_number presence and uniqueness" do
    account = Account.new(account_type: "dda", branch: branches(:one), currency_code: "USD", status: "active")
    assert_not account.valid?
    assert_includes account.errors[:account_number], "can't be blank"

    assert_raises(ActiveRecord::RecordInvalid) do
      Account.create!(account_number: "1001", account_type: "dda", branch: branches(:one), currency_code: "USD", status: "active")
    end
  end

  test "validates account_type inclusion" do
    account = accounts(:one)
    account.account_type = "invalid"
    assert_not account.valid?
  end

  test "belongs to branch" do
    account = accounts(:one)
    assert_equal branches(:one), account.branch
  end

  test "has many account_owners" do
    account = accounts(:one)
    assert_respond_to account, :account_owners
    assert account.account_owners.any?
  end
end
