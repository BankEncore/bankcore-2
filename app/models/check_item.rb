# frozen_string_literal: true

class CheckItem < ApplicationRecord
  STATUS_POSTED = "posted"
  STATUS_RETURNED = "returned"
  STATUS_REVERSED = "reversed"
  STATUS_EXCEPTION = "exception"

  belongs_to :account
  belongs_to :operational_transaction, class_name: "BankingTransaction", foreign_key: :operational_transaction_id
  belongs_to :posting_batch

  validates :check_number, presence: true
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: [ STATUS_POSTED, STATUS_RETURNED, STATUS_REVERSED, STATUS_EXCEPTION ] }
  validates :business_date, presence: true
end
