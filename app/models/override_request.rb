# frozen_string_literal: true

class OverrideRequest < ApplicationRecord
  include Bankcore::Enums

  belongs_to :requested_by, class_name: "User", optional: true
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :branch, optional: true
  belongs_to :operational_transaction, class_name: "BankingTransaction", optional: true

  validates :request_type, presence: true, inclusion: { in: Bankcore::Enums::OVERRIDE_TYPES }
  validates :status, presence: true, inclusion: { in: Bankcore::Enums::OVERRIDE_STATUSES }

  scope :pending, -> { where(status: OVERRIDE_STATUS_PENDING) }
  scope :approved, -> { where(status: OVERRIDE_STATUS_APPROVED) }
  scope :usable, -> { where(status: OVERRIDE_STATUS_APPROVED).where(used_at: nil) }
end
