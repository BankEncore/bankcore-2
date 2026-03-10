# frozen_string_literal: true

class BankDraftSequenceService
  def self.next_number!(branch_id:, instrument_type:)
    new(branch_id: branch_id, instrument_type: instrument_type).next_number!
  end

  def initialize(branch_id:, instrument_type:)
    @branch_id = branch_id
    @instrument_type = instrument_type
  end

  def next_number!
    BankDraftSequence.transaction do
      seq = BankDraftSequence.lock.find_or_initialize_by(
        branch_id: @branch_id,
        instrument_type: @instrument_type
      )
      seq.last_number ||= 0
      seq.last_number += 1
      seq.save!
      seq.last_number.to_s
    end
  end
end
