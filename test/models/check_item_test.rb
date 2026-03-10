# frozen_string_literal: true

require "test_helper"

class CheckItemTest < ActiveSupport::TestCase
  test "valid check item" do
    item = CheckItem.new(
      account: accounts(:one),
      check_number: "1001",
      amount_cents: 1000,
      status: CheckItem::STATUS_POSTED,
      operational_transaction: transactions(:one),
      posting_batch: posting_batches(:one),
      business_date: Date.current
    )
    assert item.valid?, item.errors.full_messages.join(", ")
  end

  test "requires check_number" do
    item = CheckItem.new(
      account: accounts(:one),
      check_number: nil,
      amount_cents: 1000,
      status: CheckItem::STATUS_POSTED,
      operational_transaction: transactions(:one),
      posting_batch: posting_batches(:one),
      business_date: Date.current
    )
    assert_not item.valid?
    assert_includes item.errors[:check_number], "can't be blank"
  end

  test "status must be valid" do
    item = CheckItem.new(
      account: accounts(:one),
      check_number: "1001",
      amount_cents: 1000,
      status: "invalid",
      operational_transaction: transactions(:one),
      posting_batch: posting_batches(:one),
      business_date: Date.current
    )
    assert_not item.valid?
    assert_includes item.errors[:status], "is not included in the list"
  end
end
