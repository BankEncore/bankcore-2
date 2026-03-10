# frozen_string_literal: true

require "test_helper"

class BankDraftTest < ActiveSupport::TestCase
  test "valid bank draft" do
    draft = BankDraft.new(
      instrument_type: BankDraft::INSTRUMENT_TYPE_CASHIERS_CHECK,
      instrument_number: "2001",
      amount_cents: 5000,
      currency_code: "USD",
      payee_name: "Acme Corp",
      issue_date: Date.current,
      status: BankDraft::STATUS_ISSUED,
      remitter_party: parties(:one),
      branch: branches(:one)
    )
    assert draft.valid?, draft.errors.full_messages.join(", ")
  end

  test "requires instrument_type" do
    draft = build_valid_draft(instrument_type: nil)
    assert_not draft.valid?
    assert_includes draft.errors[:instrument_type], "can't be blank"
  end

  test "instrument_type must be valid" do
    draft = build_valid_draft(instrument_type: "invalid")
    assert_not draft.valid?
    assert_includes draft.errors[:instrument_type], "is not included in the list"
  end

  test "requires instrument_number" do
    draft = build_valid_draft(instrument_number: nil)
    assert_not draft.valid?
    assert_includes draft.errors[:instrument_number], "can't be blank"
  end

  test "instrument_number must be unique per instrument_type" do
    unique_num = "uniq-#{SecureRandom.hex(4)}"
    draft = build_valid_draft(instrument_number: unique_num)
    draft.save!
    duplicate = build_valid_draft(instrument_number: unique_num)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:instrument_number], "has already been taken"
  end

  test "allows same instrument_number for different instrument_types" do
    BankDraft.create!(
      instrument_type: BankDraft::INSTRUMENT_TYPE_CASHIERS_CHECK,
      instrument_number: "3001",
      amount_cents: 1000,
      currency_code: "USD",
      payee_name: "A",
      issue_date: Date.current,
      status: BankDraft::STATUS_ISSUED,
      remitter_party: parties(:one),
      branch: branches(:one)
    )
    draft = build_valid_draft(
      instrument_type: BankDraft::INSTRUMENT_TYPE_MONEY_ORDER,
      instrument_number: "3001"
    )
    assert draft.valid?, draft.errors.full_messages.join(", ")
  end

  test "requires amount_cents" do
    draft = build_valid_draft(amount_cents: nil)
    assert_not draft.valid?
    assert_includes draft.errors[:amount_cents], "can't be blank"
  end

  test "amount_cents must be positive" do
    draft = build_valid_draft(amount_cents: 0)
    assert_not draft.valid?
    assert_includes draft.errors[:amount_cents], "must be greater than 0"
  end

  test "requires payee_name" do
    draft = build_valid_draft(payee_name: nil)
    assert_not draft.valid?
    assert_includes draft.errors[:payee_name], "can't be blank"
  end

  test "requires issue_date" do
    draft = build_valid_draft(issue_date: nil)
    assert_not draft.valid?
    assert_includes draft.errors[:issue_date], "can't be blank"
  end

  test "status must be valid" do
    draft = build_valid_draft(status: "invalid")
    assert_not draft.valid?
    assert_includes draft.errors[:status], "is not included in the list"
  end

  test "scopes" do
    BankDraft.destroy_all
    BankDraft.create!(
      instrument_type: BankDraft::INSTRUMENT_TYPE_CASHIERS_CHECK,
      instrument_number: "5001",
      amount_cents: 1000,
      currency_code: "USD",
      payee_name: "A",
      issue_date: Date.current,
      status: BankDraft::STATUS_ISSUED,
      remitter_party: parties(:one),
      branch: branches(:one)
    )
    BankDraft.create!(
      instrument_type: BankDraft::INSTRUMENT_TYPE_CASHIERS_CHECK,
      instrument_number: "5002",
      amount_cents: 2000,
      currency_code: "USD",
      payee_name: "B",
      issue_date: Date.current,
      status: BankDraft::STATUS_VOIDED,
      remitter_party: parties(:one),
      branch: branches(:one)
    )
    assert_equal 1, BankDraft.issued.count
    assert_equal 1, BankDraft.voided.count
    assert_equal 1, BankDraft.outstanding.count
  end

  private

  def build_valid_draft(overrides = {})
    BankDraft.new(
      {
        instrument_type: BankDraft::INSTRUMENT_TYPE_CASHIERS_CHECK,
        instrument_number: "9999",
        amount_cents: 1000,
        currency_code: "USD",
        payee_name: "Test",
        issue_date: Date.current,
        status: BankDraft::STATUS_ISSUED,
        remitter_party: parties(:one),
        branch: branches(:one)
      }.merge(overrides)
    )
  end
end
