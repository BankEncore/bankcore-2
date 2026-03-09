# frozen_string_literal: true

class ReversalService
  include Bankcore::Enums
  include ActiveSupport::NumberHelper

  class ReversalError < StandardError; end
  class OverrideRequiredError < ReversalError; end

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
    precheck_override_requirement!

    @posting_batch.with_lock do
      if @posting_batch.reversal_batch.present?
        return @posting_batch.reversal_batch if idempotent_replay?

        raise ReversalError, "Batch already reversed"
      end

      reversal_code = TransactionCode.find_by(code: @posting_batch.transaction_code)&.reversal_code
      raise ReversalError, "No reversal code for #{@posting_batch.transaction_code}" if reversal_code.blank?

      override_request = resolve_override_request!
      emit_reversal_requested!(reversal_code: reversal_code)

      reversal_batch = nil
      ActiveRecord::Base.transaction do
        reversal_batch = create_reversal_batch!(reversal_code)
        OverrideRequestService.use!(override_request: override_request) if override_request.present?
        AuditEmissionService.emit!(
          event_type: AuditEmissionService::EVENT_REVERSAL_COMMITTED,
          action: "reverse",
          target: reversal_batch,
          metadata: {
            original_batch_id: @posting_batch.id,
            reversal_code: reversal_code,
            posting_reference: reversal_batch.posting_reference
          }
        )
      end
      reversal_batch
    end
  end

  private

  def precheck_override_requirement!
    return unless override_required?
    return if @override_request.present?
    return if OverrideRequest.usable.exists?(
      operational_transaction_id: @posting_batch.operational_transaction_id,
      request_type: OVERRIDE_TYPE_REVERSAL
    )

    create_override_required_exception!
    raise OverrideRequiredError, override_required_message
  end

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

  def resolve_override_request!
    return nil unless override_required?

    override_request = @override_request || OverrideRequest.usable.find_by(
      operational_transaction_id: @posting_batch.operational_transaction_id,
      request_type: OVERRIDE_TYPE_REVERSAL
    )
    raise OverrideRequiredError, override_required_message unless override_request

    validate_override_request!(override_request)
    override_request
  end

  def validate_override_request!(override_request)
    return if override_request.request_type == OVERRIDE_TYPE_REVERSAL &&
      override_request.operational_transaction_id == @posting_batch.operational_transaction_id

    raise ReversalError, "Override request is not valid for this reversal"
  end

  def override_required?
    # Use debit-leg sum (economic amount), not total leg sum which doubles for balanced two-leg postings
    economic_amount_cents = @posting_batch.posting_legs.where(leg_type: LEG_TYPE_DEBIT).sum(:amount_cents)
    economic_amount_cents >= Bankcore::REVERSAL_OVERRIDE_THRESHOLD_CENTS
  end

  def override_required_message
    threshold = number_to_currency(Bankcore::REVERSAL_OVERRIDE_THRESHOLD_CENTS / 100.0)
    "Reversals of #{threshold} or more require supervisor approval. Please request an override first."
  end

  def emit_reversal_requested!(reversal_code:)
    AuditEmissionService.emit!(
      event_type: AuditEmissionService::EVENT_REVERSAL_REQUESTED,
      action: "request",
      target: @posting_batch,
      business_date: BusinessDateService.current,
      metadata: {
        original_batch_id: @posting_batch.id,
        reversal_code: reversal_code,
        idempotency_key: @idempotency_key
      }.compact
    )
  end

  def create_override_required_exception!
    return unless @posting_batch.operational_transaction_id.present?

    TransactionException.find_or_create_by!(
      transaction_id: @posting_batch.operational_transaction_id,
      exception_type: TransactionException::EXCEPTION_TYPE_OVERRIDE_REQUIRED,
      status: TransactionException::STATUS_OPEN,
      reason_code: "reversal_threshold",
      requires_override: true
    )
  end
end
