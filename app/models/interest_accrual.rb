# frozen_string_literal: true

class InterestAccrual < ApplicationRecord
  include Bankcore::Enums

  belongs_to :account
  belongs_to :posting_batch, optional: true

  validates :accrual_date, presence: true
  validates :amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: Bankcore::Enums::POSTING_STATUSES }
end
