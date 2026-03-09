# frozen_string_literal: true

class TransactionException < ApplicationRecord
  EXCEPTION_TYPE_OVERRIDE_REQUIRED = "override_required"
  EXCEPTION_TYPE_POLICY_BLOCKED = "policy_blocked"
  EXCEPTION_TYPES = [
    EXCEPTION_TYPE_OVERRIDE_REQUIRED,
    EXCEPTION_TYPE_POLICY_BLOCKED
  ].freeze

  STATUS_OPEN = "open"
  STATUS_RESOLVED = "resolved"
  STATUS_BLOCKED = "blocked"
  STATUSES = [
    STATUS_OPEN,
    STATUS_RESOLVED,
    STATUS_BLOCKED
  ].freeze

  belongs_to :operational_transaction, class_name: "BankingTransaction", foreign_key: :transaction_id
  belongs_to :resolved_by, class_name: "User", optional: true

  validates :exception_type, presence: true, inclusion: { in: EXCEPTION_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :reason_code, presence: true

  scope :open, -> { where(status: STATUS_OPEN) }

  def resolve!(resolved_by_id: nil)
    update!(
      status: STATUS_RESOLVED,
      resolved_at: Time.current,
      resolved_by_id: resolved_by_id
    )
  end

  def block!(resolved_by_id: nil)
    update!(
      status: STATUS_BLOCKED,
      resolved_at: Time.current,
      resolved_by_id: resolved_by_id
    )
  end
end
