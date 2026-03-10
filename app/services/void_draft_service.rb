# frozen_string_literal: true

class VoidDraftService
  class VoidDraftError < StandardError; end

  def self.void!(bank_draft:, void_reason:, voided_by_id: nil, idempotency_key: nil, override_request: nil)
    new(
      bank_draft: bank_draft,
      void_reason: void_reason,
      voided_by_id: voided_by_id,
      idempotency_key: idempotency_key,
      override_request: override_request
    ).void!
  end

  def initialize(bank_draft:, void_reason:, voided_by_id: nil, idempotency_key: nil, override_request: nil)
    @bank_draft = bank_draft
    @void_reason = void_reason
    @voided_by_id = voided_by_id
    @idempotency_key = idempotency_key
    @override_request = override_request
  end

  def void!
    validate_eligibility!

    reversal_batch = ReversalService.reverse!(
      posting_batch: @bank_draft.posting_batch,
      idempotency_key: @idempotency_key,
      override_request: @override_request
    )

    @bank_draft.update!(void_reason: @void_reason, voided_by_id: @voided_by_id)
    reversal_batch
  end

  private

  def validate_eligibility!
    raise VoidDraftError, "Draft is not issued" unless @bank_draft.status == BankDraft::STATUS_ISSUED
    raise VoidDraftError, "Draft has no posting batch" unless @bank_draft.posting_batch.present?
    raise VoidDraftError, "Void reason is required" if @void_reason.blank?
  end
end
