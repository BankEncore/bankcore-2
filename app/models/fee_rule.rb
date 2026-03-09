# frozen_string_literal: true

class FeeRule < ApplicationRecord
  METHOD_FIXED_AMOUNT = "fixed_amount"
  METHODS = [ METHOD_FIXED_AMOUNT ].freeze

  belongs_to :fee_type
  belongs_to :account_product
  belongs_to :gl_account, optional: true

  has_many :fee_assessments, dependent: :restrict_with_error

  validates :priority, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :method, presence: true, inclusion: { in: METHODS }
  validates :amount_cents, numericality: { greater_than: 0 }, allow_nil: true
  validate :active_range_is_valid

  scope :active_on, lambda { |date|
    where("effective_on IS NULL OR effective_on <= ?", date)
      .where("ends_on IS NULL OR ends_on >= ?", date)
  }
  scope :ordered, -> { order(:priority, :id) }

  def amount_cents_for_assessment
    amount_cents || fee_type.default_amount_cents
  end

  def gl_account_id_for_posting
    gl_account_id || fee_type.gl_account_id
  end

  private

  def active_range_is_valid
    return if effective_on.blank? || ends_on.blank?
    return if ends_on >= effective_on

    errors.add(:ends_on, "must be on or after effective_on")
  end
end
