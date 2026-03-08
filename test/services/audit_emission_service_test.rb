# frozen_string_literal: true

require "test_helper"

class AuditEmissionServiceTest < ActiveSupport::TestCase
  test "emit! creates audit event" do
    assert_difference "AuditEvent.count", 1 do
      AuditEmissionService.emit!(
        event_type: "posting_succeeded",
        action: "post",
        target: posting_batches(:one),
        metadata: { transaction_code: "ADJ_CREDIT" }
      )
    end

    event = AuditEvent.last
    assert_equal "posting_succeeded", event.event_type
    assert_equal "post", event.action
    assert_equal "PostingBatch", event.target_type
    assert event.target_id.present?
    assert_equal({ "transaction_code" => "ADJ_CREDIT" }, JSON.parse(event.metadata_json))
  end

  test "emit! with optional params" do
    AuditEmissionService.emit!(
      event_type: "reversal_created",
      action: "reverse",
      target: nil,
      actor: nil,
      business_date: Date.current,
      metadata: {}
    )

    event = AuditEvent.last
    assert_equal "reversal_created", event.event_type
    assert_equal Date.current, event.business_date
  end

  private

  def posting_batches(which)
    # Use fixture if available, else create minimal batch
    return PostingBatch.first if PostingBatch.any?

    branch = Branch.first || Branch.create!(branch_code: "T", name: "Test", status: "active")
    txn = BankingTransaction.create!(
      transaction_type: "ADJ_CREDIT",
      channel: "back_office",
      branch_id: branch.id,
      status: "posted",
      business_date: Date.current
    )
    PostingBatch.create!(
      operational_transaction_id: txn.id,
      status: "posted",
      business_date: Date.current,
      transaction_code: "ADJ_CREDIT"
    )
  end
end
