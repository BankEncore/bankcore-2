# frozen_string_literal: true

class TransactionReference < ApplicationRecord
  REFERENCE_TYPE_REFERENCE_NUMBER = "reference_number"
  REFERENCE_TYPE_EXTERNAL_REFERENCE = "external_reference"
  REFERENCE_TYPE_IDEMPOTENCY_KEY = "idempotency_key"

  belongs_to :operational_transaction, class_name: "BankingTransaction", foreign_key: :transaction_id

  validates :reference_type, presence: true
  validates :reference_value, presence: true
  validates :reference_value, uniqueness: { scope: [ :transaction_id, :reference_type ] }
end
