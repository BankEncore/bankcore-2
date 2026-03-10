# frozen_string_literal: true

class DraftClearingService
  class DraftClearingError < StandardError; end

  def self.clear!(bank_draft:, clearing_reference: nil, cleared_by_id: nil)
    new(
      bank_draft: bank_draft,
      clearing_reference: clearing_reference,
      cleared_by_id: cleared_by_id
    ).clear!
  end

  def initialize(bank_draft:, clearing_reference: nil, cleared_by_id: nil)
    @bank_draft = bank_draft
    @clearing_reference = clearing_reference
    @cleared_by_id = cleared_by_id
  end

  def clear!
    validate_eligibility!

    @bank_draft.update!(
      status: BankDraft::STATUS_CLEARED,
      cleared_at: Time.current,
      clearing_reference: @clearing_reference,
      cleared_by_id: @cleared_by_id
    )
    @bank_draft
  end

  private

  def validate_eligibility!
    raise DraftClearingError, "Draft is not issued" unless @bank_draft.status == BankDraft::STATUS_ISSUED
  end
end
