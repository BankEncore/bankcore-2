# frozen_string_literal: true

class FeeAssessment < ApplicationRecord
  include Bankcore::Enums

  belongs_to :account
  belongs_to :fee_type
  belongs_to :fee_rule, optional: true
  belongs_to :posting_batch, optional: true

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :assessed_on, presence: true
  validates :status, presence: true, inclusion: { in: Bankcore::Enums::POSTING_STATUSES }
end
