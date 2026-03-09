# frozen_string_literal: true

class InterestAccrual < ApplicationRecord
  include Bankcore::Enums

  belongs_to :account
  belongs_to :interest_rule, optional: true
  belongs_to :posting_batch, optional: true
  has_one :interest_posting_application, dependent: :restrict_with_error

  validates :accrual_date, presence: true
  validates :amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: Bankcore::Enums::POSTING_STATUSES }

  scope :unposted, -> { where.missing(:interest_posting_application) }
end
