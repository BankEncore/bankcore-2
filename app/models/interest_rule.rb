# frozen_string_literal: true

class InterestRule < ApplicationRecord
  DAY_COUNT_METHOD_ACTUAL_365 = "actual_365"
  DAY_COUNT_METHOD_30_360 = "30_360"
  DAY_COUNT_METHODS = [ DAY_COUNT_METHOD_ACTUAL_365, DAY_COUNT_METHOD_30_360 ].freeze

  POSTING_CADENCE_MONTHLY = "monthly"
  POSTING_CADENCE_QUARTERLY = "quarterly"
  POSTING_CADENCE_ANNUAL = "annual"
  POSTING_CADENCES = [
    POSTING_CADENCE_MONTHLY,
    POSTING_CADENCE_QUARTERLY,
    POSTING_CADENCE_ANNUAL
  ].freeze

  belongs_to :account_product

  has_many :interest_accruals, dependent: :restrict_with_error

  validates :rate, presence: true, numericality: { greater_than: 0 }
  validates :day_count_method, presence: true, inclusion: { in: DAY_COUNT_METHODS }
  validates :posting_cadence, presence: true, inclusion: { in: POSTING_CADENCES }
  validate :active_range_is_valid

  scope :active_on, lambda { |date|
    where("effective_on IS NULL OR effective_on <= ?", date)
      .where("ends_on IS NULL OR ends_on >= ?", date)
  }
  scope :ordered, -> { order(effective_on: :desc, id: :desc) }

  private

  def active_range_is_valid
    return if effective_on.blank? || ends_on.blank?
    return if ends_on >= effective_on

    errors.add(:ends_on, "must be on or after effective_on")
  end
end
