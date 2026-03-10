# frozen_string_literal: true

require "test_helper"

class BankDraftSequenceTest < ActiveSupport::TestCase
  test "valid sequence" do
    seq = BankDraftSequence.new(
      branch: branches(:two),
      instrument_type: BankDraft::INSTRUMENT_TYPE_CASHIERS_CHECK,
      last_number: 0
    )
    assert seq.valid?, seq.errors.full_messages.join(", ")
  end

  test "instrument_type must be valid" do
    seq = BankDraftSequence.new(
      branch: branches(:one),
      instrument_type: "invalid",
      last_number: 0
    )
    assert_not seq.valid?
    assert_includes seq.errors[:instrument_type], "is not included in the list"
  end

  test "unique per branch and instrument_type" do
    seq = bank_draft_sequences(:one)
    duplicate = BankDraftSequence.new(
      branch: seq.branch,
      instrument_type: seq.instrument_type,
      last_number: 100
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:instrument_type], "has already been taken"
  end
end
