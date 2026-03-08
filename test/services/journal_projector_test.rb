# frozen_string_literal: true

require "test_helper"

class JournalProjectorTest < ActiveSupport::TestCase
  test "uses posting reference as journal entry reference number" do
    batch = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: accounts(:one).id,
      amount_cents: 1_000,
      business_date: business_dates(:one).business_date
    )

    assert_equal batch.posting_reference, batch.journal_entries.first.reference_number
  end
end
