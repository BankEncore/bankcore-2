# frozen_string_literal: true

class ReversalService
  include Bankcore::Enums

  class ReversalError < StandardError; end

  def self.reverse!(posting_batch:, idempotency_key: nil, override_request: nil)
    new(posting_batch: posting_batch, idempotency_key: idempotency_key, override_request: override_request).reverse!
  end

  def initialize(posting_batch:, idempotency_key: nil, override_request: nil)
    @posting_batch = posting_batch
    @idempotency_key = idempotency_key
    @override_request = override_request
  end

  def reverse!
    raise ReversalError, "Batch is not posted" unless @posting_batch.status == STATUS_POSTED

    if @posting_batch.reversal_batch.present?
      return @posting_batch.reversal_batch if idempotent_replay?

      raise ReversalError, "Batch already reversed"
    end

    reversal_code = TransactionCode.find_by(code: @posting_batch.transaction_code)&.reversal_code
    raise ReversalError, "No reversal code for #{@posting_batch.transaction_code}" if reversal_code.blank?

    reversal_batch = nil
    ActiveRecord::Base.transaction do
      reversal_batch = create_reversal_batch!(reversal_code)
      OverrideRequestService.use!(override_request: @override_request) if @override_request.present?
      AuditEmissionService.emit!(
        event_type: "reversal_created",
        action: "reverse",
        target: reversal_batch,
        metadata: {
          original_batch_id: @posting_batch.id,
          reversal_code: reversal_code
        }
      )
    end
    reversal_batch
  end

  private

  def create_reversal_batch!(reversal_code)
    legs = @posting_batch.posting_legs.order(:position)
    account_leg = legs.find { |l| l.ledger_scope == LEDGER_SCOPE_ACCOUNT }

    batch = PostingEngine.post!(
      transaction_code: reversal_code,
      account_id: reversal_code == "XFER_INTERNAL" ? nil : account_leg&.account_id,
      source_account_id: reversal_code == "XFER_INTERNAL" ? legs.find { |l| l.leg_type == LEG_TYPE_CREDIT }&.account_id : nil,
      destination_account_id: reversal_code == "XFER_INTERNAL" ? legs.find { |l| l.leg_type == LEG_TYPE_DEBIT }&.account_id : nil,
      amount_cents: legs.first.amount_cents,
      business_date: BusinessDateService.current,
      idempotency_key: @idempotency_key,
      reversal_of_batch_id: @posting_batch.id,
      gl_account_id: legs.find { |l| l.gl_account_id.present? }&.gl_account_id
    )
    batch
  end

  def idempotent_replay?
    @idempotency_key.present? && @posting_batch.reversal_batch.idempotency_key == @idempotency_key
  end
end
