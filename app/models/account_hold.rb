# frozen_string_literal: true

class AccountHold < ApplicationRecord
  include Bankcore::Enums

  belongs_to :account

  validates :hold_type, presence: true
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :status, presence: true, inclusion: { in: Bankcore::Enums::HOLD_STATUSES }
end
