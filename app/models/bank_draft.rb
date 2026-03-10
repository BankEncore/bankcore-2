# frozen_string_literal: true

class BankDraft < ApplicationRecord
  include Bankcore::Enums

  STATUS_ISSUED = "issued"
  STATUS_VOIDED = "voided"
  STATUS_CLEARED = "cleared"

  DRAFT_STATUSES = [ STATUS_ISSUED, STATUS_VOIDED, STATUS_CLEARED ].freeze

  INSTRUMENT_TYPE_CASHIERS_CHECK = "cashiers_check"
  INSTRUMENT_TYPE_MONEY_ORDER = "money_order"

  INSTRUMENT_TYPES = [
    INSTRUMENT_TYPE_CASHIERS_CHECK,
    INSTRUMENT_TYPE_MONEY_ORDER
  ].freeze

  belongs_to :branch
  belongs_to :remitter_party, class_name: "Party"
  belongs_to :account, optional: true
  belongs_to :issued_by, class_name: "User", optional: true
  belongs_to :voided_by, class_name: "User", optional: true
  belongs_to :cleared_by, class_name: "User", optional: true
  belongs_to :operational_transaction, class_name: "BankingTransaction", optional: true, foreign_key: :operational_transaction_id
  belongs_to :posting_batch, optional: true

  validates :instrument_type, presence: true, inclusion: { in: INSTRUMENT_TYPES }
  validates :instrument_number, presence: true
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :currency_code, presence: true
  validates :payee_name, presence: true
  validates :issue_date, presence: true
  validates :status, presence: true, inclusion: { in: DRAFT_STATUSES }
  validates :instrument_number, uniqueness: { scope: :instrument_type }

  scope :issued, -> { where(status: STATUS_ISSUED) }
  scope :voided, -> { where(status: STATUS_VOIDED) }
  scope :cleared, -> { where(status: STATUS_CLEARED) }
  scope :outstanding, -> { where(status: STATUS_ISSUED) }
end
