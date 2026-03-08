# frozen_string_literal: true

class PostingLeg < ApplicationRecord
  include Bankcore::Enums

  belongs_to :posting_batch
  belongs_to :gl_account, optional: true
  belongs_to :account, optional: true

  validates :leg_type, presence: true, inclusion: { in: Bankcore::Enums::LEG_TYPES }
  validates :ledger_scope, presence: true, inclusion: { in: Bankcore::Enums::LEDGER_SCOPES }
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validate :has_target

  private

  def has_target
    return if gl_account_id.present? ^ account_id.present?

    errors.add(:base, "Leg must have exactly one of gl_account or account")
  end
end
