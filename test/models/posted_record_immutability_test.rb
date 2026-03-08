# frozen_string_literal: true

require "test_helper"

class PostedRecordImmutabilityTest < ActiveSupport::TestCase
  def setup
    @batch = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: accounts(:one).id,
      amount_cents: 4_200,
      business_date: business_dates(:one).business_date
    )
    @posting_leg = @batch.posting_legs.first
    @journal_entry = @batch.journal_entries.first
    @journal_entry_line = @journal_entry.journal_entry_lines.first
    @account_transaction = AccountTransaction.find_by!(posting_batch_id: @batch.id)
  end

  test "posted financial rows reject updates" do
    assert_immutable_update(@batch, transaction_code: "ADJ_DEBIT")
    assert_immutable_update(@posting_leg, amount_cents: 9_999)
    assert_immutable_update(@journal_entry, reference_number: "JE-OVERRIDE")
    assert_immutable_update(@journal_entry_line, memo: "updated")
    assert_immutable_update(@account_transaction, description: "updated")
  end

  test "posted financial rows reject deletes" do
    assert_immutable_destroy(@batch)
    assert_immutable_destroy(@posting_leg)
    assert_immutable_destroy(@journal_entry)
    assert_immutable_destroy(@journal_entry_line)
    assert_immutable_destroy(@account_transaction)
  end

  private

  def assert_immutable_update(record, attrs)
    assert_raises(ActiveRecord::RecordNotSaved) do
      record.update!(attrs)
    end

    assert_includes record.errors.full_messages.join(", "), "cannot be updated once posted"
  end

  def assert_immutable_destroy(record)
    assert_raises(ActiveRecord::RecordNotDestroyed) do
      record.destroy!
    end

    assert_includes record.errors.full_messages.join(", "), "cannot be deleted once posted"
  end
end
