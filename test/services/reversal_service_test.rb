# frozen_string_literal: true

require "test_helper"

class ReversalServiceTest < ActiveSupport::TestCase
  def setup
    @account = accounts(:one)
    @business_date = business_dates(:one).business_date
    @batch = PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: @account.id,
      amount_cents: 4000,
      business_date: @business_date
    )
  end

  test "reverses posted batch" do
    reversal_batch = ReversalService.reverse!(posting_batch: @batch)

    assert reversal_batch.persisted?
    assert_equal "posted", reversal_batch.status
    assert_equal @batch.id, reversal_batch.reversal_of_batch_id
  end

  test "reversal zeros out balance" do
    ReversalService.reverse!(posting_batch: @batch)

    @account.reload
    balance = @account.account_balances.first
    assert_equal 0, balance.posted_balance_cents
  end

  test "raises when batch not posted" do
    draft_batch = PostingBatch.create!(
      status: "draft",
      business_date: @business_date,
      transaction_code: "ADJ_CREDIT"
    )

    assert_raises(ReversalService::ReversalError) do
      ReversalService.reverse!(posting_batch: draft_batch)
    end
  end

  test "raises when already reversed" do
    ReversalService.reverse!(posting_batch: @batch)
    @batch.reload

    assert_raises(ReversalService::ReversalError) do
      ReversalService.reverse!(posting_batch: @batch)
    end
  end

  test "reverse! with override_request uses override" do
    high_value_batch = high_value_batch()
    override = OverrideRequest.create!(
      request_type: "reversal",
      status: "approved",
      operational_transaction_id: high_value_batch.operational_transaction_id,
      branch_id: @account.branch_id
    )

    reversal_batch = ReversalService.reverse!(posting_batch: high_value_batch, override_request: override)

    assert reversal_batch.persisted?
    override.reload
    assert override.used_at.present?
    assert_equal "used", override.status
  end

  test "idempotent reversal retry returns existing reversal batch" do
    key = "reversal-idem-#{SecureRandom.hex(8)}"

    reversal_batch = ReversalService.reverse!(posting_batch: @batch, idempotency_key: key)
    replay_batch = ReversalService.reverse!(posting_batch: @batch, idempotency_key: key)

    assert_equal reversal_batch.id, replay_batch.id
  end

  test "raises when high-value reversal lacks override approval" do
    error = assert_raises(ReversalService::OverrideRequiredError) do
      ReversalService.reverse!(posting_batch: high_value_batch())
    end

    assert_match(/require supervisor approval/i, error.message)
  end

  test "uses an existing approved override from service policy" do
    high_value_batch = high_value_batch()
    override = OverrideRequest.create!(
      request_type: "reversal",
      status: "approved",
      operational_transaction_id: high_value_batch.operational_transaction_id,
      branch_id: @account.branch_id
    )

    reversal_batch = ReversalService.reverse!(posting_batch: high_value_batch)

    assert reversal_batch.persisted?
    override.reload
    assert_equal "used", override.status
  end

  test "emits reversal requested and committed audit events" do
    assert_difference "AuditEvent.count", 4 do
      ReversalService.reverse!(posting_batch: @batch)
    end

    events = AuditEvent.order(:id).last(4).map(&:event_type)
    assert_equal [ "reversal_requested", "posting_requested", "posting_committed", "reversal_committed" ], events
  end

  private

  def high_value_batch
    PostingEngine.post!(
      transaction_code: "ADJ_CREDIT",
      account_id: @account.id,
      amount_cents: Bankcore::REVERSAL_OVERRIDE_THRESHOLD_CENTS,
      business_date: @business_date
    )
  end
end
