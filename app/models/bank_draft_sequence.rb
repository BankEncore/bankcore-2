# frozen_string_literal: true

class BankDraftSequence < ApplicationRecord
  include Bankcore::Enums

  belongs_to :branch

  validates :instrument_type, presence: true, inclusion: { in: Bankcore::Enums::BANK_DRAFT_INSTRUMENT_TYPES }
  validates :last_number, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :instrument_type, uniqueness: { scope: :branch_id }
end
